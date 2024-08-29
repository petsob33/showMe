import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  bool _isPasswordValid(String password) {
    // Password must be at least 8 characters long and contain at least one number
    return password.length >= 8 && password.contains(RegExp(r'[0-9]'));
  }

  Future<void> _register() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = '';
      });

      final username = _usernameController.text;
      final password = _passwordController.text;

      try {
        final response = await http.post(
          Uri.parse('http://lifetracker.euweb.cz/createuser.php'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'username': username,
            'password': password,
          }),
        );

        final data = json.decode(response.body);

        setState(() {
          _isLoading = false;
          if (data['success'] != null) {
            _message = 'Registrace úspěšná!';
            // Navigate to home page
            prefs.setInt('user_id', data['user_id']);
            Navigator.pushReplacementNamed(context, '/home');
          } else if (data['error'] != null) {
            _message = data['error'];
          } else {
            _message = 'Neočekávaná odpověď ze serveru';
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _message = 'Chyba při komunikaci se serverem: $e';
        });
      }
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
            key: _formKey,
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
                    if (!_isPasswordValid(value)) {
                      return 'Heslo musí mít alespoň 8 znaků a obsahovat číslo';
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
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  child: Text('Registrovat se'),
                  onPressed: _register,
                ),
                SizedBox(height: 20),
                Text(
                  _message,
                  style: TextStyle(
                    color: _message.startsWith('Registrace úspěšná')
                        ? Colors.green
                        : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}