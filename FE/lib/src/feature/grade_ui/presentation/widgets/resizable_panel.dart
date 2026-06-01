import 'package:flutter/material.dart';

class ResizablePanel extends StatefulWidget {
  final Widget child;
  final double initialWidth;
  final double initialHeight;
  final double minWidth;
  final double minHeight;
  final double? maxWidth;
  final double? maxHeight;
  final bool isHorizontal;
  final double handleSize;

  const ResizablePanel({
    super.key,
    required this.child,
    required this.initialWidth,
    required this.initialHeight,
    this.minWidth = 250,
    this.minHeight = 200,
    this.maxWidth,
    this.maxHeight,
    this.isHorizontal = true,
    this.handleSize = 12,
  });

  @override
  State<ResizablePanel> createState() => _ResizablePanelState();
}

class _ResizablePanelState extends State<ResizablePanel> {
  late double _width;
  late double _height;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth
        .clamp(widget.minWidth, _resolvedMax(widget.minWidth, widget.maxWidth))
        .toDouble();
    _height = widget.initialHeight
        .clamp(widget.minHeight, _resolvedMax(widget.minHeight, widget.maxHeight))
        .toDouble();
  }

  void _handleResize(double dx, double dy) {
    final maxWidth = _resolvedMax(widget.minWidth, widget.maxWidth);
    final maxHeight = _resolvedMax(widget.minHeight, widget.maxHeight);

    setState(() {
      if (widget.isHorizontal) {
        // Handle is on the left edge, so dragging right should reduce width.
        _width = (_width - dx).clamp(widget.minWidth, maxWidth).toDouble();
      } else {
        // Handle is on the top edge, so dragging down should reduce height.
        _height = (_height - dy).clamp(widget.minHeight, maxHeight).toDouble();
      }
    });
  }

  double _resolvedMax(double minValue, double? maxValue) {
    if (maxValue == null || maxValue.isInfinite) {
      return double.infinity;
    }
    return maxValue < minValue ? minValue : maxValue;
  }

  @override
  Widget build(BuildContext context) {
    final boundedWidth = _width.clamp(
      widget.minWidth,
      _resolvedMax(widget.minWidth, widget.maxWidth),
    ).toDouble();
    final boundedHeight = _height.clamp(
      widget.minHeight,
      _resolvedMax(widget.minHeight, widget.maxHeight),
    ).toDouble();

    return SizedBox(
      width: widget.isHorizontal ? boundedWidth : null,
      height: !widget.isHorizontal ? boundedHeight : null,
      child: Stack(
        children: [
          widget.child,
          // Resize handle
          if (widget.isHorizontal)
            Positioned(
              left: -widget.handleSize / 2,
              top: 0,
              bottom: 0,
              width: widget.handleSize,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                onEnter: (_) => setState(() => _isDragging = false),
                onExit: (_) => setState(() => _isDragging = false),
                child: GestureDetector(
                  onHorizontalDragStart: (_) {
                    setState(() => _isDragging = true);
                  },
                  onHorizontalDragUpdate: (details) {
                    _handleResize(details.delta.dx, 0);
                  },
                  onHorizontalDragEnd: (_) {
                    setState(() => _isDragging = false);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 2,
                        color: Colors.grey.withAlpha(_isDragging ? 180 : 100),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              top: -widget.handleSize / 2,
              height: widget.handleSize,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                onEnter: (_) => setState(() => _isDragging = false),
                onExit: (_) => setState(() => _isDragging = false),
                child: GestureDetector(
                  onVerticalDragStart: (_) {
                    setState(() => _isDragging = true);
                  },
                  onVerticalDragUpdate: (details) {
                    _handleResize(0, details.delta.dy);
                  },
                  onVerticalDragEnd: (_) {
                    setState(() => _isDragging = false);
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        height: 2,
                        color: Colors.grey.withAlpha(_isDragging ? 180 : 100),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

