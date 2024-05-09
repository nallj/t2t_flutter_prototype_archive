import 'package:t2t_flutter_prototype/constants/firestore.dart';

class Business {
  late String email;
  late String name;
  late String phone;
  late String id;

  Business(this.id, this.email, this.name, this.phone);

  Business.withFirstoreMap(FirestoreMap firestoreMap) {
    fromFirestoreMap(firestoreMap);
  }

  void fromFirestoreMap(FirestoreMap map) {
    id = map[idKey];
    email = map[emailKey];
    name = map[nameKey];
    phone = map[phoneKey];
  }

  FirestoreMap toFirestoreMap() {
    final firestoreMap = {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone
    };
    return firestoreMap;
  }
}