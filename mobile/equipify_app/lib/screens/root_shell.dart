import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'browse_screen.dart';
import 'my_listings_screen.dart';
import 'requests_screen.dart';
import 'profile_screen.dart';

/// Root navigation shell with a bottom bar (mobile pattern).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  final Map<int, Widget> _cache = {};

  Widget _buildTab(Widget Function() builder, int index) {
    return _cache.putIfAbsent(index, builder);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = S.of(context);
    final isAr = s.isAr;

    final tabs = <_Tab>[
      _Tab(Icons.home_rounded, Icons.home_outlined, s.t('nav.home')),
      _Tab(Icons.explore_rounded, Icons.explore_outlined, s.t('nav.browse')),
      if (auth.user != null) ...[
        _Tab(Icons.inventory_2_rounded, Icons.inventory_2_outlined, s.t('nav.myListings')),
        _Tab(Icons.receipt_long_rounded, Icons.receipt_long_outlined, s.t('nav.requests')),
        _Tab(Icons.person_rounded, Icons.person_outline, s.t('nav.profile')),
      ] else
        _Tab(Icons.person_rounded, Icons.person_outline, s.t('nav.profile')),
    ];

    final logoWidget = Image(
      image: AssetImage(
        Theme.of(context).brightness == Brightness.dark
            ? 'img/logo_dark.png'
            : 'img/logo_light.png',
      ),
      height: 38,
      fit: BoxFit.contain,
    );

    // Build only the selected tab + any previously visited tabs
    final pages = <Widget>[];
    for (var i = 0; i < tabs.length; i++) {
      if (i == _index) {
        pages.add(_buildTab(() => _createPage(i), i));
      } else if (_cache.containsKey(i)) {
        pages.add(_cache[i]!);
      } else {
        // Placeholder for unvisited tabs (won't be built)
        pages.add(const SizedBox.shrink());
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: isAr ? null : logoWidget,
        title: Text(
          'Equipify',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : EqColors.accent,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isAr) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: logoWidget,
            ),
          ],
        ],
        leadingWidth: 54,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _cache.containsKey(i) ? _cache[i]! : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index.clamp(0, tabs.length - 1),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (var i = 0; i < tabs.length; i++)
            NavigationDestination(
              icon: Icon(tabs[i].outlined),
              selectedIcon: Icon(tabs[i].filled),
              label: tabs[i].label,
            ),
        ],
      ),
    );
  }

  Widget _createPage(int index) {
    switch (index) {
      case 0: return const HomeScreen();
      case 1: return const BrowseScreen();
      case 2: return const MyListingsScreen();
      case 3: return const RequestsScreen();
      default: return const ProfileScreen();
    }
  }
}

class _Tab {
  const _Tab(this.filled, this.outlined, this.label);
  final IconData filled;
  final IconData outlined;
  final String label;
}
