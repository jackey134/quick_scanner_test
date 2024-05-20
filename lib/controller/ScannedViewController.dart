import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quick_scanner/helper/devlog.dart';

class ScannedViewController {
  Future<String> loadJsonData(String path) async {
    var jsonText = await rootBundle.loadString(path);

    return jsonText;
  }

  Future<List> loadData(String path) async {
    String jsonString = await loadJsonData(path);

    var jsonData = jsonDecode(jsonString);

    devLog("json資料測試", jsonData.toString());

    return jsonData;
  }
}
