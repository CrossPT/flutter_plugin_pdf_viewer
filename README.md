# flutter_pdf_viewer

A cross platform plugin for handling PDF files.

## Installation

Add  *flutter_pdf_viewer*  as a dependency in [your pubspec.yaml file](https://flutter.io/platform-plugins/).
```
flutter_pdf_viewer: any
```

## Android
No permissions required. Uses application cache directory.

## iOS
No permissions required.

### How-to

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
PDFPage pageOne = await doc.get(1);

// Load all pages
List<PDFPage> pages = await doc.getAll();
```

#### Alternative
Use the pre-built PDF Viewer
```
@override
  Widget build(BuildContext context) {
    Scaffold(
        appBar: AppBar(
          title: const Text('FlutterPDFViewer'),
        ),
        body: Center(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : PDFViewer(document: document)),
    );
  }
```