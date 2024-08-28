import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _message = '';

  Future<void> _register() async {
    final username = _usernameController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _message = 'Všechna pole jsou povinná';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _message = 'Hesla se neshodují';
      });
      return;
    }

    final response = await http.post(
      Uri.parse('http://lifetracker.euweb.cz/createuser.php'), // Adresa API
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _message = data['message'];
        if (data['success']) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    } else {
      setState(() {
        _message = 'Registrace se nezdařila';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrace')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Uživatelské jméno'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Prosím zadejte uživatelské jméno';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Heslo'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Prosím zadejte heslo';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Potvrzení hesla'),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Hesla se neshodují';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  child: Text('Registrovat se'),
                  onPressed: _register,
                ),
                SizedBox(height: 20),
                Text(_message, style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}