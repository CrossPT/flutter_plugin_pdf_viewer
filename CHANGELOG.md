# Changelog

## 2.0.1
* Bug fixes related to cache
* improvements

## 2.0.0
* Null safety upgrade
* Fixed some issues
* new `numberPickerConfirmWidget`

## 1.2.2
* fix error with single page pdf

## 1.2.1+2
* dart doc comments improvement

## 1.2.1+1
* fix error null `onPageChanged` error

## 1.2.1
* Dependencies upgraded to latest
* `cacheManager` optional parameter in `PDFDocument.fromURL` method to configure cache options.

## 1.2.0
* updated to work with Flutter 1.20+

## 1.1.6
* Exposing `ZoomableWidget` from [flutter_advanced_networkimage](https://pub.dartlang.org/packages/flutter_advanced_networkimage) parameters (minScale, zoomSteps, maxScale,panLimit)

## 1.1.5
* Page controller initial page setting fixed (making able to set initially loaded page)

## 1.1.4
* Proper android cache cleanup
* iOS build fix

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