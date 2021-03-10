import 'package:flutter/material.dart';
import 'package:inherited_geolocation/inherited_geolocation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Geolocation demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Example(),
    ),
  );
}

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

class Message extends StatelessWidget {
  const Message(
    this.text, {
    Key? key,
  }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

class Map extends StatelessWidget {
  const Map({
    Key? key,
    required this.position,
    required this.markerIcon,
  }) : super(key: key);

  final Position position;
  final IconData markerIcon;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(),
      layers: [
        TileLayerOptions(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayerOptions(
          markers: [
            Marker(
              width: 60.0,
              height: 60.0,
              point: LatLng(
                position.latitude,
                position.longitude,
              ),
              builder: (ctx) => Container(
                child: Icon(markerIcon),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
