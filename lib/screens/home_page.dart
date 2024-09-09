import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

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
              'date': _parseDate(item['date']),
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

  DateTime? _parseDate(dynamic dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print('Error parsing date: $dateString. Error: $e');
      return null;
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

    if (posts.isEmpty) {
      return Center(child: Text('No posts to display'));
    }

    return RefreshIndicator(
      onRefresh: _fetchPosts,
      child: ListView.separated(
        itemCount: posts.length,
        separatorBuilder: (context, index) => Container(
          height: 40,
          child: Center(
            child: Container(
              margin: EdgeInsets.all(3),
              width: 2,
              color: Colors.white,
            ),
          ),
        ),
        itemBuilder: (context, index) {
          final post = posts[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              children: [
                if (post['date'] != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('dd.MM.yyyy').format(post['date']),
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                if (post['images'] != null && (post['images'] as List).isNotEmpty)
                  Container(
                    color: Colors.grey[900],
                    height: 150,
                    child: PageView.builder(
                      itemCount: (post['images'] as List).length,
                      itemBuilder: (context, imageIndex) {
                        return Center(
                          child: _buildBase64Image((post['images'] as List)[imageIndex]),
                        );
                      },
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                  child: Center(
                    child: Text(
                      post['description'] ?? 'No description',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        height: 150,
        width: 250,
        color: Colors.grey[700],
        child: Center(child: Text('No image', style: TextStyle(color: Colors.white))),
      );
    }

    try {
      base64String = base64String.trim();

      if (base64String.startsWith('data:image')) {
        base64String = base64String.split(',')[1];
      }

      Uint8List bytes = base64Decode(base64String);

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          height: 150,
          width: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error');
            return Container(
              height: 150,
              width: 250,
              color: Colors.grey[700],
              child: Center(child: Text('Error loading image', style: TextStyle(color: Colors.white))),
            );
          },
        ),
      );
    } catch (e) {
      print('Error decoding base64: $e');
      return Container(
        height: 150,
        width: 250,
        color: Colors.grey[700],
        child: Center(child: Text('Invalid image format', style: TextStyle(color: Colors.white))),
      );
    }
  }
}