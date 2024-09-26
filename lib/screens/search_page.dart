import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_post_list_widget.dart'; // Import the new shared widget

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
    if (userId == null) {
      return;
    }
    setState(() {
      _isLoadingPosts = true;
    });
    try {
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/get_recent_posts.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'limit': 10}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _recentPosts = data.map((item) {
            return {
              'date': DateTime.parse(item['date']),
              'description': item['description'] as String? ?? 'No description',
              'images': item['images'] as List<dynamic>?,
              'username': item['username']
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
                    : SharedPostListWidget(
                  posts: _recentPosts,
                  onRefresh: _fetchRecentPosts,
                  showUsername: true,
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