import 'dart:convert';

import 'package:chat_app/helperfunctions/sharedpref_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class DatabaseMethods {
  Future addUserInfoToDB(
      String userId, Map<String, dynamic> userInfoMap) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .set(userInfoMap);
  }

  Future addGroupInfoToDB(
      String groupId, Map<String, dynamic> userInfoMap) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(groupId)
        .set(userInfoMap);
  }

  Future<Stream<QuerySnapshot>> getUserByUserName(String name) async {
    return FirebaseFirestore.instance
        .collection("users")
        .where("searchUserList", arrayContains: name.toLowerCase())
        .snapshots();
  }

  Future<List> getAuthorities() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection("authorities").get();
    List authorities = [];
    querySnapshot.docs.forEach((element) {
      authorities.add(element);
    });
    return authorities;
  }

  Future addMessage(
      String chatRoomId, String messageId, Map messageInfoMap) async {
    print("I am printing $messageId inside addMessage");
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .set(messageInfoMap);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getForwarded(
      String chatRoomId, String messageId) async {
    print("inside getForwarded $messageId");
    print("inside getForwarded $chatRoomId");
    return await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .get();
  }

  Future<List> getChatRoomUsers(String chatRoomId) async {
    List userList = [];
    await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get()
        .then((DocumentSnapshot ds) {
      if (ds.data() != null) {
        userList = ds["users"];
        print("userList inside getForwarded is $userList");
      }
    });
    print(userList);
    return userList;
  }

  updateForwardedList(Map forwardedlist, List forwardedList) {
    String chatRoomId = forwardedlist["chatRoomId"];
    String messageId = forwardedlist["messageId"];
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .update({"forwardedTo": forwardedList});
  }

  updateConfidenceFake(Map forwardedlist, int confidenceFake) {
    String chatRoomId = forwardedlist["chatRoomId"];
    String messageId = forwardedlist["messageId"];
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .update({"confidenceFake": confidenceFake});
  }

  updateReported(Map forwardedlist, List upVoters) {
    String chatRoomId = forwardedlist["chatRoomId"];
    String messageId = forwardedlist["messageId"];
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .update({"reported": true, "upVoters": upVoters});
  }

  addUserToGroup(String chatRoomId, List usersList) {
    print("user added by addUserToGroup");
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .update({"users": usersList}).then((value) =>
            print("user added by addUserToGroup value is jsjkksdjss"));
  }

  Future<List> checkMessageCollection(String message) async {
    var bytes = utf8.encode(message);
    String messageId = sha256.convert(bytes).toString();
    int confidence;
    String classOfMessage;
    List forwardedList, upVoters;
    await FirebaseFirestore.instance
        .collection("messages")
        .doc(messageId)
        .get()
        .then((DocumentSnapshot ds) {
      if (ds.data() != null) {
        confidence = ds["confidence"];
        classOfMessage = ds["class"];
        forwardedList = ds["forwardedTo"];
        upVoters = ds["upvoters"];
        print("all good $forwardedList");
      }
    });

    return [confidence, classOfMessage, forwardedList, upVoters];
  }

  Future<Timestamp> getLastMessageTS(
      String chatRoomId, String messageId) async {
    print("Hello, getLastMessageTS is working");
    Timestamp lastMessageTS;
    await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .get()
        .then((DocumentSnapshot ds) {
      print("Hello, getLastMessageTS then is working");
      if (ds.data() != null) {
        print("Hello, getLastMessageTS then if is working");
        lastMessageTS = ds["ts"];
        print("Hello, getLastMessageTS the if 2 is working $lastMessageTS");
      } else {
        lastMessageTS = null;
      }
    });
    print("One to 3 $lastMessageTS");
    return lastMessageTS;
  }

  updateLastMessageSend(String chatRoomId, Map lastMessageInfoMap) {
    print("Hello, updateLastmessageSend is working");
    print(lastMessageInfoMap["lastMessageId"]);
    print(chatRoomId);
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .set(lastMessageInfoMap, SetOptions(merge: true));
  }

  createChatRoom(
      String chatRoomId, Map chatRoomInfoMap, Map lastMessageInfoMap) async {
    print("Fuckoff this createRoom ");
    FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get()
        .then((DocumentSnapshot snapShot) {
      if (snapShot.data() != null) {
        print("Hello, createRoom then if is working");
        return null;
      } else {
        print("Hello, createRoom then else is working");
        FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(chatRoomId)
            .set(chatRoomInfoMap);
        return FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(chatRoomId)
            .set(lastMessageInfoMap, SetOptions(merge: true));
      }
    });
  }

  Future<Stream<QuerySnapshot>> getChatRoomMessages(String chatRoomId) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("ts", descending: true)
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> getChatRooms() async {
    String myUsername = await SharedPreferenceHelper().getUserName();
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .orderBy("lastMessageSendTS", descending: true)
        .where("users", arrayContains: myUsername)
        .snapshots();
  }

  Future<QuerySnapshot> getUserInfo(String username) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .get();
  }

  Future<QuerySnapshot> getGroupInfo(String username) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .get();
  }
}
