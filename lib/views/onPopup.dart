import 'dart:convert';

import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/forwarded_menu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PopUpEntry extends PopupMenuEntry<Icon> {
  @override
  final height = 100;
  final String message, messageId, chatRoomId, upvoterName;
  final List upVoters;
  final int confidenceFake, confidenceReal;
  final bool forwarded;
  PopUpEntry(
      this.message,
      this.messageId,
      this.chatRoomId,
      this.forwarded,
      this.upvoterName,
      this.upVoters,
      this.confidenceFake,
      this.confidenceReal);

  @override
  _PopUpEntryState createState() => _PopUpEntryState();

  @override
  bool represents(Icon value) {
    throw UnimplementedError();
  }
}

class _PopUpEntryState extends State<PopUpEntry> {
  void onCopy() {
    Navigator.pop(context);
    Clipboard.setData(ClipboardData(text: widget.message.trim()));
  }

  void onForward() {
    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ForwardMenu(
                widget.messageId, widget.message, widget.chatRoomId)));
  }

  void onReport() async {
    Navigator.pop(context);

    DocumentSnapshot<Map<String, dynamic>> forwarded;
    forwarded = await DatabaseMethods()
        .getForwarded(widget.chatRoomId, widget.messageId);
    List forwardedList = forwarded["forwardedTo"];
    List upVoters = forwarded["upVoters"];
    upVoters.add(widget.upvoterName);

    if (upVoters.length > 0) {
      List authorities = await DatabaseMethods().getAuthorities();
      DocumentSnapshot authority = (authorities..shuffle()).first;
      String username = authority["username"];
      String chatRoomId = "$username\_$username";
      DateTime lastMessageTS = DateTime.now();
      var bytes = utf8.encode(widget.message);
      String messageId = sha256.convert(bytes).toString();

      Map<String, dynamic> messageInfoMap = {
        "message": widget.message,
        "sendBy": username,
        "sendByName": "Authority",
        "ts": lastMessageTS,
        "imgUrl": "",
        "forwardedTo": forwardedList,
        "forwarded": true,
        "reported": true,
        "upVoters": upVoters,
        "confidenceFake": forwarded["confidenceFake"],
        "confidenceReal": forwarded["confidenceReal"],
        "authorityReported": false
      };
      DatabaseMethods()
          .addMessage(chatRoomId, messageId, messageInfoMap)
          .then((value) {
        print(widget.messageId);
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": widget.message,
          "lastMessageSendTS": lastMessageTS,
          "lastMessageSendBy": username,
          "lastMessageId": messageId,
        };
        print("add message inside chat screen is working");

        DatabaseMethods().updateLastMessageSend(chatRoomId, lastMessageInfoMap);
      });
    }

    for (var forwardedlistmap in forwardedList) {
      print("forwardedlistmap $forwardedlistmap");
      await DatabaseMethods().updateReported(forwardedlistmap, upVoters);
    }
  }

  @override
  Widget build(BuildContext context) {
    String urlPattern = r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+';
    RegExp linkRegExp = RegExp('($urlPattern)', caseSensitive: false);
    RegExpMatch match = linkRegExp.firstMatch(widget.message);

    print("Match $match");

    return Row(
      children: <Widget>[
        SizedBox(
          width: 8,
        ),
        Expanded(
          child: TextButton(
            onPressed: onCopy,
            child: Column(
              children: [
                Icon(Icons.copy),
                SizedBox(
                  height: 4,
                ),
                Text("Copy"),
              ],
            ),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: onForward,
            child: Column(
              children: [
                Icon(Icons.forward),
                SizedBox(
                  height: 4,
                ),
                Text("Forward"),
              ],
            ),
          ),
        ),
        (widget.confidenceFake == 100 || widget.confidenceReal == 100)
            ? Container()
            : (widget.forwarded && widget.message.split(" ").length >= 10) ||
                    match != null
                ? widget.upVoters.contains(widget.upvoterName)
                    ? Container()
                    : Expanded(
                        child: TextButton(
                          onPressed: onReport,
                          child: Column(
                            children: [
                              Icon(Icons.report),
                              SizedBox(
                                height: 4,
                              ),
                              Text("Report"),
                            ],
                          ),
                        ),
                      )
                : Container(),
        SizedBox(
          width: 8,
        ),
      ],
    );
  }
}
