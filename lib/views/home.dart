import 'package:chat_app/helperfunctions/sharedpref_helper.dart';
import 'package:chat_app/views/chatscreen.dart';
import 'package:chat_app/views/new_group.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/new_chat.dart';
import 'package:chat_app/views/signin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String myName, myProfilePic, myUserName, myEmail;
  Stream chatRoomStream;

  getMyInfoFromSharedPreferences() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();
    setState(() {});
  }

  getChatRoomIdByUsername(String a, String b) {
    if (a.compareTo(b) == -1) {
      return "$b\_$a";
    } else if (a.compareTo(b) == 1) {
      return "$a\_$b";
    } else if (a.compareTo(b) == 0) {
      return "$a\_$b";
    }
  }

  Widget chatRoomsList() {
    print("I am still working though");
    return StreamBuilder(
        stream: chatRoomStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Snapshot Error receiving chatrooms"),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.data.docs.length == 0) {
              return Center(child: Text("No user found"));
            }
            return ListView.builder(
              itemCount: snapshot.data.docs.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                DocumentSnapshot ds = snapshot.data.docs[index];
                print("hey list builder inside home is working");
                return ChatRoomListTile(ds["lastMessage"], ds.id, myUserName,
                    ds["lastMessageSendTS"]);
              },
            );
          } else {
            return Text("It");
          }
        });
  }

  Widget icon(String choice) {
    if (choice == "New Chat") {
      return Icon(
        Icons.person,
        color: Colors.blue,
      );
    } else if (choice == "New Group") {
      return Icon(
        Icons.people,
        color: Colors.blue,
      );
    } else if (choice == "Logout") {
      return Icon(
        Icons.exit_to_app,
        color: Colors.blue,
      );
    }
    return null;
  }

  void handlePopupMenuClick(String choice) {
    if (choice == "New Chat") {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => NewChat(myUserName)));
    } else if (choice == "New Group") {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => NewGroup(myUserName)));
    } else if (choice == "Logout") {
      AuthMethods().signOut().then((value) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => SignIn()));
      });
    }
  }

  getChatRooms() async {
    chatRoomStream = await DatabaseMethods().getChatRooms();
    setState(() {});
  }

  onScreenLoaded() async {
    await getMyInfoFromSharedPreferences();
    getChatRooms();
  }

  @override
  void initState() {
    onScreenLoaded();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("ChatApp"),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (choice) {
              handlePopupMenuClick(choice);
            },
            itemBuilder: (BuildContext context) {
              return {'New Chat', 'New Group', 'Logout'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                    children: [
                      icon(choice),
                      SizedBox(
                        width: 10,
                      ),
                      Text(choice),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.all(8),
        child: Column(
          children: [chatRoomsList()],
        ),
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  final String lastMessage, chatRoomId, myUsername;
  final Timestamp lastMessageSendTS;
  ChatRoomListTile(this.lastMessage, this.chatRoomId, this.myUsername,
      this.lastMessageSendTS);

  @override
  _ChatRoomListTileState createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  String profilePicUrl = "", name = "", username = "";
  getThisUserInfo() async {
    print("I am being called on ${widget.lastMessage}");
    if (widget.chatRoomId.contains("Group", 0)) {
      username = widget.chatRoomId;
    } else {
      username = widget.chatRoomId
          .replaceFirst(widget.myUsername, "")
          .replaceAll("_", "");
    }

    if (widget.chatRoomId.contains("Group", 0)) {
      QuerySnapshot querySnapshot =
          await DatabaseMethods().getGroupInfo(username);
      name = "${querySnapshot.docs[0]["name"]}";
      profilePicUrl = "${querySnapshot.docs[0]["imgUrl"]}";
      print("Group name $name profilepic $profilePicUrl");
      setState(() {});
    } else {
      QuerySnapshot querySnapshot =
          await DatabaseMethods().getUserInfo(username);
      name = "${querySnapshot.docs[0]["name"]}";
      profilePicUrl = "${querySnapshot.docs[0]["imgUrl"]}";
      print("User name $name profilepic $profilePicUrl");
      setState(() {});
    }
  }

  @override
  void initState() {
    getThisUserInfo();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ChatRoomListTile oldWidget) {
    if (oldWidget.lastMessage != widget.lastMessage) {
      getThisUserInfo();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    print("name $name");
    print("ProfilePicUrl is $profilePicUrl");
    DateTime date = DateTime.fromMicrosecondsSinceEpoch(
        widget.lastMessageSendTS.microsecondsSinceEpoch);
    print("inside chatroom tile $date");

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            print("ChatScreen is opening");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ChatScreen(
                      username, name, profilePicUrl, widget.lastMessage);
                },
              ),
            );
          },
          child: Card(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: profilePicUrl != ""
                        ? Image.network(
                            profilePicUrl,
                            height: 50,
                            width: 50,
                          )
                        : CircleAvatar(
                            child: Icon(
                              widget.chatRoomId.contains("Group", 0)
                                  ? Icons.people_alt_sharp
                                  : Icons.person,
                              color: Colors.black87,
                            ),
                            backgroundColor: Colors.grey,
                            radius: 25,
                          ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 3),
                      Container(
                        constraints: BoxConstraints(maxWidth: 255),
                        child: Text(
                          widget.lastMessage.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.bottomRight,
                      child: date == null
                          ? Text("")
                          : Text(DateFormat('hh:mm a').format(date)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
