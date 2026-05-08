import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/income_expense/presentation/pages/income_expense_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/result/presentation/pages/result_page.dart';
import '../../features/assets/presentation/pages/assets_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return _ScaffoldWithBottomNav(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardPage(),
          ),
        ),
        GoRoute(
          path: '/income-expense',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: IncomeExpensePage(),
          ),
        ),
        GoRoute(
          path: '/assets',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AssetsPage(),
          ),
        ),
        GoRoute(
          path: '/result',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ResultPage(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilePage(),
          ),
        ),
      ],
    ),
  ],
);

class _ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  const _ScaffoldWithBottomNav({required this.child});

  int _currentIndex(String location) {
    if (location.startsWith('/income-expense')) return 1;
    if (location.startsWith('/result')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _currentIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/income-expense');
              break;
            case 2:
              context.go('/result');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: '收支',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '结果',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
