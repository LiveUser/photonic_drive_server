import 'package:flutter/material.dart';
import 'package:photonic_drive_server/widgets.dart';
import 'dart:io';

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
              //TODO: Display info like ip, port and allow creating access tokens. Access tokens can be copied or scanned using QR codes.
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
class TokenManager extends StatelessWidget {
  const TokenManager({
    super.key,
    required this.databaseLocation,
  });
  final String databaseLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        GestureDetector(
          onTap: (){
            //TODO: Create access token

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
        //TODO: Display access tokens
        
      ],
    );
  }
}