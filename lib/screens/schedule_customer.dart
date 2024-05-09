import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:t2t_flutter_prototype/constants/firestore.dart';
import 'package:t2t_flutter_prototype/constants/view_state.dart';
import 'package:t2t_flutter_prototype/models/destination.dart';
import 'package:t2t_flutter_prototype/models/map_marker.dart';
import 'package:t2t_flutter_prototype/models/service_request.dart';
import 'package:t2t_flutter_prototype/repositories/active_request_consumer_repository.dart';
import 'package:t2t_flutter_prototype/repositories/request_repository.dart';
import 'package:t2t_flutter_prototype/screens/customer_panel.dart';
import 'package:t2t_flutter_prototype/services/debug_service.dart';
import 'package:t2t_flutter_prototype/services/mock_service.dart';
import 'package:t2t_flutter_prototype/services/user_service.dart';
import 'package:t2t_flutter_prototype/src/logic/location.dart';
import 'package:t2t_flutter_prototype/src/logic/request_participant.dart';
import 'package:t2t_flutter_prototype/src/logic/schedule_customer.dart';

const tLogOut = 'Log Out';
const tGiveFeedback = 'TODO: Give Feedback';
const tSettings = 'TODO: Settings';
const tCallProvider = 'Call Provider';
const tOmgYourACustomer = "OMG You're a Customer!";
const tYouAreHere = 'You are here';
const tChooseYourDestination = 'Choose your Destination';
const tCorrectAddress = 'Is this address correct?';
const tCancel = 'Cancel';
const tConfirm = 'Confirm';
const tCancelActiveRequest = 'Cancel Active Request?';
const tNevermind = 'Nevermind';
const tProviderOnTheWay = 'Provider on the way!';
const tProvider = 'Provider';
const tYourLocation = 'Your Location';
const tProviderTowing = 'The Provider is Towing';
const tTotalDistance = 'Total Distance';
const tDestination = 'Destination';
const tDetails = 'Details';

const MILE_TO_KM_RATIO = 0.621371;

final textInputSyle = TextStyle(fontSize: 24, color: Colors.blueGrey);
final textInputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(6));

final nop = () => null;

class ScheduleCustomer extends StatefulWidget {
  static const route = '/scheduleCustomer';

  @override
  ScheduleCustomerState createState() => ScheduleCustomerState();
}

class ScheduleCustomerState extends State<ScheduleCustomer> {

  Completer<GoogleMapController> _map = Completer();
  CameraPosition _camera = CameraPosition(target: LatLng(0, 0));
  // PanelController _pc = new PanelController();

  // View
  List<String> _menuItems = [
    tLogOut,
    tGiveFeedback,
    tSettings,
    'Remove later: acceptJob',
    'Remove later: undoAcceptJob'
  ];
  Set<Marker> _mapMarkers = {};
  TextEditingController _destinationField = TextEditingController();
  bool _displayBoxAddressDestination = true;
  String _buttonText = tCallProvider;
  Function _buttonFn = () {};
  bool showPanel = false;

  void initState() {
    super.initState();

    final bloc = BlocProvider.of<ScheduleCustomerBloc>(context);


    // bloc.add(WatchNewRequest(requestId: widget._currentRequestId));

    // Moved to BlocListener
    // _bloc.viewStateStream.listen((viewState) {
    //   _viewStateHandler(viewState);
    // });
    // _bloc.currentRequestStream.listen((RequestRecord? currentRequest) {
    //   if (currentRequest != null) {
    //     // Don't maintain own copy of current request. Use _bloc.currentRequest instead.
    //     // _setCurrentRequest(currentRequest);
    //   } else {
    //     DebugService.pr('currentRequest not set', 'initState > _bloc.currentRequestStream.listen');
    //   }
    // });

    // This is copy/paste same pattern from provider_select.
    // TODO: Probably needs tweaking yeah.
    // _recoverActiveRequest(); // I should be using the recover functionality in the _bloc instead.

    // bloc.attemptRecoverActiveRequest();
    bloc.add(InitCustomerScreen());
  }

  _addCustomerMarkerToMap(Position location) =>
    _addMarkerToMap(location, 'assets/images/car_pin.png', tYourLocation);

  _addMarker(Marker marker) {
    setState(() {
      _mapMarkers.add(marker);
    });
  }

  _addMarkerToMap(Position location, String markerImage, String infoWindowTitle) async {
    final ratio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(
        devicePixelRatio: ratio
        // size: Size(50, 81) // TODO: doesn't seem to affect the size of the marker.
      ),
      markerImage
    )
    .then((BitmapDescriptor icon) {
      final customerMarker = Marker(
        markerId: MarkerId(requestCustomerKey),
        icon: icon,
        infoWindow: InfoWindow(title: infoWindowTitle),
        position: LatLng(location.latitude, location.longitude)
      );
      _addMarker(customerMarker);
    });
  }

  // Doesn't belong in BLoC
  _callProvider() async {
    DebugService.pr('Calling the provider', '_callProvider');

    final destinationAddress = _destinationField.text;
    final destinationNotProvided = destinationAddress.isEmpty;
    if (destinationNotProvided) {
      throw Exception('Destination not provided.');
    }

    DebugService.pr('Destination provided', '_callProvider');
    // TODO: Watch out for the following:
    // PlatformException (PlatformException(IO_ERROR, A network error occurred trying to lookup the address ''., null, null))
    final coordinates = await locationFromAddress(destinationAddress);
    final noCoordinatesReturned = coordinates.length == 0;
    if (noCoordinatesReturned) {
      throw Exception('No GPS coordinates found for given address.');
    }

    // final multipleCoordsReturned = coordinates.length > 1;
    // TODO: What do we do if multiple results come back?
    final firstChoice = coordinates.first;
    final latitude = firstChoice.latitude;
    final longitude = firstChoice.longitude;

    final placemarks = await placemarkFromCoordinates(latitude, longitude);

    final noPlacemarksReturned = placemarks.length == 0;
    if (noPlacemarksReturned) {
      throw Exception('No GPS placemarks found for given coordinates. How can this be possible?');
    }
    // TODO: What do we do if multiple placemarks come back? Uber has a selector list view for this.

    final firstPlacemark = placemarks.first;

    final missingData =
      firstPlacemark.administrativeArea == null
      || firstPlacemark.locality == null
      || firstPlacemark.postalCode == null
      || firstPlacemark.street == null;

    // TODO: Minimally, I should loop through the placemarks looking for one that doesn't have `missingData`.
    if (missingData) {
      throw Exception('GPC placemark is missing data.');
    }

    final destination = new Destination();
    destination.state = firstPlacemark.administrativeArea!;
    destination.city = firstPlacemark.locality!;
    destination.zip = firstPlacemark.postalCode!;
    destination.street = firstPlacemark.street!;
    destination.latitude = latitude;
    destination.longitude = longitude;

    final confirmationMessage = destination.street
      + "\n"
      + destination.city
      + ', '
      + destination.state
      + ' '
      + destination.zip;

    final alertFn = (BuildContext context) => AlertDialog(
      title: Text(tCorrectAddress),
      content: Text(confirmationMessage),
      contentPadding: EdgeInsets.all(10),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            tCancel,
            style: TextStyle(color: Colors.red),
          )
        ),
        TextButton(
          onPressed: () async {
            // await _bloc.saveRequestAction(destination);
            context
              .read<ScheduleCustomerBloc>()
              .add(CustomerCreateRequest(destination: destination));
            Navigator.pop(context);
          },
          child: Text(
            tConfirm,
            style: TextStyle(color: Colors.green)
          )
        )
      ],
    );
    showDialog(context: context, builder: alertFn);
  }

  _centerMapOnMarkers(MapMarker origin, MapMarker destination) {
    final originLatitude = origin.location.latitude;
    final originLongitude = origin.location.longitude;

    final destinationLatitude = destination.location.latitude;
    final destinationLongitude = destination.location.longitude;

    _displayTwoMarkers(origin, destination);

    var nLat, nLon, sLat, sLon;

    final huh = originLatitude <= destinationLatitude;
    if (huh) {
      sLat = originLatitude;
      nLat = destinationLatitude;
    } else {
      sLat = destinationLatitude;
      nLat = originLatitude;
    }

    final againHuh = originLongitude <= destinationLongitude;
    if (againHuh) {
      sLon = originLongitude;
      nLon = destinationLongitude;
    } else {
      sLon = destinationLongitude;
      nLon = originLongitude;
    }

    _moveCameraBounds(LatLngBounds(
      northeast: LatLng(nLat, nLon),
      southwest: LatLng(sLat, sLon)
    ));
  }

  _changeMainButton(String text, Function buttonFn) {
    setState(() {
      _buttonText = text;
      _buttonFn = buttonFn;
    });
  }

  _confirmCancellation() {
    final alertFn = (BuildContext context) => AlertDialog(
      title: Text(tCancelActiveRequest),
      // content: Text(tCancelRequest),
      contentPadding: EdgeInsets.all(10),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            tNevermind,
            style: TextStyle(color: Colors.blueAccent)
          )
        ),
        TextButton(
          onPressed: () {
            // _bloc.cancelRequestAction(null);
            context.read<ScheduleCustomerBloc>().add(CustomerCancelRequest());
            Navigator.pop(context);
          },
          child: Text(
            tCancel,
            style: TextStyle(color: Colors.red),
          )
        ),
      ],
    );
    showDialog(context: context, builder: alertFn);
  }

  _displayTwoMarkers(MapMarker origin, MapMarker destination) {
    final ratio = MediaQuery.of(context).devicePixelRatio;

    final originLocation = origin.location;
    final destinationLocation = destination.location;

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
          infoWindow: InfoWindow(title: origin.title),
          icon: icon,
          rotation: origin.heading
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
          rotation: destination.heading,
          infoWindow: InfoWindow(title: destination.title),
          icon: icon
        );
        markers.add(destinationMarker);
      });

    _setMarkers(markers);
  }

  double _getRequestCustomerLat() => _getCurrentLocation()!.latitude;
  double _getRequestCustomerLon() => _getCurrentLocation()!.longitude;
  // double _getRequestCustomerHeading() => _getCurrentLocation()!.heading;

  Position? _getCurrentLocation() => context.read<LocationBloc>().state.currentLocation;

  double _getRequestProviderLat() =>
    context
      .read<ScheduleCustomerBloc>()
      .getProviderLatFromRequest();

  double _getRequestProviderLon() =>
    context
      .read<ScheduleCustomerBloc>()
      .getProviderLonFromRequest();

  double _getRequestProviderHeading() =>
    context
      .read<ScheduleCustomerBloc>()
      .getProviderHeadingFromRequest();

  double _getRequestOrigLat() =>
    context
      .read<ScheduleCustomerBloc>()
      .getRequestOrigLat();

  double _getRequestOrigLon() =>
    context
      .read<ScheduleCustomerBloc>()
      .getRequestOrigLon();

  double _getRequestDestLat() =>
    context
      .read<ScheduleCustomerBloc>()
      .getRequestDestLat();

  double _getRequestDestLon() =>
    context
      .read<ScheduleCustomerBloc>()
      .getRequestDestLon();

  ServiceRequest _getCurrentRequestOrThrow() =>
    context
      .read<ScheduleCustomerBloc>()
      .getCurrentRequestOrThrow();

  _handleMapCreated(GoogleMapController controller) {
    DebugService.pr('Trying to complete _map', '_handleMapCreated');
    _map.complete(controller);
    DebugService.pr('Completed _map!', '_handleMapCreated');
  }

  _logout() =>
    context
      .read<ScheduleCustomerBloc>()
      .add(UserLogout(context: context));

  _moveCamera(CameraPosition cameraPosition) async {
    final map = await _map.future;
    map.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  _moveCameraBounds(LatLngBounds latLngBounds) async {
    final mapController = await _map.future;
    mapController.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 100));
  }

  _performMenuAction(String itemId) {
    switch (itemId) {
      case tLogOut:
        _logout();
        break;
      case tGiveFeedback:
        // TODO
        break;
      case tSettings:
        // TODO
        break;
      case 'Remove later: acceptJob':
        _fakeProviderAcceptJob();
        break;
      case 'Remove later: undoAcceptJob':
        _undoFakeProviderAcceptJob();
        break;
    }
  }

  // From provider_schedule.dart
  _recoverActiveRequest() async {
    final userNotAuthed = !(await UserService.isAuthedUser());
    if (userNotAuthed) {
      DebugService.pr('Failed to test for active customer request. User not logged in (how did I get here?).', 'schedule_customer._recoverActiveRequest');
      return;
    }

    final currentUser = await UserService.getCurrentUser();
    final userId = currentUser.uid;

    final activeRequest = await ActiveRequestConsumerRepository.get(userId);
    final hasActiveRequest = activeRequest != null;

    if (hasActiveRequest) {
      // TODO: Can data() ever really be null?
      final requestId = activeRequest!.requestId;

      final request = await RequestRepository.get(requestId);

      // TODO: Hook up telemetry to missingCorrespondingRequest.
      final missingCorrespondingRequest = request == null;
      if (missingCorrespondingRequest) {
        DebugService.pr('REQUEST MISSING', 'ScheduleCustomer._recoverActiveRequest');
        throw Exception('REQUEST MISSING');
      }

      context.read<ScheduleCustomerBloc>().add(SetCurrentRequest(request: request!));
    }
  }

  _setJobFinishedStatus() async {
    showPanel = false;

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

    _changeMainButton(tTotalDistance, nop);

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
    _addMarkerToMap(location, 'assets/images/lol.png', tDestination);

    final cameraPosition = CameraPosition(
      target: LatLng(location.latitude, location.longitude),
      zoom: 20
    );
    _moveCamera(cameraPosition);
  }

  _setMarkers(Set<Marker> markers) {
    setState(() {
      _mapMarkers = markers;
    });
  }

  _setProviderCommittedStatus() async {
    _displayBoxAddressDestination = false;
    showPanel = true;

    _changeMainButton(tProviderOnTheWay, nop);

    final bloc = context.read<ScheduleCustomerBloc>();
    final driverUserId = bloc.state.currentRequest!.provider!.userId;
    final driverInformation = await bloc.getDriverInfo(driverUserId);
    bloc.state.driverInfo = driverInformation;
    final consumerLatitude = _getRequestCustomerLat();
    final consumerLongitude = _getRequestCustomerLon();
    final consumerHeading = 0.0;

    final providerLatitude = _getRequestProviderLat();
    final providerLongitude = _getRequestProviderLon();
    final providerHeading = _getRequestProviderHeading();

    final consumerMarker = new MapMarker(
      LatLng(consumerLatitude, consumerLongitude),
      consumerHeading,
      'assets/images/car_pin.png',
      tYourLocation
    );

    final providerMarker = new MapMarker(
      LatLng(providerLatitude, providerLongitude),
      providerHeading,
      'assets/images/truck_icon.png',
      tProvider
    );

    _centerMapOnMarkers(providerMarker, consumerMarker);
  }

  _setProviderNotCalledStatus() {
    _displayBoxAddressDestination = true;
    showPanel = false;

    _changeMainButton(tCallProvider, _callProvider);

    final locationBloc = context.read<LocationBloc>();
    final currentLocation = locationBloc.state.currentLocation;
    final customerLocationNotSet = currentLocation == null;
    // final customerLocationNotSet = !_bloc.isCurrentLocationSet();
    if (customerLocationNotSet) {
      // TODO: Reaching this space likely means that _bloc.currentLocation needs to be seeded upon initialization.
      DebugService.pr('Customer location is NOT set', '_setProviderNotCalledStatus');
      throw Exception('This should hopefully be unreachable.');
    }

    DebugService.pr('Customer location is set', '_setProviderNotCalledStatus');

    // final currentLocation = _bloc.currentLocation!;
    _addCustomerMarkerToMap(currentLocation!);

    final cameraPosition = CameraPosition(
      target: LatLng(
        currentLocation.latitude,
        currentLocation.longitude
      ),
      zoom: 15 // changed from 18 - way too close
    );

    _moveCamera(cameraPosition);
  }

  _setProviderTowing() {
    _displayBoxAddressDestination = false;
    showPanel = false;

    _changeMainButton(tProviderTowing, nop);

    final originLat = _getRequestProviderLat();
    final originLon = _getRequestProviderLon();
    final originHeading = _getRequestProviderHeading();

    final destinationLat = _getRequestDestLat();
    final destinationLon = _getRequestDestLon();
    final destinationHeading = 0.0;

    final originMarker = MapMarker(
      LatLng(originLat, originLon),
      originHeading,
      'assets/images/car_pin.png',
      'meh what?' // TODO
    );

    final destMarker = MapMarker(
      LatLng(destinationLon, destinationLat),
      destinationHeading,
      'assets/images/truck_pin.png',
      'meh what?' // TODO
    );

    _displayTwoMarkers(originMarker, destMarker);
  }

  _setWaitingForProviderStatus() {
    showPanel = false;

    // final currentRequestNotSet = _currentRequest == null;
    final currentRequest = context.read<ScheduleCustomerBloc>().state.currentRequest;
    final currentRequestNotSet = currentRequest == null;
    // final currentRequestNotSet = !_bloc.isRequestSetRaw();
    if (currentRequestNotSet) {
      throw Exception('Current request data not set.');
    }

    _displayBoxAddressDestination = false;

    _changeMainButton(tCancel, _confirmCancellation);

    final latitude = _getRequestCustomerLat();
    final longitude = _getRequestCustomerLon();

    final location = new Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    _addCustomerMarkerToMap(location);

    final cameraPosition = new CameraPosition(
      target: LatLng(location.latitude, location.longitude),
      zoom: 20
    );
    _moveCamera(cameraPosition);
  }

  final fakeRequestId = 'KrsyCA8JVJz5nSoLUv1A';

  // TODO: Remove once this test function is no longer needed.
  _fakeProviderAcceptJob() {
    MockService.fakeProviderAcceptJob(fakeRequestId);
  }
  // TODO: Remove once this test function is no longer needed.
  _undoFakeProviderAcceptJob() {
    //! Actually, this can be repurposed as the 'provider quit' functionality.
    MockService.undoFakeProviderAcceptJob(fakeRequestId);
  }

  @override
  Widget build(BuildContext screenContext) {
    return BlocListener<ScheduleCustomerBloc, RequestParticipantState>(
      listener: (blocContext, state) async {

        //! From original switch case Rx.combineLatest2(_bloc.currentRequestStream, _bloc.currentLocationStream,
        //! Does this still matter?
        //!!! I think this only applies to the provider view.
        // if (state.currentRequest == null) {
        //   // Request set to null from previous logout.
        //   return;
        // }

        final bloc = screenContext.read<ScheduleCustomerBloc>();
        final currentViewState = bloc.state.viewState;

        // final nextViewState = state.viewState;
        final nextViewState = bloc.getViewStateWithPotentiallyNoCurrentRequest();
        final isViewStateChange = currentViewState != nextViewState;
        if (isViewStateChange) {
          DebugService.pr('Does this ever occur? Can I just rely on request status?', 'ProviderEngaged.BlocListener');
        }

        switch (nextViewState) {
          case ViewState.PROVIDER_NOT_CALLED:
            _setProviderNotCalledStatus();
            break;
          case ViewState.WAITING_FOR_PROVIDER:
            _setWaitingForProviderStatus();
            break;
          case ViewState.PROVIDER_COMMITTED:
            await _setProviderCommittedStatus();
            break;
          case ViewState.PROVIDER_AT_SCENE:
            throw Exception('Not implemented');
          case ViewState.PROVIDER_TOWING:
            _setProviderTowing();
            break;
          case ViewState.JOB_FINISHED:
            _setJobFinishedStatus();
            break;
          case ViewState.CUSTOMER_CANCELED:
          case ViewState.PROVIDER_CANCELED:
          case ViewState.CUSTOMER_CANCELED_AFTER_PROVIDER_CANCELED:
            break;
          default:
            final error = 'Reached not implemented state.';

            DebugService.pr(error, 'ScheduleCustomer.BlocListener');
            throw Exception(error);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tOmgYourACustomer),
          actions: [
            PopupMenuButton<String>(
              itemBuilder: (context) =>
                _menuItems
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
          // padding: EdgeInsets.all(32),
          child: Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _camera,
                onMapCreated: _handleMapCreated,
                myLocationButtonEnabled: false,
                markers: _mapMarkers,
                zoomControlsEnabled: false,
              ),
              Visibility(
                visible: _displayBoxAddressDestination,
                child: Stack(
                  children: [
                    // Positioned(
                    //   left: 0,
                    //   top: 0,
                    //   right: 0,
                    //   // bottom: 0,
                    //   child: Padding(
                    //     padding: EdgeInsets.all(10),
                    //     child: Container(
                    //       height: 60,
                    //       width: double.infinity,
                    //       decoration: BoxDecoration(
                    //         border: Border.all(color: Colors.pink),
                    //         borderRadius: BorderRadius.circular(6),
                    //         color: Colors.teal,
                    //       ),
                    //       child: TextField(
                    //         readOnly: true,
                    //         decoration: InputDecoration(
                    //           border: InputBorder.none,
                    //           contentPadding: EdgeInsets.only(left: 15, top: 15),
                    //           hintText: tYouAreHere,
                    //           icon: Container(
                    //             width: 10,
                    //             height: 10,
                    //             margin: EdgeInsets.only(left: 10),
                    //             child: Icon(
                    //               Icons.location_on,
                    //               color: Colors.purple,
                    //             )
                    //           )
                    //         ),
                    //       )
                    //     ),
                    //   ),
                    // ),
                    Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      // bottom: 0,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        child: Container(
                          height: 60,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white
                          ),
                          child: TextField(
                            controller: _destinationField,
                            // onChanged: ,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(left: 15, top: 15),
                              hintText: tChooseYourDestination,
                              icon: Container(
                                height: 10,
                                width: 10,
                                margin: EdgeInsets.only(left: 25),
                                child: Icon(
                                  Icons.store,
                                  color: Colors.grey,
                                )
                              )
                            )
                          )
                        )
                      )
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: Platform.isIOS
                    ? EdgeInsets.fromLTRB(20, 10, 20, 30)
                    : EdgeInsets.all(5),
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Why can't I plug this into onPressed directly?
                      _buttonFn();
                    },
                    child: Text(
                      _buttonText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20
                      ),
                    ),
                  ),
                ),
              ),

              if (showPanel)
                CustomerPanel(),
            ],
          ),
        ),
      )
    );
  }
}
