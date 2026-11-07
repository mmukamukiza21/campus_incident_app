import 'package:cloud_firestore/cloud_firestore.dart';
import 'incident_constants.dart';

class Incident {
  final String id, reporterId, title, description, location;
  final bool anonymous;
  final IncidentCategory category;
  final IncidentStatus status;
  final String? photoUrl, staffNote;
  final DateTime createdAt;

  const Incident({
    required this.id,
    required this.reporterId,
    required this.title,
    required this.description,
    required this.location,
    required this.anonymous,
    required this.category,
    required this.status,
    required this.createdAt,
    this.photoUrl,
    this.staffNote,
  });

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Incident(
      id: doc.id,
      reporterId: d['reporterId'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      location: d['location'] ?? '',
      anonymous: d['anonymous'] ?? false,
      category: IncidentCategory.fromName(d['category']),
      status: IncidentStatus.fromName(d['status']),
      photoUrl: d['photoUrl'],
      staffNote: d['staffNote'],
      // null briefly while the server timestamp is still pending
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get dateLabel {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} '
        '${two(createdAt.hour)}:${two(createdAt.minute)}';
  }
  Map<String, dynamic> toMap() {
  return {
    'id': id,
    'reporterId': reporterId,
    'title': title,
    'description': description,
    'location': location,
    'anonymous': anonymous,
    'category': category.name,
    'status': status.name,
    'photoUrl': photoUrl,
    'staffNote': staffNote,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
}