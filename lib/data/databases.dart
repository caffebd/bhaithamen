import 'package:bhaithamen/utilities/variables.dart';

class DatabaseService {

  final String uid;
  DatabaseService({this.uid});

Future updateUserData (String userName, String email) async{
  return await userCollection.doc(uid).set({
        'uid': uid,
        'username': userName,
        'email': email,
        'profilepic': 'default'
        
      
      });
}

}