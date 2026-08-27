import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/constants.dart';
import '../core/i18n.dart';
import '../models/models.dart';
import 'skeleton.dart';

/// Airbnb-style listing card: full-bleed image, title + rating row,
/// muted address, bold price line.
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, this.onTap});

  final ListingSummary listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(EqRadius.card),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(EqRadius.card),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _image(),
                    if (listing.status != 'Active')
                      PositionedDirectional(
                        top: 10,
                        start: 10,
                        child: _StatusPill(status: listing.status),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.locationAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.outline, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '${listing.costPerDay.toStringAsFixed(0)} ${s.t('common.jod')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        ' ${s.t('common.perDay')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: cs.outline, fontSize: 12.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    final url = imageUrl(listing.mainImage);
    final placeholder = Container(
      color: Colors.black.withValues(alpha: 0.04),
      child: Center(
        child: Icon(Icons.image_outlined,
            size: 40, color: Colors.grey.withValues(alpha: 0.5)),
      ),
    );
    if (url.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ShimmerBox(),
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'Pending' => ('status.Pending', EqColors.warn),
      'Inactive' => ('status.Inactive', EqColors.bad),
      _ => (status, EqColors.info),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(EqRadius.pill),
      ),
      child: Text(
        S.of(context).t(label),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
