import 'package:t2t_flutter_prototype/models/business.dart';
import 'package:t2t_flutter_prototype/providers/business_provider.dart';

class BusinessRepository {

  static Future<Business> get(String id) async {
    final data = await BusinessProvider.getOrThrow(id);
    final business = Business.withFirstoreMap(data);
    return business;
  }
}
