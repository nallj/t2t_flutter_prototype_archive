import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/constants/fleet_vehicle_type.dart';
import 'package:t2t_flutter_prototype/services/fleet_vehicle_service.dart';

class FleetVehicle {
  late String id;
  late String fleetId;
  late String color;
  late String make;
  late String model;
  late FleetVehicleType type;
  late String iconId;
  String? name;

  FleetVehicle(
    this.id,
    this.fleetId,
    this.make,
    this.model,
    this.color,
    this.type,
    this.iconId
  );

  FleetVehicle.withFirstoreMap(FirestoreMap firestoreMap) {
    fromFirestoreMap(firestoreMap);
  }

  void fromFirestoreMap(FirestoreMap map) {
    id = map[idKey];
    fleetId = map[fleetIdKey];
    color = map[colorKey];
    make = map[makeKey];
    model = map[modelKey];
    type = FleetVehicleService.getTypeFromDbString(map[typeKey]);
    iconId = map[iconIdKey];

    final isNameSet = map.containsKey(nameKey);
    if (isNameSet) {
      name = map[nameKey];
    }
  }

  FirestoreMap toFirestoreMap() {
    final firestoreMap = {
      'id': id,
      'fleetId': fleetId,
      'color': color,
      'make': make,
      'model': model,
      'iconId': iconId,
      'type': FleetVehicleService.getDbStringFromType(type)
    };

    final isNameSet = name != null;
    if (isNameSet) {
      firestoreMap[nameKey] = name!;
    }
    return firestoreMap;
  }
}