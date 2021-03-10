import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inherited_geolocation/src/status.dart';

import 'geolocation.dart';

/// Widget that builds itself based on the latest [Geolocation] status.
///
/// If a user location is available, the [available] builder is used, else the
/// [fallback] builder is used.
///
/// In any case, a default location is available, whether it is the real user location
/// or the fallback value provided by the [Geolocation].
class GeolocationBuilder extends StatelessWidget {
  const GeolocationBuilder({
    Key? key,
    required this.available,
    required this.fallback,
  }) : super(key: key);

  final GeolocationAvailableWidgetBuilder available;
  final GeolocationFallbackWidgetBuilder fallback;

  @override
  Widget build(BuildContext context) {
    final status = Geolocation.of(context);
    return status.maybeMap(
      available: (position) => available(context, position),
      orElse: () => fallback(
        context,
        status.fallback,
        status,
        Geolocation.controllerOf(context),
      ),
    );
  }
}

typedef GeolocationAvailableWidgetBuilder = Widget Function(
    BuildContext context, Position position);

typedef GeolocationFallbackWidgetBuilder = Widget Function(
  BuildContext context,
  Position fallbackPosition,
  GeolocationStatus status,
  GeolocationController controller,
);
