import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:graphene_server/graphene_server.dart';
import 'package:photonic_drive_server/widgets.dart';
import 'dart:io';
import 'package:objective_db/objective_db.dart';
import 'package:power_plant/power_plant.dart';
import 'package:confirm_button/confirm_buttons.dart';
import 'package:flutter/services.dart';


class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.databaseLocation,
    required this.serverPort,
  });
  final String databaseLocation;
  final int serverPort;

  Future<HttpServer> bindServer()async{
    try{
      HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, serverPort);
      //Create server functions
      startServer(
        server: server, 
        getHandler: GetHandler(
          handler: (arguments)async{ 
            return Uint8List.fromList([]);
          }
        ), 
        query: GrapheneQuery(
          resolver: {
            //TODO: Get images metadata list
            //TODO: Fetch image thumbnail
          },
        ), 
        mutations: GrapheneMutation(
          resolver: {
            //TODO: Upload image
            //TODO: Delete image
          },
        ), 
        redirectHandler: (arguments)=> null,
      );
      return server;
    }catch(error){
      throw error.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: Padding(
        padding: EdgeInsetsGeometry.all(20),
        child: FutureBuilder(
          future: bindServer(),
          builder: (context,snapshot){
            if(snapshot.hasError){
              return Column(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    snapshot.error.toString(),
                  ),
                  GestureDetector(
                    onTap: (){
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      color: Colors.deepPurple,
                      child: Row(
                        spacing: 10,
                        children: [
                          Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                          Expanded(
                            child: Text(
                              "Back",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }else if(snapshot.connectionState == ConnectionState.done){
              //Display info like ip, port and allow creating access tokens. Access tokens can be copied.
              HttpServer httpServer = snapshot.data as HttpServer;
              return Column(
                spacing: 10,
                children: [
                  ServerInfo(
                    httpServer: httpServer,
                  ),
                  TokenManager(
                    databaseLocation: databaseLocation,
                  ),
                ],
              );
            }else{
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class ServerInfo extends StatelessWidget {
  const ServerInfo({
    super.key,
    required this.httpServer,
  });

  final HttpServer httpServer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      color: Colors.deepPurple,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        spacing: 10,
        children: [
          Text(
            "Server IP: ${httpServer.address.host}",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          Text(
            "Server Port: ${httpServer.port}",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
class TokenManager extends StatefulWidget {
  const TokenManager({
    super.key,
    required this.databaseLocation,
  });
  final String databaseLocation;

  @override
  State<TokenManager> createState() => _TokenManagerState();
}

class _TokenManagerState extends State<TokenManager> {

  List<Widget> widgetizeTokens(){
    List<Widget> widgets = [];
    Entry entry = Entry(
      dbPath: widget.databaseLocation,
    );
    List<String> accessTokens = [];
    try{
      accessTokens = List<String>.from(entry.select().view()["accessTokens"]);
    }catch(error){
      accessTokens = [];
    }
    for(String accessToken in accessTokens){
      widgets.add(AccessToken(
        databaseLocation: widget.databaseLocation,
        accessToken: accessToken
      ));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        GestureDetector(
          onTap: (){
            //Create access token
            String newAccessToken = uniqueAlphanumeric(tokenLength: 100);
            Entry entry = Entry(
              dbPath: widget.databaseLocation,
            );
            entry.select().insert(
              key: "accessTokens", 
              value: [
                newAccessToken,
              ],
            );
            setState(() {
              
            });
          },
          child: Container(
            color: Colors.deepPurple,
            width: double.infinity,
            padding: EdgeInsets.all(10),
            child: Row(
              spacing: 10,
              children: [
                Icon(
                  Icons.add_circle,
                  color: Colors.white,
                ),
                Expanded(
                  child: Text(
                    "Create Access Token",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        //Display access tokens
        SingleChildScrollView(
          child: Column(
            spacing: 10,
            children: widgetizeTokens(),
          ),
        ),
      ],
    );
  }
}
class AccessToken extends StatefulWidget {
  const AccessToken({
    super.key,
    required this.databaseLocation,
    required this.accessToken,
  });
  final String databaseLocation;
  final String accessToken;

  @override
  State<AccessToken> createState() => _AccessTokenState();
}

class _AccessTokenState extends State<AccessToken> {
  bool deleted = false;

  @override
  Widget build(BuildContext context) {
    return deleted ? SizedBox() : GestureDetector(
      onTap: (){
        Clipboard.setData(ClipboardData(
          text: widget.accessToken
        ));
        CherryToast.success(
          title: Text("Copied access token"),
        ).show(context);
      },
      child: Container(
        width: double.infinity,
        color: Colors.deepPurple,
        padding: EdgeInsets.all(20),
        child: Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.copy,
              color: Colors.white,
            ),
            Text(
              widget.accessToken,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            RadialConfirm(
              strokeWidth: 4, 
              secondsToConfirm: 3, 
              radius: 40,
              backgroundColor: Colors.deepPurple,
              valueColor: Colors.white,
              onConfirmed: (){
                Entry entry = Entry(
                  dbPath: widget.databaseLocation,
                );
                List<String> accessTokens = [];
                try{
                  accessTokens = List<String>.from(entry.select().view()["accessTokens"]);
                }catch(error){
                  accessTokens = [];
                }
                int index = accessTokens.indexOf(widget.accessToken);
                if(index != -1){
                  entry.select().pop(
                    index: index, 
                    key: "accessTokens",
                  );
                  setState(() {
                    deleted = true;
                  });
                }
              },
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}