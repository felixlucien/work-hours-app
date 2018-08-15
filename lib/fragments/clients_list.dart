import 'package:flutter/material.dart';
import 'package:work_hours/fragments/client_detail.dart';
import 'package:work_hours/fragments/state_manager.dart';

class ClientList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ClientListState();
}

class ClientListState extends State<ClientList> {
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    var clientManagerService = StateManager.of(context).clientManagerService;

    return Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: new Text("Clients"),
      ),
      body: new StreamBuilder(
          stream: clientManagerService.clientStream,
          builder: (context, snap) {
            if (snap.hasData) {
              return new ListView(
                  children: (snap.data as List).map((client) {
                return new InkWell(
                  child: new ListTile(title: new Text(client["name"])),
                  onTap: () {
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => new ClientDetail(client)));
                  },
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => new AlertDialog(
                              title: new Text("Confirm delete?"),
                              content: new Text(
                                  "Are you sure you want to delete ${client["name"]}? This cannot be undone."),
                              actions: [
                                new FlatButton(
                                  child: new Text("Ok"),
                                  onPressed: () {
                                    clientManagerService.deleteClient(client);
                                    Navigator.pop(context);
                                  },
                                ),
                                new FlatButton(
                                  child: new Text("Cancel"),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ]),
                    );
                  },
                );
              }).toList());
            } else {
              return new Center(child: new Text("Loading..."));
            }
          }),
      floatingActionButton: new FloatingActionButton(
          child: new Icon(Icons.create),
          onPressed: () {
            var clientName = "";
            showDialog(
                context: context,
                builder: (context) => new AlertDialog(
                        title: new Text("Add New Client."),
                        content: new TextField(
                            decoration:
                                new InputDecoration(hintText: "Client Name"),
                            onChanged: (newVal) => clientName = newVal),
                        actions: [
                          new FlatButton(
                            child: new Text("Add"),
                            onPressed: () {
                              if (clientName != "") {
                                if (!clientManagerService
                                    .createClient(clientName)) {
                                  scaffoldKey.currentState.showSnackBar(
                                      new SnackBar(
                                          content: new Text(
                                              "Sorry, but you can't add two clients with the same name")));
                                }
                              }
                              Navigator.pop(context);
                            },
                          ),
                          new FlatButton(
                            child: new Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ]));
          }),
    );
  }
}
