import 'package:flutter/material.dart';

class FloatingActionButtonMenu extends StatefulWidget {
  final List<FloatingActionButtonItem> items;
  final Color backgroundColor;
  final Color foregroundColor;
  final Icon icon;
  final double elevation;

  const FloatingActionButtonMenu({
    Key? key,
    required this.items,
    this.backgroundColor = Colors.blue,
    this.foregroundColor = Colors.white,
    this.icon = const Icon(Icons.add),
    this.elevation = 6.0,
  }) : super(key: key);

  @override
  State<FloatingActionButtonMenu> createState() =>
      _FloatingActionButtonMenuState();
}

class _FloatingActionButtonMenuState extends State<FloatingActionButtonMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _translateAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _translateAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Menu items
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.items.length, (index) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    20 *
                        (widget.items.length - index) *
                        (1 - _translateAnimation.value),
                  ),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _scaleAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMenuItem(widget.items[index]),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        // Main FAB
        FloatingActionButton(
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          elevation: widget.elevation,
          onPressed: _toggle,
          child: RotationTransition(
            turns: _rotateAnimation,
            child: widget.icon,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(FloatingActionButtonItem item) {
    return SizedBox(
      height: 60,
      width: 60,
      child: FloatingActionButton(
        mini: item.mini,
        heroTag: item.heroTag,
        backgroundColor: item.backgroundColor ?? widget.backgroundColor,
        foregroundColor: item.foregroundColor ?? widget.foregroundColor,
        elevation: 4,
        onPressed: () {
          _toggle();
          item.onTap();
        },
        child: item.child,
      ),
    );
  }
}

class FloatingActionButtonItem {
  final Widget child;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? heroTag;
  final bool mini;

  FloatingActionButtonItem({
    required this.child,
    required this.onTap,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.heroTag,
    this.mini = false,
  });
}
