import 'package:chat_app/helperfunctions/sharedpref_helper.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  getCurrentUser() async {
    return auth.currentUser;
  }

  Future saveSharedPrefs(userDetails) async {
    await SharedPreferenceHelper().saveUserEmail(userDetails.email);
    await SharedPreferenceHelper().saveUserId(userDetails.uid);
    await SharedPreferenceHelper()
        .saveUserName(userDetails.email.replaceAll("@gmail.com", ""));
    await SharedPreferenceHelper().saveDisplayName(userDetails.displayName);
    await SharedPreferenceHelper().saveUserProfileUrl(userDetails.photoURL);
  }

  getSharedPrefs() async {
    String myUserEmail, myUserId, myUserName, myDisplayName, myUserProfilePic;
    myUserEmail = await SharedPreferenceHelper().getUserEmail();
    myUserId = await SharedPreferenceHelper().getUserId();
    myUserName = await SharedPreferenceHelper().getUserName();
    myDisplayName = await SharedPreferenceHelper().getDisplayName();
    myUserProfilePic = await SharedPreferenceHelper().getUserProfileUrl();

    print("User details from shared prefs is");
    print("myUserEmail $myUserEmail");
    print("myUserId $myUserId");
    print("myUserName $myUserName");
    print("myDisplayName $myDisplayName");
    print("myUserProfilePic $myUserProfilePic");
  }

  signInWithGoogle(BuildContext context) async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    final GoogleSignInAccount _googleSignInAccount =
        await _googleSignIn.signIn();

    final GoogleSignInAuthentication googleSignInAuthentication =
        await _googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken);
    UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    User userDetails = userCredential.user;

    if (userCredential != null) {
      await saveSharedPrefs(userDetails);
      await getSharedPrefs();

      List searchListForUser = [];
      String temp = "", name = userDetails.displayName;
      for (int i = 0; i < name.length; ++i) {
        temp = temp + name[i];
        searchListForUser.add(temp.toLowerCase());
      }

      Map<String, dynamic> userInfoMap = {
        "email": userDetails.email,
        "username": userDetails.email.replaceAll("@gmail.com", ""),
        "name": userDetails.displayName,
        "imgUrl": userDetails.photoURL,
        "searchUserList": searchListForUser,
      };

      DatabaseMethods()
          .addUserInfoToDB(userDetails.uid, userInfoMap)
          .then((value) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Home()));
      });
    }
  }

  Future signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    await auth.signOut();
  }

  
}
