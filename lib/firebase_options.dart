import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBtlGFnFf8k2vXZjggH0RWpOl_A90odCc0',
    appId: '1:569202997079:web:17216d177395070399b012',
    messagingSenderId: '569202997079',
    projectId: 'expensetracker-65999',
    storageBucket: 'expensetracker-65999.firebasestorage.app',
    iosBundleId: 'com.example.demoapplication',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBtlGFnFf8k2vXZjggH0RWpOl_A90odCc0',
    appId: '1:569202997079:web:17216d177395070399b012',
    messagingSenderId: '569202997079',
    projectId: 'expensetracker-65999',
    authDomain: 'expensetracker-65999.firebaseapp.com',
    storageBucket: 'expensetracker-65999.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB_5ZJm3KXAjyoSXrifHqyPtKaAYsynmoQ',
    appId: '1:569202997079:android:8db01c24dc68e46299b012',
    messagingSenderId: '569202997079',
    projectId: 'expensetracker-65999',
    storageBucket: 'expensetracker-65999.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyFakeKeyForDemoApplication123456',
    appId: '1:123456789012:ios:abcdef1234567890abcdef',
    messagingSenderId: '123456789012',
    projectId: 'demoapplication-app',
    storageBucket: 'demoapplication-app.appspot.com',
    iosBundleId: 'com.example.demoapplication',
  );
}
