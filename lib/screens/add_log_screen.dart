import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_log.dart';
import '../services/supabase_service.dart';
import 'paywall_screen.dart';

Future<Uint8List?> _compressImage(Uint8List bytes) async {
  img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  if (decoded.width > 1200 || decoded.height > 1200) {
    if (decoded.width > decoded.height) {
      decoded = img.copyResize(decoded, width: 1200);
    } else {
      decoded = img.copyResize(decoded, height: 1200);
    }
  }

  int quality = 80;
  Uint8List? compressed;
  while (quality > 10) {
    compressed = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
    if (compressed.lengthInBytes <= 250000) {
      break;
    }
    quality -= 10;
  }
  return compressed;
}

/// Full-screen form for creating or editing a daily training log.
///
/// Pass [initialLog] to open in **edit mode** — all fields will be
/// pre-populated and saving calls [SupabaseService.updateLog] instead
/// of [insertLog].
///
/// Falls back to local-only mode (with a snackbar notice) if not authenticated.
class AddLogScreen extends StatefulWidget {
  /// Called after a successful save — passes the created/updated [DailyLog].
  final ValueChanged<DailyLog>? onSaved;

  /// When non-null the form opens in edit mode pre-filled with this log.
  final DailyLog? initialLog;

  const AddLogScreen({super.key, this.onSaved, this.initialLog});

  @override
  State<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends State<AddLogScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _descCtrl   = TextEditingController();
  final _issuesCtrl = TextEditingController();

  DateTime _date           = DateTime.now();
  TaskType _taskType       = TaskType.fieldWork;
  String?  _imageUrl;
  bool     _isUploadingImage = false;
  bool     _isSaving       = false;

  /// True when the screen was opened with an existing log to edit.
  bool get _isEditing => widget.initialLog != null;

  @override
  void initState() {
    super.initState();
    final log = widget.initialLog;
    if (log != null) {
      _date           = log.date;
      _taskType       = log.taskType;
      _descCtrl.text  = log.description;
      _issuesCtrl.text = log.issuesFound;
      _imageUrl = log.imageUrl;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, String> _getQuickSuggestions(TaskType type) {
    switch (type) {
      case TaskType.fieldWork:
        return {
          'Concrete Pouring': 'Supervised concrete pouring for the slab, monitored slump test, and ensured proper vibration.',
          'Formwork Inspection': 'Inspected formwork installation, verified dimensions against approved shop drawings, and checked support stability.',
          'Rebar Check': 'Checked reinforcement steel placement, verified bar spacing, and ensured adequate concrete cover.',
          'Site Safety': 'Conducted a site safety tour, ensured PPE compliance among workers, and identified potential hazards.',
          'Material Inspection': 'Received and inspected delivered materials, checked quantities against POs, and verified quality.',
          'صب الخرسانة': 'الإشراف على صب الخرسانة، ومراقبة اختبار الهبوط، والتأكد من استخدام الهزاز بشكل صحيح.',
          'استلام حديد التسليح': 'تم استلام حديد التسليح والتأكد من الأقطار والمسافات حسب المخططات المعتمدة.',
        };
      case TaskType.officeWork:
        return {
          'Quantity Take-off': 'Performed detailed quantity take-off from architectural and structural drawings.',
          'Progress Meeting': 'Attended weekly progress meeting, reviewed project schedule, and discussed site issues.',
          'Drawing Review': 'Reviewed structural shop drawings for constructability and cross-referenced with architectural plans.',
          'Report Writing': 'Drafted the weekly progress report, highlighting completed milestones and upcoming tasks.',
          'Supplier Specs': 'Communicated with suppliers to request quotations, compare prices, and arrange delivery.',
          'حصر كميات': 'تم عمل حصر كميات تفصيلي للمواد المطلوبة بناءً على المخططات التنفيذية.',
          'مراجعة المخططات': 'مراجعة المخططات المعمارية والإنشائية والتأكد من عدم وجود تعارضات.',
        };
      case TaskType.software:
        return {
          'Revit Modeling': 'Developed 3D structural model in Revit, coordinated MEP clashes, and extracted schedules.',
          'SAP2000 Analysis': 'Modeled structural frame in SAP2000, applied loads, and analyzed deflection and shear forces.',
          'AutoCAD Editing': 'Drafted and revised 2D structural details in AutoCAD based on the engineer\'s markups.',
          'ETABS Design': 'Performed structural design and lateral load analysis for a multi-story building using ETABS.',
          'Primavera P6': 'Updated the project baseline schedule, adding new activities and adjusting logic ties.',
          'تصميم ETABS': 'عمل نموذج إنشائي على برنامج إيتابس وإدخال الأحمال وتحليل النتائج.',
          'رسم AutoCAD': 'رسم تفاصيل إنشائية وتعديل الملاحظات على المخططات باستخدام أوتوكاد.',
        };
    }
  }

  void _insertSuggestion(String text) {
    final current = _descCtrl.text;
    if (current.trim().isEmpty) {
      _descCtrl.text = text;
    } else {
      _descCtrl.text = '$current\n$text';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
            onPrimary: Theme.of(context).colorScheme.surface,
            surface: Theme.of(context).colorScheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickAndUploadImage() async {
    // 1. Trial Limit Check
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final createdAt = DateTime.tryParse(user.createdAt) ?? DateTime.now();
      final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
      final isPremium = user.userMetadata?['is_premium'] == true;

      if (daysSinceCreation <= 3 && !isPremium) {
        final uploadCount = await SupabaseService.instance.getImageUploadCount();
        if (uploadCount >= 3) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Trial Limit Reached', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text('You have reached the maximum of 3 image uploads on the free trial. Upgrade to Premium for unlimited image uploads.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                  },
                  child: const Text('Upgrade to Pro', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          return;
        }
      }
    }

    if (!mounted) return;
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: Theme.of(context).colorScheme.primary),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.primary),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: source);
    if (file == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final bytes = await file.readAsBytes();
      
      // Frontend compression to max 1200px and < 250KB
      final compressedBytes = await compute(_compressImage, bytes);
      if (compressedBytes == null) {
        _showSnackbar('Failed to compress image.', isError: true);
        return;
      }

      // Upload to ImgBB (serverless-safe: no local FS access)
      final url = await SupabaseService.instance.uploadImageToImgBB(compressedBytes);
      
      if (url != null) {
        setState(() => _imageUrl = url);
      } else {
        _showSnackbar('Failed to upload image.', isError: true);
      }
    } catch (e) {
      _showSnackbar('Error processing image: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final svc    = SupabaseService.instance;
    final userId = svc.currentUserId ?? '';
    final init   = widget.initialLog;

    final log = DailyLog(
      id:          init?.id ?? '',   // preserved for updates; empty for inserts
      userId:      init?.userId ?? userId,
      date:        _date,
      taskType:    _taskType,
      description: _descCtrl.text.trim(),
      issuesFound: _issuesCtrl.text.trim(),
      imageUrl:    _imageUrl,
    );

    try {
      if (userId.isNotEmpty) {
        if (_isEditing) {
          await svc.updateLog(log);
          _showSnackbar('Log updated ✓', isError: false);
        } else {
          await svc.insertLog(log);
          _showSnackbar('Log saved to Supabase ✓', isError: false);
        }
      } else {
        // Not signed in → local-only mode
        _showSnackbar('Saved locally — sign in to sync to the cloud.',
            isError: false);
      }

      widget.onSaved?.call(log);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackbar('Error saving log: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackbar(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _issuesCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width     = MediaQuery.of(context).size.width;
    final isDesktop = width >= 960;
    final formWidth = isDesktop ? 720.0 : double.infinity;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Theme.of(context).dividerColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Theme.of(context).colorScheme.onSurface,
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          _isEditing ? 'Edit Log' : 'New Daily Log',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).dividerColor),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: formWidth,
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 40 : 20,
                    24,
                    isDesktop ? 40 : 20,
                    120,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // ── Header banner ─────────────────────────────────
                      _HeaderBanner(),
                      const SizedBox(height: 24),

                      // ── Date picker ───────────────────────────────────
                      _SectionLabel(label: 'Date'),
                      const SizedBox(height: 8),
                      _DatePickerRow(
                        date: _date,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 24),

                      // ── Task type ─────────────────────────────────────
                      _SectionLabel(label: 'Task Type'),
                      const SizedBox(height: 10),
                      ...TaskType.values.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TaskTypeCard(
                            taskType: t,
                            selected: _taskType == t,
                            onTap: () => setState(() => _taskType = t),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Task description ──────────────────────────────
                      _SectionLabel(label: 'Task Description'),
                      const SizedBox(height: 8),
                      _StyledTextArea(
                        controller: _descCtrl,
                        hint:
                            'Describe what you did today — activities, '
                            'observations, materials used, people involved…',
                        minLines: 5,
                        prefixIcon: Icons.description_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Description cannot be empty'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _getQuickSuggestions(_taskType).entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ActionChip(
                                label: Text(e.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onPressed: () => _insertSuggestion(e.value),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Issues & solutions ────────────────────────────
                      _SectionLabel(label: 'Issues & Solutions'),
                      const SizedBox(height: 8),
                      _StyledTextArea(
                        controller: _issuesCtrl,
                        hint:
                            'Describe any problems encountered and how they '
                            'were resolved. Leave blank if none.',
                        minLines: 4,
                        prefixIcon: Icons.warning_amber_outlined,
                        accentColor: const Color(0xFFF57C00),
                        fillColor: const Color(0xFFFFFDE7),
                        borderColor: const Color(0xFFFFECB3),
                        focusBorderColor: const Color(0xFFF57C00),
                      ),
                      const SizedBox(height: 24),

                      // ── Image attachment ──────────────────────────────
                      _SectionLabel(label: 'Photo Attachment'),
                      const SizedBox(height: 8),
                      _ImageAttachmentZone(
                        imageUrl: _imageUrl,
                        isUploading: _isUploadingImage,
                        onToggle: _pickAndUploadImage,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'JPEG / PNG · max 10 MB · Uploaded securely via ImgBB.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // ── Sticky Save button ────────────────────────────────────────────────
      bottomNavigationBar: _SaveBar(
        isSaving: _isSaving,
        onSave:   _save,
        label:    _isEditing ? 'Update Log' : 'Save Log',
      ),
    );
  }
}

// ── Section widgets ───────────────────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFFE8F5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFB2EBF2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.edit_note_rounded,
                color: Theme.of(context).colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Training Log',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Document your internship activities for today.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerRow({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFD0ECF0), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.calendar_today_rounded,
                  size: 18, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d yyyy').format(date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Tap to change date',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Task type card ────────────────────────────────────────────────────────────

class _TaskTypeCard extends StatefulWidget {
  final TaskType taskType;
  final bool selected;
  final VoidCallback onTap;

  const _TaskTypeCard({
    required this.taskType,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_TaskTypeCard> createState() => _TaskTypeCardState();
}

class _TaskTypeCardState extends State<_TaskTypeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t        = widget.taskType;
    final selected = widget.selected;
    final bg = selected
        ? t.bgColor
        : _hovered
            ? const Color(0xFFF5FBFC)
            : Theme.of(context).colorScheme.surface;
    final borderColor = selected
        ? t.color.withValues(alpha: 0.5)
        : _hovered
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
            : const Color(0xFFE0ECF0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: t.color.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Icon circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? t.color.withValues(alpha: 0.15)
                      : const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(t.icon,
                    color: selected ? t.color : Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey, size: 20),
              ),
              const SizedBox(width: 14),
              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected ? t.color : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.example,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? t.color : Colors.transparent,
                  border: Border.all(
                    color: selected ? t.color : const Color(0xFFD0D8E0),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded,
                        size: 12, color: Theme.of(context).colorScheme.surface)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Styled text area ──────────────────────────────────────────────────────────

class _StyledTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final IconData prefixIcon;

  final Color? accentColor;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusBorderColor;
  final String? Function(String?)? validator;

  const _StyledTextArea({
    required this.controller,
    required this.hint,
    required this.minLines,
    required this.prefixIcon,

    this.accentColor,
    this.fillColor,
    this.borderColor,
    this.focusBorderColor,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final fill   = fillColor  ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
    final border = borderColor ?? const Color(0xFFD0ECF0);
    final focus  = focusBorderColor ?? Theme.of(context).colorScheme.primary;
    final icon   = accentColor ?? Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey;

    return TextFormField(
      controller: controller,
      validator: validator,
      minLines: minLines,
      maxLines: minLines + 4,
      style: TextStyle(
        fontSize: 13.5,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.55,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
          fontSize: 13,
          height: 1.55,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10, top: 14),
          child: Icon(prefixIcon, size: 18, color: icon),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

// ── Image attachment zone ─────────────────────────────────────────────────────

class _ImageAttachmentZone extends StatefulWidget {
  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onToggle;

  const _ImageAttachmentZone(
      {required this.imageUrl, required this.isUploading, required this.onToggle});

  @override
  State<_ImageAttachmentZone> createState() => _ImageAttachmentZoneState();
}

class _ImageAttachmentZoneState extends State<_ImageAttachmentZone> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isUploading ? null : widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: widget.imageUrl != null ? 220 : 160,
          decoration: BoxDecoration(
            color: widget.imageUrl != null
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : _hovered
                    ? const Color(0xFFF0FAFB)
                    : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.imageUrl != null
                  ? Theme.of(context).colorScheme.primary
                  : _hovered
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                      : const Color(0xFFCCE5EA),
              width: widget.imageUrl != null ? 1.5 : 1,
            ),
          ),
          child: widget.isUploading
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(color: Theme.of(context).colorScheme.primary, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                      SizedBox(height: 16),
                      Text('Compressing and uploading...',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : widget.imageUrl != null
                  ? _AttachedPreview(imageUrl: widget.imageUrl!)
                  : _UploadPrompt(hovered: _hovered),
        ),
      ),
    );
  }
}

class _UploadPrompt extends StatelessWidget {
  final bool hovered;
  const _UploadPrompt({required this.hovered});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hovered
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : const Color(0xFFF0F4F8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_upload_outlined,
            size: 28,
            color:
                hovered ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tap to attach a photo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hovered ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'JPEG · PNG · max 10 MB',
          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
        ),
      ],
    );
  }
}

class _AttachedPreview extends StatelessWidget {
  final String imageUrl;
  const _AttachedPreview({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Actual image thumbnail via network URL ──────────────────────
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2.5,
                ),
              );
            },
            errorBuilder: (ctx, error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined,
                      size: 32,
                      color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
                  const SizedBox(height: 6),
                  Text('Could not load preview',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey)),
                ],
              ),
            ),
          ),
          // ── Overlay footer strip ────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                  const Text(
                    'Photo uploaded  ·  Tap to replace',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sticky save bar ───────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;
  final String label;

  const _SaveBar({
    required this.isSaving,
    required this.onSave,
    this.label = 'Save Log',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isSaving ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.surface,
            disabledBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.surface,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}