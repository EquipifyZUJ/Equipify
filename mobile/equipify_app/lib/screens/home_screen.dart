import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/category_strip.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';
import '../widgets/listing_card.dart';
import 'browse_screen.dart';
import 'listing_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = ListingService();
  final _catSvc = CategoryService();
  final _search = TextEditingController();

  List<Category>? _cats;
  Paged<ListingSummary>? _featured;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([
        _catSvc.all(),
        _svc.browse(pageSize: 6),
      ]);
      if (!mounted) return;
      setState(() {
        _cats = results[0] as List<Category>;
        _featured = results[1] as Paged<ListingSummary>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 18),
          Text(
            s.t('home.heroTitle'),
            style: const TextStyle(
              fontSize: 28,
              height: 1.3,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.t('home.heroSub'),
            style: TextStyle(color: cs.outline, fontSize: 14.5, height: 1.5),
          ),
          const SizedBox(height: 18),

          // ── Search pill ──
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _openBrowse(),
            decoration: InputDecoration(
              hintText: s.t('common.search'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: _openBrowse,
              ),
            ),
          ),

          // ── Categories strip ──
          SectionHeader(s.t('home.categories')),
          if (_cats == null)
            const ShimmerBox(height: 92)
          else
            CategoryStrip(
              categories: _cats!,
              onSelect: (c) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BrowseScreen(initialCategoryId: c?.id),
                ),
              ),
            ),

          // ── Featured listings ──
          SectionHeader(
            s.t('home.featured'),
            actionLabel: s.t('home.seeAll'),
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BrowseScreen()),
            ),
          ),
          if (_error != null)
            ErrorPanel(error: _error!, onRetry: _load)
          else if (_featured == null)
            const CardsSkeleton()
          else if (_featured!.items.isEmpty)
            EmptyState(
              icon: Icons.inventory_2_outlined,
              text: s.t('browse.empty'),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 14,
              childAspectRatio: 0.72,
              children: [
                for (final l in _featured!.items)
                  ListingCard(listing: l, onTap: () => _openDetails(l.id)),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _openBrowse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BrowseScreen(initialSearch: _search.text)),
    );
  }

  void _openDetails(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ListingDetailsScreen(id: id)),
    );
  }
}
