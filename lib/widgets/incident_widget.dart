import 'package:flutter/material.dart';
import '../models/incident.dart';
import '../models/incident_constants.dart';

class StatusChip extends StatelessWidget {
  final IncidentStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            color: status.color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback onTap;
  const IncidentCard({super.key, required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Icon(incident.category.icon)),
        title: Text(incident.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${incident.location}\n${incident.dateLabel}'),
        isThreeLine: true,
        trailing: StatusChip(incident.status),
      ),
    );
  }
}