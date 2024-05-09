import 'package:t2t_flutter_prototype/constants/fleet_vehicle_type.dart';

class FleetVehicleService {

  static FleetVehicleType getTypeFromDbString(String dbString) {
    final isTow = dbString == FleetVehicleTypes.TOW;
    return isTow ? FleetVehicleType.Tow : FleetVehicleType.Flatbed;
  }

  static String getDbStringFromType(FleetVehicleType type) {
    return type == FleetVehicleType.Tow ? FleetVehicleTypes.TOW : FleetVehicleTypes.FLATBED;
  }
}
