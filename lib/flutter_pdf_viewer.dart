import 'dart:async';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class FlutterPdfViewer {

  static const MethodChannel _channel = const MethodChannel('flutter_pdf_viewer');

  String filePath;

  FlutterPdfViewer({@required String filePath}) {
    assert(filePath != null);
    this.filePath = filePath;
  }

  /// Creates a temporary PNG image for the provided PDF file
  ///
  /// [pageNumber] defaults to `1` and must be equal or above it
  Future<dynamic> getPage({int pageNumber = 1}) {
    assert(pageNumber > 0);
    return _channel.invokeMethod('getPage', {'filePath': filePath, 'pageNumber': pageNumber});
  }

  /// Returns the number of pages that exists in the provided PDF file
  Future<dynamic> getNumberOfPages() {
    return _channel.invokeMethod('getNumberOfPages', {'filePath': filePath});
  }
}
