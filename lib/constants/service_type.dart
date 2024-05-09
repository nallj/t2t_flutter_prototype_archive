enum ServiceType {
  NOT_SET,
  LOCKED_VEHICLE,
  FLAT_TIRE,
  WONT_START,
  TOW,
  FLATBED_TOW,
}

class ServiceTypeString {
  static const String FLAT_TIRE = 'flat_tire';
  static const String LOCKED_VEHICLE = 'locked_vehicle';
  static const String WONT_START = 'wont_start';
  static const String TOW = 'tow';
  static const String FLATBED_TOW = 'flatbed_tow';

  static toServiceType(String type) {
    switch (type) {
      case ServiceTypeString.FLAT_TIRE:
        return ServiceType.FLAT_TIRE;
      case ServiceTypeString.LOCKED_VEHICLE:
        return ServiceType.LOCKED_VEHICLE;
      case ServiceTypeString.WONT_START:
        return ServiceType.WONT_START;
      case ServiceTypeString.TOW:
        return ServiceType.TOW;
      case ServiceTypeString.FLATBED_TOW:
        return ServiceType.FLATBED_TOW;
    }
    throw Exception('Unknown service type selected.');
  }
}
