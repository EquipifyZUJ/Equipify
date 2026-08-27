import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Review> _reviews = [];
  bool _reviewsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    try {
      final reviews = await ListingService().userReviews(user.id);
      if (mounted) setState(() { _reviews = reviews; _reviewsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final user = auth.user;

    if (user == null) return const _LoggedOut();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 8),
        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: EqColors.accent,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: EqColors.accentText),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        Center(
          child: Text(user.emailAddress,
              style: TextStyle(color: cs.outline, fontSize: 13.5)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '${s.t('profile.memberSince')} ${user.createdAt.year}/${user.createdAt.month.toString().padLeft(2, '0')}',
            style: TextStyle(color: cs.outline, fontSize: 12),
          ),
        ),

        const SizedBox(height: 24),

        _SwitchTile(
          icon: Icons.dark_mode_outlined,
          label: s.t('profile.darkMode'),
          value: theme.mode == ThemeMode.dark,
          onChanged: (_) => theme.toggle(),
        ),
        _Tile(
          icon: Icons.language_rounded,
          label:
              '${s.t('profile.language')}: ${locale.isArabic ? 'العربية' : 'English'}',
          onTap: locale.toggle,
        ),

        // --- Reviews Section ---
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(EqRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 20),
                  const SizedBox(width: 6),
                  Text(s.t('auth.reviews'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              if (_reviewsLoading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))))
              else if (_reviews.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(s.t('auth.noReviews'),
                        style: TextStyle(color: cs.outline)),
                  ),
                )
              else
                ..._reviews.map((r) => _ReviewTile(review: r)),
            ],
          ),
        ),

        const SizedBox(height: 8),
        _Tile(
          icon: Icons.logout_rounded,
          label: s.t('profile.logout'),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(s.t('profile.logout')),
                content: Text(locale.isArabic
                    ? 'هل أنت متأكد من تسجيل الخروج؟'
                    : 'Are you sure you want to log out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(s.t('common.cancel')),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(s.t('common.confirm')),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await auth.logout();
            }
          },
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.renterName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(Icons.star_rounded,
                      size: 16,
                      color: i < review.rating.round()
                          ? Colors.amber
                          : cs.outlineVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${review.listingTitle} — ${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
            style: TextStyle(fontSize: 12.5, color: cs.outline),
          ),
        ],
      ),
    );
  }
}

class _LoggedOut extends StatelessWidget {
  const _LoggedOut();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: EqColors.accent,
                foregroundColor: EqColors.accentText,
                minimumSize: const Size(180, 50)),
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Text(s.t('nav.login')),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: Text(s.t('nav.register')),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(EqRadius.field),
      ),
      child: ListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(EqRadius.field)),
        leading: Icon(icon),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(EqRadius.field),
      ),
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        value: value,
        activeThumbColor: EqColors.accent,
        onChanged: onChanged,
      ),
    );
  }
}
