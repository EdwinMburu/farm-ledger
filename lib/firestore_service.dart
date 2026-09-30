import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No farmer is currently logged in.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _collection(String name) {
    return _db.collection('users').doc(uid).collection(name);
  }

  Future<void> saveCow({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    await _collection('cattle').doc(id.toString()).set({
      ...data,
      'id': id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'updatedBy': uid,
    });
  }

  Future<void> updateCow({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    await _collection('cattle').doc(id.toString()).set({
      ...data,
      'id': id,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'updatedBy': uid,
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> loadCows() async {
    final snapshot = await _collection('cattle').get();

    return snapshot.docs.map((doc) {
      return doc.data();
    }).toList();
  }

  Future<void> saveFeed({required String month, required double cost}) async {
    await _collection('feeds').add({'month': month, 'cost': cost});
  }

  Future<List<Map<String, dynamic>>> loadFeeds() async {
    final snapshot = await _collection('feeds').get();

    return snapshot.docs.map((doc) {
      return doc.data();
    }).toList();
  }

  Future<void> saveMilkPrice({
    required String monthKey,
    required int month,
    required int year,
    required double pricePerLiter,
  }) async {
    await _collection('milkPrices').doc(monthKey).set({
      'monthKey': monthKey,
      'month': month,
      'year': year,
      'pricePerLiter': pricePerLiter,
      'unitValue': pricePerLiter,
      'currency': 'KES',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'updatedBy': uid,
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> loadMilkPrices() async {
    final snapshot = await _collection('milkPrices').get();

    return snapshot.docs.map((doc) {
      return doc.data();
    }).toList();
  }

  Future<String> saveProduction({
    required int cowId,
    required String cowName,
    required String date,
    required int year,
    required int month,
    required int day,
    required String session,
    required double liters,
    required double pricePerLiter,
    String notes = '',
  }) async {
    final reference = await _collection('production').add({
      'cowId': cowId,
      'cowName': cowName,
      'date': date,
      'year': year,
      'month': month,
      'day': day,
      'session': session,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'unitValue': pricePerLiter,
      'totalValue': liters * pricePerLiter,
      'value': liters * pricePerLiter,
      'notes': notes,
      'recordedBy': uid,
      'recordedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return reference.id;
  }

  Future<void> updateProduction({
    required String id,
    required int cowId,
    required String cowName,
    required String date,
    required int year,
    required int month,
    required int day,
    required String session,
    required double liters,
    required double pricePerLiter,
    String notes = '',
  }) async {
    await _collection('production').doc(id).update({
      'cowId': cowId,
      'cowName': cowName,
      'date': date,
      'year': year,
      'month': month,
      'day': day,
      'session': session,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'unitValue': pricePerLiter,
      'totalValue': liters * pricePerLiter,
      'value': liters * pricePerLiter,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduction(String id) async {
    await _collection('production').doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> loadProduction() async {
    final snapshot = await _collection('production').get();

    return snapshot.docs.map((doc) {
      return {...doc.data(), '_documentId': doc.id};
    }).toList();
  }

  Future<void> saveExpense({
    required int cowId,
    required String date,
    required String description,
    required double amount,
  }) async {
    await _collection('expenses').add({
      'cowId': cowId,
      'date': date,
      'description': description,
      'amount': amount,
    });
  }

  Future<List<Map<String, dynamic>>> loadExpenses() async {
    final snapshot = await _collection('expenses').get();

    return snapshot.docs.map((doc) {
      return doc.data();
    }).toList();
  }

  Future<void> deleteCow(int id) async {
    await _collection('cattle').doc(id.toString()).delete();
  }

  CollectionReference<Map<String, dynamic>> _cattleSubcollection(
    int cattleId,
    String name,
  ) {
    return _collection('cattle').doc(cattleId.toString()).collection(name);
  }

  Future<String> saveCattleEvent({
    required int cattleId,
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final reference = await _cattleSubcollection(cattleId, collection).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    });
    return reference.id;
  }

  Future<List<Map<String, dynamic>>> loadCattleEvents({
    required int cattleId,
    required String collection,
  }) async {
    final snapshot = await _cattleSubcollection(cattleId, collection).get();
    return snapshot.docs
        .map((doc) => {...doc.data(), '_documentId': doc.id})
        .toList();
  }

  Future<void> updateCattleEvent({
    required int cattleId,
    required String collection,
    required String eventId,
    required Map<String, dynamic> data,
  }) async {
    await _cattleSubcollection(cattleId, collection).doc(eventId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    });
  }

  Future<void> deleteCattleEvent({
    required int cattleId,
    required String collection,
    required String eventId,
  }) async {
    await _cattleSubcollection(cattleId, collection).doc(eventId).delete();
  }

  Future<Map<String, dynamic>?> loadDashboardNotification(
    String monthKey,
  ) async {
    final snapshot = await _collection('dashboardNotifications')
        .doc(monthKey)
        .get();
    return snapshot.data();
  }

  Future<void> saveDashboardNotification({
    required String monthKey,
    required bool calvingReminderShown,
    required bool dismissed,
  }) async {
    await _collection('dashboardNotifications').doc(monthKey).set({
      'monthKey': monthKey,
      'calvingReminderShown': calvingReminderShown,
      'dismissed': dismissed,
      'dismissedAt': dismissed ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    }, SetOptions(merge: true));
  }
}
