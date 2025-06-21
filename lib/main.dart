import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quizds/LeaderboardScreen.dart';
import 'package:quizds/firebase_options.dart';
import 'package:quizds/home.page.dart';
import 'package:quizds/login.view.dart';
import 'package:quizds/signup.view.dart';
import 'package:quizds/splash.view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'utils/theme_manager.dart';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background Message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('Notification tapped: ${response.payload}');
    },
  );

  // Get and print the access token
  try {
    final accessToken = await getAccessToken();
    print('OAuth 2.0 Access Token: $accessToken');
  } catch (e) {
    print('Error getting access token: $e');
  }

  await setupFCM(flutterLocalNotificationsPlugin);

  // Initialize theme manager
  final themeManager = ThemeManager();
  await themeManager.initializeTheme();

  runApp(
    ChangeNotifierProvider(
      create: (context) => themeManager,
      child: MyApp(),
    ),
  );
}

// Function to get OAuth 2.0 access token
Future<String> getAccessToken() async {
  // Load the service account JSON from assets
  final serviceAccountJson = await rootBundle.loadString(
      'adfile/quizds-3b5cc-firebase-adminsdk-fbsvc-8509acf71e.json');
  final serviceAccount = jsonDecode(serviceAccountJson);

  // Define the scopes required for FCM
  const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  // Create credentials from the service account
  final credentials = ServiceAccountCredentials.fromJson(serviceAccount);

  // Obtain an authenticated HTTP client
  final client = await clientViaServiceAccount(credentials, scopes);
  final accessToken = client.credentials.accessToken.data;

  // Close the client to avoid memory leaks
  client.close();

  return accessToken;
}

Future<void> setupFCM(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get token
  String? token = await messaging.getToken();
  print('FCM Token: $token');

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground Message: ${message.notification?.title}');
    if (message.notification != null) {
      _showNotification(
        message.notification!.title ?? 'No Title',
        message.notification!.body ?? 'No Body',
        flutterLocalNotificationsPlugin,
      );
    }
  });

  // Handle notification tap when app is in background or terminated
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification tapped: ${message.notification?.title}');
  });

  // Handle initial message
  RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    print('Initial Message: ${initialMessage.notification?.title}');
  }
}

// Show local notification
Future<void> _showNotification(String title, String body,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'channel_id',
    'Channel Name',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    notificationDetails,
  );
}

class MyApp extends StatelessWidget {
  final routes = {
    '/home': (context) => const HomePage(),
    '/signup': (context) => const SignupView(),
    '/login': (context) => const LoginView(),
    '/leaderboard': (context) => const LeaderboardScreen(
          category: 'defaultCategory',
          difficulty: 'defaultDifficulty',
        ),
  };

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          routes: routes,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getLightTheme(),
          darkTheme: AppTheme.getDarkTheme(),
          themeMode: themeManager.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashView(),
        );
      },
    );
  }
}
