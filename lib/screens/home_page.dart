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

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');
    try {
      print('Uživatel $userId');
      final body = json.encode({'user_id': userId});

      print('Sending request to server...'); // Log the request
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/get_post.php'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      print('Received response. Status code: ${response.statusCode}'); // Log the response status

      if (response.statusCode == 200) {
        print('Response body: ${response.body}'); // Log the full response body
        final List<dynamic> data = json.decode(response.body);
        print('Decoded data: $data'); // Log decoded data

        setState(() {
          posts = data.map((item) {
            print('Processing item: $item'); // Log each item being processed
            return {
              'date': _parseDate(item['date']),
              'imageBase64': item['image'] as String?,
              'description': item['description'] as String? ?? 'No description',
            };
          }).toList();
        });
        print('Processed posts: $posts'); // Log processed posts
      } else {
        throw Exception('Failed to load posts. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _fetchPosts: $e'); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při načítání příspěvků: $e')),
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
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Implementujte funkci vyhledávání
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          Container(), // Placeholder for AddPostPage
          Container(), // Placeholder for SearchPage
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            if (index == 0) {
              Navigator.pushNamed(context, '/home_page');
            } else if (index == 1) {
              Navigator.pushNamed(context, '/add_post');
            } else if (index == 2) {
              Navigator.pushNamed(context, '/search_page');
            }
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Domů'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Přidat'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Hledat'),
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
      return Center(child: Text('Žádné příspěvky k zobrazení'));
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
                if (post['imageBase64'] != null && post['imageBase64'].isNotEmpty)
                  Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: _buildBase64Image(post['imageBase64']),
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
        child: Center(child: Text('Žádný obrázek', style: TextStyle(color: Colors.white))),
      );
    }

    try {
      base64String = base64String.trim();

      if (base64String.startsWith('data:image')) {
        base64String = base64String.split(',')[1];
      }

      print('Decoding base64 string: ${base64String.substring(0, min(50, base64String.length))}...');
      Uint8List bytes = base64Decode(base64String);

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          height: 150,
          width: 250, // Zmenšená šířka
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error');
            return Container(
              height: 150,
              width: 250, // Zmenšená šířka
              color: Colors.grey[700],
              child: Center(child: Text('Chyba při načítání obrázku', style: TextStyle(color: Colors.white))),
            );
          },
        ),
      );
    } catch (e) {
      print('Error decoding base64: $e');
      print('Base64 string: ${base64String?.substring(0, min(50, base64String.length))}...');
      return Container(
        height: 150,
        width: 250,
        color: Colors.grey[700],
        child: Center(child: Text('Neplatný formát obrázku', style: TextStyle(color: Colors.white))),
      );
    }
  }
}