import 'package:google_sign_in/google_sign_in.dart' as gsi;
void main() {
  final gsi.GoogleSignIn googleSignIn = gsi.GoogleSignIn();
  print(googleSignIn.signIn);
}
