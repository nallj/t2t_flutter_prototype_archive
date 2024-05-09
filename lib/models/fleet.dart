import 'package:t2t_flutter_prototype/constants/firestore.dart';

class Fleet {
  late String id;
  late String businessId;
  String? name;

  Fleet(this.id, this.businessId, this.name);

  Fleet.withFirstoreMap(FirestoreMap firestoreMap) {
    fromFirestoreMap(firestoreMap);
  }

  void fromFirestoreMap(FirestoreMap map) {
    id = map[idKey];
    businessId = map[businessIdKey];

    final isNameSet = map.containsKey(nameKey);
    if (isNameSet) {
      name = map[nameKey];
    }
  }

  FirestoreMap toFirestoreMap() {
    final firestoreMap = {
      'id': id,
      'businessId': businessId
    };

    final isNameSet = name != null;
    if (isNameSet) {
      firestoreMap[nameKey] = name!;
    }
    return firestoreMap;
  }
}