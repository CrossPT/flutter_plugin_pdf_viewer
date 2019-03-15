import 'dart:io';

import 'package:flutter/material.dart';

class PDFPage extends StatefulWidget {
  final String imgPath;
  PDFPage(this.imgPath);

  _PDFPageState createState() => _PDFPageState();
}

class _PDFPageState extends State<PDFPage> {
  ImageProvider provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repaint();
  }

  @override
  void didUpdateWidget(PDFPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imgPath != widget.imgPath) {
      _repaint();
    }
  }

  _repaint() {
    provider = FileImage(File(widget.imgPath));
    final resolver = provider.resolve(createLocalImageConfiguration(context));
    resolver.addListener((imgInfo, alreadyPainted) {
      if (!alreadyPainted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Image(image: provider);
  }
}
