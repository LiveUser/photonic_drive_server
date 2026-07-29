import 'package:flutter/material.dart';

AppBar appBar(){
  return AppBar(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
    title: Text(
      "Photonic Drive",
      style: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontFamily: "BlackOpsOne",
      ),
    ),
    centerTitle: true,
  );
}