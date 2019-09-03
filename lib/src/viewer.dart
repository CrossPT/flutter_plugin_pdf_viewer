import 'package:flutter/material.dart';
import 'package:flutter_plugin_pdf_viewer/flutter_plugin_pdf_viewer.dart';
import 'package:numberpicker/numberpicker.dart';
import 'tooltip.dart';

enum IndicatorPosition { topLeft, topRight, bottomLeft, bottomRight }

class PDFViewer extends StatefulWidget {
  final PDFDocument document;
  final Color indicatorText;
  final Color indicatorBackground;
  final IndicatorPosition indicatorPosition;
  final bool showIndicator;
  final bool showPicker;
  final bool showNavigation;
  final PDFViewerTooltip tooltip;

  PDFViewer(
      {Key key,
      @required this.document,
      this.indicatorText = Colors.white,
      this.indicatorBackground = Colors.black54,
      this.showIndicator = true,
      this.showPicker = true,
      this.showNavigation = true,
      this.tooltip = const PDFViewerTooltip(),
      this.indicatorPosition = IndicatorPosition.topRight})
      : super(key: key);

  _PDFViewerState createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  bool _isLoading = true;
  int _pageNumber = 1;
  int _oldPage = 0;
  PDFPage _page;
  List<PDFPage> _pages = List();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _oldPage = 0;
    _pageNumber = 1;
    _isLoading = true;
    _pages.clear();
    _loadPage();
  }

  @override
  void didUpdateWidget(PDFViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _oldPage = 0;
    _pageNumber = 1;
    _isLoading = true;
    _pages.clear();
    _loadPage();
  }

  _loadPage() async {
    setState(() => _isLoading = true);
    if (_oldPage == 0) {
      _page = await widget.document.get(page: _pageNumber);
    } else if (_oldPage != _pageNumber) {
      _oldPage = _pageNumber;
      _page = await widget.document.get(page: _pageNumber);
    }
    if(this.mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _drawIndicator() {
    Widget child = GestureDetector(
        onTap: _pickPage,
        child: Container(
            padding:
                EdgeInsets.only(top: 4.0, left: 16.0, bottom: 4.0, right: 16.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: widget.indicatorBackground),
            child: Text("$_pageNumber/${widget.document.count}",
                style: TextStyle(
                    color: widget.indicatorText,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400))));

    switch (widget.indicatorPosition) {
      case IndicatorPosition.topLeft:
        return Positioned(top: 20, left: 20, child: child);
      case IndicatorPosition.topRight:
        return Positioned(top: 20, right: 20, child: child);
      case IndicatorPosition.bottomLeft:
        return Positioned(bottom: 20, left: 20, child: child);
      case IndicatorPosition.bottomRight:
        return Positioned(bottom: 20, right: 20, child: child);
      default:
        return Positioned(top: 20, right: 20, child: child);
    }
  }

  _pickPage() {
    showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return NumberPickerDialog.integer(
            title: Text(widget.tooltip.pick),
            minValue: 1,
            cancelWidget: Container(),
            maxValue: widget.document.count,
            initialIntegerValue: _pageNumber,
          );
        }).then((int value) {
      if (value != null) {
        _pageNumber = value;
        _loadPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _isLoading ? Center(child: CircularProgressIndicator()) : _page,
          (widget.showIndicator && !_isLoading)
              ? _drawIndicator()
              : Container(),
        ],
      ),
      floatingActionButton: widget.showPicker
          ? FloatingActionButton(
              elevation: 4.0,
              tooltip: widget.tooltip.jump,
              child: Icon(Icons.view_carousel),
              onPressed: () {
                _pickPage();
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: (widget.showNavigation || widget.document.count > 1)
          ? BottomAppBar(
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: IconButton(
                      icon: Icon(Icons.first_page),
                      tooltip: widget.tooltip.first,
                      onPressed: () {
                        _pageNumber = 1;
                        _loadPage();
                      },
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Icon(Icons.chevron_left),
                      tooltip: widget.tooltip.previous,
                      onPressed: () {
                        _pageNumber--;
                        if (1 > _pageNumber) {
                          _pageNumber = 1;
                        }
                        _loadPage();
                      },
                    ),
                  ),
                  widget.showPicker
                      ? Expanded(child: Text(''))
                      : SizedBox(width: 1),
                  Expanded(
                    child: IconButton(
                      icon: Icon(Icons.chevron_right),
                      tooltip: widget.tooltip.next,
                      onPressed: () {
                        _pageNumber++;
                        if (widget.document.count < _pageNumber) {
                          _pageNumber = widget.document.count;
                        }
                        _loadPage();
                      },
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Icon(Icons.last_page),
                      tooltip: widget.tooltip.last,
                      onPressed: () {
                        _pageNumber = widget.document.count;
                        _loadPage();
                      },
                    ),
                  ),
                ],
              ),
            )
          : Container(),
    );
  }
}
