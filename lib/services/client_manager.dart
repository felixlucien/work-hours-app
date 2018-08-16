import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ClientManagerService {
  List<dynamic> clients = [];
  bool currentlyTiming;
  dynamic timingData;

  ClientStream clientStream;
  TimingStream timingStream;

  SharedPreferences prefs;

  ClientManagerService(this.prefs, Function onUpdate) {
    clientStream = new ClientStream(prefs);
    clientStream.listen((data) {
      this.clients = data;
      onUpdate();
      print(clients);
    });

    timingStream = new TimingStream(prefs);
    timingStream.listen((timingData) {
      this.timingData = timingData;
      onUpdate();
      print(timingData);
    });
  }

  startTiming() async {
    return await timingStream.startTiming();
  }

  stopTiming() async {
    await timingStream.stopTiming();
  }

  resetTiming() {
    timingStream.resetTiming();
  }

  startPause() {
    timingStream.startPausing();
  }

  stopPause() async {
    await timingStream.stopPausing();
    return timingStream.getTiming();
  }

  saveTiming(var clientName) {
    var time = DateTime.parse(timingData["endTime"])
        .difference(DateTime.parse(timingData["startTime"]))
        .inSeconds;

    (timingData["pauseBuffer"]).forEach((pause) {
      var pauseSplit = pause.split("|TO|");
      var start = DateTime.parse(pauseSplit[0]);
      var end = DateTime.parse(pauseSplit[1]);
      var duration = end.difference(start);
      time = time - duration.inSeconds;
    });

    var tmpClient =
        clients.firstWhere((client) => client["name"] == clientName);

    tmpClient["hours"].add({
      "startTime": timingData["startTime"],
      "endTime": timingData["endTime"],
      "breaks": timingData["pauseBuffer"],
      "time": time
    });

    updateClient(tmpClient);
  }

  createClient(String name) {
    if (clients.where((client) => client["name"] == name).isEmpty) {
      var client = {
        "name": name,
        "hours": [],
      };
      clients.add(client);
      clientStream.setData(clients);
      return true;
    } else {
      return false;
    }
  }

  updateClient(dynamic targetClient) {
    clients[clients.indexWhere(
        (client) => client["name"] == targetClient["name"])] = targetClient;
    clientStream.setData(clients);
  }

  deleteClient(dynamic targetClient) {
    clients.removeAt(
        clients.indexWhere((client) => client["name"] == targetClient["name"]));
    clientStream.setData(clients);
  }
}

class ClientStream extends Stream<List<dynamic>> {
  SharedPreferences prefs;

  ClientStream(this.prefs);

  List<dynamic> clients = [];

  Function onData;

  getData() {
    if (prefs.get("CLIENTS_KEY") != null) {
      clients = JSON.decode(prefs.get("CLIENTS_KEY"));
    }
    onData(clients);
  }

  setData(List<dynamic> clients) async {
    await prefs.setString("CLIENTS_KEY", JSON.encode(clients));
    getData();
  }

  @override
  StreamSubscription<List> listen(void Function(List event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    this.onData = onData;
    getData();
    return null;
  }
}

class TimingStream extends Stream<dynamic> {
  SharedPreferences prefs;
  bool currentlyTiming, currentlyPausing;
  String startTime, endTime, startPause, endPause;
  Function onData;

  TimingStream(this.prefs);

  startTiming() async {
    resetPauseBuffer();
    resetPause();
    await prefs.setBool("CURRENTLY_TIMING", true);
    startTime = DateTime.now().toIso8601String();
    await prefs.setString("TIMING_START", startTime);
    return getTiming();
  }

  stopTiming() async {
    assert(prefs.get("CURRENTLY_TIMING"));
    await prefs.setBool("CURRENTLY_TIMING", false);
    endTime = DateTime.now().toIso8601String();
    await prefs.setString("TIMING_END", endTime);
    getTiming();
  }

  resetTiming() {
    prefs.remove("CURRENTLY_TIMING");
    prefs.remove("TIMING_START");
    prefs.remove("TIMING_END");
    resetPause();
    resetPauseBuffer();
    getTiming();
  }

  startPausing() async {
    if (!prefs.getBool("CURRENTLY_TIMING")) {
      throw "Must be timing to pause";
    }
    await prefs.setBool("CURRENTLY_PAUSING", true);
    startPause = DateTime.now().toIso8601String();
    await prefs.setString("PAUSING_START", startPause);
    getTiming();
  }

  stopPausing() async {
    assert(prefs.get("CURRENTLY_PAUSING"));
    await prefs.setBool("CURRENTLY_PAUSING", false);
    endPause = DateTime.now().toIso8601String();
    await prefs.setString("PAUSING_END", endPause);
    await savePauseToBuffer(getPause());
    resetPause();
    getTiming();
  }

  savePauseToBuffer(var pause) async {
    List<String> pauseBuffer = [];
    if (prefs.getStringList("PAUSE_BUFFER") != null) {
      pauseBuffer.addAll(prefs.getStringList("PAUSE_BUFFER"));
    }

    pauseBuffer.add("${pause["startPause"]}|TO|${pause["endPause"]}");
    prefs.setStringList("PAUSE_BUFFER", pauseBuffer);
  }

  resetPause() {
    prefs.remove("CURRENTLY_PAUSING");
    prefs.remove("PAUSING_START");
    prefs.remove("PAUSING_END");
  }

  resetPauseBuffer() {
    prefs.remove("PAUSE_BUFFER");
  }

  dynamic getPause() {
    if (prefs.get("CURRENTLY_PAUSING") != null) {
      currentlyPausing = prefs.get("CURRENTLY_PAUSING");
    } else {
      prefs.setBool("CURRENTLY_PAUSING", false);
    }

    startPause = prefs.getString("PAUSING_START");
    endPause = prefs.getString("PAUSING_END");

    Map returnData = {"currentlyPausing": currentlyPausing};

    if (!currentlyPausing && prefs.getString("PAUSING_START") != null) {
      returnData["startPause"] = startPause;
      returnData["endPause"] = endPause;
    } else if (currentlyPausing) {
      returnData["startPause"] = startPause;
    }

    return returnData;
  }

  getTiming() {
    if (prefs.get("CURRENTLY_TIMING") != null) {
      currentlyTiming = prefs.get("CURRENTLY_TIMING");
    } else {
      prefs.setBool("CURRENTLY_TIMING", false);
      currentlyTiming = false;
    }

    if (prefs.get("CURRENTLY_PAUSING") != null) {
      currentlyPausing = prefs.get("CURRENTLY_PAUSING");
    } else {
      prefs.setBool("CURRENTLY_PAUSING", false);
      currentlyPausing = false;
    }

    startTime = prefs.getString("TIMING_START");
    endTime = prefs.getString("TIMING_END");

    dynamic returnData = {
      "currentlyTiming": currentlyTiming,
      "currentlyPausing": currentlyPausing,
      "pauseBuffer": (prefs.getStringList("PAUSE_BUFFER") != null)
          ? prefs.getStringList("PAUSE_BUFFER")
          : []
    };

    if (!currentlyTiming && prefs.get("TIMING_END") != null) {
      returnData["startTime"] = startTime;
      returnData["endTime"] = endTime;
    } else if (currentlyTiming) {
      returnData["startTime"] = startTime;
    }

    onData(returnData);
    return returnData;
  }

  @override
  StreamSubscription listen(void Function(dynamic event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    this.onData = onData;
    getTiming();
    return null;
  }
}
