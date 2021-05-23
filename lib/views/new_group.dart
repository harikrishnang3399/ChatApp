import 'dart:convert';
import 'dart:io';

import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/groupscreen.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class NewGroup extends StatefulWidget {
  final String myUserName;
  NewGroup(this.myUserName);
  @override
  _NewGroupState createState() => _NewGroupState();
}

class _NewGroupState extends State<NewGroup> {
  bool selected = false, enableButton = false;
  TextEditingController groupNameContoller = TextEditingController();
  String groupName;
  String chatRoomId, profileUrl = "";
  File _image;
  ImagePicker imagePicker = ImagePicker();
  Future getImage() async {
    final image = await imagePicker.getImage(source: ImageSource.gallery);
    setState(() {
      _image = File(image.path);
    });
  }

  // uploadImage(File image) async {
  //   StorageReference reference =
  //       FirebaseFirestore.instance.ref().child(image.path.toString());
  //   StorageUploadTask uploadTask = reference.putFile(image);

  //   StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);

  //   String url = (await downloadUrl.ref.getDownloadURL());
  // }

  createGroup() {
    groupName = groupNameContoller.text;
    var date = DateTime.now();
    chatRoomId = "Group$groupName\_$date";
    Map<String, dynamic> chatRoomInfoMap = {
      "users": [widget.myUserName]
    };
    Map<String, dynamic> lastMessageInfoMap = {
      "lastMessage": " ",
      "lastMessageSendTS": DateTime.now(),
      "lastMessageSendBy": " ",
      "lastMessageId": " ",
    };

    Map<String, dynamic> groupInfoMap = {
      "name": groupName,
      "username": chatRoomId,
      "imgUrl": ""
    };

    var bytes = utf8.encode(chatRoomId);

    String groupId = sha1.convert(bytes).toString();

    DatabaseMethods().addUserInfoToDB(groupId, groupInfoMap);

    DatabaseMethods()
        .createChatRoom(chatRoomId, chatRoomInfoMap, lastMessageInfoMap);

    Navigator.popUntil(context, (route) => route.isFirst);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                GroupScreen(groupName, chatRoomId, profileUrl)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("New Group"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _image ==
              null?CircleAvatar(
            child: Container(
              child: IconButton(
                onPressed: () {
                  getImage();
                },
                icon: Icon(Icons.camera_alt),
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.grey,
            radius: 40,
          ): Container(),
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
            onPressed: enableButton
                ? () {
                    createGroup();
                  }
                : null,
            child: Text("Create Group"),
          )
        ],
      ),
    );
  }
}
