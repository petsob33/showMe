import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:typed_data';

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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserPosts();
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
    try {
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/get_post.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          posts = data.map((item) {
            return {
              'date': _parseDate(item['date']),
              'imageBase64': item['image'] as String?,
              'description': item['description'] as String? ?? 'No description',
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při načítání příspěvků')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username.isEmpty ? 'Profil uživatele' : username),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildUserProfile(),
    );
  }

  Widget _buildUserProfile() {
    if (posts.isEmpty) {
      return Center(child: Text('Žádné příspěvky k zobrazení'));
    }

    return ListView.separated(
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
              child: Center(child: Text('Chyba při načítání obrázku', style: TextStyle(color: Colors.white))),
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
        child: Center(child: Text('Neplatný formát obrázku', style: TextStyle(color: Colors.white))),
      );
    }
  }
}