import 'package:flutter/material.dart';
import 'package:work_hours/services/client_manager.dart';

class StateManager extends InheritedWidget {
  final ClientManagerService clientManagerService;

  StateManager(this.clientManagerService, {Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(StateManager oldWidget) {
    return clientManagerService != oldWidget.clientManagerService;
  }

  static StateManager of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(StateManager) as StateManager;
  }
}
