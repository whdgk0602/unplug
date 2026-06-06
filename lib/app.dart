import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project001/core/theme/app_colors.dart';
import 'package:project001/core/theme/app_theme.dart';
import 'package:project001/presentation/home/home_screen.dart';
import 'package:project001/presentation/onboarding/onboarding_screen.dart';
import 'package:project001/presentation/providers/providers.dart';
import 'package:project001/presentation/settings/settings_screen.dart';
import 'package:project001/presentation/stats/stats_screen.dart';
import 'package:project001/presentation/world_detail/world_detail_screen.dart';

class UnplugApp extends ConsumerWidget {
  const UnplugApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _createRouter(ref);
    return MaterialApp.router(
      title: 'Unplug',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  GoRouter _createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const _SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/world-detail',
          builder: (context, state) => const WorldDetailScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => _ScaffoldWithNav(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
            ]),
          ],
        ),
      ],
    );
  }
}

class _SplashScreen extends ConsumerWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    settingsAsync.whenData((settings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (settings.onboardingDone) {
          context.go('/');
        } else {
          context.go('/onboarding');
        }
      });
    });

    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Unplug',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '덜 쓸수록 자라나는 세계',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

class _ScaffoldWithNav extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _ScaffoldWithNav({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(index),
          indicatorColor: AppColors.primaryLight,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.landscape_outlined),
              selectedIcon: Icon(Icons.landscape_rounded, color: AppColors.primary),
              label: '나의 섬',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary),
              label: '통계',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}
