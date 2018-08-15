import 'package:flutter/material.dart';
import 'package:work_hours/fragments/stop_watch_detail.dart';
import 'package:work_hours/fragments/timing_detail.dart';
import 'package:work_hours/services/utils.dart';

class ClientDetail extends StatefulWidget {
  dynamic client;

  ClientDetail(this.client);

  @override
  State<StatefulWidget> createState() => new ClientDetailState(client);
}

class ClientDetailState extends State<ClientDetail> {
  dynamic client;
  var timeMeasures = [
    "Today",
    "This week",
    "This month",
    "This year",
    "All Time"
  ];
  var selectedMeasure = 0;

  ClientDetailState(this.client);

  var totalTime = 0;

  //Widget presetData(scope, hours) {}

  @override
  Widget build(BuildContext context) {
    var totalHours = 0.0;

    TimeUtils.getHoursInScope(selectedMeasure, client["hours"]).forEach((hour) {
      totalHours += (hour["time"] / 3600);
    });

    return new Scaffold(
        floatingActionButton: new FloatingActionButton(
            onPressed: () {
              Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (context) => new StopWatchFragment()));
            },
            child: new Icon(Icons.access_alarm)),
        appBar: new AppBar(title: new Text(client["name"])),
        body: new Column(children: [
          new ListTile(
              title: new Text("Hours: ${totalHours.toStringAsFixed(2)}"),
              trailing: new DropdownButton(
                  hint: new Text(timeMeasures[selectedMeasure]),
                  items: timeMeasures.map((item) {
                    return new DropdownMenuItem<int>(
                        child: new Text(item),
                        value: timeMeasures.indexOf(item));
                  }).toList(),
                  onChanged: (index) {
                    setState(() {
                      selectedMeasure = index;
                    });
                  })),
          new ListTile(title: new Text("Hours by day:")),
          new SingleChildScrollView(
              child: new Column(
                  children: TimeUtils
                      .getHoursForEachDay(client["hours"])
                      .values
                      .map((value) {
            var date = DateTime.parse(value["key"]);

            return new InkWell(
                child: new ListTile(
                    leading: new Text("${date.day}/${date.month}/${date.year}"),
                    title: new Text("${value["time"]}"),
                    trailing: new Icon(Icons.info_outline)),
                onTap: () => Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) =>
                            new TimingDetail(value["source"], date))));
          }).toList()))
        ]));
  }
}
