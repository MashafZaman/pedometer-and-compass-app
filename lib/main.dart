import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

void main() {
  runApp(
    MyApp()
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _steps = '?';
  bool _hasPermissions = false;
  CompassEvent? _lastRead;
  DateTime? _lastReadAt;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    fetchPermissionStatus();
  }

  void onStepCount(StepCount event) {
    print(event);
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream
        .listen(onStepCount)
        .onError(onStepCountError);

    if (!mounted) return;
  }

  void fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() => _hasPermissions = status == PermissionStatus.granted);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Flutter Compass'
          ),
        ),

        body:
        Builder(builder: (context) {
          if (_hasPermissions) {
            // Run if permissions are obtained
            return Column(
              children: <Widget>[
                // Build a reader that reads values of compass and displays them
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      /*Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            MaterialButton(
                              child: const Text(
                                  'Read Value',
                                  style: TextStyle(fontSize: 20, color: Colors.white)
                              ),
                              onPressed: () async {
                                final CompassEvent tmp = await FlutterCompass.events!.first;
                                setState(() {
                                  _lastRead = tmp;
                                  _lastReadAt = DateTime.now();
                                });
                              },
                            ),
                            Text(
                              '$_lastRead',
                              style: const TextStyle(fontSize: 25, color: Colors.grey),
                            ),
                            Text(
                              '$_lastReadAt',
                              style: const TextStyle(fontSize: 20, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),*/
                      Center(
                        child: Text(
                          'Steps taken: ${_steps.toString()}',
                          style: _steps == '?'
                              ? const TextStyle(fontSize: 25, color: Colors.grey)
                              : const TextStyle(fontSize: 25, color: Colors.blue),
                        ),
                      ),
                      Center(
                        child: Text(
                          'Pedestrian status: ${_status.toString()}',
                          style: _status == 'walking' || _status == 'stopped'
                              ? const TextStyle(fontSize: 25, color: Colors.blue)
                              : const TextStyle(fontSize: 25, color: Colors.red),
                        ),
                      ),
                      Center(
                        child: Icon(
                          _status == 'walking'
                              ? Icons.directions_walk
                              : _status == 'stopped'
                              ? Icons.accessibility_new
                              : Icons.error,
                          size: 50,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  // Build the compass
                  child: StreamBuilder<CompassEvent>(
                    stream: FlutterCompass.events,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          'Error reading heading: ${snapshot.error}'
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      double? direction = snapshot.data!.heading;
                      double? accuracy = snapshot.data!.accuracy;

                      // if direction is null, then device does not support this sensor
                      // show error message
                      if (direction == null) {
                        return const Center(
                          child: Text(
                              "Device does not have sensors !",
                              style: TextStyle(fontSize: 20, color: Colors.blue)
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Center(
                            child: Text(
                              "Heading: $direction\nAccuracy: $accuracy",
                              style: const TextStyle(fontSize: 20, color: Colors.grey)
                            ),
                          ),
                          Material(
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            elevation: 3.0,
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Transform.rotate(
                                angle: (direction * (math.pi / 180) * -1),
                                child: Image.asset('assets/compass.png'),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          }
          else {
            // In case of missing permissions, build permissions first
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                      'Location Permission Required'
                  ),
                  ElevatedButton(
                    child: const Text(
                        'Request Permissions'
                    ),
                    onPressed: () {
                      Permission.locationWhenInUse.request().then((ignored) {
                        fetchPermissionStatus();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    child: const Text(
                        'Open App Settings'
                    ),
                    onPressed: () {
                      openAppSettings().then((opened) {
                        //
                      });
                    },
                  )
                ],
              ),
            );
          }
        }),
      ),
    );
  }
/*

  Widget _buildPedometer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Steps taken:',
            style: TextStyle(fontSize: 30),
          ),
          Text(
            _steps */
/*== '?'
            ? _steps
            : (int.parse(initialSteps) - int.parse(_steps)).toString()*//*
,
            style: const TextStyle(fontSize: 30),
          ),
          const Divider(
            height: 100,
            thickness: 0,
            color: Colors.white,
          ),
          const Text(
            'Pedestrian status:',
            style: TextStyle(fontSize: 20),
          ),
          Icon(
            _status == 'walking'
                ? Icons.directions_walk
                : _status == 'stopped'
                ? Icons.accessibility_new
                : Icons.error,
            size: 100,
          ),
          Center(
            child: Text(
              _status,
              style: _status == 'walking' || _status == 'stopped'
                  ? const TextStyle(fontSize: 10, color: Colors.blue)
                  : const TextStyle(fontSize: 10, color: Colors.red),
            ),
          )
        ],
      ),
    );
  }
*/
}
