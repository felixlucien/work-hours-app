import 'package:flutter/material.dart';
import 'package:work_hours/services/utils.dart';

class TimingDetail extends StatefulWidget {
  List<dynamic> hoursForDay;
  DateTime date;

  TimingDetail(this.hoursForDay, this.date);

  @override
  State<StatefulWidget> createState() => TimingDetailState(hoursForDay, date);
}

class TimingDetailState extends State<TimingDetail> {
  List<dynamic> hoursForDay;
  DateTime date;

  TimingDetailState(this.hoursForDay, this.date);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          title: new Text("Work for ${date.day}/${date.month}/${date.year}")),
      body: new ListView(
          children: hoursForDay.map((work) {
        var start = DateTime.parse(work["startTime"]);
        var end = DateTime.parse(work["endTime"]);

        var time = work["time"].toDouble();

        var totalDuration = end.difference(start).inSeconds;

        var breakSeconds = totalDuration - time;

        return new ListTile(
            leading: new Text(
                "${TimeUtils.dateTimeToLocalTime(start)} - ${TimeUtils.dateTimeToLocalTime(end)}"),
            title: new Text(
                "Work: ${TimeUtils.secondsToPreferredTime(time)} Breaks: ${TimeUtils.secondsToPreferredTime(breakSeconds)}"));
      }).toList()),
    );
  }
}
