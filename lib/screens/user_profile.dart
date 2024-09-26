import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_post_list_widget.dart';

class UserProfilePage extends StatefulWidget {
  final int userId;

  UserProfilePage({required this.userId});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String username = '';
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;
  bool isFollowing = false;
  int followers = 0;
  int following = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserPosts();
    _checkFollowStatus();
    _fetchFollowCounts();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/get_username.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          username = data['username'];
        });
      } else {
        throw Exception('Failed to load username');
      }
    } catch (e) {
      print('Error fetching username: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při načítání uživatelského jména')),
      );
    }
  }

  Future<void> _fetchUserPosts() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/get_post.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      print('API response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Decoded data: $data');

        setState(() {
          posts = data.map((item) {
            return {
              'date': DateTime.parse(item['date']),
              'images': item['images'] as List<dynamic>?,
              'description': item['description'] as String? ?? 'No description',
              'username': username,
            };
          }).toList();
        });

        print('Processed posts: $posts');
      } else {
        throw Exception('Failed to load posts. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při načítání příspěvků: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchFollowCounts() async {
    try {
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/get_follow_counts.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          followers = data['followers'];
          following = data['following'];
        });
      } else {
        throw Exception('Failed to load follow counts');
      }
    } catch (e) {
      print('Error fetching follow counts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při načítání počtu sledujících')),
      );
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var userIdMy = prefs.getInt('user_id');
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/check_follow_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'follower_id': userIdMy, 'followed_id': widget.userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          isFollowing = data['is_following'];
        });
      } else {
        throw Exception('Failed to check follow status');
      }
    } catch (e) {
      print('Error checking follow status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při kontrole stavu sledování')),
      );
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var userIdMy = prefs.getInt('user_id');
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/toggle_follow.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'follower_id': userIdMy, 'followed_id': widget.userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] == 'Vztah byl úspěšně vytvořen') {
          setState(() {
            isFollowing = true;
            followers++;
          });
        } else if (data['message'] == 'Vztah byl úspěšně odstraněn') {
          setState(() {
            isFollowing = false;
            followers--;
          });
        } else {
          throw Exception('Failed to toggle follow status');
        }
      } else {
        throw Exception('Failed to toggle follow status');
      }
    } catch (e) {
      print('Error toggling follow status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při změně stavu sledování')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username.isEmpty ? 'Profil uživatele' : username),
        actions: [
          IconButton(
            icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add),
            onPressed: _toggleFollow,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildUserProfile(),
    );
  }

  Widget _buildUserProfile() {
    return Column(
      children: [
        _buildProfileHeader(),
        Expanded(
          child: SharedPostListWidget(
            posts: posts,
            onRefresh: _fetchUserPosts,
            showUsername: false,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text('Příspěvky', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${posts.length}'),
            ],
          ),
          Column(
            children: [
              Text('Sledující', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$followers'),
            ],
          ),
          Column(
            children: [
              Text('Sleduje', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$following'),
            ],
          ),
          ElevatedButton(
            onPressed: _toggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.green : Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            child: Text(isFollowing ? 'Unfollow' : 'Follow'),
          ),
        ],
      ),
    );
  }
}