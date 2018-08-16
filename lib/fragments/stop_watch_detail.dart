import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_circular_chart/flutter_circular_chart.dart';
import 'package:work_hours/fragments/state_manager.dart';
import 'package:work_hours/services/client_manager.dart';
import 'package:work_hours/services/utils.dart';

class StopWatchFragment extends StatefulWidget {
  String targetClient;

  StopWatchFragment({this.targetClient});

  @override
  State<StatefulWidget> createState() => StopWatchFragmentState(targetClient);
}

class StopWatchFragmentState extends State<StopWatchFragment> {
  bool isRunning = false;
  ClientManagerService clientManagerService;
  GlobalKey<StopWatchState> stopWatchKey = new GlobalKey();
  String targetClient;
  DateTime startTime;

  StopWatchFragmentState(this.targetClient);

  @override
  Widget build(BuildContext context) {
    clientManagerService = StateManager.of(context).clientManagerService;

    isRunning = clientManagerService.timingData["currentlyTiming"];

    if (isRunning) {
      startTime = DateTime.parse(clientManagerService.timingData["startTime"]);
    }

    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Timer'),
        ),
        body: new Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.0),
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                StopWatchWidget(stopWatchKey,
                    isTiming: isRunning,
                    startTime: clientManagerService.timingData["startTime"],
                    pauseBuffer:
                        clientManagerService.timingData["pauseBuffer"]),
                SizedBox(height: 20.0),
                Text(startTime == null
                    ? ""
                    : "Started at: ${TimeUtils.dateTimeToLocalTime(startTime)}"),
                SizedBox(height: 20.0),
                new FloatingActionButton(
                    backgroundColor: isRunning ? Colors.red : Colors.green,
                    onPressed: () async {
                      if (!isRunning) {
                        var timingData =
                            await clientManagerService.startTiming();

                        stopWatchKey.currentState.start(
                            DateTime.parse(timingData["startTime"]),
                            timingData["pauseBuffer"]);
                        isRunning = true;
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => new AlertDialog(
                                  title: new Text("Confirm action."),
                                  content: new Text(
                                      "Are you sure you want to stop timing?"),
                                  actions: [
                                    new FlatButton(
                                        child: new Text("Ok"),
                                        onPressed: () {
                                          stopWatchKey.currentState.stop();
                                          isRunning = false;
                                          clientManagerService.stopTiming();

                                          Navigator.pop(context);

                                          if (targetClient != null) {
                                            stopWatchKey.currentState.reset();
                                            clientManagerService
                                                .saveTiming(targetClient);
                                            clientManagerService.resetTiming();
                                          } else {
                                            showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder:
                                                  (context) => new AlertDialog(
                                                        title: new Text("Save"),
                                                        content: new Column(
                                                            children: [
                                                              new Text(
                                                                  "Please choose a client to save work to."),
                                                              new Container(
                                                                  child: new SingleChildScrollView(
                                                                      child: new Column(
                                                                          mainAxisSize: MainAxisSize.max,
                                                                          children: clientManagerService.clients.map((client) {
                                                                            return new InkWell(
                                                                                child: ListTile(title: new Text(client["name"])),
                                                                                onTap: () {
                                                                                  stopWatchKey.currentState.reset();
                                                                                  clientManagerService.saveTiming(client["name"]);
                                                                                  clientManagerService.resetTiming();
                                                                                  isRunning = false;
                                                                                  startTime = null;

                                                                                  Navigator.pop(context);
                                                                                  setState(() {});
                                                                                });
                                                                          }).toList()))),
                                                            ]),
                                                      ),
                                            );
                                          }
                                        }),
                                    new FlatButton(
                                        child: new Text("Cancel"),
                                        onPressed: () => Navigator.pop(context))
                                  ]),
                        );
                        setState(() {});
                      }
                    },
                    child: new Icon(isRunning ? Icons.stop : Icons.play_arrow)),
                new SizedBox(height: 20.0),
                new Text(targetClient == null
                    ? ""
                    : "Currently set to save to client ${targetClient}")
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
      if (mounted) {
        setState(() {
          _chartKey.currentState.updateData(generateChartData(Duration(
              seconds: DateTime.now().difference(start).inSeconds -
                  totalPauseTimeSeconds)));
        });
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
