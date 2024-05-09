import 'dart:math' show cos, sqrt, asin;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:t2t_flutter_prototype/models/lat_lon_bounds.dart';
import 'package:t2t_flutter_prototype/models/polyline_package.dart';
import 'package:t2t_flutter_prototype/services/debug_service.dart';

class MapService {
  // TODO: Genericize arg names if there's no reason not to.
  static getBounding(List<List<double>> markerLocations, List<PolylinePackage> polylinePackages) {

    final bounds = LatLonBounds();

    markerLocations.forEach((markerLocationTuple) {
      final lat = markerLocationTuple.first;
      final lon = markerLocationTuple.last;

      final newNorthmostBound = bounds.northBound == null || lat > bounds.northBound!;
      if (newNorthmostBound) {
        bounds.northBound = lat;
      }
      final newSouthmostBound = bounds.southBound == null || lat < bounds.southBound!;
      if (newSouthmostBound) {
        bounds.southBound = lat;
      }

      final newEastmostBound = bounds.eastBound == null || lon > bounds.eastBound!;
      if (newEastmostBound) {
        bounds.eastBound = lon;
      }
      final newWestmostBound = bounds.westBound == null || lon < bounds.westBound!;
      if (newWestmostBound) {
        bounds.westBound = lon;
      }
    });

    polylinePackages.forEach((package) {
      final packageIsIncomplete =
        package.northBound == null ||
        package.southBound == null ||
        package.westBound == null ||
        package.eastBound == null;
      if (packageIsIncomplete) {
        final error = 'Supplied package is incomplete.';

        DebugService.pr(error, 'getBounding');
        throw new Exception(error);
      }
      final packageNorthBound = package.northBound!;
      final packageSouthBound = package.southBound!;
      final packageEastBound = package.eastBound!;
      final packageWestBound = package.westBound!;

      final newNorthmostBound = bounds.northBound == null || packageNorthBound > bounds.northBound!;
      if (newNorthmostBound) {
        bounds.northBound = packageNorthBound;
      }
      final newSouthmostBound = bounds.southBound == null || packageSouthBound < bounds.southBound!;
      if (newSouthmostBound) {
        bounds.southBound = packageSouthBound;
      }

      final newEastmostBound = bounds.eastBound == null || packageEastBound > bounds.eastBound!;
      if (newEastmostBound) {
        bounds.eastBound = packageEastBound;
      }
      final newWestmostBound = bounds.westBound == null || packageWestBound < bounds.westBound!;
      if (newWestmostBound) {
        bounds.westBound = packageWestBound;
      }
    });

    final southwest = new LatLng(bounds.southBound!, bounds.westBound!);
    final northeast = new LatLng(bounds.northBound!, bounds.eastBound!);

    return [southwest, northeast];
  }

  static double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  static double calculateRouteDistance(List<LatLng> polylineCoordinates) {
    double totalDistance = 0.0;

    // Get distance by summing small segments together.
    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      totalDistance += _coordinateDistance(
        polylineCoordinates[i].latitude,
        polylineCoordinates[i].longitude,
        polylineCoordinates[i + 1].latitude,
        polylineCoordinates[i + 1].longitude,
      );
    }
    return totalDistance;
  }
}
