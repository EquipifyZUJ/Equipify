import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide Bounds;
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/constants.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/category_strip.dart';
import '../widgets/common.dart';
import '../widgets/listing_card.dart';
import 'listing_details_screen.dart';

const _rentalUnits = ['hour', 'day', 'week', 'month', 'year'];

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key, this.initialSearch, this.initialCategoryId});

  final String? initialSearch;
  final int? initialCategoryId;

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _svc = ListingService();

  bool _mapMode = true;
  bool _loading = true;
  String? _error;

  String _search = '';
  int? _categoryId;
  String? _rentalUnit;
  double? _minPrice;
  double? _maxPrice;
  int? _minDuration;
  int? _maxDuration;

  Paged<ListingSummary>? _results;
  List<MapMarker> _markers = [];
  List<Category> _cats = [];

  Bounds _bounds = Bounds(west: 35.3, south: 31.5, east: 36.2, north: 32.3);

  bool get _hasActiveFilters =>
      _rentalUnit != null ||
      _minPrice != null ||
      _maxPrice != null ||
      _minDuration != null ||
      _maxDuration != null;

  @override
  void initState() {
    super.initState();
    _search = widget.initialSearch ?? '';
    _categoryId = widget.initialCategoryId;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _cats = await CategoryService().all();
    } catch (_) {/* non-fatal */}
    await _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_mapMode) {
        final markers = await _svc.mapMarkers(_bounds, categoryId: _categoryId);
        if (!mounted) return;
        setState(() { _markers = markers; _loading = false; });
      } else {
        final res = await _svc.browse(
          search: _search,
          categoryId: _categoryId,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          rentalUnit: _rentalUnit,
          minDuration: _minDuration,
          maxDuration: _maxDuration,
          page: _page,
        );
        if (!mounted) return;
        setState(() { _results = res; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _unitLabel(S s, String unit) {
    switch (unit) {
      case 'hour': return s.t('browse.unitHour');
      case 'day': return s.t('browse.unitDay');
      case 'week': return s.t('browse.unitWeek');
      case 'month': return s.t('browse.unitMonth');
      case 'year': return s.t('browse.unitYear');
      default: return unit;
    }
  }

  String _unitSingularLabel(S s, String unit) {
    switch (unit) {
      case 'hour': return s.t('browse.unitHourSingular');
      case 'day': return s.t('browse.unitDaySingular');
      case 'week': return s.t('browse.unitWeekSingular');
      case 'month': return s.t('browse.unitMonthSingular');
      case 'year': return s.t('browse.unitYearSingular');
      default: return s.t('browse.unitDaySingular');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('browse.title')),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: Text(s.t('browse.grid')),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(s.t('browse.mapView')),
                ),
              ],
              selected: {_mapMode},
              onSelectionChanged: (v) {
                setState(() => _mapMode = v.first);
                _load();
              },
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar + filter button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: s.t('common.search'),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(EqRadius.field),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(EqRadius.field),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) { _search = v; _load(); },
                    onChanged: (v) => _search = v,
                  ),
                ),
                const SizedBox(width: 8),
                // Filter button
                BadgedIconButton(
                  icon: Icons.tune_rounded,
                  badge: _hasActiveFilters,
                  onPressed: () => _showFilterSheet(s, cs),
                ),
              ],
            ),
          ),

          // ── Category chips ──
          CategoryStrip(
            categories: _cats,
            selectedId: _categoryId,
            onSelect: (c) {
              setState(() => _categoryId = c?.id);
              _load();
            },
          ),

          Expanded(
            child: _error != null
                ? ErrorPanel(error: _error!, onRetry: _load)
                : _loading
                    ? const CardsSkeleton()
                    : _mapMode
                        ? _buildMap()
                        : _buildGrid(s, cs),
          ),
        ],
      ),
    );
  }

  // ── Filter bottom sheet ──
  void _showFilterSheet(S s, ColorScheme cs) {
    double? minP = _minPrice;
    double? maxP = _maxPrice;
    int? minD = _minDuration;
    int? maxD = _maxDuration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(s.t('browse.filters'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Rental unit
              Text(s.t('browse.rentalUnit'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.outline)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: Text(s.t('browse.allUnits')),
                    selected: _rentalUnit == null,
                    onSelected: (_) => setSheet(() => _rentalUnit = null),
                  ),
                  for (final u in _rentalUnits)
                    ChoiceChip(
                      label: Text(_unitLabel(s, u)),
                      selected: _rentalUnit == u,
                      onSelected: (_) => setSheet(() => _rentalUnit = u),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Price range
              Text(s.t('browse.minPrice'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.outline)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixText: '${s.t('common.jod')} ',
                        isDense: true,
                      ),
                      controller: TextEditingController(text: minP?.toStringAsFixed(0) ?? ''),
                      onChanged: (v) => minP = double.tryParse(v),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('—', style: TextStyle(color: cs.outline)),
                  ),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '∞',
                        prefixText: '${s.t('common.jod')} ',
                        isDense: true,
                      ),
                      controller: TextEditingController(text: maxP?.toStringAsFixed(0) ?? ''),
                      onChanged: (v) => maxP = double.tryParse(v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Duration range — labels change based on selected unit
              if (_rentalUnit != null) ...[
                Text(s.t('browse.duration'),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.outline)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '1',
                          suffixText: s.t('browse.minDuration', {'unit': _unitSingularLabel(s, _rentalUnit!)}),
                          isDense: true,
                        ),
                        controller: TextEditingController(text: minD?.toString() ?? ''),
                        onChanged: (v) => minD = int.tryParse(v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('—', style: TextStyle(color: cs.outline)),
                    ),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '∞',
                          suffixText: s.t('browse.maxDuration', {'unit': _unitSingularLabel(s, _rentalUnit!)}),
                          isDense: true,
                        ),
                        controller: TextEditingController(text: maxD?.toString() ?? ''),
                        onChanged: (v) => maxD = int.tryParse(v),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setSheet(() { minP = null; maxP = null; minD = null; maxD = null; });
                        setState(() { _minPrice = null; _maxPrice = null; _minDuration = null; _maxDuration = null; });
                        Navigator.pop(ctx);
                        _load();
                      },
                      child: Text(s.t('browse.resetFilters')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: EqColors.accent,
                        foregroundColor: EqColors.accentText,
                      ),
                      onPressed: () {
                        setState(() {
                          _minPrice = minP;
                          _maxPrice = maxP;
                          _minDuration = minD;
                          _maxDuration = maxD;
                        });
                        Navigator.pop(ctx);
                        _load();
                      },
                      child: Text(s.t('browse.applyFilters')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── grid mode ─────────────────────────

  Widget _buildGrid(S s, ColorScheme cs) {
    final items = _results!.items;
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${_results!.totalCount} ${s.t('browse.results')}',
                style: TextStyle(
                  color: cs.outline,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                  icon: Icons.search_off_rounded, text: s.t('browse.empty')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => ListingCard(
                    listing: items[i],
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) =>
                            ListingDetailsScreen(id: items[i].id),
                      ),
                    ),
                  ),
                  childCount: items.length,
                ),
              ),
            ),
          if ((_results?.totalPages ?? 1) > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: _results!.page > 1 ? _prevPage : null,
                      child: const Icon(Icons.arrow_back_ios_new, size: 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        '${_results!.page} / ${_results!.totalPages}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _results!.page < _results!.totalPages
                          ? _nextPage
                          : null,
                      child: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _page = 1;

  void _nextPage() {
    if (_results == null || _page >= _results!.totalPages) return;
    setState(() => _page++);
    _load();
  }

  void _prevPage() {
    if (_page <= 1) return;
    setState(() => _page--);
    _load();
  }

  // ───────────────────────── map mode ─────────────────────────

  final _mapCtrl = MapController();

  Widget _buildMap() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
    final tileSubdomains = ['a', 'b', 'c', 'd'];
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0c1222) : const Color(0xFFE8E4DF),
            ),
          ),
        ),
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: const LatLng(31.95, 35.91),
            initialZoom: 10,
            onPositionChanged: (pos, _) {
              final b = pos.visibleBounds;
              _bounds = Bounds(
                west: b.west, south: b.south, east: b.east, north: b.north,
              );
            },
            onMapEvent: (e) {
              if (e is MapEventMoveEnd) _load();
            },
          ),
          children: [
            TileLayer(urlTemplate: tileUrl, subdomains: tileSubdomains, userAgentPackageName: 'com.equipify.app'),
            MarkerLayer(
              markers: [
                for (final m in _markers)
                  Marker(
                    point: LatLng(m.latitude, m.longitude),
                    width: 74, height: 34,
                    child: _PricePin(
                      label: m.costPerDay.toStringAsFixed(0),
                      onTap: () => _showMarkerSheet(m),
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          ],
        ),
        PositionedDirectional(
          bottom: 18, start: 0, end: 0,
          child: Center(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? Colors.white : EqColors.ink,
                foregroundColor: isDark ? Colors.black : Colors.white,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('${_markers.length} ${S.of(context).t('browse.results')}'),
            ),
          ),
        ),
      ],
    );
  }

  void _showMarkerSheet(MapMarker m) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: InkWell(
          borderRadius: BorderRadius.circular(EqRadius.card),
          onTap: () {
            Navigator.pop(ctx);
            Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailsScreen(id: m.id)));
          },
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92, height: 74,
                  child: imageUrl(m.image).isEmpty
                      ? ColoredBox(color: Theme.of(ctx).colorScheme.surfaceContainerHighest)
                      : CachedNetworkImage(imageUrl: imageUrl(m.image), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(m.locationAddress, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Theme.of(ctx).colorScheme.outline, fontSize: 13)),
                    const SizedBox(height: 5),
                    Text(
                      '${m.costPerDay.toStringAsFixed(0)} ${S.of(ctx).t('common.jod')} ${S.of(ctx).t('common.perDay')}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Active filter tag ──
// ── Badged icon button ──
class BadgedIconButton extends StatelessWidget {
  const BadgedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, size: 22),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(EqRadius.field),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
          ),
        ),
        if (badge)
          Positioned(
            top: 6, right: 6,
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: EqColors.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// White/dark pill with the daily price — Airbnb-style map pin.
class _PricePin extends StatelessWidget {
  const _PricePin({required this.label, this.onTap, this.isDark = false});
  final String label;
  final VoidCallback? onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(EqRadius.pill),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF14161F),
          ),
        ),
      ),
    );
  }
}
