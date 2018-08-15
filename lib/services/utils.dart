class TimeUtils {
  static List<dynamic> getHoursInScope(int scope, List<dynamic> hours) {
    if (scope == 4) {
      return hours;
    }

    var today = startBoundInScope(scope);

    return hours.where((item) {
      var start = DateTime.parse(item["startTime"]);
      return start.isAfter(today);
    }).toList();
  }

  static DateTime startBoundInScope(scope) {
    var now = DateTime.now();
    if (scope == 0) {
      return new DateTime(now.year, now.month, now.day);
    } else if (scope == 1) {
      return new DateTime(now.year, now.month, now.day - now.weekday);
    } else if (scope == 2) {
      return new DateTime(now.year, now.month);
    } else {
      return new DateTime(now.year);
    }
  }

  static DateTime getDateOfTime(DateTime specific) =>
      new DateTime(specific.year, specific.month, specific.day);

  static Map getHoursForEachDay(List<dynamic> hours) {
    Map hoursForEachDay = {};

    hours.forEach((hour) {
      var timeStamp =
          getDateOfTime(DateTime.parse(hour["startTime"])).toIso8601String();

      var time = hoursForEachDay["$timeStamp"];

      var hours = (hour["time"] / 3600) as double;

      if (time == null) {
        hoursForEachDay.putIfAbsent(
            "$timeStamp",
            () => {
                  "time": double.parse(hours.toStringAsFixed(2)),
                  "key": "$timeStamp",
                  "source": [hour]
                });
      } else {
        hoursForEachDay["$timeStamp"]["time"] +=
            double.parse(hours.toStringAsFixed(2));
        hoursForEachDay["$timeStamp"]["source"].add(hour);
      }
    });

    return hoursForEachDay;
  }

  static String dateTimeToLocalTime(DateTime dateTime) {
    return "${dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour}:${dateTime.minute < 10 ? "0${dateTime.minute}" : dateTime.minute}${dateTime.hour > 12 ? "PM" : "AM"}";
  }

  static String secondsToPreferredTime(double seconds) {
    double newTime = 0.0;
    var measure = "secs";
    if (seconds > 60) {
      newTime = seconds / 60;
      measure = "mins";
    }

    if (newTime > 60) {
      newTime = newTime / 60;
      measure = "hrs";
    }

    return "${newTime.toStringAsFixed(2)}$measure";
  }
}
