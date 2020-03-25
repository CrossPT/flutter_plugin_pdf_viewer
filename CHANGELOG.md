# Changelog

## 1.1.3
- Option to pass in controller `PDFViewer(document: document,controller: PageController())` that you can use to control the pageview rendering the PDF pages.

## 1.1.2
- Option to preload all pages in memory `PDFViewer(document: document,lazyLoad: false)`

## 1.1.1
- Option to disable swipe navigation `PDFViewer(document: document,scrollDirection: Aixs.vertical)`
- Option to change scroll axis to vertical or horizontal `PDFViewer(document: document,scrollDirection: Aixs.vertical)`

## 1.1.0
- Removed rxdart dependency
- Upgraded to androidX
- Added support to optional header while loading document from url
- Auto hide picker for 1 page documents

## 1.0.1
- Swipe control
- Zoom scale up to 5.0

## 1.0.0
- First upgraded version after fork
- Cool new customization features