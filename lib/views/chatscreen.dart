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
    } else if (url.startsWith("http") || url.startsWith("www")) {
      if (url.startsWith("www")) {
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
        r"(((https?)://)|www.)([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?";
    const String emailPattern = r'\S+@\S+';
    const String phonePattern = r'[\d-]{9,}';
    final RegExp linkRegExp = RegExp(
        '($urlPattern)|($phonePattern)|($emailPattern)',
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
    if (linkText.contains(RegExp(urlPattern, caseSensitive: false))) {
      // print(linkText);
      list.add(buildLinkComponent(linkText, linkText, sendByMe));
    } else if (linkText.contains(RegExp(phonePattern, caseSensitive: false))) {
      // print("num");
      // print(linkText);
      list.add(buildLinkComponent(linkText, 'tel:$linkText', sendByMe));
    } else if (linkText.contains(RegExp(emailPattern, caseSensitive: false))) {
      // print("email");

      list.add(buildLinkComponent(linkText, 'mailto:$linkText', sendByMe));
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

  addMessage(bool sendClicked) async {
    if (widget.forwardedMessage != null && sendClicked) {
      String message = widget.forwardedMessage;
      var lastMessageTS = DateTime.now();

      var bytes = utf8.encode("$message$lastMessageTS"); // data being hashed

      messageId = sha1.convert(bytes).toString();
      print(messageId);
      print("forwardedMessageid is ${widget.forwardedMessageId}");

      DocumentSnapshot<Map<String, dynamic>> forwarded;
      forwarded = await DatabaseMethods()
          .getForwarded(widget.forwardedChatRoomId, widget.forwardedMessageId);
      List forwardedList, upVoters;

      forwardedList = forwarded["forwardedTo"];
      upVoters = forwarded["upVoters"];
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
      };

      DatabaseMethods()
          .addMessage(chatRoomId, messageId, messageInfoMap)
          .then((value) {
        print(messageId);

        for (var forwardedlistmap in forwardedList) {
          print("forwardedlistmap $forwardedlistmap");
          DatabaseMethods()
              .updateForwardedList(forwardedlistmap, forwardedList);
        }

        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": message,
          "lastMessageSendTS": lastMessageTS,
          "lastMessageSendBy": myUserName,
          "lastMessageId": messageId,
        };

        DatabaseMethods().updateLastMessageSend(chatRoomId, lastMessageInfoMap);
      });

      setState(() {
        widget.forwardedMessage = null;
      });
    }

    if (widget.forwardedMessage == null &&
        messageTextEditingController.text != "" &&
        sendClicked) {
      print("chat room id inside addMessage is $chatRoomId");
      // messageId = null;
      String message = messageTextEditingController.text;
      messageTextEditingController.text = "";
      var lastMessageTS = DateTime.now();

      var bytes = utf8.encode("$message$lastMessageTS"); // data being hashed

      messageId = sha1.convert(bytes).toString();
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

  Widget chatMessageTile(String messageId, String message, String sendBy,
      Timestamp ts, bool forwarded, String sendByName, List upVoters) {
    bool sendByMe = sendBy == myUserName;
    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(ts.millisecondsSinceEpoch);

    void showCustomPopupMenu(TapDownDetails details, String message,
        String messageId, String chatRoomId) {
      final RenderBox overlay = Overlay.of(context).context.findRenderObject();

      showMenu(
          context: context,
          items: <PopupMenuEntry<Icon>>[
            PopUpEntry(
                message, messageId, chatRoomId, forwarded, myUserName, upVoters)
          ],
          position: RelativeRect.fromRect(
              details.globalPosition &
                  const Size(40, 40), // smaller rect, the touch area
              Offset.fromDirection(pi / 2, 120) &
                  overlay.semanticBounds.size // Bigger rect, the entire screen
              ));
    }

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
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
                          forwarded
                              ? Row(
                                  children: [
                                    Icon(Icons.forward),
                                    Text("Forwarded")
                                  ],
                                )
                              : SizedBox(
                                  height: 0.0,
                                ),
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
                      ds["upVoters"]);
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
        centerTitle: true,
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
                // maxLines: 2,
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
                    child: Icon(Icons.person_add_alt_sharp),
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
  final bool forwarded;
  PopUpEntry(this.message, this.messageId, this.chatRoomId, this.forwarded,
      this.upvoterName, this.upVoters);

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

    for (var forwardedlistmap in forwardedList) {
      print("forwardedlistmap $forwardedlistmap");
      DatabaseMethods().updateReported(forwardedlistmap, upVoters);
    }
  }

  @override
  Widget build(BuildContext context) {
    String urlPattern =
        r"(((https?)://)|www.)([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?";
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
        widget.forwarded &&
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
