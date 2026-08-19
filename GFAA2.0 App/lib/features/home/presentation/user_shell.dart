import 'package:flutter/material.dart';

import '../../../core/widgets/gfaa_bottom_nav.dart';
import '../../checkins/presentation/checkins_screen.dart';
import '../../community/presentation/community_screen.dart';
import 'home_screen.dart';
import 'profile_drawer.dart';

/// Persistent bottom nav for the whole `user` experience (per the client's
/// call: Option B — every screen, not just Home). Home / Check-in /
/// Community are real tabs, each with its own nested `Navigator` so pushing
/// into e.g. Journal or Training from Home still shows a back arrow and
/// keeps that tab's history, exactly like Instagram/WhatsApp-style bottom
/// tabs — only Profile is different: it opens the drawer (a slide-over
/// panel per the reference design) rather than switching to a fourth tab.
///
/// Deliberately scoped to `user` role only — `AdminHomeScreen` and
/// `PractitionerPortalScreen` are unrelated experiences and keep their
/// existing simple screens (see `_AuthGate` in app.dart).
class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _tabNavigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];
  int _currentTab = 0;

  static const _tabRoots = [HomeScreen(), CheckinsScreen(), CommunityScreen()];

  void _onNavTap(int index) {
    if (index == 3) {
      _scaffoldKey.currentState?.openDrawer();
      return;
    }
    if (index == _currentTab) {
      // Tapping the already-active tab returns to its root, same as
      // Instagram/WhatsApp — otherwise there'd be no way back to Home
      // short of repeatedly hitting the system back button.
      _tabNavigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _currentTab = index);
  }

  Future<bool> _onWillPop() async {
    final tabNavigator = _tabNavigatorKeys[_currentTab].currentState;
    if (tabNavigator != null && tabNavigator.canPop()) {
      tabNavigator.pop();
      return false;
    }
    if (_currentTab != 0) {
      setState(() => _currentTab = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _onWillPop() && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const ProfileDrawer(),
        body: IndexedStack(
          index: _currentTab,
          children: List.generate(_tabRoots.length, (index) {
            return Navigator(
              key: _tabNavigatorKeys[index],
              onGenerateRoute: (settings) {
                return MaterialPageRoute(builder: (_) => _tabRoots[index]);
              },
            );
          }),
        ),
        bottomNavigationBar: GfaaBottomNav(currentIndex: _currentTab, onTap: _onNavTap),
      ),
    );
  }
}
