import 'dart:convert';
import 'dart:io';

import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class NewGroup extends StatefulWidget {
  final String myUserName;
  NewGroup(this.myUserName);
  @override
  _NewGroupState createState() => _NewGroupState();
}

class _NewGroupState extends State<NewGroup> {
  bool selected = false, enableButton = false, gettingImage = false;
  TextEditingController groupNameContoller = TextEditingController();
  String groupName;
  String chatRoomId;
  File _image;
  String imageUrl = "";

  ImagePicker imagePicker = ImagePicker();

  Future<String> uploadFile(image) async {
    String url;
    Reference ref = FirebaseStorage.instance
        .ref()
        .child("AppGroupImages/Image${DateTime.now()}");
    if (image != null) {
      UploadTask uploadTask = ref.putFile(image);
      url = await uploadTask.then((res) => res.ref.getDownloadURL());
      return url;
    } else {
      return null;
    }
  }

  Future saveImage(image, DocumentReference documentReference) async {
    imageUrl = await uploadFile(image);
    print("in saveImage imageUrl is $imageUrl");
  }

  Future getImage() async {
    final image = await imagePicker.getImage(source: ImageSource.gallery);
    setState(() {
      if (image != null) {
        _image = File(image.path);
      }
    });
    print("image is $_image");
  }

  createGroup() async {
    groupName = groupNameContoller.text;
    var date = DateTime.now();
    chatRoomId = "Group$groupName\_$date";
    Map<String, dynamic> chatRoomInfoMap = {
      "users": [widget.myUserName]
    };

    var bytes = utf8.encode(chatRoomId);
    String groupId = sha256.convert(bytes).toString();

    DocumentReference documentReference =
        FirebaseFirestore.instance.collection("images").doc();
    // String imgURL = "";
    if (gettingImage) {
      await saveImage(_image, documentReference);
      print("inside createGroup imageUrl is $imageUrl");
      // print("inside createGroup imgURL is $imgURL");
    }
    if (imageUrl == null) {
      imageUrl = "";
    }
    Map<String, dynamic> groupInfoMap = {
      "name": groupName,
      "username": chatRoomId,
      "imgUrl": imageUrl
    };

    DatabaseMethods().addUserInfoToDB(groupId, groupInfoMap);

    Map<String, dynamic> lastMessageInfoMap = {
      "lastMessage": " ",
      "lastMessageSendTS": DateTime.now(),
      "lastMessageSendBy": " ",
      "lastMessageId": " ",
    };
    DatabaseMethods()
        .createChatRoom(chatRoomId, chatRoomInfoMap, lastMessageInfoMap);

    Navigator.popUntil(context, (route) => route.isFirst);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoomId, groupName, imageUrl)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Group"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _image == null
              ? CircleAvatar(
                  child: Container(
                    child: IconButton(
                      onPressed: () {
                        gettingImage = true;
                        getImage();
                      },
                      icon: Icon(Icons.camera_alt),
                      color: Colors.black,
                    ),
                  ),
                  backgroundColor: Colors.grey,
                  radius: 40,
                )
              : Container(),
          _image != null
              ? Image.file(
                  _image,
                  width: 75,
                  fit: BoxFit.fitWidth,
                )
              : Container(),
          SizedBox(
            height: 10,
          ),
          Text(
            "Group Name",
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Container(
              padding: EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black87,
                  width: 1.0,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                onChanged: (text) {
                  if (text != "") {
                    enableButton = true;
                    setState(() {});
                  } else if (text == "") {
                    enableButton = false;
                    setState(() {});
                  }
                },
                controller: groupNameContoller,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hoverColor: Colors.green,
                  border: InputBorder.none,
                  hintText: "Enter a group name...",
                ),
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          ElevatedButton(
            onPressed: enableButton ? createGroup : null,
            child: Text("Create Group"),
          )
        ],
      ),
    );
  }
}
