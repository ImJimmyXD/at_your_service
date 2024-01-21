import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:flutter/foundation.dart';



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
      // Define your routes
      routes: {
        '/home_screen': (context) => const HomeScreen(),
        '/signup_screen': (context) => const SignUpScreen( ),
      },
      initialRoute: '/',

      title: 'Flutter Social Login Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LogInPage(),
    );
  }
}

class LogInPage extends StatelessWidget {
  const LogInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    // Check if the token is already set
    Future<void> checkTokenAndRedirect() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        // Token is already set, redirect to home screen
        if(!context.mounted) return;
        Navigator.pushReplacementNamed(context, '/home_screen');
      }
    }

    // Call the checkTokenAndRedirect function when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkTokenAndRedirect();
    });

    void showSnackBar(BuildContext context, String message) {
      final snackBar = SnackBar(content: Text(message));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    void showLoginSuccessDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Login Success'),
            content: const Text('You will be redirected to the home page.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    void showLoginErrorDialog(BuildContext context, String errorMessage) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Login Error'),
            content: Text(errorMessage),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    Future<void> login(BuildContext context) async {
      final String email = emailController.text;
      final String password = passwordController.text;

      // Check if email or password is empty
      if (email.isEmpty || password.isEmpty) {
        // Inform the user to enter email and password
        showSnackBar(context, 'Please enter email and password');
        return;
      }

      // Replace with your API endpoint
      final Uri apiUrl = Uri.parse('http://192.168.3.64:8080/signin');

      try {
        final response = await http.post(
          apiUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
            'password': password,
          }),
        );

        if (response.statusCode == 200) {
          // Assuming the response body contains a token
          final token = json.decode(response.body)['token'];

          // Save the token using SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);

          // Show a success message using showDialog
          if(!context.mounted) return;
          showLoginSuccessDialog(context);

          // Wait for 2 seconds
          await Future.delayed(const Duration(seconds: 2));

          if(!context.mounted) return;
          Navigator.pushReplacementNamed(context, '/home_screen');
        } else {
          // If the call to the server was not successful, handle the error
          if(!context.mounted) return;
          showLoginErrorDialog(context, 'Invalid email or password.');
        }
      } catch (e) {
        // Handle the error, show an alert or a Snackbar
        showSnackBar(context, 'Error: $e');
      }
    }



    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: passwordController,
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
                login(context);
                // Add login logic
              },
            ),
            const SizedBox(height: 8.0),
            Center(
              child: GestureDetector(
                onTap: () {

                  Navigator.pushReplacementNamed(
                    context,
                    '/signup_screen',
                    arguments: {'previousScreen': ModalRoute.of(context)?.settings.name}, // Pass the previousScreen
                  );

                },
                child: const Text(
                  "Sign Up",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
