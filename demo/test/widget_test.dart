// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_effect_flutter/api/tencent_effect_api.dart';
import 'package:tencent_effect_flutter/utils/xmagic_decode_utils.dart';
import 'package:tencent_effect_flutter/model/xmagic_property.dart';
import 'package:tencent_effect_flutter_demo/main.dart';



void main() {

    // Map<String,List<XmagicUIProperty>>? data=  XmagicDecodeUtil.decodeAllDataJson(str);
    // List<XmagicUIProperty>? list = data?['LUT'];
    // List par = [];
    // list?.forEach((element) {
    //   par.add(element.property);
    // });
    // String parameter = json.encode(par);
    // print("打印日志  getPropertyRequiredAbilities  $parameter");


  // testWidgets('Verify Platform version', (WidgetTester tester) async {
  //   // Build our app and trigger a frame.
  //   await tester.pumpWidget(const MyApp());
  //
  //   // Verify that platform version is retrieved.
  //   expect(
  //     find.byWidgetPredicate(
  //       (Widget widget) => widget is Text &&
  //                          widget.data!.startsWith('Running on:'),
  //     ),
  //     findsOneWidget,
  //   );
  // });
}
