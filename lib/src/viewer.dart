import 'package:advance_pdf_viewer/src/page_picker.dart';
import 'package:flutter/material.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:numberpicker/numberpicker.dart';

/// enum to describe indicator position
enum IndicatorPosition { topLeft, topRight, bottomLeft, bottomRight }

/// PDFViewer, a inbuild pdf viewer, you can create your own too.
/// [document] an instance of `PDFDocument`, document to be loaded
/// [indicatorText] color of indicator text
/// [indicatorBackground] color of indicator background
/// [pickerButtonColor] the picker button background color
/// [pickerIconColor] the picker button icon color
/// [indicatorPosition] position of the indicator position defined by `IndicatorPosition` enum
/// [showIndicator] show,hide indicator
/// [showPicker] show hide picker
/// [showNavigation] show hide navigation bar
/// [toolTip] tooltip, instance of `PDFViewerTooltip`
/// [enableSwipeNavigation] enable,disable swipe navigation
/// [scrollDirection] scroll direction horizontal or vertical
/// [lazyLoad] lazy load pages or load all at once
/// [controller] page controller to control page viewer
/// [zoomSteps] zoom steps for pdf page
/// [minScale] minimum zoom scale for pdf page
/// [maxScale] maximum zoom scale for pdf page
/// [panLimit] pan limit for pdf page
/// [onPageChanged] function called when page changes
///
class PDFViewer extends StatefulWidget {
  final PDFDocument document;
  final Color indicatorText;
  final Color indicatorBackground;
  final Color? pickerButtonColor;
  final Color? pickerIconColor;
  final IndicatorPosition indicatorPosition;
  final Widget numberPickerConfirmWidget;
  final bool showIndicator;
  final bool showPicker;
  final bool showNavigation;
  final PDFViewerTooltip tooltip;
  final bool enableSwipeNavigation;
  final Axis? scrollDirection;
  final bool lazyLoad;
  final PageController? controller;
  final int? zoomSteps;
  final double? minScale;
  final double? maxScale;
  final double? panLimit;
  final ValueChanged<int>? onPageChanged;

  final Widget Function(
    BuildContext,
    int? pageNumber,
    int? totalPages,
    void Function({int page}) jumpToPage,
    void Function({int? page}) animateToPage,
  )? navigationBuilder;
  final Widget? progressIndicator;

  PDFViewer({
    Key? key,
    required this.document,
    this.scrollDirection,
    this.lazyLoad = true,
    this.indicatorText = Colors.white,
    this.indicatorBackground = Colors.black54,
    this.numberPickerConfirmWidget = const Text('OK'),
    this.showIndicator = true,
    this.showPicker = true,
    this.showNavigation = true,
    this.enableSwipeNavigation = true,
    this.tooltip = const PDFViewerTooltip(),
    this.navigationBuilder,
    this.controller,
    this.indicatorPosition = IndicatorPosition.topRight,
    this.zoomSteps,
    this.minScale,
    this.maxScale,
    this.panLimit,
    this.progressIndicator,
    this.pickerButtonColor,
    this.pickerIconColor,
    this.onPageChanged,
  }) : super(key: key);

  _PDFViewerState createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  bool _isLoading = true;
  late int _pageNumber;
  bool _swipeEnabled = true;
  List<PDFPage?>? _pages;
  late PageController _pageController;
  final Duration animationDuration = Duration(milliseconds: 200);
  final Curve animationCurve = Curves.easeIn;

  @override
  void initState() {
    super.initState();
    _pages = List.filled(widget.document.count, null);
    _pageController = widget.controller ?? PageController();
    _pageNumber = _pageController.initialPage + 1;
    if (!widget.lazyLoad)
      widget.document.preloadPages(
        onZoomChanged: onZoomChanged,
        zoomSteps: widget.zoomSteps,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        panLimit: widget.panLimit,
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pageNumber = _pageController.initialPage + 1;
    _isLoading = true;
    _pages = List.filled(widget.document.count,null);
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
    if (_pages![_pageNumber - 1] != null) return;
    setState(() {
      _isLoading = true;
    });
    final data = await widget.document.get(
      page: _pageNumber,
      onZoomChanged: onZoomChanged,
      zoomSteps: widget.zoomSteps,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      panLimit: widget.panLimit,
    );
    _pages![_pageNumber - 1] = data;
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  _animateToPage({int? page}) {
    _pageController.animateToPage(page != null ? page : _pageNumber - 1,
        duration: animationDuration, curve: animationCurve);
  }

  _jumpToPage({int? page}) {
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
          return PagePicker(
            title: widget.tooltip.pick,
            maxValue: widget.document.count,
            initialValue: _pageNumber,
          );
        }).then((int? value) {
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
            physics:
                _swipeEnabled && widget.enableSwipeNavigation && !_isLoading
                    ? null
                    : NeverScrollableScrollPhysics(),
            onPageChanged: (page) {
              setState(() {
                _pageNumber = page + 1;
              });
              _loadPage();
              widget.onPageChanged?.call(page);
            },
            scrollDirection: widget.scrollDirection ?? Axis.horizontal,
            controller: _pageController,
            itemCount: _pages?.length ?? 0,
            itemBuilder: (context, index) => _pages![index] == null
                ? Center(
                    child:
                        widget.progressIndicator ?? CircularProgressIndicator(),
                  )
                : _pages![index]!,
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
              child: Icon(
                Icons.view_carousel,
                color: widget.pickerIconColor ?? Colors.white,
              ),
              backgroundColor: widget.pickerButtonColor ?? Colors.blue,
              onPressed: () {
                _pickPage();
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: (widget.showNavigation && widget.document.count > 1)
          ? widget.navigationBuilder != null
              ? widget.navigationBuilder!(
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
                          onPressed: _pageNumber == 1 || _isLoading
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
                          onPressed: _pageNumber == 1 || _isLoading
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
                          onPressed:
                              _pageNumber == widget.document.count || _isLoading
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
                          onPressed:
                              _pageNumber == widget.document.count || _isLoading
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
          : Container(
              height: 0,
            ),
    );
  }
}
