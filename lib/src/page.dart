import 'dart:io';
import 'dart:math';
import 'package:flutter/widgets.dart';

class PDFPage extends StatefulWidget {
  final String imgPath;
  PDFPage(this.imgPath);

  @override
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

  final GlobalKey _key = GlobalKey();

  double _zoom = 1.0;
  double _previousZoom = 1.0;
  Offset _previousOffset = Offset.zero;
  Offset _offset = Offset.zero;
  Offset _zoomOriginOffset = Offset.zero;

  Size _childSize = Size.zero;
  Size _containerSize = Size.zero;

  void _onScaleStart(ScaleStartDetails details) {
    if (_childSize == Size.zero) {
      final RenderBox renderbox = _key.currentContext.findRenderObject();
      _childSize = renderbox.size;
    }
    setState(() {
      _zoomOriginOffset = details.focalPoint;
      _previousOffset = _offset;
      _previousZoom = _zoom;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    Size boundarySize = _boundarySize;
    double margin = 50.0;

    if (details.scale != 1.0) {
      setState(() {
        // Ensure max zoom is between 1.0 and 5.0
        _zoom = (_previousZoom * details.scale).clamp(1.0, 5.0);
      });
    }
    Offset _panRealOffset = (details.focalPoint -
            _zoomOriginOffset +
            _previousOffset * _previousZoom) /
        _zoom;

    Offset _baseOffset = Offset(
      _panRealOffset.dx.clamp(-boundarySize.width / 2, boundarySize.width / 2),
      _panRealOffset.dy
          .clamp(-boundarySize.height / 2, boundarySize.height / 2),
    );

    Offset _marginOffset = _panRealOffset - _baseOffset;
    double _widthFactor = sqrt(_marginOffset.dx.abs()) / margin;
    double _heightFactor = sqrt(_marginOffset.dy.abs()) / margin;
    _marginOffset = Offset(
      _marginOffset.dx * _widthFactor * 2,
      _marginOffset.dy * _heightFactor * 2,
    );
    _offset = _baseOffset + _marginOffset;
    setState(() {});
  }

  void _onScaleEnd(ScaleEndDetails details) {
    Size boundarySize = _boundarySize;

    final Offset velocity = details.velocity.pixelsPerSecond;
    final double magnitude = velocity.distance;
    if (magnitude > 800.0 * _zoom) {
      final Offset direction = velocity / magnitude;
      final double distance = (Offset.zero & context.size).shortestSide;
      final Offset endOffset = _offset + direction * distance * 0.5;
      _offset = Offset(
        endOffset.dx.clamp(-boundarySize.width / 2, boundarySize.width / 2),
        endOffset.dy.clamp(-boundarySize.height / 2, boundarySize.height / 2),
      );
    }
    Offset _clampedOffset = Offset(
      _offset.dx.clamp(-boundarySize.width / 2, boundarySize.width / 2),
      _offset.dy.clamp(-boundarySize.height / 2, boundarySize.height / 2),
    );
    // If zoom is 100%, rollback to default scale
    if (_zoom == 1.0) {
      _clampedOffset = Offset.zero;
    }
    setState(() => _offset = _clampedOffset);
  }

  Size get _boundarySize {
    Size _boundarySize = Size(
      (_containerSize.width == _childSize.width)
          ? (_containerSize.width - _childSize.width / _zoom).abs()
          : (_containerSize.width - _childSize.width * _zoom).abs() / _zoom,
      (_containerSize.height == _childSize.height)
          ? (_containerSize.height - _childSize.height / _zoom).abs()
          : (_containerSize.height - _childSize.height * _zoom).abs() / _zoom,
    );

    return _boundarySize;
  }

  void _handleDoubleTap() {
    double _stepLength = 0.0;

    double _tmpZoom = _zoom + _stepLength;
    if (_tmpZoom > 5.0 || _stepLength == 0.0) _tmpZoom = 1.0;
    setState(() {
      _zoom = _tmpZoom;
    });
    setState(() => _offset = Offset.zero);

    setState(() {
      _previousZoom = _tmpZoom;
      if (_tmpZoom == 1.0) {
        _zoomOriginOffset = Offset.zero;
        _previousOffset = Offset.zero;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imgPath == null) return SizedBox();

    return CustomMultiChildLayout(
      delegate: _ZoomableLayout(),
      children: <Widget>[
        LayoutId(
          id: _ZoomableLayout.image,
          child: _ZoomableChild(
            duration: Duration(microseconds: 100),
            curve: Curves.easeInOut,
            zoom: _zoom,
            panOffset: _offset,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                _containerSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return Center(
                  child: Container(key: _key, child: Image(image: provider)),
                );
              },
            ),
          ),
        ),
        LayoutId(
          id: _ZoomableLayout.gestures,
          child: GestureDetector(
            child: Container(color: Color(0)),
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            onDoubleTap: _handleDoubleTap,
          ),
        ),
      ],
    );
  }
}

class _ZoomableLayout extends MultiChildLayoutDelegate {
  _ZoomableLayout();

  static final String gestures = 'gestures';
  static final String image = 'image';

  @override
  void performLayout(Size size) {
    layoutChild(gestures,
        BoxConstraints.tightFor(width: size.width, height: size.height));
    positionChild(gestures, Offset.zero);
    layoutChild(
        image, BoxConstraints.tightFor(width: size.width, height: size.height));
    positionChild(image, Offset.zero);
  }

  @override
  bool shouldRelayout(_ZoomableLayout oldDelegate) => false;
}

class _ZoomableChild extends ImplicitlyAnimatedWidget {
  const _ZoomableChild({
    Duration duration,
    Curve curve = Curves.linear,
    @required this.zoom,
    @required this.panOffset,
    @required this.child,
  }) : super(duration: duration, curve: curve);

  final double zoom;
  final Offset panOffset;
  final Widget child;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _ZoomableChildState();
}

class _ZoomableChildState extends AnimatedWidgetBaseState<_ZoomableChild> {
  Tween _zoom;
  Tween _offset;
  Tween _zoomOriginOffset;

  @override
  void forEachTween(visitor) {
    _zoom = visitor(_zoom, widget.zoom, (dynamic value) => Tween(begin: value));
    _offset = visitor(
        _offset, widget.panOffset, (dynamic value) => Tween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
        alignment: Alignment.center,
        origin: Offset(-_offset.evaluate(animation).dx,
            -_offset.evaluate(animation).dy),
        transform: Matrix4.identity()
          ..translate(_offset.evaluate(animation).dx,
              _offset.evaluate(animation).dy)
          ..scale(_zoom.evaluate(animation), _zoom.evaluate(animation)),
        child: widget.child);
  }
}
