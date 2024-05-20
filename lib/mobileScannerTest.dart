import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quick_scanner/helper/devlog.dart';

class ScanWindowPage extends StatefulWidget {
  final Function(Set, Set, Set) onScanned;
  final dynamic jsonData;

  const ScanWindowPage({
    super.key,
    required this.onScanned,
    required this.jsonData,
  });

  @override
  State<ScanWindowPage> createState() => _ScanWindowPageState();
}

class _ScanWindowPageState extends State<ScanWindowPage> {
  // 'assets/data/JsonData.json'

  //Load Json資料
  Future<dynamic>? jsonDataFuture;

  //插件Controller
  late MobileScannerController controller = MobileScannerController();
  BarcodeCapture? capture;
  Barcode? barcode;
  MobileScannerArguments? arguments;

  //用來判斷Qrcode是否吻合
  bool isCodeMatched = false;

  //讀取Json的List
  List<CodeData> codeDataList = [];

  //用來放已辦清單中
  Set<String> matchedCode = <String>{};

  //已辦清單顯示List
  //List<String> matchedList = [];

  //誤掃清單
  Set<String> errorScannedList = <String>{};

  //掃描到的Code
  Set<String> scannedCodeList = <String>{};

  Timer? _resetTimer;

  //當掃描到的時候的情境
  //因為相機是持續開啟，所以這個部分也就會持續的進行判斷
  //判定的基準是以相機的每一偵數進行
  Future<void> onDetect(BarcodeCapture barcode) async {
    capture = barcode;

    //選擇相機掃到的第一組Qrcode
    String scannedCode = barcode.barcodes.first.displayValue ?? '';

    //判斷條件
    bool isMatch = await checkCodeInJson(scannedCode);

    //動態更新
    //把相機畫面擷取到的第一筆資料更新為當前的barcode
    setState(() {
      this.barcode = barcode.barcodes.first;

      isCodeMatched = isMatch;
    });

    //把符合的放進已辦清單
    if (isMatch) {
      setState(() {
        matchedCode.add(scannedCode);
        //sortScannedList(matchedCode);
      });

      scannedCodeList.add(scannedCode);
    } else {
      setState(() {
        errorScannedList.add(scannedCode);
      });
      scannedCodeList.add(scannedCode);
    }

    //假如三秒後沒有掃描到任何東西就會清除畫面上的框框
    resetScanResults();

    checkScannedCodeIsOver();
  }

  //用來檢查QRcode是否跟Json資料一樣
  Future<bool> checkCodeInJson(String scannedCode) async {
    //List<CodeData> codeData = await loadJsonData();

    //回傳true、false(是否相同)
    return codeDataList.any((element) => element.code == scannedCode);
  }

  //改成兩種輸入格式
  //1.Json
  //2.String
  //3.路徑
  Future<List<CodeData>> loadJsonData(dynamic jsonData) async {
    List<dynamic> jsonList;

    if (jsonData is String && jsonData.contains('.json')) {
      String Data = await DefaultAssetBundle.of(context).loadString(jsonData);
      jsonList = json.decode(Data);
    } else if (jsonData is List) {
      // 直接使用已解析的JSON數組
      jsonList = jsonData;
    } else if (jsonData is Map) {
      // 如果是Map，同樣包裝為List進行處理
      jsonList = [jsonData];
    } else {
      throw ArgumentError('Unsupported type of jsonData');
    }

    //將Assets裡面的Json資料讀取近來

    //解析Json
    //List<dynamic> jsonData = json.decode(Data);

    //將解析的Json資料納入CodeData中
    List<CodeData> codeData = jsonList
        .map((data) => CodeData.fromJson(data as Map<String, dynamic>))
        .toList();

    //用於方便閱讀
    //JsonEncoder.withIndent(' ') 創建了一個 JsonEncoder 的實例，它將生成格式化的 JSON 字符串，其中每個層級的縮進都是兩個空格。
    //convert方法再把Dart目標改成Json字串。
    String readData = const JsonEncoder.withIndent(' ').convert(jsonList);

    debugPrint("DataList type:${jsonList.runtimeType}\nData:\n$readData");

    return codeData;
  }

  //判斷是否完成掃描
  void checkScannedCodeIsOver() {
    if (matchedCode.length == codeDataList.length) {
      controller.stop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("掃描完成"),
            content: const Text("所有條碼已掃描完成。"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  devLog("scannedCodeList:", scannedCodeList.toString());
                  devLog("matchedCode:", matchedCode.toString());
                  devLog("errorScannedList:", errorScannedList.toString());
                  scannedCodeListCallback();
                  Navigator.pop(context);
                  Navigator.pop(context);
                  //Navigator.of(context).pop();
                },
                child: const Text('確認'),
              ),
            ],
          );
        },
        //當點擊Dialog的確認後
        //目前暫定，跳轉頁面離開掃描位置
      ).then((value) {
        controller.start();
      });
    }
  }

  //清除畫面外框
  void resetScanResults() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), resetResult);
  }

  //重製掃描鏡頭
  void resetResult() {
    setState(() {
      barcode = null;
      isCodeMatched = false;
    });
    _resetTimer?.cancel();
  }

  // //排序已辦清單
  // void sortScannedList(Set<String> myList) {
  //   List<String> sortList = myList.toList();

  //   sortList.sort((a, b) => a.compareTo(b));

  //   print("Scanned List: $sortList");

  //   matchedList = sortList;
  // }

  //回傳值
  void scannedCodeListCallback() {
    widget.onScanned(
      scannedCodeList,
      matchedCode,
      errorScannedList,
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //讀取Json資料並賦予給codeDataList
    //value = codeData
    jsonDataFuture = loadJsonData(
      widget.jsonData,
    ).then(
      (value) {
        setState(() {
          codeDataList = value;
        });
      },
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    //相機在結束的時候要dispose消除內存
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //使用到FutureBuilder的方式在進入程式後先取Json資料
    return FutureBuilder(
      future: jsonDataFuture,
      builder: (context, snapshot) {
        //當future正在取資料時
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          );
          //假如取資料有錯誤時
        } else if (snapshot.hasError) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("${snapshot.error}"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("確認"),
                  ),
                ],
              );
            },
          );
          return Container();
        } else {
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 30),
                  onPressed: () {
                    scannedCodeListCallback();
                    Navigator.pop(context);
                  },
                ),
                title: const Text("ScanWindow"),
              ),
              body: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: LayoutBuilder(
                          builder: (BuildContext context,
                              BoxConstraints constraints) {
                            //用以計算相機螢幕的置中畫面大小
                            final containerCenter = Offset(
                              constraints.maxWidth / 2,
                              constraints.maxHeight / 2,
                            );

                            //在畫面的正中間部分建立一個window
                            final scanWindow = Rect.fromCenter(
                              center: containerCenter,
                              width: 200,
                              height: 200,
                            );

                            //ClipRRect用以提供一個矩形畫面
                            return ClipRRect(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  //QRcode掃描插件
                                  MobileScanner(
                                    //畫面的呈現方式
                                    //BoxFit.cover 維持畫面(圖片)比例，將容器填滿，多的自動裁切，缺少的自動拉長畫面填滿。
                                    fit: BoxFit.cover,
                                    controller: controller,
                                    //掃描的格子大小，限定使用 Rect 格式
                                    scanWindow: scanWindow,
                                    //當掃描開始的時候
                                    //將變數 argunent 替代成掃描當下的argunent
                                    onScannerStarted: (arguments) {
                                      setState(() {
                                        this.arguments = arguments;
                                      });
                                    },
                                    //假如error的話
                                    errorBuilder: (context, error, child) {
                                      return Text("$error");
                                    },
                                    //掃描啟動的時候相機每一偵做的事情
                                    onDetect: onDetect,
                                  ),
                                  //當掃描到東西的時候所繪製的外框
                                  if (barcode != null &&
                                      barcode?.corners != null &&
                                      arguments != null)
                                    CustomPaint(
                                      painter: BarcodeOverlay(
                                        barcode: barcode!,
                                        arguments: arguments!,
                                        boxFit: BoxFit.contain,
                                        capture: capture!,
                                        isCodeMatched: isCodeMatched,
                                      ),
                                    ),

                                  CustomPaint(
                                    painter: ScannerOverlay(scanWindow),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 10,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        "當前編號\n${barcode?.displayValue ?? ''}",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Material(
                        color: Colors.white,
                        child: TabBar(
                          labelColor: Colors.black,
                          labelStyle:
                              const TextStyle(fontWeight: FontWeight.bold),
                          indicatorColor: Colors.orange,
                          indicatorSize: TabBarIndicatorSize.label,
                          tabs: [
                            Tab(
                              text:
                                  '代辦清單(${codeDataList.length - matchedCode.length})',
                            ),
                            Tab(
                              text: '已辦清單(${matchedCode.length})',
                            ),
                            Tab(
                              text: '未符合(${errorScannedList.length})',
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: TabBarView(
                          children: [
                            ListView.builder(
                              itemCount: codeDataList.length,
                              itemBuilder: (context, index) {
                                final item = codeDataList[index];
                                final bool isMatched =
                                    matchedCode.contains(item.code);
                                return ListTile(
                                  title: Text(item.code),
                                  tileColor: isMatched ? Colors.green : null,
                                );
                              },
                            ),
                            ListView.builder(
                              itemCount: matchedCode.length,
                              itemBuilder: (context, index) {
                                final code = matchedCode.elementAt(index);
                                return ListTile(
                                  title: Text(code),
                                  tileColor: Colors.white,
                                );
                              },
                            ),
                            ListView.builder(
                              itemCount: errorScannedList.length,
                              itemBuilder: (context, index) {
                                final errorScannedCode =
                                    errorScannedList.elementAt(index);
                                return ListTile(
                                  title: Text(errorScannedCode),
                                  tileColor: Colors.red,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }
}

//相機上的畫面
//因為不能動到相機，因此我們只能使用到Stack的方式蓋上去
//
//---掃描框----
//--相機畫面---
//
class ScannerOverlay extends CustomPainter {
  ScannerOverlay(this.scanWindow);

  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()..addRect(scanWindow);

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    canvas.drawPath(backgroundWithCutout, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class BarcodeOverlay extends CustomPainter {
  BarcodeOverlay(
      {required this.barcode,
      required this.arguments,
      required this.boxFit,
      required this.capture,
      required this.isCodeMatched});

  final BarcodeCapture capture;
  final Barcode barcode;
  final MobileScannerArguments arguments;
  final BoxFit boxFit;
  final bool isCodeMatched;

  @override
  void paint(Canvas canvas, Size size) {
    if (barcode.corners.isEmpty) {
      return;
    }

    final adjustedSize = applyBoxFit(boxFit, arguments.size, size);

    double verticalPadding = size.height - adjustedSize.destination.height;
    double horizontalPadding = size.width - adjustedSize.destination.width;
    if (verticalPadding > 0) {
      verticalPadding = verticalPadding / 2;
    } else {
      verticalPadding = 0;
    }

    if (horizontalPadding > 0) {
      horizontalPadding = horizontalPadding / 2;
    } else {
      horizontalPadding = 0;
    }

    final double ratioWidth;
    final double ratioHeight;

    if (!kIsWeb && Platform.isIOS) {
      ratioWidth = capture.size.width / adjustedSize.destination.width;
      ratioHeight = capture.size.height / adjustedSize.destination.height;
    } else {
      ratioWidth = arguments.size.width / adjustedSize.destination.width;
      ratioHeight = arguments.size.height / adjustedSize.destination.height;
    }

    final List<Offset> adjustedOffset = [];
    for (final offset in barcode.corners) {
      adjustedOffset.add(
        Offset(
          offset.dx / ratioWidth + horizontalPadding,
          offset.dy / ratioHeight + verticalPadding,
        ),
      );
    }

    final cutoutPath = Path()..addPolygon(adjustedOffset, true);

    final backgroundPaint = Paint()
      ..color = isCodeMatched ? Colors.green : Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawPath(cutoutPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class CodeData {
  String code;

  CodeData({
    required this.code,
  });

  factory CodeData.fromJson(Map<String, dynamic> json) {
    return CodeData(
      code: json['code'],
    );
  }
}


/*
[
    {
        "code": "10:10"
    },
    {
        "code": "12:20"
    },
    {
        "code": "13:30"
    },
    {
        "code": "14:40"
    },
    {
        "code": "15:50"
    }
]

{
    "options": 
    {
        "size": 20,
    },
}

*/