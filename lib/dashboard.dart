import 'package:flutter/material.dart';
import 'package:photonic_drive_server/widgets.dart';
import 'dart:io';

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.serverPort,
  });
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

              return Placeholder();
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