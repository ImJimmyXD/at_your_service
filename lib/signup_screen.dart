import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});


  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    // Check if the password and confirm password fields match
    if (password != confirmPassword) {
      _showDialog('Error', 'Passwords do not match.');
      return;
    }

    // Check if email or password is empty
    if (email.isEmpty || password.isEmpty) {
      _showDialog('Error', 'Please enter email and password.');
      return;
    }

    // Replace with your API endpoint
    final Uri apiUrl = Uri.parse('http://10.0.2.2:8080/signup');

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
        // Handle successful response
        _showDialog('Success', 'User created successfully');
        // Optionally navigate to the login page or home page

        // Wait for 2 seconds
        await Future.delayed(const Duration(seconds: 2));

        if(!context.mounted) return;
        Navigator.of(context).pop(); // This will close the dialog
        Navigator.of(context).pop(); // This will close the sign-up screen
      } else {
        // Handle non-successful response
        _showDialog('Error', 'Failed to create user: ${response.body}');
      }
    } catch (e) {
      // Handle network error
      _showDialog('Error', 'Network error: $e');
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Retrieve the previousScreen from the arguments
    final previousScreen = args?['previousScreen'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Add a back button icon
          onPressed: () {
            if(!context.mounted) {
              debugPrint('context not mounted');
              return;
            }
            Navigator.pushReplacementNamed(context, previousScreen!);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _registerUser,
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
