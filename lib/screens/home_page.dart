import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_post_list_widget.dart'; // Import the new shared widget

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> posts = [];
  bool isLoading = false;
  int? userId;
  String username = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
      username = prefs.getString('username') ?? '';
    });
    _fetchPosts();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('username');
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _fetchPosts() async {
    if (userId == null) return;
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/get_post.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          posts = data.map((item) {
            return {
              'date': DateTime.parse(item['date']),
              'images': item['images'] as List<dynamic>?,
              'description': item['description'] as String? ?? 'No description',
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to load posts. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _fetchPosts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading posts: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ShowMe'),
        actions: [
          Center(child: Text(username, style: TextStyle(fontSize: 16, color: Colors.white))),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "logout") {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Log out'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: 'logout',
                  child: Text(choice),
                );
              }).toList();
            },
          )
        ],
      ),
      body: _buildHomeContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 1) {
            final result = await Navigator.pushNamed(context, '/add_post');
            if (result == true) {
              _fetchPosts(); // Refresh posts after adding a new one
            }
          } else if (index == 2) {
            Navigator.pushNamed(context, '/search_page');
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
      ),
    );
  }

  Widget _buildHomeContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SharedPostListWidget(
      posts: posts,
      onRefresh: _fetchPosts,
    );
  }
}