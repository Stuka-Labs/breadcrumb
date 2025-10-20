import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB_w0Oa_tWr1xvJLJ0eEI-SHfh-sbG7IsU',
    projectId: 'breadcrumb-bd857',
    messagingSenderId: '892664263258',
    appId: '1:892664263258:web:dff04dd52b3f0fd11bde63',
    authDomain: 'breadcrumb-bd857.firebaseapp.com',
    storageBucket: 'breadcrumb-bd857.appspot.com',
    measurementId: 'G-1EYR7DFV5Z',
    databaseURL: 'https://breadcrumb-bd857-default-rtdb.firebaseio.com',
  );

  // Local emulator configuration for debugging
  static const FirebaseOptions localEmulator = FirebaseOptions(
    apiKey: 'demo-api-key',
    projectId: 'demo-project',
    messagingSenderId: '123456789',
    appId: '1:123456789:web:demo',
    authDomain: 'localhost:9099',
    storageBucket: 'localhost:9199',
    measurementId: 'demo-measurement-id',
  );
} 