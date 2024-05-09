import 'package:geolocator/geolocator.dart';

class Destination {
  late String state;
  late String city;
  late String zip;
  late String street;
  late double latitude;
  late double longitude;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'street': street,
      'city': city,
      'zip': zip,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
    };
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

  Destination();

  Destination.withFirstoreMap(Map<String, dynamic> firestoreMap) {
    this.city = firestoreMap['city'];
    this.latitude = firestoreMap['latitude'];
    this.longitude = firestoreMap['longitude'];
    this.state = firestoreMap['state'];
    this.street = firestoreMap['street'];
    this.zip = firestoreMap['zip'];
  }
}
