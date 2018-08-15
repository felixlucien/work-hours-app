import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_circular_chart/flutter_circular_chart.dart';
import 'package:work_hours/fragments/state_manager.dart';
import 'package:work_hours/services/client_manager.dart';

class StopWatchFragment extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => StopWatchFragmentState();
}

class StopWatchFragmentState extends State<StopWatchFragment> {
  bool isPausing = false, isRunning = false;
  ClientManagerService clientManagerService;
  GlobalKey<StopWatchState> stopWatchKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    clientManagerService = StateManager.of(context).clientManagerService;

    isRunning = clientManagerService.timingData["currentlyTiming"];
    isPausing = clientManagerService.timingData["currentlyPausing"];

    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Timer'),
        ),
        body: new Container(
            padding: EdgeInsets.all(20.0),
            child: new Column(
              children: <Widget>[
                StopWatchWidget(stopWatchKey,
                    isTiming: isRunning,
                    startTime: clientManagerService.timingData["startTime"],
                    pauseBuffer:
                        clientManagerService.timingData["pauseBuffer"]),
                SizedBox(height: 20.0),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new FloatingActionButton(
                        backgroundColor: Colors.green,
                        onPressed: () async {
                          if (!isRunning) {
                            var timingData =
                                await clientManagerService.startTiming();

                            stopWatchKey.currentState.start(
                                DateTime.parse(timingData["startTime"]),
                                timingData["pauseBuffer"]);
                            isRunning = true;
                          } else {
                            if (!isPausing) {
                              clientManagerService.startPause();
                              stopWatchKey.currentState.stop();
                              isPausing = true;
                            } else {
                              var timing =
                                  await clientManagerService.stopPause();
                              stopWatchKey.currentState.start(
                                  DateTime.parse(timing["startTime"]),
                                  timing["pauseBuffer"]);
                              isPausing = false;
                            }
                          }
                        },
                        child: new Icon(isPausing && isRunning || !isRunning
                            ? Icons.play_arrow
                            : Icons.pause)),
                  ],
                ),
                SizedBox(height: 20.0),
                new RaisedButton(
                    onPressed: () {
                      if (isRunning) {
                        setState(() {
                          stopWatchKey.currentState.stop();
                        });

                        if (isPausing) {
                          isPausing = false;
                          clientManagerService.stopPause();
                        }

                        isRunning = false;
                        clientManagerService.stopTiming();

                        showDialog(
                          context: context,
                          builder: (context) => new AlertDialog(
                                title: new Text("Save"),
                                content: new Column(children: [
                                  new Text(
                                      "Please choose a client to save work to."),
                                  new Container(
                                      height: 128.0,
                                      child: new SingleChildScrollView(
                                          child: new Column(
                                              children: clientManagerService
                                                  .clients.map((client) {
                                        return new InkWell(
                                            child: ListTile(
                                                title:
                                                    new Text(client["name"])),
                                            onTap: () {
                                              stopWatchKey.currentState.reset();
                                              clientManagerService
                                                  .saveTiming(client["name"]);
                                              clientManagerService
                                                  .resetTiming();
                                              Navigator.pop(context);
                                            });
                                      }).toList()))),
                                ]),
                              ),
                        );
                      }
                      setState(() {});
                    },
                    child: new Text("Stop and save session")),
                SizedBox(height: 20.0)
              ],
            )));
  }
}

class StopWatchWidget extends StatefulWidget {
  bool isTiming;
  String startTime;
  List pauseBuffer;

  StopWatchWidget(GlobalKey key,
      {this.startTime,
      this.isTiming: false,
      this.pauseBuffer: const <String>[]})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      StopWatchState(isTiming, startTime, pauseBuffer);
}

class StopWatchState extends State<StopWatchWidget> {
  final GlobalKey<AnimatedCircularChartState> _chartKey =
      new GlobalKey<AnimatedCircularChartState>();

  var elapsedTime = "00:00:00";
  Timer timer;

  var isRunning = false;

  var totalPauseTimeSeconds = 0;

  StopWatchState(this.isRunning, String startTime, List pauseBuffer) {
    if (isRunning) {
      start(DateTime.parse(startTime), pauseBuffer);
    }
  }

  void start(DateTime start, List pauseBuffer) {
    totalPauseTimeSeconds = 0;
    if (pauseBuffer.isNotEmpty) {
      pauseBuffer.forEach((pause) {
        var buffer = pause.split("|TO|");
        var time =
            DateTime.parse(buffer[1]).difference(DateTime.parse(buffer[0]));
        totalPauseTimeSeconds += time.inSeconds;
      });
    }

    isRunning = true;
    timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      _chartKey.currentState.updateData(generateChartData(Duration(
          seconds: DateTime.now().difference(start).inSeconds -
              totalPauseTimeSeconds)));
      if (mounted) {
        setState(() {});
      }
    });
  }

  void stop() {
    isRunning = false;
    if (timer != null) {
      timer.cancel();
    }
  }

  void reset() {
    isRunning = false;
    if (timer != null) {
      timer.cancel();
    }
    _chartKey.currentState.updateData(generateChartData(Duration(seconds: 0)));
    if (mounted) {
      setState(() {});
    }
  }

  List<CircularStackEntry> generateChartData(Duration elapsed) {
    List<CircularStackEntry> data = [];
    var mins = elapsed.inMinutes - (60 * elapsed.inHours).floor();
    var seconds = elapsed.inSeconds - (60 * elapsed.inMinutes).floor();
    elapsedTime =
        "${elapsed.inHours}:${mins < 10 ? "0$mins" : "$mins"}:${seconds < 10 ? "0$seconds" : "$seconds"}";

    data.add(new CircularStackEntry(<CircularSegmentEntry>[
      new CircularSegmentEntry(elapsed.inHours / 12 * 100.0, Colors.red),
    ]));

    data.add(new CircularStackEntry(<CircularSegmentEntry>[
      new CircularSegmentEntry(mins / 60 * 100, Colors.blue),
    ]));

    data.add(new CircularStackEntry(<CircularSegmentEntry>[
      new CircularSegmentEntry(seconds / 60 * 100, Colors.green),
    ]));

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: new AnimatedCircularChart(
        key: _chartKey,
        size: const Size(250.0, 250.0),
        initialChartData: <CircularStackEntry>[],
        chartType: CircularChartType.Radial,
        edgeStyle: SegmentEdgeStyle.round,
        holeLabel: elapsedTime,
        percentageValues: true,
        labelStyle: Theme.of(context).textTheme.title,
      ),
    );
  }
}
