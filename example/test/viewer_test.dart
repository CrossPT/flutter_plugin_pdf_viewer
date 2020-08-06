import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_plugin_pdf_viewer/flutter_plugin_pdf_viewer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_plugin_pdf_viewer');
  List<MethodCall> log;

  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    log.add(methodCall);
    switch (methodCall.method) {
      case 'getNumberOfPages':
        return '5';
      default:
        return null;
    }
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channelPath =
  MethodChannel('plugins.flutter.io/path_provider');
  List<MethodCall> logPath;

  channelPath.setMockMethodCallHandler((MethodCall methodCall) async {
    logPath.add(methodCall);
    switch (methodCall.method) {
      case 'getApplicationDocumentsDirectory':
        return Directory.current.path;
      default:
        return null;
    }
  });

  setUp(() {
    logPath = <MethodCall>[];
    log = <MethodCall>[];
  });

  Widget createWidgetForTesting({Widget child}) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('PDFViewer with BottomAppBar', (WidgetTester tester) async {
    PDFDocument _document = await PDFDocument.fromAsset('assets/sample2.pdf');
    await tester.pumpWidget(
        createWidgetForTesting(child: PDFViewer(document: _document)));

    var bottomBar = find.byType(BottomAppBar);
    expect(bottomBar, findsOneWidget);
  });
}
