part of 'location.dart';

class LocationState {
  Position? currentLocation;
  Position? lastKnownLocation;
  Position? previousLocation;

  LocationState({
    this.currentLocation,
    this.lastKnownLocation,
    this.previousLocation,
  });
}
