import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../core/i18n.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';

class ListingDetailsScreen extends StatefulWidget {
  const ListingDetailsScreen({super.key, required this.id});
  final int id;

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  final _listings = ListingService();

  Listing? listing;
  List<Review> _reviews = [];
  String? error;
  int page = 0;

  // Booking form state
  DateTime? from;
  DateTime? to;
  TimeOfDay tFrom = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay tTo = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => error = null);
    try {
      final l = await _listings.details(widget.id);
      if (!mounted) return;
      setState(() => listing = l);
      // Load reviews
      try {
        final reviews = await _listings.listingReviews(widget.id);
        if (mounted) setState(() => _reviews = reviews);
      } catch (_) {}
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    if (error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorPanel(error: error!, onRetry: _load),
      );
    }
    final l = listing;
    if (l == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ListView(
          children: const [
            ShimmerBox(height: 300, radius: 0),
            Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerBox(height: 22),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.categoryName)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: l.status == 'Active'
              ? Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(l.primaryPrice ?? l.costPerDay).toStringAsFixed(0)} ${s.t('common.jod')}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        Text(_perUnitLabel(s, l.rentalUnit),
                            style: TextStyle(color: cs.outline, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: FilledButton(
                        onPressed: _openBookingFlow,
                        style: FilledButton.styleFrom(
                            backgroundColor: EqColors.accent,
                            foregroundColor: EqColors.accentText),
                        child: Text(s.t('listing.bookNow')),
                      ),
                    ),
                  ],
                )
              : Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(EqRadius.pill),
                  ),
                  child: Text(s.t('listing.unavailable'),
                      style: TextStyle(color: cs.outline)),
                ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _Gallery(images: l.images.isEmpty ? [l.mainImage] : l.images),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 15, color: cs.outline),
                    const SizedBox(width: 4),
                    Text(l.locationAddress,
                        style: TextStyle(color: cs.outline, fontSize: 13.5)),
                  ],
                ),
                if (l.owner != null) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: EqColors.accent,
                      child: Text(
                        l.owner!.name.isNotEmpty
                            ? l.owner!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: EqColors.accentText,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.t('listing.owner'),
                              style:
                                  const TextStyle(fontSize: 11.5, color: EqColors.lightMuted)),
                          Text(l.owner!.name,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                    const Spacer(),
                    Icon(Icons.star_rounded,
                        size: 17, color: EqColors.accentDeep),
                    Text(
                        (l.owner!.rating ?? 0).toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                ],

                const Divider(height: 34),

                Text(s.t('listing.about'),
                    style: const TextStyle(
                        fontSize: 16.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  l.description.isEmpty ? '—' : l.description,
                  style: TextStyle(height: 1.7, color: cs.onSurface.withValues(alpha: 0.85)),
                ),

                const SizedBox(height: 18),

                // ── Reviews ──
                if (_reviews.isNotEmpty) ...[
                  Text(s.t('auth.reviews'),
                      style: const TextStyle(
                          fontSize: 16.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ..._reviews.map((r) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r.renterName,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(Icons.star_rounded,
                                        size: 16,
                                        color: i < r.rating.round()
                                            ? Colors.amber
                                            : cs.outlineVariant),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${r.listingTitle} — ${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
                              style: TextStyle(fontSize: 12.5, color: cs.outline),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 24),
                ],

                // ── Price tiers ──
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (l.rentalUnit != 'day')
                      _priceChip(s.t('common.perDay'), l.costPerDay, s),
                    if (l.costPerHour != null && l.rentalUnit != 'hour')
                      _priceChip(s.t('common.perHour'), l.costPerHour!, s),
                    if (l.costPerWeek != null && l.rentalUnit != 'week')
                      _priceChip(s.t('common.perWeek'), l.costPerWeek!, s),
                    if (l.costPerMonth != null && l.rentalUnit != 'month')
                      _priceChip(s.t('common.perMonth'), l.costPerMonth!, s),
                    if (l.costPerYear != null && l.rentalUnit != 'year')
                      _priceChip(s.t('common.perYear'), l.costPerYear!, s),
                  ],
                ),

                // ── Min / Max duration ──
                if (l.minRentalDays != null || l.maxRentalDays != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (l.minRentalDays != null)
                        _durationBadge(s.t('browse.minDuration', {'unit': _unitSingularLabel(s, l.rentalUnit)}), l.minRentalDays!, cs),
                      if (l.maxRentalDays != null)
                        _durationBadge(s.t('browse.maxDuration', {'unit': _unitSingularLabel(s, l.rentalUnit)}), l.maxRentalDays!, cs),
                    ],
                  ),
                ],

                const Divider(height: 34),

                Text(s.t('listing.location'),
                    style: const TextStyle(
                        fontSize: 16.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(EqRadius.card),
                  child: SizedBox(
                    height: 190,
                    child: Builder(
                      builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0c1222)
                                      : const Color(0xFFE8E4DF),
                                ),
                              ),
                            ),
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(l.latitude, l.longitude),
                                initialZoom: 13,
                                interactionOptions:
                                    const InteractionOptions(flags: InteractiveFlag.none),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: isDark
                                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                                      : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                                  subdomains: const ['a', 'b', 'c', 'd'],
                                  userAgentPackageName: 'com.equipify.app',
                                ),
                                MarkerLayer(markers: [
                                  Marker(
                                    point: LatLng(l.latitude, l.longitude),
                                    width: 60,
                                    height: 60,
                                    child: const Icon(Icons.location_on_rounded,
                                        size: 42, color: EqColors.bad),
                                  ),
                                ]),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                if ((l.owner?.phone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: Text(s.t('listing.contactOwner')),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceChip(String unit, double value, S s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: EqColors.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(EqRadius.pill),
          border: Border.all(color: EqColors.accent.withValues(alpha: 0.45)),
        ),
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                text: '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)} ${s.t('common.jod')} ',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: EqColors.accentText),
              ),
              TextSpan(
                text: unit,
                style: const TextStyle(fontSize: 11.5, color: EqColors.accentText),
              ),
            ],
          ),
        ),
      );

  String _perUnitLabel(S s, String unit) {
    switch (unit) {
      case 'hour': return s.t('common.perHour');
      case 'week': return s.t('common.perWeek');
      case 'month': return s.t('common.perMonth');
      case 'year': return s.t('common.perYear');
      default: return s.t('common.perDay');
    }
  }

  String _unitSingularLabel(S s, String unit) {
    switch (unit) {
      case 'hour': return s.t('browse.unitHourSingular');
      case 'week': return s.t('browse.unitWeekSingular');
      case 'month': return s.t('browse.unitMonthSingular');
      case 'year': return s.t('browse.unitYearSingular');
      default: return s.t('browse.unitDaySingular');
    }
  }

  Widget _durationBadge(String label, int value, ColorScheme cs) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(EqRadius.pill),
        ),
        child: Text('≥ $value $label',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      );

  // ───────────────────── booking flow with OTP ─────────────────────

  Future<void> _openBookingFlow() async {
    final s = S.of(context);
    final picked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BookingSheet(
        listingId: widget.id,
        costPerDay: listing?.costPerDay ?? 0,
      ),
    );
    if (picked == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.t('status.Pending')), backgroundColor: EqColors.ok),
      );
    }
  }
}

// ═══════════════════════ Gallery ═══════════════════════

class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});
  final List<String?> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.images.whereType<String>().toList();
    final count = imgs.isEmpty ? 1 : imgs.length;
    return SizedBox(
      height: 290,
      child: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: count,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: imageUrl(imgs.isEmpty ? null : imgs[i]),
              fit: BoxFit.cover,
              placeholder: (_, __) => const ShimmerBox(radius: 0),
              errorWidget: (_, __, ___) =>
                  ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
            ),
          ),
          if (count > 1)
            PositionedDirectional(
              bottom: 12,
              start: 0,
              end: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: i == _page ? 1 : 0.5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════ Booking sheet ═══════════════════════

class _BookingSheet extends StatefulWidget {
  const _BookingSheet({required this.listingId, required this.costPerDay});
  final int listingId;
  final double costPerDay;

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  final _reqSvc = RequestService();

  DateTime from = DateTime.now().add(const Duration(days: 1));
  DateTime to = DateTime.now().add(const Duration(days: 2));
  TimeOfDay tf = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay tt = const TimeOfDay(hour: 17, minute: 0);

  OtpSent? otp;
  int _cooldown = 0;
  final _codeCtrl = TextEditingController();
  bool busy = false;
  String? error;

  double get days =>
      to.difference(from).inDays < 1 ? 1 : to.difference(from).inDays + 0.0;

  String two(int n) => n.toString().padLeft(2, '0');
  String fmtT(TimeOfDay t) => '${two(t.hour)}:00:00';
  String fmtD(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  Future<void> _sendOtp() async {
    setState(() { busy = true; error = null; });
    try {
      final o = await _reqSvc.sendOtp(widget.listingId);
      setState(() {
        otp = o;
        _cooldown = o.cooldownSeconds;
      });
      _tick();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _tick() async {
    while (_cooldown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _cooldown--);
    }
  }

  Future<void> _submit() async {
    setState(() { busy = true; error = null; });
    try {
      await _reqSvc.create(
        listingId: widget.listingId,
        fromDate: from,
        toDate: to,
        fromTime: fmtT(tf),
        toTime: fmtT(tt),
        otpCode: _codeCtrl.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { error = e.toString(); busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 18, right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.t('otp.title'),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: _dateField(context, s.t('listing.from'), from, (d) => setState(() { from = d; if (to.isBefore(from)) to = from; }))),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, size: 18),
              const SizedBox(width: 10),
              Expanded(child: _dateField(context, s.t('listing.to'), to, (d) => setState(() => to = d))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _timeField(context, s.t('listing.timeFrom'), tf, (t) => setState(() => tf = t))),
              const SizedBox(width: 10),
              Expanded(child: _timeField(context, s.t('listing.timeTo'), tt, (t) => setState(() => tt = t))),
            ]),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(EqRadius.field),
              ),
              child: Row(children: [
                Text(s.t('listing.total'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  '${days.toStringAsFixed(0)} ${s.t('listing.days')} × ${widget.costPerDay.toStringAsFixed(0)} ${s.t('common.jod')}',
                  style: TextStyle(color: cs.outline, fontSize: 12.5),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(days * widget.costPerDay).toStringAsFixed(2)} ${s.t('common.jod')}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ]),
            ),

            const SizedBox(height: 18),

            if (otp == null)
              FilledButton(
                onPressed: busy ? null : _sendOtp,
                child: Text(s.t('auth.sendOtp')),
              )
            else ...[
              if (otp!.devCode != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${s.t('otp.devCode')}: ${otp!.devCode}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: EqColors.ok),
                  ),
                ),
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.w800),
                decoration: InputDecoration(hintText: '0000', counterText: ''),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cooldown > 0 || busy ? null : _sendOtp,
                    child: Text(_cooldown > 0
                        ? '${s.t('otp.resendIn')} $_cooldown ${s.t('otp.seconds')}'
                        : s.t('auth.sendOtp')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : _submit,
                    style: FilledButton.styleFrom(
                        backgroundColor: EqColors.accent,
                        foregroundColor: EqColors.accentText),
                    child: Text(s.t('common.confirm')),
                  ),
                ),
              ]),
            ],

            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: EqColors.bad, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateField(BuildContext ctx, String label, DateTime v, ValueChanged<DateTime> onPick) {
    return InkWell(
      borderRadius: BorderRadius.circular(EqRadius.field),
      onTap: () async {
        final d = await showDatePicker(
          context: ctx,
          initialDate: v,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(fmtD(v), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      ),
    );
  }

  Widget _timeField(BuildContext ctx, String label, TimeOfDay v, ValueChanged<TimeOfDay> onPick) {
    return InkWell(
      borderRadius: BorderRadius.circular(EqRadius.field),
      onTap: () async {
        final t = await showTimePicker(context: ctx, initialTime: v);
        if (t != null) onPick(t);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text('${two(v.hour)}:${two(v.minute)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      ),
    );
  }
}
