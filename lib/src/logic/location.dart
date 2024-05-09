import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

part 'location_state.dart';

abstract class LocationEvent {}
class BeginListening extends LocationEvent {}
// class UpdateLocation extends LocationEvent {
//   Position location;
//   UpdateLocation({ required this.location });
// }
class StopListening extends LocationEvent {}

class LocationBloc extends Bloc<LocationEvent, LocationState> {

  StreamController<Position>? _currentLocation$;
  final _geolocatorStream = Geolocator
    .getPositionStream(
      locationSettings: new LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10
      )
    );
  StreamSubscription<Position>? _geolocatorStream$;

  LocationBloc() : super(LocationState()) {
    on<BeginListening>((_, emit) => _beginListening(emit));
    // on<UpdateLocation>((event, emit) => _handleLocationUpdate);
    on<StopListening>((_, emit) => _stopListening(emit));
  }

  @override
  Future<void> close() async {
    await _killStreams();
    await super.close();
  }

  _beginListening(Emitter<LocationState> emit) async {
    // Ensure you have the current location before proceeding with setup.
    // final currentPosition = await Geolocator.getCurrentPosition();
    await _emitInitialLocation(emit);
    _setLocationStreams();

    await emit.forEach(_currentLocation$!.stream, onData: (Position newLocation) {
      final nextState = new LocationState(
        currentLocation: newLocation,
        previousLocation: state.currentLocation
      );
      return nextState;
    }, onError: (error, stackTrace) {
        final meh = LocationState();
        return meh;
    });

    // _registerNewLocation(currentPosition);
  }

  _emitInitialLocation(Emitter<LocationState> emit) async {
    final initialLocation = await Geolocator.getCurrentPosition();
    final nextState = new LocationState(
      currentLocation: initialLocation,
      previousLocation: state.currentLocation
    );
    emit(nextState);
  }

  _emitLastKnownLocation(Emitter<LocationState> emit) {
    final nextState = new LocationState(
      currentLocation: null,
      lastKnownLocation: state.currentLocation,
      previousLocation: null,
    );
    emit(nextState);
  }

  // _handleLocationUpdate(UpdateLocation event, Emitter<LocationState> emit) {
  //   final currentLocation = event.location;
  //   final nextState = new LocationState(
  //     currentLocation: currentLocation,
  //     previousLocation: state.currentLocation
  //   );
  //   emit(nextState);
  // }

  _killStreams() async {
    await _geolocatorStream$?.cancel();
    _currentLocation$?.sink.close();
    _currentLocation$ = null;
  }

  _registerNewLocation(Position newLocation) {
    // _currentLocation$ can be null in a split moment during logout.
    _currentLocation$?.add(newLocation);
  }

  _setLocationStreams() {
    _currentLocation$ = new StreamController<Position>();
    _geolocatorStream$ = _geolocatorStream.listen(_registerNewLocation);
    // _currentLocation$!.stream.listen(_registerNewLocation);
  }

  _stopListening(Emitter<LocationState> emit) async {
    _emitLastKnownLocation(emit);
    await _killStreams();
  }
}
