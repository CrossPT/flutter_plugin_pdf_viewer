## 1.0.6

- Fixed issue in 1.0.5 on iOS that caused xcode build to fail

## 1.0.5

- Fixed bug in iOS where due to caching of Flutter ImageProvider when switching documents old pages would persist
- Added more cases in example demo

## 1.0.4

- Refactored PDFdocument.getAllPages() method (Thanks for @SergioBernal8 for PR )
- Added white background to page (iOS)
- Changed page resolution in iOS to 300 dpi
- Moved tooltips to a proper class

## 1.0.3

- Added white background to page (Android)
- Fixed cocoapods name
- User can now define tooltips and page selection dialog strings
- Tapping on page indicator now prompts to user to page selection dialog
- Added zoom to PDFPage

## 1.0.2

- Bottom appbar no longer appears if PDF has only one page (Thanks for @markathomas for suggesting this )
- Fixed opening PDF from assets not working.
- Example now opens file from assets

## 1.0.1

- Updated readme.md and added screenshots to package

## 1.0.0

- Initial release