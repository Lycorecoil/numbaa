import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A physically-swipeable stack of "poster" cards.
///
/// The active card sits on top; up to [depth] following cards peek out
/// behind it, slightly rotated/offset/scaled to read as a loose stack of
/// posters. Dragging the top card follows the finger in real time; releasing
/// it either flings it off-stage (revealing the next/previous card) or
/// springs it back to center, depending on how far/fast it was dragged.
///
/// Built entirely on [GestureDetector] + [Transform] + a single
/// [AnimationController] driven by Flutter's built-in physics simulations
/// (no external package): cheap enough for entry-level Android hardware,
/// and only [depth] + 1 cards are ever built regardless of [itemCount], so
/// it stays just as fluid with 3 items as with 30.
class CardSwipeStack extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) cardBuilder;
  final ValueChanged<int>? onIndexChanged;
  final int initialIndex;
  final int depth;

  /// Called with the current card's index on a plain tap (no drag) of the
  /// top card — e.g. to open a fullscreen view of it. Coexists safely with
  /// the pan/drag recognizer below: Flutter resolves a quick tap-and-lift
  /// via the tap recognizer and a moving finger via the pan recognizer in
  /// the same gesture arena, so neither interferes with the other.
  final ValueChanged<int>? onCardTap;

  const CardSwipeStack({
    super.key,
    required this.itemCount,
    required this.cardBuilder,
    this.onIndexChanged,
    this.onCardTap,
    this.initialIndex = 0,
    this.depth = 2,
  });

  @override
  State<CardSwipeStack> createState() => CardSwipeStackState();
}

class CardSwipeStackState extends State<CardSwipeStack>
    with SingleTickerProviderStateMixin {
  late int _index;
  late final AnimationController _controller;
  double _dragX = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.itemCount == 0
        ? 0
        : widget.initialIndex.clamp(0, widget.itemCount - 1);
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() => _dragX = _controller.value);
      });
  }

  @override
  void didUpdateWidget(CardSwipeStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount &&
        _index > widget.itemCount - 1) {
      _index = widget.itemCount == 0 ? 0 : widget.itemCount - 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get currentIndex => _index;

  /// Programmatically jump to [index] (used by external dot indicators),
  /// without the fling/rotation physics of a manual swipe.
  void goTo(int index) {
    if (index < 0 || index >= widget.itemCount || index == _index) return;
    _controller.stop();
    setState(() {
      _dragX = 0;
      _index = index;
    });
    widget.onIndexChanged?.call(_index);
  }

  void _onPanStart(DragStartDetails details) {
    _controller.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _dragX += details.delta.dx);
  }

  void _onPanEnd(DragEndDetails details, double width) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final passedThreshold = _dragX.abs() > width * 0.28;
    final fastFling = velocity.abs() > 700;
    final wantsNext = _dragX < 0 || (fastFling && velocity < 0);
    final canGoNext = _index < widget.itemCount - 1;
    final canGoPrev = _index > 0;
    final commit =
        (passedThreshold || fastFling) && (wantsNext ? canGoNext : canGoPrev);

    if (commit) {
      final direction = wantsNext ? -1 : 1; // -1 exits off-stage to the left
      final target = direction * (width * 1.5);
      _controller
          .animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeIn,
      )
          .then((_) {
        if (!mounted) return;
        setState(() {
          _index = wantsNext ? _index + 1 : _index - 1;
          _dragX = 0;
        });
        _controller.value = 0;
        widget.onIndexChanged?.call(_index);
      });
    } else {
      final spring = SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: 380,
        ratio: 1,
      );
      _controller.animateWith(SpringSimulation(spring, _dragX, 0, velocity));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layers = <Widget>[];

        for (var d = widget.depth; d >= 1; d--) {
          final i = _index + d;
          if (i >= widget.itemCount) continue;
          final depth = d.toDouble();
          layers.add(
            Positioned.fill(
              key: ValueKey('stack_behind_$i'),
              child: IgnorePointer(
                child: Transform.translate(
                  offset: Offset(0, 11.0 * depth),
                  child: Transform.scale(
                    scale: 1 - 0.055 * depth,
                    child: Transform.rotate(
                      angle: (d.isEven ? 1 : -1) * 0.045 * depth,
                      // RepaintBoundary innermost, around the Opacity (which
                      // forces its own offscreen layer) and the card content:
                      // caches that raster so the top card's per-frame drag
                      // doesn't force these static layers to re-rasterize —
                      // they only actually change when _index changes.
                      child: RepaintBoundary(
                        child: Opacity(
                          opacity: math.max(1 - 0.22 * depth, 0.35),
                          child: widget.cardBuilder(context, i),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final dx = _dragX;
        final rotation = (dx / width).clamp(-1.0, 1.0) * 0.24;
        final lift = -(dx.abs() / width) * 12;

        layers.add(
          Positioned.fill(
            key: ValueKey('stack_top_$_index'),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onCardTap == null
                  ? null
                  : () => widget.onCardTap!(_index),
              // Horizontal-only recognizer: a vertical finger movement (e.g.
              // scrolling the SingleChildScrollView/ReorderableListView
              // inside the card's own content) is left entirely to that
              // inner scrollable instead of also being captured here as a
              // pan, which used to make the card visibly wobble/rotate
              // while the user was just trying to scroll the preview.
              onHorizontalDragStart: _onPanStart,
              onHorizontalDragUpdate: _onPanUpdate,
              onHorizontalDragEnd: (d) => _onPanEnd(d, width),
              // RepaintBoundary sits directly around the (expensive) card
              // content, with the animating Transforms OUTSIDE it: that way
              // the shadow/gradient/image raster is cached in its own GPU
              // layer once, and dragging just repositions/rotates that
              // cached layer via compositing instead of re-rasterizing it
              // on every frame.
              child: Transform.translate(
                offset: Offset(dx, lift),
                child: Transform.rotate(
                  angle: rotation,
                  child: RepaintBoundary(
                    child: widget.cardBuilder(context, _index),
                  ),
                ),
              ),
            ),
          ),
        );

        return Stack(clipBehavior: Clip.none, children: layers);
      },
    );
  }
}
