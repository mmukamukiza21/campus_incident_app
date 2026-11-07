
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/incident.dart';
import '../models/incident_constants.dart';
import '../services/cloudinary_service.dart';

class IncidentProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription? _sub;

  String? _uid;
  bool _isAdmin = false;
  bool _isResponder = false;

  List<Incident> _all = [];

  bool loading = false;
  String? error;

  String query = '';
  IncidentCategory? categoryFilter;
  IncidentStatus? statusFilter;

  void bind(
    String? uid, {
    required bool isAdmin,
    required bool isResponder,
  }) {
    if (uid == _uid &&
        isAdmin == _isAdmin &&
        isResponder == _isResponder) {
      return;
    }

    _uid = uid;
    _isAdmin = isAdmin;
    _isResponder = isResponder;

    _sub?.cancel();
    _all = [];
    error = null;

    if (uid == null) {
      loading = false;
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    Query<Map<String, dynamic>> q =
        _db.collection('incidents');

    if (_isResponder) {
      q = q.where('assignedTo', isEqualTo: uid);
    } else if (!_isAdmin) {
      q = q.where('reporterId', isEqualTo: uid);
    }

    _sub = q.snapshots().listen(
      (snapshot) {
        _all = snapshot.docs
            .map((doc) => Incident.fromDoc(doc))
            .toList();

        loading = false;
        error = null;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        loading = false;
        notifyListeners();
      },
    );
  }

  List<Incident> get incidents {
    final searchText = query.trim().toLowerCase();

    final result = _all.where((incident) {
      if (categoryFilter != null &&
          incident.category != categoryFilter) {
        return false;
      }

      if (statusFilter != null &&
          incident.status != statusFilter) {
        return false;
      }

      if (searchText.isEmpty) return true;

      return incident.title.toLowerCase().contains(searchText) ||
          incident.description.toLowerCase().contains(searchText) ||
          incident.location.toLowerCase().contains(searchText);
    }).toList();

    result.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return result;
  }

  Incident? byId(String id) {
    for (final incident in _all) {
      if (incident.id == id) return incident;
    }
    return null;
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setCategory(IncidentCategory? category) {
    categoryFilter = category;
    notifyListeners();
  }

  void setStatus(IncidentStatus? status) {
    statusFilter = status;
    notifyListeners();
  }

  Future<void> submitIncident({
    required String uid,
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    required bool anonymous,
    Uint8List? photoBytes,
  }) async {
    if (_uid != uid || _isAdmin || _isResponder) {
      throw Exception('Only a signed-in student can submit an incident.');
    }

    final doc = _db.collection('incidents').doc();

    String? photoUrl;

    if (photoBytes != null) {
      photoUrl = await CloudinaryService.uploadImage(photoBytes);
    }

    await doc.set({
      'id': doc.id,
      'reporterId': uid,
      'anonymous': anonymous,
      'title': title,
      'description': description,
      'category': category.name,
      'status': IncidentStatus.pending.name,
      'location': location,
      'photoUrl': photoUrl,
      'assignedTo': null,
      'assignedBy': null,
      'assignedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> assignIncident({
    required String incidentId,
    required String responderUid,
  }) async {
    if (_uid == null || !_isAdmin) {
      throw Exception('Only an admin can assign incidents.');
    }

    if (responderUid.trim().isEmpty) {
      throw Exception('Please select a responder.');
    }

    final responderDoc =
        await _db.collection('users').doc(responderUid).get();

    if (!responderDoc.exists) {
      throw Exception('The selected responder account does not exist.');
    }

    final role =
        responderDoc.data()?['role']?.toString().toLowerCase();

    if (role != 'responder' && role != 'staff') {
      throw Exception('You can only assign incidents to responders.');
    }

    await _db.collection('incidents').doc(incidentId).update({
      'assignedTo': responderUid,
      'assignedBy': _uid,
      'assignedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(
    String id,
    IncidentStatus status, {
    String? note,
  }) async {
    if (_uid == null || (!_isAdmin && !_isResponder)) {
      throw Exception('You are not allowed to update incident status.');
    }

    final docRef = _db.collection('incidents').doc(id);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('This incident could not be found.');
    }

    if (_isResponder && doc.data()?['assignedTo'] != _uid) {
      throw Exception('You can only update incidents assigned to you.');
    }

    await docRef.update({
      'status': status.name,
      'staffNote': (note == null || note.trim().isEmpty)
          ? null
          : note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
