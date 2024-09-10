import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  List<User> _searchResults = [];
  List<Map<String, dynamic>> _recentPosts = [];
  Timer? _debounce;
  bool _isLoading = false;
  bool _isLoadingPosts = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchRecentPosts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.length >= 3) {
        _performSearch(_searchController.text);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/search_users.php'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'query': query,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((json) => User.fromJson(json)).toList();
        });
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      print('Error during search: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při vyhledávání: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRecentPosts() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getInt('user_id');
    if (userId == null) return;
    setState(() {
      _isLoadingPosts = true;
    });
    try {
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/get_recent_posts.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId,'limit':10}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _recentPosts = data.map((item) {
            return {
              'date': _parseDate(item['date']),
              'description': item['description'] as String? ?? 'No description',
              'images': item['images'] as List<dynamic>?,
              'username':item['username']
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
        _isLoadingPosts = false;
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

  void _navigateToUserProfile(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('searched_user_id', user.id);
    Navigator.pushNamed(context, '/user_profile', arguments: user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Hledat uživatele...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator()
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.username[0].toUpperCase()),
                      backgroundColor: Colors.blue,
                    ),
                    title: Text(
                      user.username,
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () => _navigateToUserProfile(user),
                  );
                },
              ),
            )
          else if (_searchController.text.isEmpty)
              Expanded(
                child: _isLoadingPosts
                    ? Center(child: CircularProgressIndicator())
                    : ListView.separated(
                  itemCount: _recentPosts.length,
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
                    final post = _recentPosts[index];
                    return Container(
                      padding: EdgeInsets.only(top: 30),
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
                                  post['username'],
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
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
        ],
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

class User {
  final int id;
  final String username;

  User({required this.id, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
    );
  }
}