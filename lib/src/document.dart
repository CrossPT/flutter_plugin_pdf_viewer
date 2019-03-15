import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_pdf_viewer/src/page.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PDFDocument {
  static const MethodChannel _channel =
      const MethodChannel('flutter_pdf_viewer');

  String _filePath;
  int count;

  static Future<PDFDocument> fromFile(File f) async {
    PDFDocument document = PDFDocument();
    document._filePath = f.path;
    var pageCount =
        await _channel.invokeMethod('getNumberOfPages', {'filePath': f.path});
    document.count = int.parse(pageCount);
    return document;
  }

  /// Load a PDF File from a given URL
  ///
  ///
  static Future<PDFDocument> fromURL(String url) async {
    // Download into cahce
    File f = await DefaultCacheManager().getSingleFile(url);
    PDFDocument document = PDFDocument();
    document._filePath = f.path;
    var pageCount =
        await _channel.invokeMethod('getNumberOfPages', {'filePath': f.path});
    document.count = int.parse(pageCount);
    return document;
  }

  static Future<PDFDocument> fromAsset(String asset) async {
    PDFDocument document = PDFDocument();
    ByteData data = await rootBundle.load(asset);
    File f = File.fromRawPath(data.buffer.asUint8List());
    document._filePath = f.path;
    var pageCount =
        await _channel.invokeMethod('getNumberOfPages', {'filePath': f.path});
    document.count = document.count = int.parse(pageCount);
    return document;
  }

  /// Load specific page
  ///
  /// [page] defaults to `1` and must be equal or above it
  Future<dynamic> get({int page = 1}) async {
    assert(page > 0);
    var data = await _channel
        .invokeMethod('getPage', {'filePath': _filePath, 'pageNumber': page});
    return new PDFPage(data);
  }

  /// Load all pages
  ///
  Future<List<dynamic>> getAll() async {
    return [];
  }
}
