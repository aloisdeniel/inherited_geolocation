import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:geolocator/geolocator.dart';
import 'package:inherited_geolocation/inherited_geolocation.dart';
import 'package:locale_latlng/locale_latlng.dart';
import 'status.dart';

typedef GeolocationFallbackBuilder = Position Function(BuildContext context);

/// A widget that provides user's geolocation to its widget subtree.
///
/// The widget automatically asks for user's permission as soon as [requestPermissionIfNeeded] is set to `true`.
///
/// Any of the [child]'s descendant can access the geolocation status by using `Geolocation.of(context)` method.
///
///
///
/// If [isEnabled] is `false`, no geolocation is get.
class Geolocation extends StatelessWidget {
  const Geolocation({
    Key? key,
    required this.child,
    this.requestPermissionIfNeeded = true,
    this.isObserving = true,
    this.isEnabled = true,
    this.stopWhileInBackground = true,
    this.fallbackBuilder = defaultGeolocationFallbackBuilder,
    this.onStatusChanged,
    this.controller,
  }) : super(key: key);

  final Widget child;
  final bool isObserving;
  final bool isEnabled;
  final bool stopWhileInBackground;
  final bool requestPermissionIfNeeded;
  final GeolocationFallbackBuilder fallbackBuilder;
  final ValueChanged<GeolocationStatus>? onStatusChanged;
  final GeolocationController? controller;

  /// Get the current geolocation status.
  static GeolocationStatus of(BuildContext context, {bool listen = true}) {
    final inherited = (listen
        ? context.dependOnInheritedWidgetOfExactType<_InheritedGeolocation>()
        : context
            .getElementForInheritedWidgetOfExactType<_InheritedGeolocation>()
            ?.widget) as _InheritedGeolocation?;

    if (inherited == null) {
      throw Exception('No Geolocation found in widget tree');
    }

    return inherited.status;
  }

  static GeolocationController controllerOf(BuildContext context) {
    final inherited = context.findAncestorStateOfType<_GeolocationState>();

    if (inherited == null) {
      throw Exception('No Geolocation found in widget tree');
    }

    return inherited._controller!;
  }

  @override
  Widget build(BuildContext context) {
    return _Geolocation(
      isEnabled: isEnabled,
      stopWhileInBackground: stopWhileInBackground,
      isObserving: isObserving,
      controller: controller,
      fallbackPosition: fallbackBuilder(context),
      requestPermissionIfNeeded: requestPermissionIfNeeded,
      onStatusChanged: onStatusChanged,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty(
        'requestPermissionIfNeeded',
        requestPermissionIfNeeded,
      ),
    );
  }
}

/// Gets the country's location from the current [Locale].
Position defaultGeolocationFallbackBuilder(BuildContext context) {
  final locale = Localizations.localeOf(context);
  final countryLocation = findLocation(
    countryCode: locale.countryCode ?? 'us',
  )!;
  return Position(
    accuracy: 0.01,
    altitude: 13.0,
    heading: 0.0,
    latitude: countryLocation.latitude,
    longitude: countryLocation.longitude,
    speed: 0.0,
    speedAccuracy: 0.0,
    timestamp: DateTime.fromMicrosecondsSinceEpoch(0),
    floor: 0,
    isMocked: true,
  );
}

class _Geolocation extends StatefulWidget {
  const _Geolocation({
    Key? key,
    required this.requestPermissionIfNeeded,
    required this.child,
    required this.isObserving,
    required this.isEnabled,
    required this.fallbackPosition,
    required this.stopWhileInBackground,
    required this.onStatusChanged,
    required this.controller,
  }) : super(key: key);

  final Widget child;
  final bool isObserving;
  final bool isEnabled;
  final Position fallbackPosition;
  final bool requestPermissionIfNeeded;
  final bool stopWhileInBackground;
  final ValueChanged<GeolocationStatus>? onStatusChanged;
  final GeolocationController? controller;

  @override
  _GeolocationState createState() => _GeolocationState();
}

class _GeolocationState extends State<_Geolocation>
    with WidgetsBindingObserver {
  StreamSubscription<Position>? _updates;
  Position? _lastKnownPosition;
  GeolocationController? _controller;

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    _lastKnownPosition = widget.fallbackPosition;
    _controller = widget.controller ?? GeolocationController();
    _controller!._state = this;
    _controller!.status = GeolocationStatus.notStarted(widget.fallbackPosition);
    if (widget.isEnabled) {
      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
        _startObservingStatus(
            widget.isObserving, widget.requestPermissionIfNeeded);
      });
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant _Geolocation oldWidget) {
    final wasObserving = oldWidget.isEnabled && oldWidget.isObserving;
    final isObserving = widget.isEnabled && widget.isObserving;

    if (!wasObserving && isObserving) {
      _startObservingStatus(true, widget.requestPermissionIfNeeded);
    } else if (wasObserving && !isObserving) {
      _updates?.cancel();
      _updates = null;
      _updateStatus(GeolocationStatus.notStarted(_lastKnownPosition!));
    }

    if (widget.controller != _controller) {
      _controller?._state = null;
      _controller = widget.controller;
      _controller!._state = this;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.stopWhileInBackground) {
      switch (state) {
        case AppLifecycleState.detached:
        case AppLifecycleState.paused:
          _stopObservingStatus();
          break;
        case AppLifecycleState.resumed:
          if (widget.isEnabled && widget.isObserving) {
            _startObservingStatus(widget.isObserving, false);
          }
          break;
        case AppLifecycleState.inactive:
          break;
      }
    }
  }

  void _updateStatus(GeolocationStatus status) {
    if (_controller!.status != status && mounted) {
      setState(() {
        status.maybeMap(
          available: (position) => _lastKnownPosition = position,
          orElse: () {},
        );
        _controller!.status = status;
      });
      widget.onStatusChanged?.call(status);
    }
  }

  Future<void> _stopObservingStatus() async {
    if (_updates != null) {
      _updateStatus(GeolocationStatus.notStarted(_lastKnownPosition!));
      await _updates!.cancel();
      _updates = null;
    }
  }

  Future<void> _startObservingStatus(
      bool observe, bool requestPermission) async {
    if (_controller!.status.maybeMap(
      available: (_) => false,
      starting: () => false,
      orElse: () => true,
    )) {
      LocationPermission permission;
      _updates = null;
      _updateStatus(GeolocationStatus.starting(widget.fallbackPosition));

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _updateStatus(GeolocationStatus.disabled(widget.fallbackPosition));
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        _updateStatus(GeolocationStatus.permissionDenied(
          permission,
          widget.fallbackPosition,
        ));
        return;
      }

      if (permission == LocationPermission.denied) {
        if (requestPermission) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          _updateStatus(GeolocationStatus.permissionDenied(
            permission,
            widget.fallbackPosition,
          ));
          return;
        }
      }
      final newPosition = await Geolocator.getCurrentPosition();

      if (observe && _updates == null) {
        _updateStatus(GeolocationStatus.available(newPosition));
        _updates = Geolocator.getPositionStream().listen(
          (newPosition) {
            _updateStatus(GeolocationStatus.available(newPosition));
          },
          onDone: () {
            _updates = null;
            _updateStatus(GeolocationStatus.notStarted(_lastKnownPosition!));
          },
          onError: (e) {
            _updates = null;
            _updateStatus(GeolocationStatus.notStarted(_lastKnownPosition!));
          },
        );
      } else {
        _updateStatus(GeolocationStatus.notStarted(newPosition));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _controller!._state = null;
    _updates?.cancel();
    _updates = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedGeolocation(
      status: _controller!.status,
      child: widget.child,
    );
  }
}

class _InheritedGeolocation extends InheritedWidget {
  const _InheritedGeolocation({
    Key? key,
    required this.status,
    required Widget child,
  }) : super(
          key: key,
          child: child,
        );

  final GeolocationStatus status;

  @override
  bool updateShouldNotify(covariant _InheritedGeolocation oldWidget) {
    return status != oldWidget.status;
  }
}

class GeolocationController extends ChangeNotifier {
  GeolocationStatus? _status;
  GeolocationStatus get status {
    if (_state == null) {
      throw Exception('The controller isn\' associated to a Geolocation');
    }
    if (_status == null) {
      throw Exception('The geolocation hasn\'t been initialized yet');
    }
    return _status!;
  }

  set status(GeolocationStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }

  _GeolocationState? _state;

  /// Starts to update geolocation updates.
  ///
  /// If the user had denied access or the service was disabled at first try,
  /// it will try again to get access to location.
  void start() {
    final state = _state;
    if (state == null) {
      throw Exception('The controller isn\' associated to a Geolocation');
    }
    assert(
        state.widget.isEnabled, 'Associated Geolocation widget is disabled.');
    state._startObservingStatus(
        state.widget.isObserving, state.widget.requestPermissionIfNeeded);
  }

  /// Open the system settings to help changing the permissions.
  Future<void> openSystemSettings() {
    return status.maybeMap(
      disabled: (isServiceAvailable) async {
        if (!isServiceAvailable) {
          await Geolocator.openLocationSettings();
        } else {
          await Geolocator.openAppSettings();
        }
      },
      orElse: () async {
        await Geolocator.openAppSettings();
      },
    );
  }
}
