import 'package:flutter/material.dart';

class IslandWidget extends StatefulWidget {
  final int stage;
  final bool animate;
  final double size;

  const IslandWidget({
    super.key,
    required this.stage,
    this.animate = true,
    this.size = 280,
  });

  @override
  State<IslandWidget> createState() => _IslandWidgetState();
}

class _IslandWidgetState extends State<IslandWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(IslandWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stage != oldWidget.stage) {
      // brief pulse when stage changes
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _assetPath {
    final s = widget.stage.clamp(1, 12);
    return 'assets/images/island_stage_${s.toString().padLeft(2, '0')}.png';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: child,
          ),
        );
      },
      child: Image.asset(
        _assetPath,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // stage 0 or missing asset fallback: ocean placeholder
          return _OceanPlaceholder(size: widget.size);
        },
      ),
    );
  }
}

class _OceanPlaceholder extends StatelessWidget {
  final double size;
  const _OceanPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFF5BB8F5), Color(0xFF1565C0)],
          center: Alignment.center,
        ),
      ),
      child: const Center(
        child: Text('🌊', style: TextStyle(fontSize: 60)),
      ),
    );
  }
}

class IslandStageLabel extends StatelessWidget {
  final int stage;

  const IslandStageLabel({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    const labels = [
      '황량한 바다',      // 0
      '모래섬',           // 1
      '새싹 섬',          // 2
      '야자수 섬',        // 3
      '쌍야자 섬',        // 4
      '오두막 섬',        // 5
      '부두 섬',          // 6
      '등대 섬',          // 7
      '풍요로운 섬',      // 8
      '낙원 직전',        // 9
      '완전한 낙원',      // 10
      '신비로운 낙원',    // 11
      '전설의 섬',        // 12
    ];
    final label = stage < labels.length ? labels[stage] : '전설의 섬';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x225BB8F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x445BB8F5)),
      ),
      child: Text(
        'Lv.$stage  $label',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF1976D2),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
