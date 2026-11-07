import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident.dart';

class IncidentService {
  final _col = FirebaseFirestore.instance.collection('incidents');

  Stream<List<Incident>> streamAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Incident.fromDoc).toList());

  Stream<List<Incident>> streamByUser(String uid) => _col
      .where('reporterId', isEqualTo: uid)
      .snapshots()
      .map((s) {
        final list = s.docs.map(Incident.fromDoc).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  Future<void> create(Incident incident) => _col.add(incident.toMap());

  Future<void> updateStatus(String id, String status) => _col.doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateDetails(
    String id, {
    required String title,
    required String description,
    required String category,
    required String location,
  }) =>
      _col.doc(id).update({
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(String id) => _col.doc(id).delete();
}
