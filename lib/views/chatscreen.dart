import 'dart:convert';
import 'dart:math';

import 'package:chat_app/helperfunctions/sharedpref_helper.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/addusertogroup.dart';
import 'package:chat_app/views/forwarded_menu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class ChatScreen extends StatefulWidget {
  final String chatWithUsername, name, profileUrl, lastMessage;
  String forwardedMessage, forwardedMessageId, forwardedChatRoomId;

  ChatScreen(this.chatWithUsername, this.name, this.profileUrl,
      [this.lastMessage,
      this.forwardedMessage,
      this.forwardedMessageId,
      this.forwardedChatRoomId]);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Text buildTextWithLinks(String textToLink, bool sendByMe) => Text.rich(
        TextSpan(children: linkify(textToLink, sendByMe)),
        style: TextStyle(color: Colors.white),
      );

  Future<void> openUrl(String url) async {
    if (url.startsWith(r'tel')) {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } else if (url.startsWith(r'mailto')) {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } else {
      if (url.startsWith("www")) {
        url = "https://$url";
      } else if (!url.startsWith("http")) {
        url = "https://$url";
      }
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    }
  }

  WidgetSpan buildLinkComponent(
          String text, String linkToOpen, bool sendByMe) =>
      WidgetSpan(
          child: InkWell(
        child: Text(
          text,
          style: TextStyle(
            color: sendByMe
                ? Colors.lightBlue.shade100
                : Colors.lightBlue.shade300,
            decoration: TextDecoration.underline,
          ),
        ),
        onTap: () => openUrl(linkToOpen),
      ));

  List<InlineSpan> linkify(String text, bool sendByMe) {
    const String urlPattern =
        r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+';
    const String emailPattern = r'\S+@\S+';
    const String phonePattern = r'[\d-]{9,}';
    final RegExp linkRegExp = RegExp(
        '($emailPattern)|($phonePattern)|($urlPattern)',
        caseSensitive: false);
    final List<InlineSpan> list = <InlineSpan>[];
    final RegExpMatch match = linkRegExp.firstMatch(text);
    if (match == null) {
      list.add(TextSpan(text: text));
      return list;
    }

    if (match.start > 0) {
      print(match.start);
      list.add(TextSpan(text: text.substring(0, match.start)));
    }

    final String linkText = match.group(0);
    if (linkText.contains(RegExp(emailPattern, caseSensitive: false))) {
      // print("email");

      list.add(buildLinkComponent(linkText, 'mailto:$linkText', sendByMe));
    } else if (linkText.contains(RegExp(urlPattern, caseSensitive: false))) {
      // print(linkText);
      list.add(buildLinkComponent(linkText, linkText, sendByMe));
    } else if (linkText.contains(RegExp(phonePattern, caseSensitive: false))) {
      // print("num");
      // print(linkText);
      list.add(buildLinkComponent(linkText, 'tel:$linkText', sendByMe));
    } else {
      throw 'Unexpected match: $linkText';
    }

    list.addAll(
        linkify(text.substring(match.start + linkText.length), sendByMe));

    return list;
  }

  String chatRoomId, messageId;
  Stream messageStream;
  String myName, myProfilePic, myUserName, myEmail;
  TextEditingController messageTextEditingController = TextEditingController();
  bool selected = false;

  getMyInfoFromSharedPreferences() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();

    if (widget.chatWithUsername.contains("Group", 0)) {
      chatRoomId = widget.chatWithUsername;
    } else {
      chatRoomId = getChatRoomIdByUsername(widget.chatWithUsername, myUserName);
    }
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

  Future<List> postRequest(String message, int forwarded) async {
    var url = 'https://us-central1-chatapp-89c43.cloudfunctions.net/isFake';
    var body = json.encode({
      "msg": message,
      "forwarded": forwarded,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json-patch+json',
        },
        body: body,
      );

      var output = json.decode(response.body);
      String message = output["msg"];
      String classOfMessage = output["class"];
      int confidence = output["confidence"];

      print("Hello, $message, $classOfMessage, $confidence");
      return [confidence, classOfMessage];
    } catch (e) {
      return [null, null];
    }
  }

  addMessage(bool sendClicked) async {
    if (widget.forwardedMessage != null && sendClicked) {
      String message = widget.forwardedMessage;
      var lastMessageTS = DateTime.now();

      var bytes = utf8.encode("$message$lastMessageTS");

      messageId = sha256.convert(bytes).toString();
      print(messageId);
      print("forwardedMessageid is ${widget.forwardedMessageId}");

      DocumentSnapshot<Map<String, dynamic>> forwarded;
      forwarded = await DatabaseMethods()
          .getForwarded(widget.forwardedChatRoomId, widget.forwardedMessageId);

      List forwardedList, upVoters;
      int confidenceFake, confidenceReal;
      bool authorityReported;

      forwardedList = forwarded["forwardedTo"];
      upVoters = forwarded["upVoters"];
      confidenceFake = forwarded["confidenceFake"];
      confidenceReal = forwarded["confidenceReal"];
      authorityReported = forwarded["authorityReported"];

      if (authorityReported == false) {
        print("Hello is working");
        int confidence;
        String classOfMessage;
        List check;

        check = await DatabaseMethods().checkMessageCollection(message);
        confidence = check[0];
        classOfMessage = check[1];

        if (confidence == null && classOfMessage == null) {
          print("Hello Part 2 is working");
          check = await postRequest(message, 1);
          confidence = check[0];
          classOfMessage = check[1];
        }

        if (classOfMessage == "Fake") {
          print("Hello Part 3 is working");
          confidenceFake = confidence;
        }
      }

      Map<String, String> forwardedListInfoMap = {
        "chatRoomId": chatRoomId,
        "messageId": messageId
      };
      forwardedList.add(forwardedListInfoMap);

      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sendBy": myUserName,
        "sendByName": myName,
        "ts": lastMessageTS,
        "imgUrl": myProfilePic,
        "forwardedTo": forwardedList,
        "forwarded": true,
        "reported": forwarded["reported"],
        "upVoters": upVoters,
        "confidenceFake": confidenceFake,
        "confidenceReal": confidenceReal,
        "authorityReported": authorityReported
      };

      DatabaseMethods()
          .addMessage(chatRoomId, messageId, messageInfoMap)
          .then((value) {
        print(messageId);

        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": message,
          "lastMessageSendTS": lastMessageTS,
          "lastMessageSendBy": myUserName,
          "lastMessageId": messageId,
        };

        DatabaseMethods().updateLastMessageSend(chatRoomId, lastMessageInfoMap);

        for (var forwardedlistmap in forwardedList) {
          print("forwardedlistmap $forwardedlistmap");
          DatabaseMethods()
              .updateForwardedList(forwardedlistmap, forwardedList);
        }

        for (var forwardedlistmap in forwardedList) {
          print("forwardedlistmap $forwardedlistmap");
          DatabaseMethods()
              .updateConfidenceFake(forwardedlistmap, confidenceFake);
        }
      });

      setState(() {
        widget.forwardedMessage = null;
      });
    }

    if (widget.forwardedMessage == null &&
        messageTextEditingController.text != "" &&
        sendClicked) {
      print("chat room id inside addMessage is $chatRoomId");
      String message = messageTextEditingController.text;
      messageTextEditingController.text = "";

      int confidence = 0;
      String classOfMessage;
      List check;

      check = await DatabaseMethods().checkMessageCollection(message);
      if (check[0] != null && check[1] != null) {
        confidence = check[0];
        classOfMessage = check[1];
      }

      if (confidence == null && classOfMessage == null) {
        check = await postRequest(message, 0);
        if (check[0] != null && check[1] != null) {
          confidence = check[0];
          classOfMessage = check[1];
        }
      }

      var lastMessageTS = DateTime.now();

      var bytes = utf8.encode("$message$lastMessageTS");

      messageId = sha256.convert(bytes).toString();
      print(messageId);
      print("forwardedMessageid is ${widget.forwardedMessageId}");

      List forwardedList = [];
      Map<String, String> forwardedListInfoMap = {
        "chatRoomId": chatRoomId,
        "messageId": messageId
      };
      forwardedList.add(forwardedListInfoMap);

      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sendBy": myUserName,
        "sendByName": myName,
        "ts": lastMessageTS,
        "imgUrl": myProfilePic,
        "forwarded": false,
        "forwardedTo": forwardedList,
        "reported": false,
        "upVoters": [],
        "confidenceFake": confidence,
        "confidenceReal": 0,
        "authorityReported": false,
      };

      DatabaseMethods()
          .addMessage(chatRoomId, messageId, messageInfoMap)
          .then((value) {
        print(messageId);
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": message,
          "lastMessageSendTS": lastMessageTS,
          "lastMessageSendBy": myUserName,
          "lastMessageId": messageId,
        };
        print("add message inside chat screen is working");

        DatabaseMethods().updateLastMessageSend(chatRoomId, lastMessageInfoMap);
      });
    }
  }

  Widget chatMessageTile(
      String messageId,
      String message,
      String sendBy,
      Timestamp ts,
      bool forwarded,
      String sendByName,
      List upVoters,
      int confidenceFake,
      int confidenceReal) {
    bool sendByMe = sendBy == myUserName;
    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(ts.millisecondsSinceEpoch);

    void showCustomPopupMenu(TapDownDetails details, String message,
        String messageId, String chatRoomId) {
      final RenderBox overlay = Overlay.of(context).context.findRenderObject();

      showMenu(
          context: context,
          items: <PopupMenuEntry<Icon>>[
            PopUpEntry(message, messageId, chatRoomId, forwarded, myUserName,
                upVoters, confidenceFake, confidenceReal)
          ],
          position: RelativeRect.fromRect(
              details.globalPosition & const Size(40, 40),
              Offset.fromDirection(pi / 2, 120) & overlay.semanticBounds.size));
    }

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
        showCustomPopupMenu(details, message, messageId, chatRoomId);
      },
      child: Card(
        color: Colors.grey.shade50,
        elevation: 0,
        child: Row(
          mainAxisAlignment:
              sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          //this will determine if the message should be displayed left or right

          children: [
            Flexible(
              child: IntrinsicWidth(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.0),
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                          color: sendByMe ? Colors.blue : Colors.blueGrey,
                          borderRadius: BorderRadius.all(Radius.circular(6.0))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          chatRoomId.contains("Group", 0)
                              ? sendByMe
                                  ? Container()
                                  : Text(sendByName)
                              : Container(),
                          confidenceFake > 50
                              ? Text("This is $confidenceFake% fake")
                              : Container(),
                          forwarded
                              ? Row(
                                  children: [
                                    Icon(Icons.forward),
                                    Text("Forwarded")
                                  ],
                                )
                              : Container(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                constraints: BoxConstraints(maxWidth: 250),
                                child: buildTextWithLinks(
                                    message.trim(), sendByMe),
                              ),
                              SizedBox(
                                width: 10.0,
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 4.0),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd MMM hh:mm a').format(date),
                                style: TextStyle(
                                    fontSize: 10.0, color: Colors.black),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget chatMessages() {
    return StreamBuilder(
      stream: messageStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                padding: EdgeInsets.only(bottom: 70, top: 16),
                itemCount: snapshot.data.docs.length,
                reverse: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return chatMessageTile(
                      ds.id,
                      ds["message"],
                      ds["sendBy"],
                      ds["ts"],
                      ds["forwarded"],
                      ds["sendByName"],
                      ds["upVoters"],
                      ds["confidenceFake"],
                      ds["confidenceReal"]);
                },
              )
            : Center(child: CircularProgressIndicator());
      },
    );
  }

  getAndSetMessages() async {
    messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomId);
    setState(() {});
  }

  doThisOnLaunch() async {
    await getMyInfoFromSharedPreferences();
    await getAndSetMessages();
    print("dothis launch $chatRoomId");
  }

  doThisForForwardedMessage() async {
    await doThisOnLaunch();

    print("Inside chatscreen doThisForNormalEntry $chatRoomId");
    if (widget.forwardedMessage != null) {
      print("Inside chatscreen doThisFOrFOrwardedMessage1 $chatRoomId");
      addMessage(true);
      setState(() {});
    }
  }

  @override
  void initState() {
    doThisForForwardedMessage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.profileUrl,
                height: 40,
                width: 40,
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace stackTrace) {
                  return CircleAvatar(
                    child: Icon(
                      chatRoomId.contains("Group", 0)
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
            SizedBox(
              width: 20,
            ),
            Container(
              constraints: BoxConstraints(maxWidth: 235),
              child: Text(
                widget.name,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
        actions: [
          chatRoomId != null && chatRoomId.contains("Group")
              ? GestureDetector(
                  onTap: () {
                    selected = true;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                AddUserToGroup(chatRoomId, widget.profileUrl)));
                    setState(() {});
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(Icons.person_add_alt_1_sharp),
                  ),
                )
              : Container()
        ],
      ),
      body: Container(
        child: Stack(
          children: [
            chatMessages(),
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
                          addMessage(false);
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
                        addMessage(true);
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
          .addMessage(chatRoomId, widget.messageId, messageInfoMap)
          .then((value) {
        print(widget.messageId);
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": widget.message,
          "lastMessageSendTS": lastMessageTS,
          "lastMessageSendBy": username,
          "lastMessageId": widget.messageId,
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
            : widget.forwarded &&
                    (widget.message.split(" ").length > 10 || match != null)
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
