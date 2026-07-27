import 'package:flutter/material.dart';

AppBar appBar(){
  return AppBar(
    backgroundColor: Colors.black,
    title: Text(
      "Photonic Drive",
      style: TextStyle(
        color: Colors.amber,
        fontSize: 22,
        fontFamily: "BlackOpsOne",
      ),
    ),
    centerTitle: true,
  );
}