import 'package:flutter/material.dart';
import 'package:photonic_drive_server/dashboard.dart';
import 'package:photonic_drive_server/widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cherry_toast/cherry_toast.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photonic Drive',
      home: const HomePage(),
    );
  }
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String databaseLocation = "";

  TextEditingController serverPort = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: appBar(),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 10,
          children: [
            //Database Folder Picker
            DatabasePicker(
              onChange: (selectedPath){
                databaseLocation = selectedPath;
              },
            ),
            //Server Port
            TextField(
              controller: serverPort,
              decoration: InputDecoration(
                label: Text(
                  "Server Port",
                ),
              ),
            ),
            StartServerButton(
              onTap: (){
                //Validate and navigate to the other screen
                if(databaseLocation.isEmpty){
                  CherryToast.info(
                    title: Text(
                      "Database location is required",
                    ),
                  ).show(context);
                }else if(serverPort.text.isEmpty){
                  CherryToast.info(
                    title: Text(
                      "Server port is required",
                    ),
                  ).show(context);
                }else{
                  //Make sure that port is a valid integer
                  try{
                    int parsedServerPort = int.parse(serverPort.text);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => Dashboard(
                        serverPort: parsedServerPort,
                      ),
                    ));
                  }catch(error){
                    CherryToast.error(
                      title: Text(
                        "Server port must be an integer",
                      ),
                    ).show(context);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
class DatabasePicker extends StatefulWidget {
  const DatabasePicker({
    super.key,
    required this.onChange,
  });
  final Function(String selectedPath) onChange;

  @override
  State<DatabasePicker> createState() => _DatabasePickerState();
}

class _DatabasePickerState extends State<DatabasePicker> {
  String selectedPath = "";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()async{
        String? folder = await FilePicker.getDirectoryPath();
        if(folder != null){
          setState(() {
            selectedPath = folder;
          });
          widget.onChange(selectedPath);
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(10),
        color: Colors.deepPurple,
        child: Text(
          selectedPath.isEmpty ? "Click to pick database location" : selectedPath,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
class StartServerButton extends StatelessWidget {
  const StartServerButton({
    super.key,
    required this.onTap,
  });
  final Function onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        onTap();
      },
      child: Container(
        width: double.infinity,
        color: Colors.deepPurple,
        padding: EdgeInsets.all(20),
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: Text(
                "Start Server",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: "BlackOpsOne",
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}