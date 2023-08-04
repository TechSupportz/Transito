import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:transito/models/app_colors.dart';
import 'package:transito/models/favourite.dart';
import 'package:transito/models/nearby_bus_stops.dart';
import 'package:transito/providers/favourites_service.dart';
import 'package:transito/providers/settings_service.dart';
import 'package:transito/screens/mrt_map_screen.dart';
import 'package:transito/screens/onboarding_screens/location_access_screen.dart';
import 'package:transito/screens/settings_screen.dart';
import 'package:transito/widgets/error_text.dart';

import '../../models/bus_stops.dart';
import '../../models/user_settings.dart';
import '../../widgets/bus_stop_card.dart';
import '../../widgets/favourites_timing_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const distance = Distance();

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin<HomeScreen> {
  late Future<List<NearbyBusStops>> nearbyBusStops;
  late Future<List<NearbyFavourites>> nearbyFavourites;
  late Future<bool> _isLocationPermissionGranted;
  bool isFabVisible = true;

  // sets the state of the FAB to hide or show depending if the user is scrolling in order to prevent blocking content
  bool hideFabOnScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      !isFabVisible ? setState(() => isFabVisible = true) : null;
    } else if (notification.direction == ScrollDirection.reverse) {
      isFabVisible ? setState(() => isFabVisible = false) : null;
    }

    return true;
  }

  // checks if the user has granted access to their location
  Future<bool> checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      return false;
    } else {
      return true;
    }
  }

  // gets the user's current location
  Future<Position> getUserLocation() async {
    debugPrint("Fetching user location");
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    debugPrint('$position');
    return position;
  }

  // fetches the bus stop json file from the assets folder and decodes it into a list of BusStops objects
  Future<List<BusStopInfo>> fetchBusStops() async {
    debugPrint("Fetching bus stops");
    final String response = await rootBundle.loadString('assets/bus_stops.json');
    return AllBusStops.fromJson(jsonDecode(response)).busStops;
  }

  Future<List<NearbyBusStops>> getNearbyBusStops() async {
    debugPrint("Fetching nearby bus stops");
    List<NearbyBusStops> _nearbyBusStops = [];
    Position userLocation = await getUserLocation();
    List<BusStopInfo> allBusStops = await fetchBusStops();

    // searches through the list of bus stops and returns those within 500m to the user's current location sorted by nearest to farthest
    for (var busStop in allBusStops) {
      LatLng busStopLocation = LatLng(busStop.latitude, busStop.longitude);
      double distanceAway = distance.as(
          LengthUnit.Meter, LatLng(userLocation.latitude, userLocation.longitude), busStopLocation);
      if (distanceAway <= 500) {
        _nearbyBusStops.add(NearbyBusStops(busStopInfo: busStop, distanceFromUser: distanceAway));
      }
    }
    List<NearbyBusStops> _tempNearbyBusStops = _nearbyBusStops;
    _tempNearbyBusStops.sort((a, b) => a.distanceFromUser.compareTo(b.distanceFromUser));
    return _tempNearbyBusStops;
  }

  // function to get the user's nearby favourites
  Future<List<NearbyFavourites>> getNearbyFavourites({
    bool refresh = false,
  }) async {
    debugPrint("Fetching nearby favourites");
    List<NearbyFavourites> _nearbyFavourites = [];
    List<Favourite> favouritesList =
        await FavouritesService().getFavourites(context.read<User>().uid);
    Position userLocation = await getUserLocation();

    // searches through the list of favourites and returns those within 750m to the user's current location sorted by nearest to farthest
    for (var favourite in favouritesList) {
      double distanceAway = distance.as(LengthUnit.Meter,
          LatLng(userLocation.latitude, userLocation.longitude), favourite.busStopLocation);
      if (distanceAway <= 750) {
        _nearbyFavourites
            .add(NearbyFavourites(busStopInfo: favourite, distanceFromUser: distanceAway));
      }
    }
    List<NearbyFavourites> _tempNearbyFavourites = _nearbyFavourites;
    _tempNearbyFavourites.sort((a, b) => a.distanceFromUser.compareTo(b.distanceFromUser));
    // _nearbyFavouritesCache = _tempNearbyFavourites;
    return _tempNearbyFavourites;
    // }
  }

  // function to get the list of all nearby bus stops
  void getAllNearby() async {
    print("Getting all nearby");
    // Position userLocation = await getUserLocation();

    setState(() {
      nearbyBusStops = getNearbyBusStops();
      nearbyFavourites = getNearbyFavourites();
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint("Initializing bus stops");
    _isLocationPermissionGranted = checkLocationPermissions();
    nearbyBusStops = getNearbyBusStops();
    nearbyFavourites = getNearbyFavourites();
  }

  @override
  Widget build(BuildContext context) {
    var user = context.watch<User?>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${user?.displayName ?? ''}'),
        actions: [
          // button to open the MRT map screen
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MrtMapScreen(),
              ),
            ),
            icon: const Icon(Icons.map_rounded),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            ),
            icon: const Icon(Icons.settings_rounded),
          )
        ],
      ),
      // notification listener to call the hideFabOnScroll function when the user scrolls
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) => hideFabOnScroll(notification),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 32, top: 12),
          child: FutureBuilder(
              future: _isLocationPermissionGranted,
              builder: (context, AsyncSnapshot<bool> snapshot) {
                // display a loading indicator while the user's location is being fetched
                if (snapshot.hasData) {
                  // if the user has granted access to their location, display the list of nearby bus stops
                  if (snapshot.data!) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        nearbyFavouritesList(),
                        nearbyBusStopsGrid(),
                      ],
                    );
                  } else {
                    // if the user has not granted access to their location, display a message to the user and a button to open the location access screen
                    return Material(
                      color: AppColors.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Center(
                          child: Column(
                            children: [
                              const Text(
                                "Please grant location permission to use this feature",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                  onPressed: () => Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LocationAccessScreen(),
                                      ),
                                      (route) => false),
                                  child: const Text("Grant permission")),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  );
                } else {
                  return const SizedBox(height: 0);
                }
              }),
        ),
      ),
      // floating action button to refresh user's location and nearbyBusStops
      floatingActionButton: isFabVisible
          ? FloatingActionButton(
              heroTag: "homeFAB",
              onPressed: () {
                getAllNearby();
                HapticFeedback.selectionClick();
              },
              child: const Icon(Icons.my_location_rounded),
            )
          : null,
    );
  }

  Column nearbyBusStopsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nearby",
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 12,
        ),
        StreamBuilder(
            stream: SettingsService().streamSettings(context.watch<User?>()?.uid),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                UserSettings userSettings = snapshot.data as UserSettings;
                return FutureBuilder(
                    future: nearbyBusStops,
                    builder: (BuildContext context, AsyncSnapshot<List<NearbyBusStops>> snapshot) {
                      // display a loading indicator while the list of nearby bus stops is being fetched
                      if (snapshot.hasData && snapshot.data != null) {
                        if (snapshot.data!.isNotEmpty) {
                          return GridView.count(
                            childAspectRatio: userSettings.isNearbyGrid ? 2.5 / 1 : 5 / 1,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: userSettings.isNearbyGrid ? 21 : 16,
                            crossAxisCount: userSettings.isNearbyGrid ? 2 : 1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              // loop through nearby bus stops and send their data to the BusStopCard widget to display them
                              for (var busStop in snapshot.data!)
                                BusStopCard(
                                  busStopInfo: busStop.busStopInfo,
                                  distanceFromUser: busStop.distanceFromUser,
                                  showDistanceFromUser: userSettings.showNearbyDistance ?? true,
                                ),
                            ],
                          );
                        } else {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 18.0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Text("No bus stops nearby",
                                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
                                ),
                              ),
                            ),
                          );
                        }
                      } else if (snapshot.hasError) {
                        // return Text("${snapshot.error}");
                        debugPrint("<=== ERROR ${snapshot.error} ===>");
                        return const ErrorText();
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 3),
                        );
                      }
                    });
              } else if (snapshot.hasError) {
                // return Text("${snapshot.error}");
                debugPrint("<=== ERROR ${snapshot.error} ===>");
                return const ErrorText();
              } else {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 3),
                );
              }
            })
      ],
    );
  }

  Column nearbyFavouritesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nearby Favourites",
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(
          height: 12,
        ),
        FutureBuilder(
          future: nearbyFavourites,
          builder: (BuildContext context, AsyncSnapshot<List<NearbyFavourites>> snapshot) {
            // display a loading indicator while the list of nearby favourites is being fetched
            if (snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
              // checks if user has any favourites within 750m of their current location and displays them if they do
              if (snapshot.data!.isNotEmpty) {
                return ListView.separated(
                  itemBuilder: (context, int index) {
                    return FavouritesTimingCard(
                      busStopCode: snapshot.data![index].busStopInfo.busStopCode,
                      busStopName: snapshot.data![index].busStopInfo.busStopName,
                      busStopAddress: snapshot.data![index].busStopInfo.busStopAddress,
                      busStopLocation: snapshot.data![index].busStopInfo.busStopLocation,
                      services: snapshot.data![index].busStopInfo.services,
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(
                    height: 18,
                  ),
                  padding: const EdgeInsets.only(bottom: 18.0),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                );
              } else {
                // if user has no favourites within 750m of their current location, display a message to tell them
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text("No favourites nearby",
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
                    ),
                  ),
                );
              }
            } else if (snapshot.hasError) {
              // return Text("${snapshot.error}");
              debugPrint("<=== ERROR ${snapshot.error} ===>");
              return const ErrorText();
            } else {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 3),
              );
            }
          },
        )
      ],
    );
  }
}
