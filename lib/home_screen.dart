import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:location/location.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<Position> _currentLocation;
  double latitude = 0;
  double longitude = 0;
  bool _showServiceSelection = false;
  bool _showServiceForm = false;

  bool get showServiceSelection => _showServiceSelection;
  bool get showServiceForm => _showServiceForm;

  void _toggleServiceSelection() {
    setState(() {
      _showServiceSelection = !_showServiceSelection;
    });
  }

  void _toggleServiceForm() {
    setState(() {
      _showServiceForm = !_showServiceForm;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentLocation = _determinePosition();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    var mapController = MapController();

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(10.0), // Set the height to 10 pixels
        child: AppBar(
          // AppBar content here, but keep in mind it will be constrained
        ),
      ),
      drawer: SizedBox(
        width: 150, // Set the width of the drawer to 200 pixels
        child: Drawer(
          child: ListView(
            // Add drawer contents here
            children: <Widget>[
              const SizedBox(
                height: 100,

                child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Align(
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,

                      ),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.account_circle), // Add the account icon here
                title: const Text('Account'),
                onTap: () {
                  // Handle drawer item tap
                },
              ),
              ListTile(
                leading: const Icon(Icons.history), // Add the account icon here
                title: const Text('History'),
                onTap: () {
                  // Handle drawer item tap
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings), // Add the account icon here
                title: const Text('Settings'),
                onTap: () {
                  // Handle drawer item tap
                },
              ),
              // Add more list items as needed
            ],
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          FutureBuilder<Position>(
            future: _currentLocation,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // While waiting for the location, show a loading spinner
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                // If we run into an error, display it
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                // Once the future is completed, build the FlutterMap with the data
                final position = snapshot.data!;
                latitude = position.latitude;
                longitude = position.longitude;

                return FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: LatLng(latitude, longitude),
                    initialZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    CurrentLocationLayer(),
                  ],
                );
              } else {
                // This should never happen, but just in case
                return const Center(child: Text("Unexpected error!"));
              }
            },
          ),
          Positioned(
            top: 10,
            left: 10,
            child: FloatingActionButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              mini: true, // Hamburger icon
              heroTag: null,
              child: const Icon(Icons.menu), // Disable hero animation by setting heroTag to null
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Column(
              children: <Widget>[
                FloatingActionButton(
                  onPressed: () {
                    mapController.move(
                        mapController.camera.center, mapController.camera.zoom + 0.5);
                  },
                  mini: true,
                  heroTag: null,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () {
                    mapController.move(
                        mapController.camera.center, mapController.camera.zoom - 0.5);
                  },
                  mini: true,
                  heroTag: null,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: () {
                    mapController.move(
                        LatLng(latitude, longitude), mapController.camera.zoom);
                  },
                  mini: true,
                  heroTag: null,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10, // Adjust the value to position the button as desired
            child: Center(
              child: SizedBox(
                height: 80, // Set the desired height
                width: 160, // Set the desired width
                child: ElevatedButton(
                  onPressed: () {
                    _toggleServiceSelection();
                    // setState(() {
                    //   isFormVisible = !isFormVisible;
                    // });
                  },
                  child: const Text('Book a Service'),
                ),
              ),
            ),
          ),
          Visibility(
            visible: _showServiceSelection,
            child: GestureDetector(
              onTap: _toggleServiceSelection,
              child: ServiceSelectionList(
                toggleServiceSelection: _toggleServiceSelection,
                toggleServiceForm: _toggleServiceForm,
                showServiceSelection: showServiceSelection,
                showServiceForm: showServiceForm,
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class ServiceSelectionList extends StatelessWidget {
  final VoidCallback toggleServiceSelection;
  final VoidCallback toggleServiceForm;
  final bool showServiceSelection;
  final bool showServiceForm;

  const ServiceSelectionList({
    super.key,
    required this.toggleServiceSelection,
    required this.toggleServiceForm,
    required this.showServiceSelection,
    required this.showServiceForm,
  });

  @override
  Widget build(BuildContext context) {


    if (showServiceSelection && showServiceForm){
      return buildServiceForm(context);
    }
    else if (showServiceSelection && !showServiceForm){
      return buildServiceSelectionList();
    }
    else {
      return Container();
    }
  }

  Widget buildServiceSelectionList() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 400,
        height: 300,
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Center( // Centering the ListTile horizontally (if it has a constrained width)
              child: SizedBox(
                width: double.infinity, // Taking full width of the parent
                child: ListTile(
                  title: const Center(child: Text('Car cleaning')), // Centering text inside the ListTile
                  onTap: () {
                    // Handle service selection
                  },
                ),
              ),
            ),
            Center( // Repeat for each ListTile
              child: SizedBox(
                width: double.infinity,
                child: ListTile(
                  title: const Center(child: Text('Driver buddy after drinking')),
                  onTap: () {
                    // Handle service selection
                  },
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ListTile(
                  title: const Center(child: Text('Dry cleaning')),
                  onTap: () {
                    // toggleServiceSelection();
                    toggleServiceForm();
                  },
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ListTile(
                  title: const Center(child: Text('Talking buddy')),
                  onTap: () {
                    // Handle service selection
                  },
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ListTile(
                  title: const Center(child: Text('Special Request')),
                  onTap: () {
                    // Handle service selection
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildServiceForm(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Stack(
        children: [
          // Form Container
          Container(
            width: 400,
            height: 500,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // To wrap the content in the column
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Input 2',
                      ),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Input 3',
                      ),
                    ),
                    const SizedBox(height: 10), // Space between the form fields and the buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Add space between buttons
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Handle new button action
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero, // Removes default padding around the icon
                            minimumSize: const Size(40, 36), // Minimum touch target size
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: toggleServiceForm, // Calls toggleServiceForm when pressed
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            // Handle form submission
                          },
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }




}



