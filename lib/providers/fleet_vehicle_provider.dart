import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';

const _COLLECTION_KEY = COLLECTION_FLEET_VEHICLE;

class FleetVehicleProvider {

  static Future<FirestoreMap> getOrThrow(String id) async {
    final snapshot = await FirebaseFirestore
      .instance
      .collection(_COLLECTION_KEY)
      .doc(id)
      .get();
    final fleetVehicleData = snapshot.data();
    final noFleetVehicleData = fleetVehicleData == null;
    if (noFleetVehicleData) {
      throw Exception('No fleet vehicle data found for this ID.');
    }
    return fleetVehicleData!;
  }
}
