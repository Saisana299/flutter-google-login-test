import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:login_test/env/env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // supabaseの初期化
  await Supabase.initialize(
    url: Env.supabaseUrl, // supabaseのURL
    anonKey: Env.anonKey, // supabaseのプロジェクトのAPIキー(anon)
  );
  runApp(const MyApp());
}

// supabase変数にインスタンスを格納しておく
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Login Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _userId;

  // Android, iOS の場合のGoogleログイン処理
  Future<void> _nativeGoogleSignIn() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: Platform.isAndroid ? Env.androidClientId : Env.iosClientId,
      serverClientId: Env.webClientId,
    );
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _userId = data.session?.user.id; // ユーザーIDの取得
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_userId == null) const Text('Not signed in'),
            if (_userId == null) ElevatedButton(
              onPressed: () async {
                if(!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                  // Android, iOS の場合
                  await _nativeGoogleSignIn();
                } else {
                  // Webブラウザの場合
                  await supabase.auth.signInWithOAuth(OAuthProvider.google);
                }
              },
              child: const Text('Google Login'),
            ),
            if (_userId != null) Text('User ID: $_userId'),
          ],
        ),
      ),
    );
  }
}
