import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/common.dart';

/// Two tabs: my outgoing requests & incoming (owner-side) requests.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late final _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('nav.requests')),
        bottom: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: s.t('requests.mine')),
            Tab(text: s.t('requests.incoming')),
          ],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        _RequestsList(mode: _Mode.mine),
        _RequestsList(mode: _Mode.incoming),
      ]),
    );
  }
}

enum _Mode { mine, incoming }

class _RequestsList extends StatefulWidget {
  const _RequestsList({required this.mode});
  final _Mode mode;

  @override
  State<_RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<_RequestsList> {
  final _svc = RequestService();
  List<RentalRequest>? _items;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => error = null);
    try {
      final items =
          await (widget.mode == _Mode.mine ? _svc.mine() : _svc.incoming());
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (error != null) return ErrorPanel(error: error!, onRetry: _load);
    if (_items == null) return const CardsSkeleton(crossAxisCount: 1);
    if (_items!.isEmpty) return EmptyState(icon: Icons.receipt_long_outlined, text: s.t('requests.none'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _card(_items![i]),
      ),
    );
  }

  Widget _card(RentalRequest r) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(EqRadius.card),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(r.listingTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          _statusPill(r.status),
        ]),
        const SizedBox(height: 8),
        if (widget.mode == _Mode.incoming)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(Icons.person_outline, size: 15, color: cs.outline),
              const SizedBox(width: 4),
              Text(r.renter.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (r.renter.phoneNumber.isNotEmpty) ...[
                const SizedBox(width: 10),
                Icon(Icons.call_outlined, size: 14, color: cs.outline),
                const SizedBox(width: 3),
                Text(r.renter.phoneNumber,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: cs.outline, fontSize: 12.5)),
              ],
            ]),
          ),
        Row(children: [
          Icon(Icons.calendar_today_outlined, size: 13.5, color: cs.outline),
          const SizedBox(width: 5),
          Text(
            '${_fmt(r.fromDate)} → ${_fmt(r.toDate)}   ·   ${r.fromTime} - ${r.toTime}',
            textDirection: TextDirection.ltr,
            style: TextStyle(fontSize: 12.5, color: cs.outline),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Text(
            '${r.totalCost.toStringAsFixed(2)} ${s.t('common.jod')}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const Spacer(),
          if (widget.mode == _Mode.incoming && r.isPending) ...[
            OutlinedButton(
              onPressed: () async { await _svc.reject(r.id); _load(); },
              style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  foregroundColor: EqColors.bad,
                  side: BorderSide(color: EqColors.bad.withValues(alpha: .45)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9)),
              child: Text(s.t('requests.reject')),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async { await _svc.accept(r.id); _load(); },
              style: FilledButton.styleFrom(
                  minimumSize: Size.zero,
                  backgroundColor: EqColors.ok,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 9)),
              child: Text(s.t('requests.accept')),
            ),
          ] else if (widget.mode == _Mode.mine &&
              r.isPending &&
              r.hasRating == false)
            OutlinedButton(
              onPressed: () async { await _svc.cancel(r.id); _load(); },
              style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
              child: Text(s.t('common.cancel')),
            )
          else if (widget.mode == _Mode.mine && r.isAccepted)
            r.hasRating
                ? Text('${s.t('requests.rated')} ✓',
                    style: const TextStyle(
                        color: EqColors.ok, fontWeight: FontWeight.w700))
                : FilledButton.icon(
                    onPressed: () => _rateDialog(r),
                    icon: const Icon(Icons.star_rounded, size: 17),
                    style: FilledButton.styleFrom(
                        minimumSize: Size.zero,
                        backgroundColor: EqColors.accent,
                        foregroundColor: EqColors.accentText,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9)),
                    label: Text(s.t('requests.rate')),
                  ),
        ]),
      ]),
    );
  }

  Widget _statusPill(String status) {
    final s = S.of(context);
    final color = switch (status) {
      'Accepted' => EqColors.ok,
      'Rejected' => EqColors.bad,
      _ => EqColors.warn,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(s.t('status.$status'),
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _rateDialog(RentalRequest r) async {
    double stars = 5;
    final s = S.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(s.t('requests.rate')),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 34,
                  onPressed: () => setD(() => stars = i.toDouble()),
                  icon: Icon(
                    Icons.star_rounded,
                    color: i <= stars ? EqColors.accent : Theme.of(ctx).colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.t('common.cancel'))),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _svc.rate(r.id, stars);
                _load();
              },
              child: Text(s.t('common.confirm')),
            ),
          ],
        ),
      ),
    );
  }
}
