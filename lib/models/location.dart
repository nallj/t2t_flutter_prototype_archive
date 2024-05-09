import 'package:geolocator/geolocator.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';

class Location {
  late double latitude;
  late double longitude;

  Location(double lat, double lon) {
    latitude = lat;
    longitude = lon;
  }

  Location.withFirstoreMap(FirestoreMap firestoreMap) {
    latitude = firestoreMap['latitude'];
    longitude = firestoreMap['longitude'];
  }

  Map<String, dynamic> toFirestoreMap() {
    final firestoreMap = {
      'latitude': latitude,
      'longitude': longitude,
    };
    return firestoreMap;
  }

  Position toPosition() {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
