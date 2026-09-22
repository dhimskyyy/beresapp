// File generated to configure Firebase for Android, iOS, and Web.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCdVv40X7hD0NoGMNKtWyzsNzjASKkMKRU',
    appId: '1:563609525230:web:0b3d3fed1a4befd144ccff',
    messagingSenderId: '563609525230',
    projectId: 'beress-app',
    authDomain: 'beress-app.firebaseapp.com',
    storageBucket: 'beress-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbmoWRV-AIioCNj6fXr4FGcpU_aql73VU',
    appId: '1:563609525230:android:a0948dea15fb706a44ccff',
    messagingSenderId: '563609525230',
    projectId: 'beress-app',
    storageBucket: 'beress-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC9G6sIFl1JxpdDLVbZ8yFESg36Nhn7AtA',
    appId: '1:563609525230:ios:6252ba808e1b902444ccff',
    messagingSenderId: '563609525230',
    projectId: 'beress-app',
    storageBucket: 'beress-app.firebasestorage.app',
    iosClientId: '563609525230-q1glt8s7v1u32c9190e09a91q43pkt93.apps.googleusercontent.com',
    iosBundleId: 'com.beres.beresapp',
  );
}
