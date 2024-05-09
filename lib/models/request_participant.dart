import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/constants/user_type.dart';
import 'package:t2t_flutter_prototype/models/location.dart';
import 'package:t2t_flutter_prototype/models/user.dart';
import 'package:t2t_flutter_prototype/services/user_service.dart';

class RequestParticipant {
  late String userId;
  late String name;
  late String email;
  late String password;
  late UserType userType;
  late double latitude;
  late double longitude;
  late double heading;
  late Timestamp _locationTimestamp;

  RequestParticipant();

  RequestParticipant.withFirstoreMap(Map<String, dynamic> firestoreMap) {
    fromFirestoreMap(firestoreMap);
  }

  RequestParticipant.fromUser(User user) {
    userId = user.id;
    name = user.name;
    email = user.email;
    userType = user.type;
    // No iconId in RequestParticipant, otherwise we could extend User.
  }

  Location getLocation() {
    final location = new Location(latitude, longitude);
    return location;
  }

  void fromFirestoreMap(FirestoreMap firestoreMap) {
    userId = firestoreMap[userIdKey];
    name = firestoreMap[nameKey];
    email = firestoreMap[emailKey];

    final userType = firestoreMap[userTypeKey];
    final isTypeSet = userType != null;
    if (isTypeSet) {
      setUserTypeFromDbString(userType);
    }

    latitude = firestoreMap[latitudeKey];
    longitude = firestoreMap[longitudeKey];
    heading = double.parse(firestoreMap[headingKey].toString());
    _locationTimestamp = firestoreMap[locationTimestampKey];
  }

  FirestoreMap toFirestoreMap({ bool includeLocation = false, bool includeType = false }) {
    // TODO: Do I really want/need this lat/lon on the user record? Why would I keep track of this?
    FirestoreMap firestoreMap = {
      'userId': userId,
      'name': name,
      'email': email
    };

    if (includeLocation) {
      firestoreMap[latitudeKey] = latitude;
      firestoreMap[longitudeKey] = longitude;
      firestoreMap[headingKey] = heading;
      firestoreMap[locationTimestampKey] = _locationTimestamp;
    }
    if (includeType) {
      firestoreMap[typeKey] = UserService.getDbStringFromUserType(userType);
    }
    return firestoreMap;
  }

  void setUserTypeFromDbString(String dbString) {
    userType = UserService.getUserTypeFromDbString(dbString);
  }

  void updateLocation(double lat, double lon, double heading) {
    latitude = lat;
    longitude = lon;
    this.heading = heading;
    _locationTimestamp = Timestamp.now();
  }
}
