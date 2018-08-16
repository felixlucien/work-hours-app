import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:work_hours/fragments/clients_list.dart';
import 'package:work_hours/fragments/state_manager.dart';
import 'package:work_hours/fragments/stop_watch_detail.dart';
import 'package:work_hours/services/client_manager.dart';

void main() => runApp(AppRoot());

class AppRoot extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AppRootState();
}

enum AppState { CLIENTS, TIMER }

class AppRootState extends State<AppRoot> {
  ClientManagerService clientManagerService;
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey();
  AppState appState = AppState.CLIENTS;

  AppRootState() {
    SharedPreferences.getInstance().then((prefs) {
      clientManagerService =
          new ClientManagerService(prefs, () {
            if(mounted) {setState(() {});}
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    var homeWidget;
    switch (appState) {
      case AppState.CLIENTS:
        {
          homeWidget = new ClientList();
          break;
        }
      case AppState.TIMER:
        {
          homeWidget = new StopWatchFragment();
          break;
        }
      default:
        {
          homeWidget = new ClientList();
          break;
        }
    }

    return new StateManager(clientManagerService,
        child: new MaterialApp(
          home: clientManagerService != null
              ? new Scaffold(
                  key: scaffoldKey,
                  body: homeWidget,
                  bottomNavigationBar: new BottomNavigationBar(
                      currentIndex: AppState.values.indexOf(appState),
                      items: [
                        new BottomNavigationBarItem(
                            icon: new Icon(Icons.description),
                            title: new Text("Clients")),
                        new BottomNavigationBarItem(
                            icon: new Icon(Icons.alarm),
                            title: new Text("Timer")),
                      ],
                      onTap: (index) {
                        setState(() => appState = AppState.values[index]);
                      }),
                )
              : new Center(child: new Text("Loading...")),
        ));
  }
}
