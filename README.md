# inherited_geolocation

<p>
  <a href="https://pub.dartlang.org/packages/inherited_geolocation"><img src="https://img.shields.io/pub/v/inherited_geolocation.svg"></a>
  <a href="https://www.buymeacoffee.com/aloisdeniel">
    <img src="https://img.shields.io/badge/$-donate-ff69b4.svg?maxAge=2592000&amp;style=flat">
  </a>
</p>


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
class Example extends StatelessWidget {
  const Example({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Geolocation(
      child: GeolocationBuilder(
        available: (context, position) => Map(
          position: position,
          markerIcon: Icons.people,
        ),
        fallback: (context, fallbackPosition, status, controller) {
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
                denied: () => ElevatedButton(
                  onPressed: () => controller.start(),
                  child: Text('Geolocate me'),
                ),
                disabled: (_) => ElevatedButton(
                  onPressed: () => controller.openSystemSettings(),
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
