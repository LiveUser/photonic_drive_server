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

  bool tokenIsValid({
    required String databaseLocation,
    required String accessToken,
  }){
    Entry entry = Entry(
      dbPath: databaseLocation,
    );
    List<String> accessTokens = [];
    try{
      accessTokens = List<String>.from(entry.select().view()["accessTokens"]);
    }catch(error){
      accessTokens = [];
    }
    if(accessTokens.contains(accessToken)){
      return true;
    }else{
      return false;
    }
  }
  void verifyValidity({
    required String databaseLocation,
    required String accessToken,
  }){
    if(!tokenIsValid(databaseLocation: databaseLocation, accessToken: accessToken)){
      throw "Token invalid: Access denied.";
    }
  }

  Future<HttpServer> bindServer()async{
    //Directory x = Directory("../");
    //x = Directory(x.resolveSymbolicLinksSync());
    //print(x.absolute.path);
    try{
      //Create drive folder before starting the server
      Directory driveFolder = Directory("$databaseLocation/drive");
      if(!driveFolder.existsSync()){
        driveFolder.createSync(recursive: true);
      }

      HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, serverPort);
      //Create server functions
      startServer(
        server: server, 
        isolateVariables: {
          "databaseLocation": databaseLocation,
        },
        getHandler: GetHandler(
          handler: (arguments)async{ 
            return Uint8List.fromList([]);
          },
        ), 
        query: GrapheneQuery(
          resolver: {
            //List folder contents
            "listDirContents":(arguments)async{
              if(!tokenIsValid(databaseLocation: arguments["databaseLocation"], accessToken: arguments["accessToken"])){
                throw "Token invalid: Access denied.";
              }
              String drivePath = "${arguments["databaseLocation"]}/drive";
              if(Platform.isWindows){
                drivePath.replaceAll("/", "\\");
              }
              Directory directory = Directory(arguments["fullPath"]);
              if(directory.path.isEmpty){
                directory = Directory(drivePath);
              }
              //This resolves things like ../ to an absolute path
              directory = Directory(directory.resolveSymbolicLinksSync());
              if(directory.path.startsWith(drivePath)){
                if(directory.existsSync()){
                  List<Map<String,dynamic>> directoryContents = [];
                  List<FileSystemEntity> contents = directory.listSync();
                  for(FileSystemEntity element in contents){
                    if(element is Directory){
                      directoryContents.add({
                        "type": "dir",
                        "fullPath": element.path,
                      });
                    }else{
                      directoryContents.add({
                        "type": "file",
                        "fullPath": element.path,
                      });
                    }
                  }
                  return directoryContents;
                }else{
                  throw "Directory does not exists.";
                }
              }else{
                throw "Access to outside the drive folder is denied.";
              }
            },
            //Verify that the access token is valid
            "tokenIsValid":(arguments)async{
              return tokenIsValid(databaseLocation: arguments["databaseLocation"], accessToken: arguments["accessToken"]);
            },
            //TODO: Get images metadata list (crawl all folders, filter by image extension, extract metadata, return list)

            //TODO: Fetch image thumbnail
            
          },
        ), 
        mutations: GrapheneMutation(
          resolver: {
            //Create directory
            "createDir":(arguments)async{
              //Throws an error if access token is invalid
              verifyValidity(databaseLocation: arguments["databaseLocation"], accessToken: arguments["accessToken"]);
              String drivePath = "${arguments["databaseLocation"]}/drive";
              if(Platform.isWindows){
                drivePath.replaceAll("/", "\\");
              }
              Directory newDirectory = Directory(arguments["fullPath"]);
              //This resolves things like ../ to an absolute path
              newDirectory = Directory(newDirectory.resolveSymbolicLinksSync());
              if(newDirectory.path.startsWith(drivePath)){
                if(!newDirectory.existsSync()){
                  newDirectory.createSync(recursive: true);
                  return "Successfully created Directory.";
                }else{
                  throw "Directory already exists.";
                }
              }else{
                throw "Access to outside the drive folder is denied.";
              }
            },
            //Create file
            "createFile":(arguments)async{
              //Throws an error if access token is invalid
              verifyValidity(databaseLocation: arguments["databaseLocation"], accessToken: arguments["accessToken"]);
              Uint8List bytes = Uint8List.fromList(List<int>.from(arguments["bytes"]));
              String drivePath = "${arguments["databaseLocation"]}/drive";
              if(Platform.isWindows){
                drivePath.replaceAll("/", "\\");
              }
              File newFile = File(arguments["fullPath"]);
              //This resolves things like ../ to an absolute path
              newFile = File(newFile.resolveSymbolicLinksSync());
              String fileName = "";
              String folderPath = "";
              if(Platform.isWindows){
                fileName = newFile.path.substring(newFile.path.lastIndexOf("\\") + 1, newFile.path.lastIndexOf("."));
                folderPath = newFile.path.substring(0,newFile.path.lastIndexOf("\\"));
              }else{
                fileName = newFile.path.substring(newFile.path.lastIndexOf("/") + 1, newFile.path.lastIndexOf("."));
                folderPath = newFile.path.substring(0,newFile.path.lastIndexOf("/"));
              }
              String extension = newFile.path.substring(newFile.path.lastIndexOf("."));
              int i = 0;
              File validFile;
              do{
                if(i == 0){
                  validFile = File("$folderPath/$fileName$extension");
                }else{
                  validFile = File("$folderPath/$fileName-$i$extension");
                }
                i++;
              }while(validFile.existsSync());
              if(newFile.path.startsWith(drivePath)){
                if(!newFile.existsSync()){
                  newFile.createSync(recursive: true);
                  newFile.writeAsBytesSync(bytes);
                  return "Successfully created File.";
                }else{
                  throw "File already exists.";
                }
              }else{
                throw "Access to outside the drive folder is denied.";
              }
            },
            //Delete directory
            "deleteDir":(arguments)async{
              //Throws an error if access token is invalid
              verifyValidity(databaseLocation: arguments["databaseLocation"], accessToken: arguments["accessToken"]);
              String drivePath = "${arguments["databaseLocation"]}/drive";
              if(Platform.isWindows){
                drivePath.replaceAll("/", "\\");
              }
              Directory directory = Directory(arguments["fullPath"]);
              //This resolves things like ../ to an absolute path
              directory = Directory(directory.resolveSymbolicLinksSync());
              if(directory.path.startsWith(drivePath)){
                if(directory.existsSync()){
                  directory.deleteSync(recursive: true);
                  return "Successfully deleted Directory.";
                }else{
                  throw "Directory does not exists.";
                }
              }else{
                throw "Access to outside the drive folder is denied.";
              }
            },
            //Delete file
            "deleteFile":(arguments)async{
              //Throws an error if access token is invalid
              verifyValidity(databaseLocation: arguments["databaseLocation"], accessToken: arguments["accessToken"]);
              String drivePath = "${arguments["databaseLocation"]}/drive";
              if(Platform.isWindows){
                drivePath.replaceAll("/", "\\");
              }
              File file = File(arguments["fullPath"]);
              //This resolves things like ../ to an absolute path
              file = File(file.resolveSymbolicLinksSync());
              if(file.path.startsWith(drivePath)){
                if(file.existsSync()){
                  file.deleteSync(recursive: true);
                  return "Successfully deleted File.";
                }else{
                  throw "File does not exists.";
                }
              }else{
                throw "Access to outside the drive folder is denied.";
              }
            },
            //Rename directory
            "renameDir":(arguments)async{
              //Throws an error if access token is invalid
              verifyValidity(databaseLocation: arguments["databaseLocation"], accessToken: arguments["accessToken"]);
              String drivePath = "${arguments["databaseLocation"]}/drive";
              if(Platform.isWindows){
                drivePath.replaceAll("/", "\\");
              }
              String newName = arguments["newName"];
              Directory directory = Directory(arguments["fullPath"]);
              //This resolves things like ../ to an absolute path
              directory = Directory(directory.resolveSymbolicLinksSync());
              if(directory.path.startsWith(drivePath)){
                if(directory.existsSync()){
                  String newPath = "${directory.path.substring(0,directory.path.lastIndexOf(RegExp(r"[/\\]")))}/$newName";
                  directory.renameSync(newPath);
                  return "Successfully renamed Directory.";
                }else{
                  throw "Directory does not exists.";
                }
              }else{
                throw "Access to outside the drive folder is denied.";
              }
            },
            //Rename file
            "renameFile":(arguments)async{
              //Throws an error if access token is invalid
              verifyValidity(databaseLocation: arguments["databaseLocation"], accessToken: arguments["accessToken"]);
              String drivePath = "${arguments["databaseLocation"]}/drive";
              if(Platform.isWindows){
                drivePath.replaceAll("/", "\\");
              }
              String newName = arguments["newName"];
              File file = File(arguments["fullPath"]);
              //This resolves things like ../ to an absolute path
              file = File(file.resolveSymbolicLinksSync());
              if(file.path.startsWith(drivePath)){
                if(file.existsSync()){
                  String newPath = "${file.path.substring(0,file.path.lastIndexOf(RegExp(r"[/\\]")))}/$newName";
                  file.renameSync(newPath);
                  return "Successfully renamed File.";
                }else{
                  throw "File does not exists.";
                }
              }else{
                throw "Access to outside the drive folder is denied.";
              }
            },
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