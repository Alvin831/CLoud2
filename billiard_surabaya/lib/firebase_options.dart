import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAHp-KHqxxM3KNHf_ll4qd0cD4esp-zYuI',
    authDomain: 'billiard-surabaya-map.firebaseapp.com',
    projectId: 'billiard-surabaya-map',
    storageBucket: 'billiard-surabaya-map.firebasestorage.app',
    messagingSenderId: '682530664863',
    appId: '1:682530664863:web:391d7d01ea0be901570daa',
    measurementId: 'G-957N8FQEWD',
  );
}