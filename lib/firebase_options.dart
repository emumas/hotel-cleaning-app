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
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBHqgce--zPg0wrzBEqkz0tQMx2zBpaYEw',
    appId: '1:851039599507:web:348858f3401d2893fb0666',
    messagingSenderId: '851039599507',
    projectId: 'hotel-47826',
    authDomain: 'hotel-47826.firebaseapp.com',
    storageBucket: 'hotel-47826.firebasestorage.app',
    measurementId: 'G-ETSJK1SHFK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'hotel-47826',
    storageBucket: 'hotel-47826.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'hotel-47826',
    storageBucket: 'hotel-47826.firebasestorage.app',
    iosBundleId: 'com.example.hotelCleaningApp',
  );
}
