import 'package:flutter/material.dart';
import 'package:flutter_plugin_pdf_viewer/flutter_plugin_pdf_viewer.dart';

enum IndicatorPosition { topLeft, topRight, bottomLeft, bottomRight }

class PDFViewer extends StatefulWidget {
  final PDFDocument document;
  final Color indicatorText;
  final Color indicatorBackground;
  final IndicatorPosition indicatorPosition;
  final bool showIndicator;
  final bool showPicker;
  final bool showNavigation;
  final Map<String, String> tooltips;

  PDFViewer(
      {Key key,
      @required this.document,
      this.indicatorText = Colors.white,
      this.indicatorBackground = Colors.black54,
      this.showIndicator = true,
      this.showPicker = true,
      this.showNavigation = true,
      this.tooltips = const {
        'first': 'First',
        'previous': 'Previous',
        'next': 'Next',
        'last': 'Last',
        'jump': 'Jump to'
      },
      this.indicatorPosition = IndicatorPosition.topRight})
      : super(key: key);

  _PDFViewerState createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  bool _isLoading = true;
  int _pageNumber = 1;
  int _oldPage = 0;
  PDFPage _page;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPage();
  }

  @override
  void didUpdateWidget(PDFViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadPage();
  }

  _loadPage() async {
    setState(() {
      _isLoading = true;
    });
    if (_oldPage == 0) {
      _page = await widget.document.get(page: _pageNumber);
      setState(() => _isLoading = false);
    } else if (_oldPage != _pageNumber) {
      _oldPage = _pageNumber;
      setState(() => _isLoading = true);
      _page = await widget.document.get(page: _pageNumber);
      setState(() => _isLoading = false);
    }
  }

  Widget _drawIndicator() {
    Widget child = Container(
        padding:
            EdgeInsets.only(top: 4.0, left: 16.0, bottom: 4.0, right: 16.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            color: widget.indicatorBackground),
        child: Text("$_pageNumber/${widget.document.count}",
            style: TextStyle(
                color: widget.indicatorText,
                fontSize: 16.0,
                fontWeight: FontWeight.w400)));

    switch (widget.indicatorPosition) {
      case IndicatorPosition.topLeft:
        return Positioned(top: 20, left: 20.0, child: child);
      case IndicatorPosition.topRight:
        return Positioned(top: 20, right: 20.0, child: child);
      case IndicatorPosition.bottomLeft:
        return Positioned(bottom: 20, left: 20.0, child: child);
      case IndicatorPosition.bottomRight:
        return Positioned(bottom: 20, right: 20.0, child: child);
      default:
        return Positioned(top: 20, right: 20.0, child: child);
    }
  }

  _pickPage() {
    int value = _pageNumber;
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text("Pick a page"),
              content: new DropdownButton<int>(
                value: value,
                isExpanded: true,
                items: List<int>.generate(widget.document.count, (i) => i + 1)
                    .map((int val) {
                  return new DropdownMenuItem<int>(
                    value: val,
                    child: new Text("$val"),
                  );
                }).toList(),
                onChanged: (int val) {
                  setState(() {
                    value = val;
                  });
                },
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text("OK"),
                  onPressed: () {
                    if (value != null) {
                      Navigator.of(context).pop();
                      _pageNumber = value;
                      _loadPage();
                    }
                  },
                ),
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _isLoading ? Center(child: CircularProgressIndicator()) : _page,
          widget.showIndicator ? _drawIndicator() : Container()
        ],
      ),
      floatingActionButton: widget.showPicker
          ? FloatingActionButton(
              elevation: 4.0,
              tooltip: widget.tooltips['jump'],
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
                      tooltip: widget.tooltips['first'],
                      onPressed: () {
                        _pageNumber = 1;
                        _loadPage();
                      },
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Icon(Icons.chevron_left),
                      tooltip: widget.tooltips['previous'],
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
                      tooltip: widget.tooltips['next'],
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
                      tooltip: widget.tooltips['last'],
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
