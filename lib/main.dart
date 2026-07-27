import 'package:flutter/material.dart';
import 'package:photonic_drive_server/widgets.dart';
import 'package:file_picker/file_picker.dart';

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
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    String databaseLocation = "";
    TextEditingController serverPort = TextEditingController();

    return Scaffold(
      appBar: appBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          spacing: 10,
          children: [
            //TODO: Database Folder Picker
            DatabasePicker(
              onChange: (selectedPath){
                databaseLocation = selectedPath;
              },
            ),
            //TODO: Server Port
            TextField(
              controller: serverPort,
              decoration: InputDecoration(
                label: Text(
                  "Server Port",
                ),
              ),
            ),
            StartServerButton(

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
        color: Colors.black,
        child: Text(
          selectedPath.isEmpty ? "Click to pick database location" : selectedPath,
          style: TextStyle(
            color: Colors.amber,
          ),
        ),
      ),
    );
  }
}
class StartServerButton extends StatelessWidget {
  const StartServerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: EdgeInsets.all(20),
      child: Row(
        spacing: 10,
        children: [
          Expanded(
            child: Text(
              "Start Server",
              style: TextStyle(
                color: Colors.amber,
                fontSize: 22,
                fontFamily: "BlackOpsOne",
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }
}