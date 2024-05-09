import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/constants/request_status.dart';
import 'package:t2t_flutter_prototype/constants/view_state.dart';
import 'package:t2t_flutter_prototype/models/active_request_provider.dart';
import 'package:t2t_flutter_prototype/models/polyline_package.dart';
import 'package:t2t_flutter_prototype/models/destination.dart';
import 'package:t2t_flutter_prototype/models/map_marker.dart';
import 'package:t2t_flutter_prototype/models/request_participant.dart';
import 'package:t2t_flutter_prototype/models/service_request.dart';
import 'package:t2t_flutter_prototype/repositories/active_request_provider_repository.dart';
import 'package:t2t_flutter_prototype/repositories/active_request_consumer_repository.dart';
import 'package:t2t_flutter_prototype/repositories/request_repository.dart';
import 'package:t2t_flutter_prototype/screens/provider_select.dart';
import 'package:t2t_flutter_prototype/services/debug_service.dart';
import 'package:t2t_flutter_prototype/services/map_service.dart';
import 'package:t2t_flutter_prototype/services/user_service.dart';
import 'package:t2t_flutter_prototype/src/logic/location.dart';
import 'package:t2t_flutter_prototype/src/logic/provider_engaged.dart';
import 'package:t2t_flutter_prototype/src/logic/request_participant.dart';

class ProviderEngagedArgs {
  final String requestId;

  ProviderEngagedArgs(this.requestId);
}

final ACCEPT_JOB = 'Accept Job';
const tRemoveLaterLogout = 'Remove Later: Logout';

class ProviderEngaged extends StatefulWidget {
  static const route = '/providerEngaged';
  late String _currentRequestId;

  ProviderEngaged(ProviderEngagedArgs args) {
    _currentRequestId = args.requestId;
  }

  @override
  ProviderEngagedState createState() => ProviderEngagedState();
}

class ProviderEngagedState extends State<ProviderEngaged> {
  // late ProviderEngagedBloc _bloc;

  /* Common to schedule_customer */

  final tTotalDistance = 'Total Distance';
  final tYourLocation = 'Your Location';
  final tDestination = 'Destination';
  final tTowJobComplete = 'Tow Job Complete';
  final tAcceptJob = ACCEPT_JOB;
  final tApproachingCustomer = 'Approaching Cutstomer';
  // const tBeginApproach = 'Begin Approach';
  final tBeginTowJob = 'Begin Tow Job';
  final tCustomer = 'Customer';
  final tReportJobComplete = 'Report Job Complete';
  final tTowingCustomer = 'Towing Customer';

  // TODO: Move to constants file.
  final MILE_TO_KM_RATIO = 0.621371;

  final nop = () => null;

  Set<Marker> _mapMarkers = {};
  Completer<GoogleMapController> _map = Completer();
  Map<PolylineId, Polyline> _polylines = {};

  bool _showRouteDistance = false;
  String _routeDistance = '';

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  void initState() {
    super.initState();

    // _bloc = ProviderEngagedBlocProvider.of(context);

    final bloc = BlocProvider.of<ProviderEngagedBloc>(context);


    // _addRequestListener(); // this is what sets _currentRequest
    bloc.add(WatchNewRequest(requestId: widget._currentRequestId));

    //! Moved to WatchNewRequest handler.
    //// React to Geolocator update.
    // _bloc.currentLocationStream.listen((position) {
    //   // Not necessary - keep state in bloc
    //   // _setProviderLocation(position);

    //   final isRequestSet = _isRequestSet();
    //   // _isRequestSet ensures _currentRequest is not null.
    //   final isCommited = isRequestSet && RequestStatus.isCommitedStatus(_currentRequest![statusKey]);

    //   if (isRequestSet && isCommited) {
    //     // POTENTIAL DYING POINT
    //     // This will _always_ trigger a request update.
    //     UserService.updateCurrentLocationOnRequest(
    //       widget._currentRequestId,
    //       position.latitude,
    //       position.longitude,
    //       UserType.PROVIDER,
    //       'provider_engaged.initState'
    //     );
    //   } else {
    //     // Should this be in the else or just at the end of the handler?
    //     _setWaitingForProviderStatus();
    //   }
    //});

    //! Should be now handled by the BlocListener
    //// TO-DO: Moved below _addRequestListener and bloc.currentLocationStream.listen because
    // the provider location wasn't set again. May need a subject to be intermediary
    // between this and bloc.currentLocationStream
    // Rx.combineLatest2(
    //     _bloc.currentRequestStream,
    //     _bloc.currentLocationStream,
    //     (request, location) => {
    //       request,
    //       location
    //     }
    //   )
    //   .listen((thing) {
    //     // This seems to fire when I go back to provider_select and forward again.
    //     final request = thing.first as RequestMap?;
    //     if (request == null) {
    //       // Request set to null from previous logout.
    //       return;
    //     }
    //     final position = thing.last;

    //     // Not necessary since the request listener already stores it, which is what triggers the currentRequestStream.
    //     // _currentRequest = request;

    //     // Transplanted from bloc.currentRequest.listen
    //     final status = _getCurrentRequestStatus();
    //     switch (status) {
    //       // TODO: Between provider_select and provider_engaged should be a details view (or maybe just more details on provider_select) and coming to provider_engaged should imply the provider is in PROVIDER_COMMITTED.
    //       case RequestStatus.WAITING_FOR_PROVIDER: // Is there another status called "provider waiting?"
    //         _setWaitingForProviderStatus();
    //         break;
    //       case RequestStatus.PROVIDER_COMMITTED:
    //         _setProviderCommittedStatus();
    //         break;
    //       case RequestStatus.PROVIDER_AT_SCENE:
    //         throw Exception('Not implemented');
    //         // break;
    //       case RequestStatus.PROVIDER_TOWING:
    //         _setProviderTowing();
    //         break;
    //       case RequestStatus.JOB_FINISHED:
    //         _setJobFinishedStatus();
    //         break;
    //       case RequestStatus.CUSTOMER_CANCELED:
    //         // break;
    //       case RequestStatus.PROVIDER_CANCELED:
    //         // break;
    //       case RequestStatus.CUSTOMER_CANCELED_AFTER_PROVIDER_CANCELED:
    //         throw Exception('Not implemented');
    //         // break;
    //     }
    //     // /Transplanted from bloc.currentRequest.listen
    //   });
  }

  @override
  void dispose() {
    // _bloc.dispose();
    super.dispose();
  }

  _addMarker(Marker marker) {
    _mapMarkers.add(marker);
  }

  _addMarkerToMap(String markerId, Position location, String markerImage, String infoWindowTitle) async {
    final ratio = MediaQuery.of(context).devicePixelRatio;

    final icon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: ratio),
      markerImage
    );

    final marker = Marker(
      markerId: MarkerId(markerId),
      icon: icon,
      infoWindow: InfoWindow(title: infoWindowTitle),
      position: LatLng(location.latitude, location.longitude)
    );
    _addMarker(marker);
  }

  _displayTwoMarkers(MapMarker origin, MapMarker destination) {
    final ratio = MediaQuery.of(context).devicePixelRatio;

    final originLocation = origin.location;
    final originHeading = origin.heading;
    final destinationLocation = destination.location;
    final destinationHeading = destination.heading;

    Set<Marker> markers = {};

    BitmapDescriptor
      .fromAssetImage(
        ImageConfiguration(devicePixelRatio: ratio),
        origin.pathImage
      )
      .then((BitmapDescriptor icon) {
        final originMarker = Marker(
          markerId: MarkerId(origin.pathImage),
          position: LatLng(originLocation.latitude, originLocation.longitude),
          rotation: originHeading,
          infoWindow: InfoWindow(title: origin.title),
          icon: icon
        );
        markers.add(originMarker);
      });

    BitmapDescriptor
      .fromAssetImage(
        ImageConfiguration(devicePixelRatio: ratio),
        destination.pathImage
      )
      .then((BitmapDescriptor icon) {
        final destinationMarker = Marker(
          markerId: MarkerId(destination.pathImage),
          position: LatLng(destinationLocation.latitude, destinationLocation.longitude),
          rotation: destinationHeading,
          infoWindow: InfoWindow(title: destination.title),
          icon: icon
        );
        markers.add(destinationMarker);
      });

    _setMarkers(markers);
  }

  getCurrentRequestId() => _getCurrentRequestOrThrow().id;
  // _getCurrentRequestStatus() => _getCurrentRequestOrThrow().status;
  // _getRequestCustomerUserId() => _getCurrentRequestOrThrow().customer.userId;

  double _getCustomerLat() =>
    context
      .read<ProviderEngagedBloc>()
      .getCustomerLatFromRequest();

  double _getCustomerLon() =>
    context
      .read<ProviderEngagedBloc>()
      .getCustomerLonFromRequest();

  double _getCustomerHeading() =>
    context
      .read<ProviderEngagedBloc>()
      .getCustomerHeadingFromRequest();

  double _getProviderLat() => _getCurrentLocation()!.latitude;
  double _getProviderLon() => _getCurrentLocation()!.longitude;
  double _getProviderHeading() => _getCurrentLocation()!.heading;

  Position? _getCurrentLocation() => context.read<LocationBloc>().state.currentLocation;

  double _getRequestOrigLat() =>
    context
      .read<ProviderEngagedBloc>()
      .getRequestOrigLat();

  double _getRequestOrigLon() =>
    context
      .read<ProviderEngagedBloc>()
      .getRequestOrigLon();

  double _getRequestDestLat() =>
    context
      .read<ProviderEngagedBloc>()
      .getRequestDestLat();

  double _getRequestDestLon() =>
    context
      .read<ProviderEngagedBloc>()
      .getRequestDestLon();

  ServiceRequest _getCurrentRequestOrThrow() =>
    context
      .read<ProviderEngagedBloc>()
      .getCurrentRequestOrThrow();

  Position _getLocationOrThrow() {
    final location = _getCurrentLocation();
    final isLocationNotSet = location == null;
    if (isLocationNotSet) {
      DebugService.pr('Current location is not set!', 'ProviderEngaged._getLocationOrThrow');
      throw Exception('ouch');
    }
    return location!;
  }

  _handleMapCreated(GoogleMapController controller) {
    DebugService.pr('Trying to complete _map', '_handleMapCreated');
    if (!_map.isCompleted) {
      _map.complete(controller);
    }
    DebugService.pr('Completed _map!', '_handleMapCreated');
  }

  // was pretty much the same as _isCustomerLocationSet before introduction of LocationBloc
  _isProviderLocationSet() {
    // final state = context.read<ProviderEngagedBloc>().state;
    // final currentRequest = state.currentRequest;
    // // final providerLocation = currentRequest!.provider!.getLocation();

    // final currentRequestNotSet = currentRequest == null;
    // final providerSet = !currentRequestNotSet && currentRequest!.provider != null;
    // return providerSet;

    final currentLocation = _getCurrentLocation();

    final locationSet = currentLocation != null;
    return locationSet;
  }

  _moveCamera(CameraPosition cameraPosition) async {
    final map = await _map.future;
    map.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  _moveCameraBounded(LatLng southwest, LatLng northeast) async {
    final map = await _map.future;

    final bounds = new LatLngBounds(southwest: southwest, northeast: northeast);
    map.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }

  _moveCameraBounds(LatLngBounds latLngBounds) async {
    final mapController = await _map.future;
    mapController.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 100));
  }

  _setMarkers(Set<Marker> markers) {
    setState(() {
      _mapMarkers = markers;
    });
  }

  /* /Common to schedule_customer */

  // late String _currentRequestId;//  = ''; // TODO: Do I really need this?
  // ServiceRequest? _currentRequest;
  // bool _currentRequestSet = false; // TODO: I should use the dartrx equivalent of first() to skip this strategy.

  // Position? _providerLocation; // TODO: Turn this into a late when able.
  CameraPosition _cameraPosition = CameraPosition(target: LatLng(0, 0));

  // View
  bool _displayBoxAddressDestination = true;
  String _buttonText = ACCEPT_JOB; //tAcceptJob;
  Color _buttonColor = Colors.indigoAccent;
  Function _buttonFn = () {};
  String _statusText = '';

  // TODO: None of this is view logic. Move this to bloc.
  _acceptJob() async {
    final providerUser = await UserService.getUserDataLogin();
    final provider = RequestParticipant.fromUser(providerUser);

    if(_isProviderLocationSet()) {
      final providerLocation = _getCurrentLocation();

      provider.updateLocation(
        providerLocation!.latitude,
        providerLocation.longitude,
        providerLocation.heading
      );
    }

    final db = FirebaseFirestore.instance;
    final requestId = getCurrentRequestId();

    final nextStatus = RequestStatus.PROVIDER_COMMITTED;
    final requestUpdate = {
      'provider': provider.toFirestoreMap(includeLocation: true),
      'status': nextStatus,
    };

    await RequestRepository.update(requestId, requestUpdate);

    // final customerId = _getRequestCustomerUserId();
    final activeRequestUpdate = {
      'status': nextStatus,
    };
    await ActiveRequestConsumerRepository.update(requestId, activeRequestUpdate);

    final activeRequest = await ActiveRequestProvider.create(requestId);
    activeRequest.status = RequestStatusType.PROVIDER_COMMITTED;
    activeRequest.userId = provider.userId;

    await ActiveRequestProviderRepository.createOrReplace(activeRequest);
  }

  _beginTowing() {
    final db = FirebaseFirestore.instance;
    final requestId = getCurrentRequestId();

    final nextStatus = RequestStatus.PROVIDER_TOWING;
    final requestUpdate = {
      // 'provider': provider.toFirestoreMap(includeLocation: true),
      'status': nextStatus,
      'origin': { // this is new
        'latitude': _getProviderLat(),
        'longitude': _getProviderLon(),
      }
    };

    RequestRepository.update(requestId, requestUpdate);

    // final customerId = _getRequestCustomerUserId();
    final activeRequestUpdate = {
      'status': nextStatus,
    };
    ActiveRequestConsumerRepository.update(requestId, activeRequestUpdate);

    final providerId = _getRequestProviderUserId();
    final activeRequestProviderUpdate = {
      'status': nextStatus,
      'requestId': requestId,
      'userId': providerId,
    };
    ActiveRequestProviderRepository.update(requestId, activeRequestProviderUpdate);
  }

  _completeTowJob() {
    final db = FirebaseFirestore.instance;
    final requestId = getCurrentRequestId();

    final nextStatus = RequestStatus.JOB_FINISHED;
    final requestUpdate = {
      'status': nextStatus,
    };

    RequestRepository.update(requestId, requestUpdate);

    // final customerId = _getRequestCustomerUserId();
    final activeRequestUpdate = {
      'status': nextStatus,
    };
    ActiveRequestConsumerRepository.update(requestId, activeRequestUpdate);

    final providerId = _getRequestProviderUserId();
    final activeRequestProviderUpdate = {
      'status': nextStatus,
    };
    ActiveRequestProviderRepository.update(requestId, activeRequestProviderUpdate);
  }

  _confirmTowComplete() {
    // TODO: Unset something so the app stops loading the "total distance" screen.
    Navigator.pushReplacementNamed(context, ProviderSelect.route);
  }

  _changeMainButton(String text, Color color, Function buttonFn) {
    setState(() {
      _buttonText = text;
      _buttonColor = color;
      _buttonFn = buttonFn;
    });
  }

  // Create the polylines for showing the route between two places
  // ref: https://blog.codemagic.io/creating-a-route-calculator-using-google-maps/
  /// Create polyline between a starting and ending point.
  /// @return double The distance of the polyline in miles.
  Future<PolylinePackage> _createPolyline(
    String id,
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
    { Color color = Colors.red }
  ) async {
    // Initialize the PolylinePoints service object.
    var polylinePointsSvc = PolylinePoints();

    PolylineResult result = await polylinePointsSvc.getRouteBetweenCoordinates(
      // TODO: Get this out of here.
      "<redacted>", // Secrets.API_KEY, // Google Maps API Key
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.driving,
    );

    final package = PolylinePackage();
    package.hasPolylines = result.points.isNotEmpty;

    List<LatLng> polylineCoordinates = [];

    // Adding the coordinates to the list
    if (package.hasPolylines) {
      result.points.forEach((PointLatLng point) {
        final lat = point.latitude;
        final lon = point.longitude;
        polylineCoordinates.add(LatLng(lat, lon));

        final newNorthmostBound = package.northBound == null || lat > package.northBound!;
        if (newNorthmostBound) {
          package.northBound = lat;
        }
        final newSouthmostBound = package.southBound == null || lat < package.southBound!;
        if (newSouthmostBound) {
          package.southBound = lat;
        }

        final newEastmostBound = package.eastBound == null || lon > package.eastBound!;
        if (newEastmostBound) {
          package.eastBound = lon;
        }
        final newWestmostBound = package.westBound == null || lon < package.westBound!;
        if (newWestmostBound) {
          package.westBound = lon;
        }
      });
    }

    // Defining an ID
    PolylineId polylineId = PolylineId(id);

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: polylineId,
      color: color,
      points: polylineCoordinates,
      width: 3,
    );

    setState(() {
       _polylines[polylineId] = polyline;
    });

    package.routeDistance = (MapService.calculateRouteDistance(polylineCoordinates) * MILE_TO_KM_RATIO).toStringAsFixed(2);
    return package;
  }

  _getRequestProviderUserId() {
    final provider = _getCurrentRequestOrThrow().provider;
    final providerNotSet = provider == null;
    if (providerNotSet) {
      final error = 'Provider not set on current request.';

      DebugService.pr(error, 'ProviderEngaged._getRequestProviderUserId');
      throw Exception(error);
    }

    return provider!.userId;
  }

  ServiceRequest? _getCurrentRequest() =>
    context
      .read<ProviderEngagedBloc>()
      .state
      .currentRequest;

  // Handle back button press.
  Future<bool> _handleOnWillPop() async {
    // ref: https://stackoverflow.com/questions/50452710/catch-android-back-button-event-on-flutter
    // Do your normal thing.
    context.read<ProviderEngagedBloc>().add(ClearCurrentRequest());
    return Future(() => true);
    // Don't go anywhere.
    // return false;
  }

  _isRequestSet() {
    // final currentRequestNotSet = _currentRequest == null;
    // if (currentRequestNotSet) {
    //   return false;
    // }
    // String? currentRequestId = _currentRequest!.id;
    // return currentRequestId.isNotEmpty;
    final currentRequest = _getCurrentRequest();

    final currentRequestNotSet = currentRequest == null;
    if (currentRequestNotSet) {
      return false;
    }
    String? currentRequestId = currentRequest!.id;
    return currentRequestId.isNotEmpty;
  }

  // all the same as schedule_customer
  _setJobFinishedStatus() {
    final originLatitude = _getRequestOrigLat();
    final originLongitude = _getRequestOrigLon();

    final destinationLatitude = _getRequestDestLat();
    final destinationLongitude = _getRequestDestLon();

    final meters = GeolocatorPlatform
      .instance
      .distanceBetween(
        originLatitude,
        originLongitude,
        destinationLatitude,
        destinationLongitude
      );

    final km = meters / 1000;
    final miles = MILE_TO_KM_RATIO * km;

    // View
    _setStatusText(tTowJobComplete);
    _changeMainButton(
      tTotalDistance,
      Colors.greenAccent,
      _confirmTowComplete
    );

    // TODO: What would happen if this wasn't wrapped with setState?
    _setMarkers({});

    final location = Position(
      latitude: destinationLatitude,
      longitude: destinationLongitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    _addMarkerToMap(
      'DC',
      location,
      'assets/images/lol.jpeg',
      tDestination
    );

    final cameraPosition = CameraPosition(
      target: LatLng(location.latitude, location.longitude),
      zoom: 20
    );
    _moveCamera(cameraPosition);
  }

  _setProviderCommittedStatus() {

    // View changes
    _setStatusText(tApproachingCustomer);
    _changeMainButton(
      tBeginTowJob,
      Colors.black,
      _beginTowing
    );

    final originLatitude = _getProviderLat();
    final originLongitude = _getProviderLon();
    final originHeading = _getProviderHeading();

    final destLatitude = _getCustomerLat();
    final destLongitude = _getCustomerLon();
    final destHeading = 0.0;

    final originMarker = new MapMarker(
      LatLng(originLatitude, originLongitude),
      originHeading,
      'assets/images/truck_icon.png',
      tYourLocation
    );

    final destMarker = new MapMarker(
      LatLng(destLatitude, destLongitude),
      destHeading,
      'assets/images/car_pin.png',
      tCustomer
    );

    _displayTwoMarkers(originMarker, destMarker);

    var nLat, nLon, sLat, sLon;

    final huh = originLatitude <= destLatitude;
    if (huh) {
      sLat = originLatitude;
      nLat = destLatitude;
    } else {
      sLat = destLatitude;
      nLat = originLatitude;
    }

    final againHuh = originLongitude <= destLongitude;
    if (againHuh) {
      sLon = originLongitude;
      nLon = destLongitude;
    } else {
      sLon = destLongitude;
      nLon = originLongitude;
    }

    _moveCameraBounds(LatLngBounds(
      northeast: LatLng(nLat, nLon),
      southwest: LatLng(sLat, sLon)
    ));
  }

  //! Not necessary - keep state in bloc
  // _setProviderLocation(Position location) {
  //   // setState rebuilds the entire widget tree. Do I need this?
  //   setState(() {
  //     _providerLocation = location;
  //   });
  // }

  _setProviderTowing() {

    // View changes
    _setStatusText(tTowingCustomer);
    _changeMainButton(
      tReportJobComplete,
      Colors.black,
      _completeTowJob
    );

    // EVERYTHING The same as _setProviderCommittedStatus

    final originLatitude = _getProviderLat();
    final originLongitude = _getProviderLon();
    final originHeading = _getProviderHeading();

    final destLatitude = _getRequestDestLat();
    final destLongitude = _getRequestDestLon();
    final destHeading = 0.0;

    final originMarker = new MapMarker(
      LatLng(originLatitude, originLongitude),
      originHeading,
      'assets/images/truck_icon.png',
      tYourLocation
    );

    final destMarker = new MapMarker(
      LatLng(destLatitude, destLongitude),
      destHeading,
      'assets/images/destination_pin.png',
      tCustomer
    );

    _displayTwoMarkers(originMarker, destMarker);

    var nLat, nLon, sLat, sLon;

    final huh = originLatitude <= destLatitude;
    if (huh) {
      sLat = originLatitude;
      nLat = destLatitude;
    } else {
      sLat = destLatitude;
      nLat = originLatitude;
    }

    final againHuh = originLongitude <= destLongitude;
    if (againHuh) {
      sLon = originLongitude;
      nLon = destLongitude;
    } else {
      sLon = destLongitude;
      nLon = originLongitude;
    }

    _moveCameraBounds(LatLngBounds(
      northeast: LatLng(nLat, nLon),
      southwest: LatLng(sLat, sLon)
    ));
  }

  _setStatusText(String statusText) {
    setState(() {
      _statusText = statusText;
    });
  }

  _setWaitingForProviderStatus() {

    // FROM: provider_engaged.dart: _setWaitingForProviderStatus

    _changeMainButton(
      tAcceptJob,
      Colors.black,
      () { // that's wierd, I can do this: _changeMainButton(tCallProvider, _callProvider);
        _acceptJob();
      }
    );

    // final isSet = _providerLocation != null;
    if(_isProviderLocationSet()) {
      final providerLocation = _getLocationOrThrow();

      // Add provider marker.
      _addMarkerToMap(
        requestProviderKey,
        providerLocation, // TODO: Can I really get away with this?
        'assets/images/truck_pin.png',
        tYourLocation
      );

    } else {
      // This was triggered when I had to accept via Android the app is allowed access to location.
      DebugService.pr('Provider location missing', '_setWaitingForProviderStatus');
      throw Exception('Failed assertion: provider location missing');
    }

    final currentRequest = _getCurrentRequestOrThrow();
    final destination = currentRequest.destination;

    // TODO: Consider rename of RequestMap? Consider new type?
    final customer = currentRequest.customer;
    final customerLat = customer.latitude;
    final customerLon = customer.longitude;
    final customerPos = new Position(
      longitude: customerLon,
      latitude: customerLat,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0
    );

    // Add customer marker.
    _addMarkerToMap(
      requestCustomerKey,
      customerPos, // TODO: Can I really get away with this?
      'assets/images/car_pin.png',
      tCustomer
    );

    // Add destination marker.
    final destinationPosition = destination.toPosition();
    _addMarkerToMap(
      requestDestinationKey,
      destinationPosition,
      'assets/images/destination_pin.png',
      tDestination
    );

    _showPolylinesWithDistance(customerLat, customerLon, destination);
  }

  _showPolylinesWithDistance(
    double customerLat,
    double customerLon,
    Destination destination
  ) async {
    final providerLocation = _getLocationOrThrow();
    final arrivalRoutePackage = await _createPolyline(
      'toCustomer',
      providerLocation.latitude,
      providerLocation.longitude,
      customerLat,
      customerLon
    );
    final arrivalRouteDistance = arrivalRoutePackage.routeDistance;

    final towRoutePackage = await _createPolyline(
      'tow',
      customerLat,
      customerLon,
      destination.latitude,
      destination.longitude,
      color: Colors.blueAccent.shade700
    );
    final towRouteDistance = towRoutePackage.routeDistance;

    final routeDistance = arrivalRouteDistance + towRouteDistance;

    setState(() {
      _routeDistance = "Distance: \n" + '$routeDistance Mi';
      _showRouteDistance = true;
    });

    final markerLocations = [
      [customerLat, customerLon],
      [providerLocation.latitude, providerLocation.longitude],
      [destination.latitude, destination.longitude]
    ];
    final polylinePackages = [arrivalRoutePackage, towRoutePackage];

    // Moved to _showPolylinesWithDistance
    final bounding = MapService.getBounding(markerLocations, polylinePackages);
    final southwest = bounding[0];
    final northeast = bounding[1];

    _moveCameraBounded(southwest, northeast);
  }

  // TODO: Remove when ready to move to production.
  _performMenuAction(String itemId) {
    switch (itemId) {
      case tRemoveLaterLogout:
        // _bloc.logoutAction(context);
        BlocProvider
          .of<ProviderEngagedBloc>(context)
          .add(UserLogout(context: context));

        break;
    }
  }

  @override
  Widget build(BuildContext screenContext) {
    return WillPopScope(
      child: BlocListener<ProviderEngagedBloc, RequestParticipantState>(
        listener: (blocContext, state) {

          //! From original switch case Rx.combineLatest2(_bloc.currentRequestStream, _bloc.currentLocationStream,
          //! Does this still matter?
          if (state.currentRequest == null) {
            // Request set to null from previous logout.
            return;
          }

          final bloc = screenContext.read<ProviderEngagedBloc>();
          final currentViewState = bloc.state.viewState;

          // final nextViewState = state.viewState;
          final nextViewState = bloc.getViewStateFromRequestStatus();
          final isViewStateChange = currentViewState != nextViewState;
          if (isViewStateChange) {
            DebugService.pr('Does this ever occur? Can I just rely on request status?', 'ProviderEngaged.BlocListener');
          }

          switch (nextViewState) {
            // TODO: Between provider_select and provider_engaged should be a details view (or maybe just more details on provider_select) and coming to provider_engaged should imply the provider is in PROVIDER_COMMITTED.
            case ViewState.WAITING_FOR_PROVIDER: // Is there another status called "provider waiting?"
              _setWaitingForProviderStatus();
              break;
            case ViewState.PROVIDER_COMMITTED:
              _setProviderCommittedStatus();
              break;
            case ViewState.PROVIDER_AT_SCENE:
              throw Exception('Not implemented');
              // break;
            case ViewState.PROVIDER_TOWING:
              _setProviderTowing();
              break;
            case ViewState.JOB_FINISHED:
              _setJobFinishedStatus();
              break;
            default:
              DebugService.pr('Reached not implemented state.', '_viewStateHandler');
              throw Exception('Reached not implemented state.');
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text("Provider Engaged - $_statusText"),
            actions: [
              PopupMenuButton<String>(
                itemBuilder: (context) =>
                  [tRemoveLaterLogout]
                    .map((String item) => PopupMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ))
                    .toList()
                ,
                onSelected: _performMenuAction,
              )
            ],
          ),
          body: Container(
            child: Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _cameraPosition,
                  onMapCreated: _handleMapCreated,
                  myLocationButtonEnabled: true,
                  markers: _mapMarkers,

                  // https://blog.codemagic.io/creating-a-route-calculator-using-google-maps/
                  zoomControlsEnabled: false,
                  // zoomGesturesEnabled: true,
                  polylines: Set<Polyline>.of(_polylines.values),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Opacity(
                    opacity: _showRouteDistance ? 1 : 0,
                    child: Text(
                      _routeDistance,
                      style: TextStyle(
                        backgroundColor: const Color(0xEEEEEE),
                      ),
                    )
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: Platform.isIOS
                      ? EdgeInsets.fromLTRB(20, 10, 20, 30)
                      : EdgeInsets.all(10),
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Why can't I plug this into onPressed directly?
                        _buttonFn();
                      },
                      child: Text(
                        _buttonText,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Handle back button push.
      onWillPop: _handleOnWillPop,
    );
  }
}
