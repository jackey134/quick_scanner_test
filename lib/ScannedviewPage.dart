import 'package:flutter/material.dart';
import 'package:quick_scanner/controller/ScannedViewController.dart';
import 'package:quick_scanner/mobileScannerTest.dart';

class ScannedViewPage extends StatefulWidget {
  const ScannedViewPage({super.key});

  @override
  State<ScannedViewPage> createState() => _ScannedViewPageState();
}

class _ScannedViewPageState extends State<ScannedViewPage> {
  //String jsonStr = '{"code":"ABC123"},{"code":"DEF456"}';
  
  List<dynamic> jsonData = [
    {"code": "ABC123"},
    {"code": "DEF456"}
  ];

  String jsonlocal = 'assets/data/JsonData.json';

  List<dynamic> scannedCodeList = [];
  List<dynamic> matchedCodeList = [];
  List<dynamic> errorCodeList = [];

  List<dynamic> needScanCodeList = [];

  void catchedMatchedCode(
    Set scannedCodeList,
    Set matchedCodeList,
    Set errorCodeList,
  ) {
    setState(() {
      this.scannedCodeList = scannedCodeList.toList();
      this.matchedCodeList = matchedCodeList.toList();
      this.errorCodeList = errorCodeList.toList();
    });
  }

  Future<void> loadData() async {
    ScannedViewController scannedViewController = ScannedViewController();
    needScanCodeList = await scannedViewController.loadData(jsonlocal);
  }

  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();
  //   loadData();
  // }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: loadData(),
        builder: (context, snapshot) {
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
              length: 4,
              child: Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.orange,
                  title: const Text("viewPage"),
                ),
                body: Builder(
                  builder: (context) {
                    return Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(
                              text: '需掃描(${needScanCodeList.length})',
                            ),
                            Tab(
                              text: '已掃過(${scannedCodeList.length})',
                            ),
                            Tab(
                              text: '符合(${matchedCodeList.length})',
                            ),
                            Tab(
                              text: '未符合(${errorCodeList.length})',
                            ),
                          ],
                        ),
                        Expanded(
                          flex: 4,
                          child: TabBarView(
                            children: [
                              ListView.builder(
                                itemCount: needScanCodeList.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(
                                      needScanCodeList[index]['code'],
                                    ),
                                  );
                                },
                              ),
                              ListView.builder(
                                itemCount: scannedCodeList.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(
                                      scannedCodeList[index],
                                    ),
                                  );
                                },
                              ),
                              ListView.builder(
                                itemCount: matchedCodeList.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(
                                      matchedCodeList[index],
                                    ),
                                  );
                                },
                              ),
                              ListView.builder(
                                itemCount: errorCodeList.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(
                                      errorCodeList[index],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScanWindowPage(
                                      onScanned: (
                                        Set scannedCodeList,
                                        Set matchedCodeList,
                                        Set errorCodeList,
                                      ) {
                                        catchedMatchedCode(
                                          scannedCodeList,
                                          matchedCodeList,
                                          errorCodeList,
                                        );
                                      },
                                      jsonData: jsonlocal,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Scan Qrcode"),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }
        });
  }
}
