import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/colors.dart';

/// Google Maps screen adapted from madpcpsgit2026.
///
/// Displays a Google Map centered on a default location with a marker,
/// bottom sheet preview on marker tap, and a FAB to animate to a second
/// location (the lake / campus area).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _kLake = CameraPosition(
    bearing: 192.8334901395799,
    target: LatLng(27.68464068736057, 85.31694662362598),
    tilt: 59.440717697143555,
    zoom: 19.151926040649414,
  );

  var showBottomSheet = false;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Map'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kLake,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: {
              Marker(
                markerId: const MarkerId("1"),
                draggable: true,
                onDragEnd: (changed) {},
                onTap: () {
                  setState(() {
                    showBottomSheet = !showBottomSheet;
                  });
                },
                infoWindow: const InfoWindow(
                  title: "PCPS",
                ),
                position: const LatLng(27.68464068736057, 85.31694662362598),
              ),
            },
          ),
          Positioned(
            bottom: 40,
            child: showBottomSheet
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(10),
                          height: size.height / 4.5,
                          width: size.width / 1.6,
                          color: Colors.grey,
                        ),
                        Container(
                          margin: const EdgeInsets.all(10),
                          height: size.height / 4.5,
                          width: size.width / 1.6,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  )
                : Container(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: const Text('To the lake!'),
        icon: const Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}
