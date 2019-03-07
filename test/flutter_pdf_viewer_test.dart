import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pdf_viewer/flutter_pdf_viewer.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_pdf_viewer');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FlutterPdfViewer.platformVersion, '42');
  });
}
