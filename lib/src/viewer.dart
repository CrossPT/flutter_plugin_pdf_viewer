import 'package:flutter/material.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:numberpicker/numberpicker.dart';

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
  final bool enableSwipeNavigation;
  final Axis scrollDirection;
  final bool lazyLoad;
  final Widget Function(
    BuildContext,
    int pageNumber,
    int totalPages,
    void Function({int page}) jumpToPage,
    void Function({int page}) animateToPage,
  ) navigationBuilder;

  PDFViewer(
      {Key key,
      @required this.document,
      this.scrollDirection,
      this.lazyLoad = true,
      this.indicatorText = Colors.white,
      this.indicatorBackground = Colors.black54,
      this.showIndicator = true,
      this.showPicker = true,
      this.showNavigation = true,
      this.enableSwipeNavigation = true,
      this.tooltip = const PDFViewerTooltip(),
      this.navigationBuilder,
      this.indicatorPosition = IndicatorPosition.topRight})
      : super(key: key);

  _PDFViewerState createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  bool _isLoading = true;
  int _pageNumber = 1;
  bool _swipeEnabled = true;
  List<PDFPage> _pages;
  PageController _pageController;
  final Duration animationDuration = Duration(milliseconds: 200);
  final Curve animationCurve = Curves.easeIn;

  @override
  void initState() {
    super.initState();
    _pages = List(widget.document.count);
    _pageController = PageController();
    if (!widget.lazyLoad)
      widget.document.preloadPages(onZoomChanged: onZoomChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pageNumber = 1;
    _isLoading = true;
    _pages = List(widget.document.count);
    // _loadAllPages();
    _loadPage();
  }

  @override
  void didUpdateWidget(PDFViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  onZoomChanged(double scale) {
    if (scale != 1.0) {
      setState(() {
        _swipeEnabled = false;
      });
    } else {
      setState(() {
        _swipeEnabled = true;
      });
    }
  }

  _loadPage() async {
    if (_pages[_pageNumber - 1] != null) return;
    setState(() {
      _isLoading = true;
    });
    final data = await widget.document
        .get(page: _pageNumber, onZoomChanged: onZoomChanged);
    _pages[_pageNumber - 1] = data;
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  _animateToPage({int page}) {
    _pageController.animateToPage(page != null ? page : _pageNumber - 1,
        duration: animationDuration, curve: animationCurve);
  }

  _jumpToPage({int page}) {
    _pageController.jumpToPage(page != null ? page : _pageNumber - 1);
  }

  Widget _drawIndicator() {
    Widget child = GestureDetector(
        onTap:
            widget.showPicker && widget.document.count > 1 ? _pickPage : null,
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
        _jumpToPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          PageView.builder(
            physics: _swipeEnabled && widget.enableSwipeNavigation
                ? null
                : NeverScrollableScrollPhysics(),
            onPageChanged: (page) {
              setState(() {
                _pageNumber = page + 1;
              });
              _loadPage();
            },
            scrollDirection: widget.scrollDirection ?? Axis.horizontal,
            controller: _pageController,
            itemCount: _pages?.length ?? 0,
            itemBuilder: (context, index) => _pages[index] == null
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : _pages[index],
          ),
          (widget.showIndicator && !_isLoading)
              ? _drawIndicator()
              : Container(),
        ],
      ),
      floatingActionButton: widget.showPicker && widget.document.count > 1
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
          ? widget.navigationBuilder != null
              ? widget.navigationBuilder(
                  context,
                  _pageNumber,
                  widget.document.count,
                  _jumpToPage,
                  _animateToPage,
                )
              : BottomAppBar(
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: IconButton(
                          icon: Icon(Icons.first_page),
                          tooltip: widget.tooltip.first,
                          onPressed: _pageNumber == 1
                              ? null
                              : () {
                                  _pageNumber = 1;
                                  _jumpToPage();
                                },
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          icon: Icon(Icons.chevron_left),
                          tooltip: widget.tooltip.previous,
                          onPressed: _pageNumber == 1
                              ? null
                              : () {
                                  _pageNumber--;
                                  if (1 > _pageNumber) {
                                    _pageNumber = 1;
                                  }
                                  _animateToPage();
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
                          onPressed: _pageNumber == widget.document.count
                              ? null
                              : () {
                                  _pageNumber++;
                                  if (widget.document.count < _pageNumber) {
                                    _pageNumber = widget.document.count;
                                  }
                                  _animateToPage();
                                },
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          icon: Icon(Icons.last_page),
                          tooltip: widget.tooltip.last,
                          onPressed: _pageNumber == widget.document.count
                              ? null
                              : () {
                                  _pageNumber = widget.document.count;
                                  _jumpToPage();
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
