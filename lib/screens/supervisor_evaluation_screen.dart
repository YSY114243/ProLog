import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SupervisorEvaluationScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const SupervisorEvaluationScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<SupervisorEvaluationScreen> createState() => _SupervisorEvaluationScreenState();
}

class _SupervisorEvaluationScreenState extends State<SupervisorEvaluationScreen> {
  // ABET Criteria Scores (1 to 5)
  double enthusiasm = 3;
  double deliveringAccurateWork = 3;
  double dealingWithNewSystems = 3;
  double initiative = 3;
  double dependability = 3;
  double learningAndSearching = 3;
  double judgmentAndDecisionMaking = 3;
  double effectiveRelations = 3;
  double reportingAndPresenting = 3;
  double attendanceAndPunctuality = 3;

  bool _isSubmitting = false;

  int get totalScore {
    return (enthusiasm +
            deliveringAccurateWork +
            dealingWithNewSystems +
            initiative +
            dependability +
            learningAndSearching +
            judgmentAndDecisionMaking +
            effectiveRelations +
            reportingAndPresenting +
            attendanceAndPunctuality)
        .toInt();
  }

  Future<void> _submitEvaluation() async {
    setState(() => _isSubmitting = true);
    try {
      final supervisorId = SupabaseService.instance.currentUserId;
      if (supervisorId == null) {
        throw Exception('Supervisor not logged in');
      }

      final evaluationData = {
        'student_id': widget.studentId,
        'supervisor_id': supervisorId,
        'enthusiasm': enthusiasm.toInt(),
        'delivering_accurate_work': deliveringAccurateWork.toInt(),
        'dealing_with_new_systems': dealingWithNewSystems.toInt(),
        'initiative': initiative.toInt(),
        'dependability': dependability.toInt(),
        'learning_and_searching': learningAndSearching.toInt(),
        'judgment_and_decision_making': judgmentAndDecisionMaking.toInt(),
        'effective_relations': effectiveRelations.toInt(),
        'reporting_and_presenting': reportingAndPresenting.toInt(),
        'attendance_and_punctuality': attendanceAndPunctuality.toInt(),
        'total_score': totalScore,
      };

      await SupabaseService.instance.submitSupervisorEvaluation(evaluationData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evaluation submitted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting evaluation: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildCriterionSlider(String title, String abetTag, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: ' ($abetTag)',
                        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toInt().toString(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TA-FORM 03: ${widget.studentName}'),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please evaluate the trainee on a scale of 1 to 5 (1 = Poor, 5 = Excellent). This evaluation is strictly confidential.',
                            style: TextStyle(color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildCriterionSlider('Enthusiasm', 'ABET 4', enthusiasm, (val) => setState(() => enthusiasm = val)),
                  _buildCriterionSlider('Delivering accurate work', 'ABET 4', deliveringAccurateWork, (val) => setState(() => deliveringAccurateWork = val)),
                  _buildCriterionSlider('Dealing with new systems', 'ABET 7', dealingWithNewSystems, (val) => setState(() => dealingWithNewSystems = val)),
                  _buildCriterionSlider('Initiative', 'ABET 5', initiative, (val) => setState(() => initiative = val)),
                  _buildCriterionSlider('Dependability', 'ABET 4', dependability, (val) => setState(() => dependability = val)),
                  _buildCriterionSlider('Learning and searching', 'ABET 7', learningAndSearching, (val) => setState(() => learningAndSearching = val)),
                  _buildCriterionSlider('Judgment and decision making', 'ABET 4', judgmentAndDecisionMaking, (val) => setState(() => judgmentAndDecisionMaking = val)),
                  _buildCriterionSlider('Effective relations', 'ABET 5', effectiveRelations, (val) => setState(() => effectiveRelations = val)),
                  _buildCriterionSlider('Reporting and presenting', 'ABET 3', reportingAndPresenting, (val) => setState(() => reportingAndPresenting = val)),
                  _buildCriterionSlider('Attendance and punctuality', 'ABET 4', attendanceAndPunctuality, (val) => setState(() => attendanceAndPunctuality = val)),
                  
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Score:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$totalScore / 50',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _submitEvaluation,
                    icon: const Icon(Icons.security, color: Colors.white),
                    label: const Text(
                      'Submit Confidential Evaluation',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
