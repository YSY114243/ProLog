import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge.dart';
import '../services/supabase_service.dart';
import '../services/speech_service.dart';

/// Full-screen tab for viewing, adding, editing, and deleting challenges.
class ChallengesTab extends StatefulWidget {
  final bool isMobile;
  final bool isDesktop;

  const ChallengesTab({
    super.key,
    required this.isMobile,
    required this.isDesktop,
  });

  @override
  State<ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<ChallengesTab> {
  List<Challenge> _challenges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    try {
      final data = await SupabaseService.instance.fetchChallenges();
      if (mounted) setState(() { _challenges = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openChallengeDialog({Challenge? existing}) async {
    final result = await showDialog<Challenge>(
      context: context,
      builder: (ctx) => _ChallengeFormDialog(existing: existing),
    );

    if (result == null) return;

    try {
      if (existing != null) {
        // Update
        final updated = result.copyWith(id: existing.id);
        await SupabaseService.instance.updateChallenge(updated);
        if (mounted) {
          setState(() {
            final idx = _challenges.indexWhere((c) => c.id == existing.id);
            if (idx != -1) _challenges[idx] = updated;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Challenge updated.')),
          );
        }
      } else {
        // Insert
        await SupabaseService.instance.insertChallenge(result);
        await _loadChallenges(); // Reload to get the DB-generated ID

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('draft_chal_prob');
        await prefs.remove('draft_chal_res');
        await prefs.remove('draft_chal_les');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Challenge logged!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteChallenge(Challenge challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Challenge', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to delete this challenge? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (challenge.id.isNotEmpty) {
        await SupabaseService.instance.deleteChallenge(challenge.id);
      }
      if (mounted) {
        setState(() => _challenges.removeWhere((c) => c.id == challenge.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Challenge deleted.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = widget.isDesktop ? 32.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Challenges & Learnings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Document problems you encountered and how you resolved them.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _openChallengeDialog(),
                icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                label: const Text('Log Challenge', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Content ─────────────────────────────────────────────────
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_challenges.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
                child: Column(
                  children: [
                    Icon(Icons.shield_rounded, size: 64, color: Theme.of(context).dividerColor),
                    const SizedBox(height: 16),
                    Text(
                      'No challenges logged yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Log Challenge" to record your first problem & solution.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _challenges.length,
              itemBuilder: (context, i) => _ChallengeCard(
                challenge: _challenges[i],
                onEdit: () => _openChallengeDialog(existing: _challenges[i]),
                onDelete: () => _deleteChallenge(_challenges[i]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Challenge Card ──────────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChallengeCard({
    required this.challenge,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(challenge.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: date + actions ──────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
                child: Icon(Icons.more_vert_rounded, size: 20, color: Theme.of(context).textTheme.labelSmall?.color),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Problem ─────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Problem',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.problem,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Resolution ──────────────────────────────────────────────
          if (challenge.resolution.trim().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check_circle_rounded, size: 18, color: Colors.green.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resolution',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.resolution,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // ── Lessons Learned ──────────────────────────────────────────────
          if (challenge.lessonsLearned.trim().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lightbulb_outline_rounded, size: 18, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lessons Learned',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.lessonsLearned,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Challenge Form Dialog ───────────────────────────────────────────────────────

class _ChallengeFormDialog extends StatefulWidget {
  final Challenge? existing;
  const _ChallengeFormDialog({this.existing});

  @override
  State<_ChallengeFormDialog> createState() => _ChallengeFormDialogState();
}

class _ChallengeFormDialogState extends State<_ChallengeFormDialog> {
  late DateTime _date;
  late TextEditingController _problemCtrl;
  late TextEditingController _resolutionCtrl;
  late TextEditingController _lessonsCtrl;
  final _formKey = GlobalKey<FormState>();

  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.date ?? DateTime.now();
    _problemCtrl = TextEditingController(text: widget.existing?.problem ?? '');
    _resolutionCtrl = TextEditingController(text: widget.existing?.resolution ?? '');
    _lessonsCtrl = TextEditingController(text: widget.existing?.lessonsLearned ?? '');
    
    if (widget.existing == null) {
      _loadDrafts();
    }

    _problemCtrl.addListener(_saveDraft);
    _resolutionCtrl.addListener(_saveDraft);
    _lessonsCtrl.addListener(_saveDraft);

    _initSpeech();
  }

  Future<void> _loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString('draft_chal_prob');
    final r = prefs.getString('draft_chal_res');
    final l = prefs.getString('draft_chal_les');

    if ((p != null && p.isNotEmpty) || (r != null && r.isNotEmpty) || (l != null && l.isNotEmpty)) {
      if (mounted) {
        setState(() {
          if (p != null) _problemCtrl.text = p;
          if (r != null) _resolutionCtrl.text = r;
          if (l != null) _lessonsCtrl.text = l;
          _hasDraft = true;
        });
      }
    }
  }

  Future<void> _saveDraft() async {
    if (widget.existing != null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_chal_prob', _problemCtrl.text);
    await prefs.setString('draft_chal_res', _resolutionCtrl.text);
    await prefs.setString('draft_chal_les', _lessonsCtrl.text);

    final hasText = _problemCtrl.text.isNotEmpty || _resolutionCtrl.text.isNotEmpty || _lessonsCtrl.text.isNotEmpty;
    if (!_hasDraft && hasText) {
      if (mounted) setState(() => _hasDraft = true);
    } else if (_hasDraft && !hasText) {
      if (mounted) setState(() => _hasDraft = false);
    }
  }

  // ── Voice-to-text ──────────────────────────────────────────────────────────
  bool _speechAvailable = false;
  TextEditingController? _activeVoiceCtrl;
  String _voiceBuffer = '';

  Future<void> _initSpeech() async {
    _speechAvailable = await SpeechService.instance.initialize();
    if (mounted) setState(() {});
  }

  void _toggleVoice(TextEditingController ctrl) {
    if (SpeechService.instance.isListening) {
      SpeechService.instance.stopListening();
      setState(() => _activeVoiceCtrl = null);
      return;
    }
    _voiceBuffer = ctrl.text;
    setState(() => _activeVoiceCtrl = ctrl);
    SpeechService.instance.startListening(
      onResult: (words) {
        if (mounted) {
          setState(() {
            ctrl.text = _voiceBuffer.isEmpty
                ? words
                : '$_voiceBuffer $words';
            ctrl.selection = TextSelection.fromPosition(
              TextPosition(offset: ctrl.text.length),
            );
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _problemCtrl.dispose();
    _resolutionCtrl.dispose();
    _lessonsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    final challenge = Challenge(
      id: '',
      userId: userId,
      date: _date,
      problem: _problemCtrl.text.trim(),
      resolution: _resolutionCtrl.text.trim(),
      lessonsLearned: _lessonsCtrl.text.trim(),
    );

    Navigator.pop(context, challenge);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final dateStr = DateFormat('MMM dd, yyyy').format(_date);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──────────────────────────────────────────────
                  Text(
                    isEditing ? 'Edit Challenge' : 'Log a Challenge',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Document a problem you faced and how you solved it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Date Picker ────────────────────────────────────────
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down_rounded, color: Theme.of(context).textTheme.labelSmall?.color),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Problem ────────────────────────────────────────────
                  Text(
                    'Problem Description',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _problemCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe the problem or challenge you encountered...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: _speechAvailable
                          ? IconButton(
                              icon: Icon(
                                _activeVoiceCtrl == _problemCtrl && SpeechService.instance.isListening
                                    ? Icons.mic_rounded
                                    : Icons.mic_none_rounded,
                                size: 20,
                                color: _activeVoiceCtrl == _problemCtrl && SpeechService.instance.isListening
                                    ? Colors.redAccent
                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                              ),
                              tooltip: _activeVoiceCtrl == _problemCtrl && SpeechService.instance.isListening
                                  ? 'Stop listening'
                                  : 'Voice input',
                              onPressed: () => _toggleVoice(_problemCtrl),
                            )
                          : null,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe the problem' : null,
                  ),
                  const SizedBox(height: 24),

                  // ── Resolution ─────────────────────────────────────────
                  Text(
                    'Resolution / Action Taken',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _resolutionCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'How did you resolve it? What actions were taken?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: _speechAvailable
                          ? IconButton(
                              icon: Icon(
                                _activeVoiceCtrl == _resolutionCtrl && SpeechService.instance.isListening
                                    ? Icons.mic_rounded
                                    : Icons.mic_none_rounded,
                                size: 20,
                                color: _activeVoiceCtrl == _resolutionCtrl && SpeechService.instance.isListening
                                    ? Colors.redAccent
                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                              ),
                              tooltip: _activeVoiceCtrl == _resolutionCtrl && SpeechService.instance.isListening
                                  ? 'Stop listening'
                                  : 'Voice input',
                              onPressed: () => _toggleVoice(_resolutionCtrl),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Lessons Learned ─────────────────────────────────────────
                  Text(
                    'Lessons Learned / What I Learned Today',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _lessonsCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'What did you learn from this? What are your key takeaways?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: _speechAvailable
                          ? IconButton(
                              icon: Icon(
                                _activeVoiceCtrl == _lessonsCtrl && SpeechService.instance.isListening
                                    ? Icons.mic_rounded
                                    : Icons.mic_none_rounded,
                                size: 20,
                                color: _activeVoiceCtrl == _lessonsCtrl && SpeechService.instance.isListening
                                    ? Colors.redAccent
                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                              ),
                              tooltip: _activeVoiceCtrl == _lessonsCtrl && SpeechService.instance.isListening
                                  ? 'Stop listening'
                                  : 'Voice input',
                              onPressed: () => _toggleVoice(_lessonsCtrl),
                            )
                          : null,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please add your lessons learned' : null,
                  ),
                  const SizedBox(height: 32),

                  // ── Actions ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _submit,
                        icon: Icon(
                          isEditing ? Icons.save_rounded : Icons.add_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        label: Text(
                          isEditing ? 'Save Changes' : 'Log Challenge',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                  if (_hasDraft) ...[
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Draft saved locally',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
