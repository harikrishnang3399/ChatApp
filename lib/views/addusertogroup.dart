import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddUserToGroup extends StatefulWidget {
  final String chatRoomId, profileUrl;
  AddUserToGroup(this.chatRoomId, this.profileUrl);

  @override
  _AddUserToGroupState createState() => _AddUserToGroupState();
}

class _AddUserToGroupState extends State<AddUserToGroup> {
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

  onSearchButtonClick() async {
    print("onsearchbutton click is working");
    isSearching = true;
    setState(() {});
    userStream = await DatabaseMethods()
        .getUserByUserName(searchUserNameEditingController.text);
    print("Got userstream too");
    setState(() {});
  }

  addUserToGroup(chatRoomId,username) async {
    List usersList = await DatabaseMethods().getChatRoomUsers(chatRoomId);
    if (usersList.contains(username)) {
    } else {
      usersList.add(username);
      DatabaseMethods().addUserToGroup(chatRoomId, usersList);
    }
    
  }

  Widget searchListUserTile({String profileUrl, name, username, email}) {
    return GestureDetector(
      onTap: () {
        print("chatRoomId inside addusertogroup is ${widget.chatRoomId}");
        addUserToGroup(widget.chatRoomId, username);
        String groupName =
            widget.chatRoomId.replaceFirst("Group", "").split("_")[0];
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ChatScreen(
                    widget.chatRoomId, groupName, widget.profileUrl)));
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
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(name), Text(username)],
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
              title: Text("Add Users To Group..."),
              actions: [
                GestureDetector(
                  onTap: () {
                    selected = true;
                    setState(() {});
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(Icons.search),
                  ),
                )
              ],
            )
          : AppBar(
              title: TextField(
                onChanged: (text) {
                  if (text != "") {
                    onSearchButtonClick();
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
        child: isSearching && selected ? searchUsersList() : Container(),
      ),
    );
  }
}
