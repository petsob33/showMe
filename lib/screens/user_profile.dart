import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserPosts();
    _checkFollowStatus();
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
      isLoading = false;
    });
    try {
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/get_post.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        final List<dynamic> data = json.decode(response.body);
        print('Decoded data: $data');

        setState(() {
          posts = data.map((item) {
            print('Processing item: $item');
            return {
              'date': _parseDate(item['date']),
              'images': item['images'] as List<dynamic>?,
              'description': item['description'] as String? ?? 'No description',
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
        SnackBar(content: Text('Chyba při načítání příspěvků')),
      );
    }
  }
  //
  // Future<void> _fetchFollowCounts() async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('http://lifetracker.euweb.cz/get_follow_counts.php'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({'user_id': widget.userId}),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       setState(() {
  //         followers = data['followers'];
  //         following = data['following'];
  //       });
  //     } else {
  //       throw Exception('Failed to load follow counts');
  //     }
  //   } catch (e) {
  //     print('Error fetching follow counts: $e');
  //   }
  // }
  Future<void> _checkFollowStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var userIdMy   = prefs.getInt('user_id');
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/check_follow_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'follower_id': userIdMy, 'followed_id': widget.userId}), // Nahraďte 1 za ID přihlášeného uživatele
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
      var userIdMy   = prefs.getInt('user_id');
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/toggle_follow.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'follower_id': userIdMy  , 'followed_id': widget.userId}), // Nahraďte 1 za ID přihlášeného uživatele
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] == 'Vztah byl úspěšně vytvořen') {
          setState(() {
            isFollowing = true;
          });
        } else if (data['message'] == 'Vztah byl úspěšně odstraněn') {
          setState(() {
            isFollowing = false;
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
  DateTime? _parseDate(dynamic dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      print('Error parsing date: $dateString. Error: $e');
      return null;
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
        Expanded(child: _buildPostsList()),
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
              Text('6'),
            ],
          ),
          Column(
            children: [
              Text('Sleduje', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('5'),
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

  Widget _buildPostsList() {
    if (posts.isEmpty) {
      return Center(child: Text('Žádné příspěvky k zobrazení'));
    }

    return RefreshIndicator(
      onRefresh: _fetchUserPosts,
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

      print('Decoding base64 string: ${base64String.substring(0, min(50, base64String.length))}...');
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
      print('Base64 string: ${base64String?.substring(0, min(50, base64String.length))}...');
      return Container(
        height: 150,
        width: 250,
        color: Colors.grey[700],
        child: Center(child: Text('Invalid image format', style: TextStyle(color: Colors.white))),
      );
    }
  }
}
