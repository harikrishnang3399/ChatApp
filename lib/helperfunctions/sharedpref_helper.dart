import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static String userIdKey = "USERKEY";
  static String userNameKey = "USERNAMEKEY";
  static String displayNameKey = "USERDISPLAYNAMEKEY";
  static String userEmailKey = "USEREMAILKEY";
  static String userProfilePicKey = "USERPROFILEPICKEY";

  // save data

  Future<bool> saveUserName(String getUserName) async {
    print("userNameKey $getUserName");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(userNameKey, getUserName);
    // userNameKey = getUserName;
    print("userNameKey $userNameKey");
    return true;
  }

  Future<bool> saveUserEmail(String getUserEmail) async {
    print("userEmailKey $getUserEmail");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(userEmailKey, getUserEmail);
    // userEmailKey = getUserEmail;
    print("userEmailKey $userEmailKey");
    return true;
  }

  Future<bool> saveUserId(String getUserId) async {
    print("userIdKey $getUserId");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(userIdKey, getUserId);
    // userIdKey = getUserId;
    print("userIdKey $userIdKey");
    return true;
  }

  Future<bool> saveDisplayName(String getDisplayName) async {
    print("displayNameKey $getDisplayName");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(displayNameKey, getDisplayName);
    // displayNameKey = getDisplayName;
    print("displayNameKey $displayNameKey");
    return true;
  }

  Future<bool> saveUserProfileUrl(String getUserProfile) async {
    print("userProfilePicKey $getUserProfile");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(userProfilePicKey, getUserProfile);
    // userProfilePicKey = getUserProfile;
    print("userProfilePicKey $userProfilePicKey");
    return true;
  }

  // get data

  Future<String> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("get userNameKey $userNameKey");
    return prefs.getString(userNameKey);
  }

  Future<String> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("get userEmailKey $userEmailKey");
    return prefs.getString(userEmailKey);
  }

  Future<String> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("get userIdKey $userIdKey");
    return prefs.getString(userIdKey);
  }

  Future<String> getDisplayName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("get displayNameKey $displayNameKey");
    return prefs.getString(displayNameKey);
  }

  Future<String> getUserProfileUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("get userProfilePicKey $userProfilePicKey");
    return prefs.getString(userProfilePicKey);
  }
}
