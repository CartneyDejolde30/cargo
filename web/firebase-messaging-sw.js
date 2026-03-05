importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// IMPORTANT: This config must be the same as your Firebase web app config.
// Using the values from `lib/firebase_options.dart` (DefaultFirebaseOptions.web).
firebase.initializeApp({
  apiKey: 'AIzaSyCSr0AwduLi3nF9IqGvEMw3t9Zpgi4V0M4',
  authDomain: 'project-1-d2d61.firebaseapp.com',
  projectId: 'project-1-d2d61',
  storageBucket: 'project-1-d2d61.firebasestorage.app',
  messagingSenderId: '647942447613',
  appId: '1:647942447613:web:e636696efbe2f8eff9f994',
});

const messaging = firebase.messaging();