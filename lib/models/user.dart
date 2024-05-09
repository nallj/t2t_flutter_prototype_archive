import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/constants/user_type.dart';
import 'package:t2t_flutter_prototype/services/user_service.dart';

class User {
  late String email;
  late String name;
  late UserType type;
  late String id;

  // Provider only
  String? businessId;
  String? iconId;
  String? assignedFleetVehicleId;

  User(this.id, this.email, this.name, this.type);

  User.withFirstoreMap(FirestoreMap firestoreMap) {
    fromFirestoreMap(firestoreMap);
  }

  void fromFirestoreMap(FirestoreMap map) {
    id = map[userIdKey];
    email = map[emailKey];
    name = map[nameKey];
    type = UserService.getUserTypeFromDbString(map[userTypeKey]);

    _setBusinessIdIfInMap(map);
    _setIconIdIfInMap(map);
    _setAssignedFleetVehicleIdIfInMap(map);
  }

  bool isProviderUser() => businessId != null;

  FirestoreMap toFirestoreMap() {
    FirestoreMap firestoreMap = {
      'userId': id,
      'email': email,
      'name': name,
      'status': UserService.getDbStringFromUserType(type),
    };

    firestoreMap = _addNullablesToMap(firestoreMap);
    return firestoreMap;
  }

  void _setAssignedFleetVehicleIdIfInMap(FirestoreMap map) {
    final assignedFleetVehicleId = map[assignedFleetVehicleIdKey];
    final assignedFleetVehicleIdProvided = assignedFleetVehicleId != null;
    if (assignedFleetVehicleIdProvided) {
      this.assignedFleetVehicleId = assignedFleetVehicleId;
    }
  }

  void _setBusinessIdIfInMap(FirestoreMap map) {
    final businessId = map[businessIdKey];
    final businessIdProvided = businessId != null;
    if (businessIdProvided) {
      this.businessId = businessId;
    }
  }

  void _setIconIdIfInMap(FirestoreMap map) {
    final iconId = map[iconIdKey];
    final iconIdProvided = iconId != null;
    if (iconIdProvided) {
      this.iconId = iconId;
    }
  }

  FirestoreMap _addNullablesToMap(FirestoreMap map) {
    final businessIdProvided = businessId != null;
    if (businessIdProvided) {
      map[businessIdKey] = businessId!;
    }

    final iconIdProvided = iconId != null;
    if (iconIdProvided) {
      map[iconIdKey] = iconId!;
    }

    final assignedFleetVehicleIdProvided = assignedFleetVehicleId != null;
    if (assignedFleetVehicleIdProvided) {
      map[assignedFleetVehicleIdKey] = assignedFleetVehicleId!;
    }

    return map;
  }
}