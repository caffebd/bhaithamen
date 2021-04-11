import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

final GoogleSignIn googleSignIn = GoogleSignIn();
final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

Future<String> signInWithGoogle() async {
  await Firebase.initializeApp();

  final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

  final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
    accessToken: googleSignInAuthentication.accessToken,
    idToken: googleSignInAuthentication.idToken,
  );

  final auth.UserCredential authResult =
      await _auth.signInWithCredential(credential);
  final auth.User user = authResult.user;

  if (user != null) {
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final auth.User currentUser = _auth.currentUser;
    assert(user.uid == currentUser.uid);

    //setLocalAuth(true);

    print('signInWithGoogle succeeded: $user');

    return '$user';
  }

  return null;
}

Future<void> signOutGoogle() async {
  //await googleSignIn.disconnect();
  await googleSignIn.signOut();

  print("User Signed Out");
}
