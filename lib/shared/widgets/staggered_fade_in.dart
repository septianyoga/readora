import 'package:flutter/material.dart';

/// Membungkus [child] dengan animasi fade + slide-in ringan yang delay-nya
/// bertambah sesuai [index] — dipakai supaya item grid/list muncul satu
/// per satu (staggered) alih-alih muncul serentak begitu data selesai
/// dimuat.
///
/// Delay di-clamp ke maksimal [maxStaggeredItems] item pertama supaya
/// list panjang tidak membuat item terakhir menunggu terlalu lama.
class StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;
  final int maxStaggeredItems;

  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.maxStaggeredItems = 12,
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);

    final delayIndex = widget.index.clamp(0, widget.maxStaggeredItems).toInt();
    Future.delayed(Duration(milliseconds: 30 * delayIndex), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}