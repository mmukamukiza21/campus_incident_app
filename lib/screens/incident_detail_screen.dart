import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/incident_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/incident_widget.dart';

class IncidentDetailScreen extends StatefulWidget {
  final String incidentId;
  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final _note = TextEditingController();
  IncidentStatus? _status;
  bool _init = false;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await context.read<IncidentProvider>().updateStatus(
            widget.incidentId,
            _status!,
            note: _note.text,
          );
      messenger.showSnackBar(const SnackBar(content: Text('Status updated')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inc = context.watch<IncidentProvider>().byId(widget.incidentId);
    final auth = context.watch<AuthProvider>();
    final canUpdate = auth.isStaff || auth.isAdmin || auth.isResponder;

    if (inc == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Report not found')),
      );
    }
    if (!_init) {
      _status = inc.status;
      _note.text = inc.staffNote ?? '';
      _init = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      bottomNavigationBar: canUpdate
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                  onPressed: _saving ? null : _save,
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (inc.photoUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                inc.photoUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator())),
                errorBuilder: (_, _, _) => const SizedBox(
                    height: 100,
                    child: Center(child: Text('Photo could not be loaded'))),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(inc.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(children: [
            StatusChip(inc.status),
            const SizedBox(width: 10),
            Icon(inc.category.icon, size: 18),
            const SizedBox(width: 4),
            Text(inc.category.label),
          ]),
          const SizedBox(height: 16),
          _ProgressTracker(inc.status),
          const SizedBox(height: 16),
          _info(Icons.place_outlined, 'Location', inc.location),
          _info(Icons.schedule, 'Reported', inc.dateLabel),
          _info(Icons.person_outline, 'Reported by',
              inc.anonymous ? 'Anonymous' : 'Student'),
          const SizedBox(height: 8),
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(inc.description),
          if (inc.staffNote != null && !canUpdate) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('Message from staff'),
                subtitle: Text(inc.staffNote!),
              ),
            ),
          ],
          if (canUpdate) ...[
            const Divider(height: 32),
            Text('Update status',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<IncidentStatus>(
              initialValue: _status,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: IncidentStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (s) => setState(() => _status = s),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note to student (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ]),
      );
}

class _ProgressTracker extends StatelessWidget {
  final IncidentStatus status;
  const _ProgressTracker(this.status);

  @override
  Widget build(BuildContext context) {
    if (status == IncidentStatus.rejected) {
      return Row(children: const [
        Icon(Icons.cancel, color: Colors.red),
        SizedBox(width: 8),
        Text('This report was rejected'),
      ]);
    }
    const steps = ['Submitted', 'In Review', 'Resolved'];
    final current = switch (status) {
      IncidentStatus.pending => 0,
      IncidentStatus.inReview => 1,
      _ => 2,
    };
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(children: [
              Icon(
                i <= current ? Icons.check_circle : Icons.radio_button_unchecked,
                color: i <= current ? status.color : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(steps[i], style: const TextStyle(fontSize: 12)),
            ]),
          ),
      ],
    );
  }
}