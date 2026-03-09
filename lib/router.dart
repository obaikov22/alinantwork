import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/employees_provider.dart';
import 'providers/leave_records_provider.dart';
import 'providers/note_records_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/eula/eula_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/team/team_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/notes/notes_screen.dart';
import 'screens/whats_new/whats_new_screen.dart';
import 'services/eula_service.dart';
import 'services/whats_new_service.dart';
import 'theme/app_theme.dart';
import 'widgets/update_banner.dart';

// Converts a Stream into a ChangeNotifier so GoRouter can listen to auth changes.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authRefresh = _GoRouterRefreshStream(
  FirebaseAuth.instance.authStateChanges(),
);

final router = GoRouter(
  initialLocation: '/calendar',
  refreshListenable: Listenable.merge(
      [_authRefresh, EulaService.instance, WhatsNewService.instance]),
  redirect: (context, state) {
    // Gate 1: EULA
    final eulaAccepted = EulaService.instance.accepted;
    final goingToEula = state.matchedLocation == '/eula';
    if (!eulaAccepted) {
      return goingToEula ? null : '/eula';
    }

    // Gate 2: What's New
    final showWhatsNew = WhatsNewService.instance.shouldShow;
    final goingToWhatsNew = state.matchedLocation == '/whats-new';
    if (showWhatsNew) {
      return goingToWhatsNew ? null : '/whats-new';
    }

    // Gate 3: Auth
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final goingToLogin = state.matchedLocation == '/login';
    if (!loggedIn && !goingToLogin) return '/login';
    if (loggedIn && goingToLogin) return '/calendar';
    return null;
  },
  routes: [
    GoRoute(
      path: '/eula',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: EulaScreen(),
      ),
    ),
    GoRoute(
      path: '/whats-new',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: WhatsNewScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LoginScreen(),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => _MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CalendarScreen(),
          ),
        ),
        GoRoute(
          path: '/team',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TeamScreen(),
          ),
        ),
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/notes',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NotesScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => const MaterialPage(
        child: SettingsScreen(),
      ),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Main scaffold (tabs + bottom nav) — triggers Firestore sync on first build
// ---------------------------------------------------------------------------

class _MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const _MainScaffold({required this.child});

  @override
  ConsumerState<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<_MainScaffold> {
  static const _tabs = ['/calendar', '/team', '/dashboard', '/notes'];

  @override
  void initState() {
    super.initState();
    // Trigger Firestore sync after the first frame so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(employeesProvider.notifier).initialize();
      ref.read(leaveRecordsProvider.notifier).initialize();
      ref.read(noteRecordsProvider.notifier).initialize();
    });
  }

  int _locationIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _tabs.indexWhere((t) => location.startsWith(t));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: UpdateBanner(child: widget.child),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => context.go(_tabs[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_view_week_outlined),
              selectedIcon: Icon(Icons.calendar_view_week),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Team',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.sticky_note_2_outlined),
              selectedIcon: Icon(Icons.sticky_note_2),
              label: 'Notes',
            ),
          ],
        ),
      ),
    );
  }
}
