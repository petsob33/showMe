import 'dart:async';
import 'dart:convert';
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
  List<Post> _recentPosts = [];
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
      if (_searchController.text.length > 3) {
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
    setState(() {
      _isLoadingPosts = true;
    });

      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getInt('user_id');

        if (userId == null) {
          throw Exception('User ID is null. Make sure the user is logged in.');
        }
        print(userId);
        final response = await http.post(
          Uri.parse('http://lifetracker.euweb.cz/get_recent_posts.php'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'user_id': userId,
            'limit': 10,
          }),
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _recentPosts = data.map((json) => Post.fromJson(json)).toList();
          });
        } else {
          throw Exception('Failed to load recent posts');
        }
      } catch (e) {
        print('Error fetching recent posts: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při načítání nedávných příspěvků: $e')),
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
          else
            Expanded(
              child: _isLoadingPosts
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _recentPosts.length,
                itemBuilder: (context, index) {
                  final post = _recentPosts[index];
                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(post.username),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('dd.MM.yyyy HH:mm').format(post.date)),
                          SizedBox(height: 4),
                          Text(post.description),
                        ],
                      ),
                    ),
                  );
                },
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

class Post {
  final int id;
  final String username;
  final DateTime date;
  final String description;

  Post({required this.id, required this.username, required this.date, required this.description});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      username: json['username'],
      date: DateTime.parse(json['date']),
      description: json['description'],
    );
  }
}