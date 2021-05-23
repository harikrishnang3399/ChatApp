import 'package:chat_app/views/addusertogroup.dart';
import 'package:flutter/material.dart';

class GroupScreen extends StatefulWidget {
  final String groupName,chatRoomId, profileUrl;

  GroupScreen(this.groupName,this.chatRoomId,this.profileUrl);
  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  TextEditingController messageTextEditingController = TextEditingController();
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          children: [
            CircleAvatar(
              child: Text(widget.groupName.substring(0, 1)),
              backgroundColor: Colors.white,
            ),
            SizedBox(
              width: 20,
            ),
            Text(widget.groupName),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              selected = true;
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AddUserToGroup(widget.chatRoomId,widget.profileUrl)));
              setState(() {});
            },
            child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.person_add_alt_sharp),
            ),
          )
        ],
      ),
      body: Container(
        child: Stack(
          children: [
            // chatMessages(),
            Container(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.black.withOpacity(0.3),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        onChanged: (value) {
                          // addMessage(false);
                        },
                        controller: messageTextEditingController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter a message...",
                          hintStyle: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // addMessage(true);
                      },
                      child: Icon(Icons.send),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
