import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_plugin_pdf_viewer/src/page.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PDFDocument {
  static const MethodChannel _channel =
      const MethodChannel('flutter_plugin_pdf_viewer');

  String _filePath;
  int count;

  /// Load a PDF File from a given File
  ///
  ///
  static Future<PDFDocument> fromFile(File f) async {
    PDFDocument document = PDFDocument();
    document._filePath = f.path;
    try {
      var pageCount =
          await _channel.invokeMethod('getNumberOfPages', {'filePath': f.path});
      document.count = document.count = int.parse(pageCount);
    } catch (e) {
      throw Exception('Error reading PDF!');
    }
    return document;
  }

  /// Load a PDF File from a given URL.
  /// File is saved in cache
  ///
  static Future<PDFDocument> fromURL(String url) async {
    // Download into cache
    File f = await DefaultCacheManager().getSingleFile(url);
    PDFDocument document = PDFDocument();
    document._filePath = f.path;
    try {
      var pageCount =
          await _channel.invokeMethod('getNumberOfPages', {'filePath': f.path});
      document.count = document.count = int.parse(pageCount);
    } catch (e) {
      throw Exception('Error reading PDF!');
    }
    return document;
  }

  /// Load a PDF File from assets folder
  ///
  ///
  static Future<PDFDocument> fromAsset(String asset) async {
    PDFDocument document = PDFDocument();
    try {
      var pageCount =
          await _channel.invokeMethod('getNumberOfPages', {'filePath': asset});
      document.count = document.count = int.parse(pageCount);
    } catch (e) {
      throw Exception('Error reading PDF!');
    }
    return document;
  }

  /// Load specific page
  ///
  /// [page] defaults to `1` and must be equal or above it
  Future<PDFPage> get({int page = 1}) async {
    assert(page > 0);
    var data = await _channel
        .invokeMethod('getPage', {'filePath': _filePath, 'pageNumber': page});
    return new PDFPage(data);
  }

  /// Load all pages
  ///
  Future<List<PDFPage>> getAll() async {
    throw Exception("Not yet implemented");
  }
}
