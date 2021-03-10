# inherited_geolocation

An inherited widget that manages geolocation updates from the user.

## Install

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
    inherited_geolocation: <version>
```

Make sure to update your manifest like described on [geolocator's plugin page](https://pub.dev/packages/geolocator#usage). **Some Android and iOS specifics are required for the geolocator to work correctly**.

## Quickstart

```dart
class Example extends StatefulWidget {
  const Example({
    Key? key,
  }) : super(key: key);

  @override
  _ExampleState createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  GeolocationController? _controller;

  @override
  void initState() {
    _controller = GeolocationController();
    super.initState();
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Geolocation(
      controller: _controller,
      child: GeolocationBuilder(
        available: (context, position) => Map(
          position: position,
          markerIcon: Icons.people,
        ),
        fallback: (context, fallbackPosition, status) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Map(
                  position: fallbackPosition,
                  markerIcon: Icons.help_outlined,
                ),
              ),
              status.maybeMap(
                permissionDenied: (permission) => ElevatedButton(
                  onPressed: () => _controller!.start(),
                  child: Text('Geolocate me ($permission)!'),
                ),
                disabled: (_) => ElevatedButton(
                  onPressed: () => _controller!.openSystemSettings(),
                  child: Text('Verify my system settings'),
                ),
                orElse: () => Message('Loading'),
              ),
            ],
          );
        },
      ),
    );
  }
}
```