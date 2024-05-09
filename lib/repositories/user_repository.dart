import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/models/user.dart';
import 'package:t2t_flutter_prototype/providers/user_provider.dart';

class UserRepository {

  // static Future<FirestoreMap?> getUser(String userId) =>
  //   UserProvider.getUser(userId);

  static Future<User> getUserOrThrow(String userId, String exMessage) async {
    final map = await UserProvider.getUserOrThrow(userId, exMessage);
    final user = User.withFirstoreMap(map);

    _throwIfIdMismatch(user, userId);
    return user;
  }

  static Future<void> upsert(User user) {
    final userId = user.id;
    final map = user.toFirestoreMap();
    return UserProvider.upsert(userId, map);
  }

  static _throwIfIdMismatch(User user, String targetId) {
    final recordIdDoesntMatch = user.id != targetId;
    if (recordIdDoesntMatch) {
      throw Exception('Fetched user record with mismatched userId.');
    }
  }
}
