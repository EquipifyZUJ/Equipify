import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/common.dart';

/// Compact admin console: dashboard stats + listing moderation.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late final _tab = TabController(length: 2, vsync: this);
  final _admin = AdminService();

  DashboardStats? _stats;
  List<ListingSummary>? _listings;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      if (_tab.index == 1 && _listings == null) _loadListings();
    });
  }

  Future<void> _load() async {
    setState(() => error = null);
    try {
      final st = await _admin.dashboard();
      if (!mounted) return;
      setState(() => _stats = st);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
    if (_listings == null) await _loadListings();
  }

  Future<void> _loadListings() async {
    try {
      final l = await _admin.listings();
      if (!mounted) return;
      setState(() => _listings = l);
    } catch (_) {/* dashboard still shown */}
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('nav.admin'))),
      body: error != null
          ? ErrorPanel(error: error!, onRetry: _load)
          : TabBarView(
              controller: _tab,
              children: [_dashboard(), _moderation()],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
        child: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(icon: const Icon(Icons.dashboard_outlined), text: s.t('admin.dashboard')),
            Tab(icon: const Icon(Icons.fact_check_outlined), text: s.t('admin.listings')),
          ],
        ),
      ),
    );
  }

  Widget _dashboard() {
    final s = S.of(context);
    final st = _stats;
    return RefreshIndicator(
      onRefresh: _load,
      child: st == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _stat(Icons.people_outline, s.t('admin.stat.users'), st.users),
                    _stat(Icons.inventory_2_outlined, s.t('admin.stat.listings'), st.listings),
                    _stat(Icons.verified_outlined, s.t('admin.stat.active'), st.activeListings,
                        color: EqColors.ok),
                    _stat(Icons.hourglass_top_rounded, s.t('admin.stat.pending'), st.pendingListings,
                        color: EqColors.warn),
                    _stat(Icons.category_outlined, s.t('admin.categories'), st.categories),
                    _stat(Icons.receipt_long_outlined, s.t('admin.stat.requests'), st.requests,
                        color: EqColors.info),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _stat(IconData icon, String label, int value, {Color? color}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(EqRadius.field),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [
          Icon(icon, size: 19, color: color ?? EqColors.accentDeep),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.outline), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 6),
        Text('$value',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1)),
      ]),
    );
  }

  Widget _moderation() {
    final s = S.of(context);
    final items = _listings;
    if (items == null) return const CardsSkeleton(crossAxisCount: 1);

    return RefreshIndicator(
      onRefresh: () async { await _loadListings(); },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final l = items[i];
          final pending = l.isPending;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(EqRadius.field),
              border: Border.all(
                  color: pending
                      ? EqColors.warn.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('${l.categoryName} · ${l.locationAddress}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
                ]),
              ),
              if (pending)
                FilledButton(
                  onPressed: () async {
                    await _admin.approveListing(l.id);
                    await _loadListings();
                  },
                  style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      backgroundColor: EqColors.ok,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 9)),
                  child: Text(s.t('admin.approve')),
                )
              else
                IconButton(
                  tooltip: s.t('admin.deactivate'),
                  onPressed: () async {
                    await _admin.deactivateListing(l.id);
                    await _loadListings();
                  },
                  icon: const Icon(Icons.block_outlined, color: EqColors.bad),
                ),
            ]),
          );
        },
      ),
    );
  }
}
