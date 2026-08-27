import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/constants.dart';
import '../core/i18n.dart';
import '../models/models.dart';

/// Horizontally scrollable circular category strip (Airbnb-style):
/// image circle + label underneath, selected = ink pill.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    super.key,
    required this.categories,
    this.selectedId,
    this.onSelect,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<Category?>? onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S.of(context);

    Widget item({Widget? image, required String label, required bool active, VoidCallback? onTap}) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Opacity(
          opacity: active || selectedId == null ? 1 : 0.55,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? EqColors.accent : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: active
                      ? [BoxShadow(color: EqColors.accent.withValues(alpha: 0.3), blurRadius: 12)]
                      : null,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(child: image),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? cs.onSurface : cs.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        children: [
          item(
            label: s.t('browse.allCategories'),
            active: selectedId == null,
            onTap: () => onSelect?.call(null),
            image: Container(
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.apps_rounded, color: cs.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(width: 14),
          for (final c in categories) ...[
            item(
              label: S.of(context).isAr && c.nameAr != null ? c.nameAr! : c.name,
              active: selectedId == c.id,
              onTap: () => onSelect?.call(c),
              image: imageUrl(c.picture).isEmpty
                  ? Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.category_outlined,
                          color: cs.onSurface.withValues(alpha: 0.6)),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl(c.picture),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          ColoredBox(color: cs.surfaceContainerHighest),
                    ),
            ),
            const SizedBox(width: 14),
          ],
        ],
      ),
    );
  }
}
