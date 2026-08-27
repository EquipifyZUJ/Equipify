import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'dart:io';

import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';

import '../core/i18n.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/map_picker_screen.dart';

const int _maxImages = 6;
const int _maxFileSizeMB = 5;

/// Create / edit a listing. Mirrors the API multipart contract exactly.
class ListingFormScreen extends StatefulWidget {
  const ListingFormScreen({super.key, this.existing});
  final ListingSummary? existing;

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  final _form = GlobalKey<FormState>();
  final _svc = ListingService();
  final _picker = ImagePicker();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();

  List<Category> _cats = [];
  int? _categoryId;

  final _costDay = TextEditingController();
  final _costHour = TextEditingController();
  final _costWeek = TextEditingController();
  final _costMonth = TextEditingController();
  final _costYear = TextEditingController();
  final _minDays = TextEditingController();
  final _maxDays = TextEditingController();

  String _rentalUnit = 'day';

  double lat = 31.95, lng = 35.91;
  final List<XFile> _newImages = [];

  bool loading = true;
  bool busy = false;
  String? error;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _cats = await CategoryService().all();
      if (isEdit) {
        final full = await _svc.details(widget.existing!.id);
        _title.text = full.title;
        _description.text = full.description;
        _address.text = full.locationAddress;
        _categoryId = full.categoryId;
        _costDay.text = full.costPerDay.toStringAsFixed(0);
        _costHour.text = full.costPerHour?.toStringAsFixed(0) ?? '';
        _costWeek.text = full.costPerWeek?.toStringAsFixed(0) ?? '';
        _costMonth.text = full.costPerMonth?.toStringAsFixed(0) ?? '';
        _costYear.text = full.costPerYear?.toStringAsFixed(0) ?? '';
        _minDays.text = full.minRentalDays?.toString() ?? '';
        _maxDays.text = full.maxRentalDays?.toString() ?? '';
        lat = full.latitude;
        lng = full.longitude;
        _rentalUnit = full.rentalUnit;
      } else if (_cats.isNotEmpty) {
        _categoryId = _cats.first.id;
      }
      setState(() => loading = false);
    } catch (e) {
      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  Future<void> _pickLocation() async {
    final p = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
          builder: (_) => MapPickerScreen(initial: LatLng(lat, lng))),
    );
    if (p != null) {
      setState(() {
        lat = p.latitude;
        lng = p.longitude;
      });
    }
  }

  // ── Image source bottom sheet ──
  void _showImageSourceSheet() {
    final s = S.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                s.t('form.addImages'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '${_newImages.length}/$_maxImages ${s.t('form.images')}',
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: s.isAr ? 'الكاميرا' : 'Camera',
                      onTap: () {
                        Navigator.pop(ctx);
                        _addImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.photo_library_rounded,
                      label: s.isAr ? 'المعرض' : 'Gallery',
                      onTap: () {
                        Navigator.pop(ctx);
                        _addMultiImages();
                      },
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

  Future<void> _addImage(ImageSource source) async {
    if (_newImages.length >= _maxImages) return;
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (file != null) {
      final sizeMB = await _fileSizeMB(file.path);
      if (sizeMB > _maxFileSizeMB) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.of(context).isAr
                    ? 'الصورة كبيرة جداً ($_maxFileSizeMB MB كحد أقصى)'
                    : 'Image too large (max $_maxFileSizeMB MB)',
              ),
              backgroundColor: EqColors.bad,
            ),
          );
        }
        return;
      }
      setState(() => _newImages.add(file));
    }
  }

  Future<void> _addMultiImages() async {
    if (_newImages.length >= _maxImages) return;
    final files = await _picker.pickMultiImage(
      imageQuality: 82,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (files.isNotEmpty) {
      final valid = <XFile>[];
      for (final f in files) {
        if (_newImages.length + valid.length >= _maxImages) break;
        final sizeMB = await _fileSizeMB(f.path);
        if (sizeMB <= _maxFileSizeMB) {
          valid.add(f);
        }
      }
      if (valid.isEmpty && files.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.of(context).isAr
                  ? 'الصور كبيرة جداً ($_maxFileSizeMB MB كحد أقصى)'
                  : 'Images too large (max $_maxFileSizeMB MB)',
            ),
            backgroundColor: EqColors.bad,
          ),
        );
      }
      setState(() => _newImages.addAll(valid));
    }
  }

  Future<double> _fileSizeMB(String path) async {
    final file = File(path);
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  double? _d(TextEditingController c) => double.tryParse(c.text.trim());
  int? _i(TextEditingController c) => int.tryParse(c.text.trim());

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_categoryId == null) return;
    if (!isEdit && _newImages.isEmpty) {
      setState(() => error = S.of(context).t('form.images'));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final hourCost = _d(_costHour);
      final dayCost = _d(_costDay);
      final weekCost = _d(_costWeek);
      final monthCost = _d(_costMonth);
      final yearCost = _d(_costYear);
      final primaryCost = _d(_priceController) ?? 0.0;

      final effectiveDayCost = _rentalUnit == 'day'
          ? (primaryCost > 0 ? primaryCost : 0.0)
          : (dayCost ?? primaryCost);

      if (isEdit) {
        await _svc.update(
          widget.existing!.id,
          title: _title.text,
          description: _description.text,
          categoryId: _categoryId!,
          locationAddress: _address.text,
          rentalUnit: _rentalUnit,
          costPerDay: effectiveDayCost,
          costPerHour: _rentalUnit == 'hour' ? primaryCost : hourCost,
          costPerWeek: _rentalUnit == 'week' ? primaryCost : weekCost,
          costPerMonth: _rentalUnit == 'month' ? primaryCost : monthCost,
          costPerYear: _rentalUnit == 'year' ? primaryCost : yearCost,
          minRentalDays: _i(_minDays),
          maxRentalDays: _i(_maxDays),
          latitude: lat,
          longitude: lng,
          imagePaths: _newImages.map((f) => f.path).toList(),
        );
      } else {
        await _svc.create(
          title: _title.text,
          description: _description.text,
          categoryId: _categoryId!,
          locationAddress: _address.text,
          rentalUnit: _rentalUnit,
          costPerDay: effectiveDayCost,
          costPerHour: _rentalUnit == 'hour' ? primaryCost : hourCost,
          costPerWeek: _rentalUnit == 'week' ? primaryCost : weekCost,
          costPerMonth: _rentalUnit == 'month' ? primaryCost : monthCost,
          costPerYear: _rentalUnit == 'year' ? primaryCost : yearCost,
          minRentalDays: _i(_minDays),
          maxRentalDays: _i(_maxDays),
          latitude: lat,
          longitude: lng,
          imagePaths: _newImages.map((f) => f.path).toList(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        error = '$e';
        busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cs = Theme.of(context).colorScheme;

    if (loading) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? s.t('common.edit') : s.t('mylistings.new')),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            // ── Title ──
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                labelText: s.t('form.title'),
                hintText: s.isAr ? 'مثال: كاميرا Canon EOS R5' : 'e.g. Canon EOS R5 Camera',
              ),
              validator: (v) => v == null || v.trim().length < 3
                  ? s.t('common.error')
                  : null,
              maxLength: 200,
            ),
            const SizedBox(height: 10),

            // ── Description ──
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: s.t('form.description'),
                alignLabelWithHint: true,
                hintText: s.isAr ? 'اكتب وصفاً تفصيلياً...' : 'Describe your item in detail...',
              ),
            ),
            const SizedBox(height: 10),

            // ── Category ──
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: InputDecoration(labelText: s.t('form.category')),
              items: [
                for (final c in _cats)
                  DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        s.isAr && c.nameAr != null ? c.nameAr! : c.name,
                      )),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? s.t('common.error') : null,
            ),
            const SizedBox(height: 10),

            // ── Address ──
            TextFormField(
              controller: _address,
              decoration: InputDecoration(
                labelText: s.t('form.address'),
                hintText: s.isAr ? 'مثال: عمّان، الحميدية' : 'e.g. Amman, Al-Hamidia',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? s.t('common.error') : null,
            ),
            const SizedBox(height: 10),

            // ── Location ──
            OutlinedButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(
                '${s.t('form.pickLocation')}: ${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}',
                textDirection: TextDirection.ltr,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),

            // ── Rental unit selector ──
            Text(s.t('browse.rentalUnit'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final u in ['hour', 'day', 'week', 'month', 'year'])
                  ChoiceChip(
                    label: Text(_unitLabel(s, u),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: _rentalUnit == u
                                ? FontWeight.w700
                                : FontWeight.w500)),
                    selected: _rentalUnit == u,
                    onSelected: (_) =>
                        setState(() => _rentalUnit = u),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Price ──
            _num(_priceController, _priceLabel(s), required: true),
            const SizedBox(height: 12),

            // ── Min / Max duration ──
            Row(children: [
              Expanded(
                  child: _num(_minDays,
                      s.t('browse.minDuration', {'unit': _unitSingular(s)}),
                      integer: true)),
              const SizedBox(width: 10),
              Expanded(
                  child: _num(_maxDays,
                      s.t('browse.maxDuration', {'unit': _unitSingular(s)}),
                      integer: true)),
            ]),

            const SizedBox(height: 24),

            // ── Images section ──
            Row(
              children: [
                Text(s.t('form.images'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${_newImages.length}/$_maxImages',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Image grid ──
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < _newImages.length; i++)
                  _ImageThumb(
                    file: File(_newImages[i].path),
                    index: i,
                    isMain: i == 0,
                    label: s.t('listings.mainImage'),
                    onRemove: () =>
                        setState(() => _newImages.removeAt(i)),
                  ),
                if (_newImages.length < _maxImages)
                  _AddPhotoButton(
                    onTap: _showImageSourceSheet,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(s.t('form.pendingNote'),
                style: TextStyle(
                    fontSize: 12.5, color: cs.outline)),

            if (error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EqColors.bad.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: EqColors.bad.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: EqColors.bad),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(error!,
                          style: const TextStyle(
                              color: EqColors.bad,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Submit ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: EqColors.accent,
                  foregroundColor: EqColors.accentText,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(
                        isEdit
                            ? s.t('form.updateSubmit')
                            : s.t('form.submit'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _num(TextEditingController c, String label,
      {bool required = false, bool integer = false}) {
    return TextFormField(
      controller: c,
      keyboardType:
          TextInputType.numberWithOptions(decimal: !integer),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (required &&
            (v == null || v.trim().isEmpty)) {
          return S.of(context).t('common.error');
        }
        if (v != null &&
            v.trim().isNotEmpty &&
            (integer ? int.tryParse(v) : double.tryParse(v)) ==
                null) {
          return S.of(context).t('common.error');
        }
        return null;
      },
    );
  }

  String _unitLabel(S s, String unit) {
    switch (unit) {
      case 'hour':
        return s.t('browse.unitHour');
      case 'day':
        return s.t('browse.unitDay');
      case 'week':
        return s.t('browse.unitWeek');
      case 'month':
        return s.t('browse.unitMonth');
      case 'year':
        return s.t('browse.unitYear');
      default:
        return unit;
    }
  }

  String _unitSingular(S s) {
    switch (_rentalUnit) {
      case 'hour':
        return s.t('browse.unitHourSingular');
      case 'day':
        return s.t('browse.unitDaySingular');
      case 'week':
        return s.t('browse.unitWeekSingular');
      case 'month':
        return s.t('browse.unitMonthSingular');
      case 'year':
        return s.t('browse.unitYearSingular');
      default:
        return s.t('browse.unitDaySingular');
    }
  }

  String _priceLabel(S s) {
    switch (_rentalUnit) {
      case 'hour':
        return '${s.t('form.priceHour')} (JOD)';
      case 'day':
        return '${s.t('form.priceDay')} (JOD)';
      case 'week':
        return '${s.t('form.priceWeek')} (JOD)';
      case 'month':
        return '${s.t('form.priceMonth')} (JOD)';
      case 'year':
        return '${s.t('form.priceYear')} (JOD)';
      default:
        return '${s.t('form.priceDay')} (JOD)';
    }
  }

  TextEditingController get _priceController {
    switch (_rentalUnit) {
      case 'hour':
        return _costHour;
      case 'week':
        return _costWeek;
      case 'month':
        return _costMonth;
      case 'year':
        return _costYear;
      default:
        return _costDay;
    }
  }
}

// ── Image thumbnail widget ──
class _ImageThumb extends StatelessWidget {
  const _ImageThumb({
    required this.file,
    required this.index,
    required this.isMain,
    required this.label,
    required this.onRemove,
  });

  final File file;
  final int index;
  final bool isMain;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: 100,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 100,
              height: 80,
              color: cs.surfaceContainerHighest,
              child: const Icon(Icons.broken_image, size: 24),
            ),
          ),
        ),
        if (isMain)
          PositionedDirectional(
            start: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: EqColors.accent,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        PositionedDirectional(
          end: 4,
          top: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: EqColors.bad,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
        PositionedDirectional(
          end: 4,
          bottom: 4,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Add photo button ──
class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 22, color: cs.outline),
            const SizedBox(height: 4),
            Text(
              S.of(context).isAr ? 'إضافة' : 'Add',
              style:
                  TextStyle(fontSize: 11, color: cs.outline),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Source option (Camera / Gallery) ──
class _SourceOption extends StatelessWidget {
  const _SourceOption({
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
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: EqColors.accent),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
