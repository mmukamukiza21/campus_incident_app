import 'package:flutter/material.dart';

enum IncidentCategory {
  facility('Broken Facility', Icons.build_outlined),
  water('Water Shortage', Icons.water_drop_outlined),
  electricity('Electricity Outage', Icons.bolt_outlined),
  furniture('Damaged Furniture', Icons.chair_outlined),
  sanitation('Sanitation', Icons.cleaning_services_outlined),
  safety('Safety Concern', Icons.shield_outlined),
  other('Other', Icons.more_horiz);

  final String label;
  final IconData icon;
  const IncidentCategory(this.label, this.icon);

  static IncidentCategory fromName(String? name) =>
      IncidentCategory.values.firstWhere(
        (c) => c.name == name,
        orElse: () => IncidentCategory.other,
      );
}

enum IncidentStatus {
  pending('Pending', Colors.orange),
  inReview('In Review', Colors.blue),
  resolved('Resolved', Colors.green),
  rejected('Rejected', Colors.red);

  final String label;
  final Color color;
  const IncidentStatus(this.label, this.color);

  static IncidentStatus fromName(String? name) =>
      IncidentStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => IncidentStatus.pending,
      );
}