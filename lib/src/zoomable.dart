import 'dart:math';
import 'package:flutter/widgets.dart';

class Zoomable extends StatefulWidget {
  Zoomable({Key key, this.child});
  final Widget child;

  @override
  _ZoomableWidgetState createState() => _ZoomableWidgetState();
}

class _ZoomableWidgetState extends State<Zoomable> {
  final GlobalKey _key = GlobalKey();

  double _zoom = 1.0;
  double _previousZoom = 1.0;
  Offset _previousPanOffset = Offset.zero;
  Offset _panOffset = Offset.zero;
  Offset _zoomOriginOffset = Offset.zero;

  Size _childSize = Size.zero;
  Size _containerSize = Size.zero;

  Duration _duration = const Duration(milliseconds: 100);
  Curve _curve = Curves.easeOut;

  void _onScaleStart(ScaleStartDetails details) {
    if (_childSize == Size.zero) {
      final RenderBox renderbox = _key.currentContext.findRenderObject();
      _childSize = renderbox.size;
    }
    setState(() {
      _zoomOriginOffset = details.focalPoint;
      _previousPanOffset = _panOffset;
      _previousZoom = _zoom;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    Size boundarySize = _boundarySize;

    Size _marginSize = Size(150.0, 150.0);

    _duration = const Duration(milliseconds: 150);
    _curve = Curves.easeOut;

    if (details.scale != 1.0) {
      setState(() {
        _zoom = (_previousZoom * details.scale).clamp(1.0, 5.0);
      });
    }
    Offset _panRealOffset = (details.focalPoint -
            _zoomOriginOffset +
            _previousPanOffset * _previousZoom) /
        _zoom;

    Offset _baseOffset = Offset(
      _panRealOffset.dx.clamp(-boundarySize.width / 2, boundarySize.width / 2),
      _panRealOffset.dy
          .clamp(-boundarySize.height / 2, boundarySize.height / 2),
    );

    Offset _marginOffset = _panRealOffset - _baseOffset;
    double _widthFactor = sqrt(_marginOffset.dx.abs()) / _marginSize.width;
    double _heightFactor = sqrt(_marginOffset.dy.abs()) / _marginSize.height;
    _marginOffset = Offset(
      _marginOffset.dx * _widthFactor * 2,
      _marginOffset.dy * _heightFactor * 2,
    );
    _panOffset = _baseOffset + _marginOffset;
    setState(() {});
  }

  void _onScaleEnd(ScaleEndDetails details) {
    Size boundarySize = _boundarySize;

    final Offset velocity = details.velocity.pixelsPerSecond;
    final double magnitude = velocity.distance;
    if (magnitude > 800.0 * _zoom) {
      final Offset direction = velocity / magnitude;
      final double distance = (Offset.zero & context.size).shortestSide;
      final Offset endOffset = _panOffset + direction * distance * 0.5;
      _panOffset = Offset(
        endOffset.dx.clamp(-boundarySize.width / 2, boundarySize.width / 2),
        endOffset.dy.clamp(-boundarySize.height / 2, boundarySize.height / 2),
      );
    }
    Offset _clampedOffset = Offset(
      _panOffset.dx.clamp(-boundarySize.width / 2, boundarySize.width / 2),
      _panOffset.dy.clamp(-boundarySize.height / 2, boundarySize.height / 2),
    );
    // If zoom = 1.0, rollback to default scale
    if (_zoom == 1.0) {
      _clampedOffset = Offset.zero;
    }
    setState(() => _panOffset = _clampedOffset);
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
    setState(() => _panOffset = Offset.zero);

    setState(() {
      _previousZoom = _tmpZoom;
      if (_tmpZoom == 1.0) {
        _zoomOriginOffset = Offset.zero;
        _previousPanOffset = Offset.zero;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.child == null) return SizedBox();

    return CustomMultiChildLayout(
      delegate: _ZoomableWidgetLayout(),
      children: <Widget>[
        LayoutId(
          id: _ZoomableWidgetLayout.painter,
          child: _ZoomableChild(
            duration: _duration,
            curve: _curve,
            zoom: _zoom,
            panOffset: _panOffset,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                _containerSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return Center(
                  child: Container(key: _key, child: widget.child),
                );
              },
            ),
          ),
        ),
        LayoutId(
          id: _ZoomableWidgetLayout.gestureContainer,
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

class _ZoomableWidgetLayout extends MultiChildLayoutDelegate {
  _ZoomableWidgetLayout();

  static final String gestureContainer = 'gesturecontainer';
  static final String painter = 'painter';

  @override
  void performLayout(Size size) {
    layoutChild(gestureContainer,
        BoxConstraints.tightFor(width: size.width, height: size.height));
    positionChild(gestureContainer, Offset.zero);
    layoutChild(painter,
        BoxConstraints.tightFor(width: size.width, height: size.height));
    positionChild(painter, Offset.zero);
  }

  @override
  bool shouldRelayout(_ZoomableWidgetLayout oldDelegate) => false;
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
  Tween _panOffset;
  Tween _zoomOriginOffset;
  Tween _rotation;

  @override
  void forEachTween(visitor) {
    _zoom = visitor(_zoom, widget.zoom, (dynamic value) => Tween(begin: value));
    _panOffset = visitor(
        _panOffset, widget.panOffset, (dynamic value) => Tween(begin: value));
    _rotation = visitor(_rotation, 0.0, (dynamic value) => Tween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      origin: Offset(-_panOffset.evaluate(animation).dx,
          -_panOffset.evaluate(animation).dy),
      transform: Matrix4.identity()
        ..translate(_panOffset.evaluate(animation).dx,
            _panOffset.evaluate(animation).dy)
        ..scale(_zoom.evaluate(animation), _zoom.evaluate(animation)),
      child: Transform.rotate(
        angle: _rotation.evaluate(animation),
        child: widget.child,
      ),
    );
  }
}
