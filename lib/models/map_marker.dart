import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarker {
  LatLng location;
  double heading;
  String pathImage;
  String title;

  MapMarker(this.location, this.heading, this.pathImage, this.title);
}
