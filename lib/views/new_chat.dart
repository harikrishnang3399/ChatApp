import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NewChat extends StatefulWidget {
  final String myUserName;
  NewChat(this.myUserName);
  @override
  _NewChatState createState() => _NewChatState();
}

class _NewChatState extends State<NewChat> {
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

  Widget searchListUserTile(
      {String profileUrl, String name, String username, String email}) {
    return GestureDetector(
      onTap: () {
        var chatRoomId = getChatRoomIdByUsername(widget.myUserName, username);
        print("chatRoomId from searchListUserTile is $chatRoomId");
        print("username is $username");

        Map<String, dynamic> chatRoomInfoMap = {
          "users": [widget.myUserName, username]
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
                builder: (context) => ChatScreen(username, name, profileUrl)));
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
          padding: EdgeInsets.only(top: 8),
          child: isSearching && selected ? searchUsersList() : Container()),
    );
  }
}
