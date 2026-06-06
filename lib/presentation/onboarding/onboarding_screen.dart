import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project001/core/constants/app_constants.dart';
import 'package:project001/core/theme/app_colors.dart';
import 'package:project001/presentation/home/widgets/island_widget.dart';
import 'package:project001/presentation/providers/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _targetMinutes = AppConstants.defaultTargetMinutes;
  bool _isRequesting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final settings = ref.read(settingsProvider).value;
    if (settings != null) {
      await ref.read(settingsProvider.notifier).updateTargetUsage(_targetMinutes);
    }
    await ref.read(settingsProvider.notifier).setOnboardingDone();
    if (mounted) context.go('/');
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    final service = ref.read(screenTimeServiceProvider);
    await service.requestPermission();
    ref.read(hasPermissionProvider.notifier).state = await service.hasPermission();
    if (mounted) setState(() => _isRequesting = false);
    _next();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.skyGradient,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                if (_currentPage < 2)
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () {
                        _pageController.animateToPage(2,
                            duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
                      },
                      child: Text(
                        '건너뛰기',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _ConceptPage(onNext: _next),
                      _PermissionPage(onRequest: _requestPermission, onSkip: _next, isLoading: _isRequesting),
                      _GoalPage(
                        targetMinutes: _targetMinutes,
                        onChanged: (v) => setState(() => _targetMinutes = v),
                        onFinish: _finish,
                      ),
                    ],
                  ),
                ),

                // Page indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConceptPage extends StatelessWidget {
  final VoidCallback onNext;
  const _ConceptPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          IslandWidget(stage: 5, size: 260, animate: true),
          const Spacer(),
          Text(
            'Unplug',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppColors.primaryDark,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '덜 쓸수록 자라나는 세계',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            '휴대폰을 덜 볼수록 나만의 섬이 자라납니다.\n오늘 하루 화면을 내려놓고, 세계를 키워보세요.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('시작하기'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PermissionPage extends StatelessWidget {
  final VoidCallback onRequest;
  final VoidCallback onSkip;
  final bool isLoading;

  const _PermissionPage({required this.onRequest, required this.onSkip, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.phone_android_rounded, size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            '스크린타임 접근',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '실제 사용시간을 측정해서\n섬을 정확하게 키우기 위해\n기기의 스크린타임 정보를 읽습니다.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '모든 데이터는 기기 안에만 저장됩니다. 외부로 전송되지 않습니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onRequest,
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('권한 허용하기'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onSkip,
            child: Text('나중에 할게요', style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  final int targetMinutes;
  final ValueChanged<int> onChanged;
  final VoidCallback onFinish;

  const _GoalPage({required this.targetMinutes, required this.onChanged, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final hours = targetMinutes ~/ 60;
    final mins = targetMinutes % 60;
    final label = mins == 0 ? '$hours시간' : '$hours시간 $mins분';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.timer_outlined, size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            '하루 목표 사용시간',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '이 시간보다 덜 쓴 만큼 씨앗이 쌓여요.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Text(
            label,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: AppColors.primaryDark,
              fontSize: 48,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: targetMinutes.toDouble(),
            min: AppConstants.minTargetMinutes.toDouble(),
            max: AppConstants.maxTargetMinutes.toDouble(),
            divisions: (AppConstants.maxTargetMinutes - AppConstants.minTargetMinutes) ~/ 30,
            onChanged: (v) => onChanged(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1시간', style: Theme.of(context).textTheme.bodySmall),
              Text('8시간', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFinish,
              child: const Text('시작하기 →'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
