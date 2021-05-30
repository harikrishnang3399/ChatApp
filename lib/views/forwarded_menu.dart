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

  bool selected = false;
  bool isSearching = false;
  Stream userStream;
  TextEditingController searchUserNameEditingController =
      TextEditingController();

  getChatRoomIdByUsername(String a, String b) {
    if (a.compareTo(b) == -1) {
      return "$b\_$a";
    } else if (a.compareTo(b) == 1) {
      return "$a\_$b";
    } else if (a.compareTo(b) == 0) {
      return "$a\_$b";
    }
  }

  onTypingTextOnSearchField() async {
    print("onsearchbutton click is working");
    isSearching = true;
    setState(() {});
    userStream = await DatabaseMethods()
        .getUserByUserName(searchUserNameEditingController.text);
    print("Got userstream too");
    setState(() {});
  }

  getMyInfoFromSharedPreferences() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();
  }

  Widget searchListUserTile(
      {String profileUrl, String name, String username, String email}) {
    return GestureDetector(
      onTap: () {
        var chatRoomId = getChatRoomIdByUsername(myUserName, username);
        print("chatRoomId from searchListUserTile is $chatRoomId");
        print("username is $username");

        Map<String, dynamic> chatRoomInfoMap = {
          "users": [myUserName, username]
        };
        Map<String, dynamic> lastMessageInfoMap;

        lastMessageInfoMap = {
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
                builder: (context) => ChatScreen(
                    username,
                    name,
                    profileUrl,
                    null,
                    widget.forwardedMessage,
                    widget.forwardedMessageId,
                    widget.chatRoomId)));
      },
      child: Card(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  profileUrl,
                  height: 50,
                  width: 50,
                  errorBuilder: (BuildContext context, Object exception,
                      StackTrace stackTrace) {
                    return CircleAvatar(
                      child: Icon(
                        name.contains("Group", 0)
                            ? Icons.people_alt_sharp
                            : Icons.person,
                        color: Colors.black87,
                      ),
                      backgroundColor: Colors.grey,
                      radius: 20,
                    );
                  },
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget searchUsersList() {
    return StreamBuilder(
      stream: userStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text("Snapshot Error receiving chatrooms"),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data.docs.length == 0) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text("No user found")),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data.docs.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              DocumentSnapshot ds = snapshot.data.docs[index];

              return searchListUserTile(
                  profileUrl: ds["imgUrl"],
                  name: ds["name"],
                  email: ds["email"],
                  username: ds["username"]);
            },
          );
        } else {
          return Text("Taco");
        }
      },
    );
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
      appBar: selected == false
          ? AppBar(
              title: Text("New Chat"),
              actions: [
                GestureDetector(
                  onTap: () {
                    selected = true;
                    setState(() {});
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 20.0),
                    child: Icon(Icons.search),
                  ),
                )
              ],
            )
          : AppBar(
              title: TextField(
                autofocus: true,
                onChanged: (text) {
                  if (text != "") {
                    onTypingTextOnSearchField();
                    setState(() {});
                  } else if (text == "") {
                    isSearching = false;
                    setState(() {});
                  }
                },
                cursorColor: Colors.black,
                controller: searchUserNameEditingController,
                decoration: InputDecoration(
                  hoverColor: Colors.green,
                  border: InputBorder.none,
                  hintText: "Search by name...",
                ),
              ),
              backgroundColor: Colors.blue.shade400,
              leading: GestureDetector(
                onTap: () {
                  selected = false;
                  isSearching = false;
                  searchUserNameEditingController.text = "";
                  setState(() {});
                },
                child: Icon(Icons.arrow_back),
              ),
            ),
      body: Container(
        padding: EdgeInsets.all(8),
        child: isSearching ? searchUsersList() : chatRoomsList(),
      ),
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
  void didUpdateWidget(covariant ForwardedChatRoomListTile oldWidget) {
    getThisUserInfo();
    super.didUpdateWidget(oldWidget);
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
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 3),
                      Container(
                        constraints: BoxConstraints(maxWidth: 200),
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
