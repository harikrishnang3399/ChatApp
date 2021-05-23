import 'package:chat_app/helperfunctions/sharedpref_helper.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ForwardMenu extends StatefulWidget {
  final String forwardedMessageId, forwardedMessage, chatRoomId;
  ForwardMenu(this.forwardedMessageId, this.forwardedMessage, this.chatRoomId);

  @override
  _ForwardMenuState createState() => _ForwardMenuState();
}

class _ForwardMenuState extends State<ForwardMenu> {
  Stream chatRoomStream;
  String myName, myProfilePic, myUserName, myEmail;

  getMyInfoFromSharedPreferences() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();
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
                print("hey its working");
                // print("forwarded message id is ${widget.forwardedMessageId}");
                print("forwarded message is ${widget.forwardedMessage}");
                print("Forwarded from chatroom ${widget.chatRoomId}");

                return ForwardedChatRoomListTile(
                    ds["lastMessage"],
                    ds.id,
                    myUserName,
                    ds["lastMessageSendTS"],
                    widget.forwardedMessage,
                    widget.forwardedMessageId,
                    widget.chatRoomId);
              },
            );
          } else {
            return Text("");
          }
        });
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
        title: Text("Forward To"),
      ),
      body: Container(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [chatRoomsList()],
          )),
    );
  }
}

class ExpandedFlex extends Flexible {
  const ExpandedFlex({
    Key key,
    int flex = 1,
    @required Widget child,
  }) : super(key: key, flex: flex, fit: FlexFit.loose, child: child);
}

class ForwardedChatRoomListTile extends StatefulWidget {
  final String lastMessage,
      chatRoomId,
      myUsername,
      forwardedMessage,
      forwardedMessageId,
      forwardedChatRoomId;
  final Timestamp lastMessageSendTS;
  ForwardedChatRoomListTile(
      this.lastMessage,
      this.chatRoomId,
      this.myUsername,
      this.lastMessageSendTS,
      this.forwardedMessage,
      this.forwardedMessageId,
      this.forwardedChatRoomId);
  @override
  _ForwardedChatRoomListTileState createState() =>
      _ForwardedChatRoomListTileState();
}

class _ForwardedChatRoomListTileState extends State<ForwardedChatRoomListTile> {
  String profilePicUrl = "", name = "", username = "";
  getThisUserInfo() async {
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
      print("Inside forward menu Group name $name profilepic $profilePicUrl");
      setState(() {});
    } else {
      QuerySnapshot querySnapshot =
          await DatabaseMethods().getUserInfo(username);
      name = "${querySnapshot.docs[0]["name"]}";
      profilePicUrl = "${querySnapshot.docs[0]["imgUrl"]}";
      print("Inside forward menu User name $name profilepic $profilePicUrl");
      setState(() {});
    }
  }

  @override
  void initState() {
    getThisUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime date = DateTime.fromMicrosecondsSinceEpoch(
        widget.lastMessageSendTS.microsecondsSinceEpoch);

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            print("ForwardedChatScreen is opening");
            Navigator.popUntil(context, (route) => route.isFirst);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ChatScreen(
                      username,
                      name,
                      profilePicUrl,
                      null,
                      widget.forwardedMessage,
                      widget.forwardedMessageId,
                      widget.forwardedChatRoomId);
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
                        constraints: BoxConstraints(maxWidth: 270),
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
                      child: Text(DateFormat('hh:mm a').format(date)),
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
