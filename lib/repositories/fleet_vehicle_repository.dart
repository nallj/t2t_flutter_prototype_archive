import 'package:t2t_flutter_prototype/models/fleet_vehicle.dart';
import 'package:t2t_flutter_prototype/providers/fleet_vehicle_provider.dart';

class FleetVehicleRepository {

  static Future<FleetVehicle> get(String id) async {
    final data = await FleetVehicleProvider.getOrThrow(id);
    final business = FleetVehicle.withFirstoreMap(data);
    return business;
  }
}
