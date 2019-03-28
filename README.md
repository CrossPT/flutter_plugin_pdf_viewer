# flutter_plugin_pdf_viewer

A flutter plugin for handling PDF files. Works on both Android & iOS

## Installation

Add  *flutter_plugin_pdf_viewer*  as a dependency in [your pubspec.yaml file](https://flutter.io/platform-plugins/).
```
flutter_plugin_pdf_viewer: any
```

## Android
No permissions required. Uses application cache directory.

## iOS
No permissions required.

## How-to:

#### Load PDF
```
// Load from assets
PDFDocument doc = await PDFDocument.fromAsset('assets/test.pdf');
 
// Load from URL
PDFDocument doc = await PDFDocument.fromURL('http://www.africau.edu/images/default/sample.pdf');

// Load from file
File file  = File('...');
PDFDocument doc = await PDFDocument.fromFile(file);
```

#### Load pages
```
// Load specific page
PDFPage pageOne = await doc.get(page: _number);
```

#### Pre-built viewer
Use the pre-built PDF Viewer
```
@override
  Widget build(BuildContext context) {
    Scaffold(
        appBar: AppBar(
          title: Text('Example'),
        ),
        body: Center(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : PDFViewer(document: document)),
    );
  }
```

This code produces the following view:

<img src="https://raw.githubusercontent.com/CrossPT/flutter_pdf_viewer/master/demo.png" alt="Demo Screenshot 1"/>
