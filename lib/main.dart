import 'package:flutter/material.dart';
// Import the necessary packages for Google, Facebook, and Instagram authentication
// For example:
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Social Login Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              child: const Text('Login'),
              onPressed: () {
                // Add login logic
              },
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                // Add Google sign-in logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Google's brand color
              ),
              child: const Text('Sign in with Google'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                // Add Facebook sign-in logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Facebook's brand color
              ),
              child: const Text('Sign in with Facebook'),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                // Add Instagram sign-in logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink, // Instagram's brand color
              ),
              child: const Text('Sign in with Instagram'),
            ),
          ],
        ),
      ),
    );
  }
}
