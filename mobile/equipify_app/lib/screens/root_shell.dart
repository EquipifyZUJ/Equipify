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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = S.of(context);
    final isAr = s.isAr;

    final tabs = <_Tab>[
      _Tab(Icons.home_rounded, Icons.home_outlined, s.t('nav.home'), const HomeScreen()),
      _Tab(Icons.explore_rounded, Icons.explore_outlined, s.t('nav.browse'), const BrowseScreen()),
      if (auth.user != null) ...[
        _Tab(Icons.inventory_2_rounded, Icons.inventory_2_outlined,
            s.t('nav.myListings'), const MyListingsScreen()),
        _Tab(Icons.receipt_long_rounded, Icons.receipt_long_outlined,
            s.t('nav.requests'), const RequestsScreen()),
        _Tab(Icons.person_rounded, Icons.person_outline, s.t('nav.profile'),
            const ProfileScreen()),
      ] else
        _Tab(Icons.person_rounded, Icons.person_outline, s.t('nav.profile'),
            const ProfileScreen()),
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
      body: IndexedStack(index: _index, children: [for (final t in tabs) t.page]),
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
}

class _Tab {
  const _Tab(this.filled, this.outlined, this.label, this.page);
  final IconData filled;
  final IconData outlined;
  final String label;
  final Widget page;
}
