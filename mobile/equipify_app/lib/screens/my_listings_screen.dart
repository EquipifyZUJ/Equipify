import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/common.dart';
import 'listing_form_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final _svc = ListingService();
  List<ListingSummary>? _items;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => error = null);
    try {
      final items = await _svc.mine();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> _toggle(ListingSummary l) async {
    try {
      await _svc.setStatus(l.id, l.isActive ? 'Inactive' : 'Active');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: EqColors.bad));
    }
  }

  Future<void> _delete(ListingSummary l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx).t('common.delete')),
        content: Text(l.title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(S.of(ctx).t('common.cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EqColors.bad),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.of(ctx).t('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _svc.delete(l.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('mylistings.title'))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: EqColors.accent,
        foregroundColor: EqColors.accentText,
        onPressed: () async {
          final ok = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => const ListingFormScreen()));
          if (ok == true) _load();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(s.t('mylistings.new')),
      ),
      body: error != null
          ? ErrorPanel(error: error!, onRetry: _load)
          : _items == null
              ? const CardsSkeleton()
              : _items!.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      text: s.t('mylistings.none'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _row(context, _items![i], cs),
                      ),
                    ),
    );
  }

  Widget _row(BuildContext context, ListingSummary l, ColorScheme cs) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(EqRadius.card),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 84, height: 68,
            child: imageUrl(l.mainImage).isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl(l.mainImage),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: const Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: const Icon(Icons.image_outlined),
                    ),
                  )
                : ColoredBox(
                    color: cs.surfaceContainerHighest,
                    child: const Icon(Icons.image_outlined),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Row(children: [
                _StatusDot(status: l.status),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${l.costPerDay.toStringAsFixed(0)} ${s.t('common.jod')}${s.t('common.perDay')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: cs.outline),
                  ),
                ),
              ]),
            ],
          ),
        ),
        IconButton(
          tooltip: l.isActive ? s.t('mylistings.deactivate') : s.t('mylistings.activate'),
          onPressed: () => _toggle(l),
          icon: Icon(
            l.isActive
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: l.isActive ? EqColors.warn : EqColors.ok,
          ),
        ),
        IconButton(
          tooltip: s.t('common.edit'),
          onPressed: () async {
            final ok = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => ListingFormScreen(existing: l)),
            );
            if (ok == true) _load();
          },
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: s.t('common.delete'),
          onPressed: () => _delete(l),
          icon: const Icon(Icons.delete_outline, color: EqColors.bad),
        ),
      ]),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final color = switch (status) {
      'Pending' => EqColors.warn,
      'Inactive' => EqColors.bad,
      _ => EqColors.ok,
    };
    final key = switch (status) {
      'Pending' => 'status.Pending',
      'Inactive' => 'status.Inactive',
      _ => 'status.Active',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(s.t(key),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
