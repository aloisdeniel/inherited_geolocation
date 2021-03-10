import 'package:geolocator/geolocator.dart';
import 'package:equatable/equatable.dart';

abstract class GeolocationStatus extends Equatable {
  const GeolocationStatus._(this.fallback);

  final Position fallback;

  factory GeolocationStatus.notStarted(Position fallback) =>
      NotStartedStatus(fallback);

  factory GeolocationStatus.starting(Position fallback) =>
      StartingStatus(fallback);

  factory GeolocationStatus.disabled(Position fallback) =>
      DisabledStatus(fallback);

  factory GeolocationStatus.available(Position position) =>
      AvailableStatus(position);

  factory GeolocationStatus.permissionDenied(
    LocationPermission permission,
    Position fallback,
  ) =>
      PermissionDeniedStatus(permission, fallback);

  T map<T>({
    required T Function() notStarted,
    required T Function() starting,
    required T Function(bool serviceAvailable) disabled,
    required T Function(Position position) available,
    required T Function(LocationPermission permission) permissionDenied,
  }) {
    final value = this;
    if (value is PermissionDeniedStatus) {
      if (value.permission == LocationPermission.deniedForever) {
        return disabled(true);
      }
      return permissionDenied(value.permission);
    }
    if (value is AvailableStatus) {
      return available(value.position);
    }
    if (value is StartingStatus) {
      return starting();
    }
    if (value is DisabledStatus) {
      return disabled(false);
    }
    if (value is NotStartedStatus) {
      return notStarted();
    }
    return notStarted();
  }

  T maybeMap<T>({
    T Function()? notStarted,
    T Function()? starting,
    T Function(bool serviceAvailable)? disabled,
    T Function(Position position)? available,
    T Function(LocationPermission permission)? permissionDenied,
    required T Function() orElse,
  }) {
    final value = this;
    if (permissionDenied != null && value is PermissionDeniedStatus) {
      if (disabled != null &&
          value.permission == LocationPermission.deniedForever) {
        return disabled(true);
      } else {
        return permissionDenied(value.permission);
      }
    } else if (available != null && value is AvailableStatus) {
      return available(value.position);
    } else if (starting != null && value is StartingStatus) {
      return starting();
    } else if (disabled != null && value is DisabledStatus) {
      return disabled(false);
    } else if (notStarted != null && value is NotStartedStatus) {
      return notStarted();
    }
    return orElse();
  }

  @override
  List<Object?> get props => [fallback];
}

class NotStartedStatus extends GeolocationStatus {
  const NotStartedStatus(Position fallback) : super._(fallback);
}

class StartingStatus extends GeolocationStatus {
  const StartingStatus(Position fallback) : super._(fallback);
}

class DisabledStatus extends GeolocationStatus {
  const DisabledStatus(Position fallback) : super._(fallback);
}

class PermissionDeniedStatus extends GeolocationStatus {
  const PermissionDeniedStatus(this.permission, Position fallback)
      : super._(fallback);
  final LocationPermission permission;

  @override
  List<Object?> get props => [...super.props, permission];
}

class AvailableStatus extends GeolocationStatus {
  const AvailableStatus(this.position) : super._(position);
  final Position position;

  @override
  List<Object?> get props => [...super.props, position];
}
