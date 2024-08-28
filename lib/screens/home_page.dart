import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> posts = [
    {'date': DateTime.now(), 'imageUrl': 'https://placekitten.com/200/200', 'description': 'Popis 1'},
    {'date': DateTime.now().subtract(Duration(days: 1)), 'imageUrl': 'https://placekitten.com/201/201', 'description': 'Popis 2'},
    {'date': DateTime.now().subtract(Duration(days: 2)), 'imageUrl': '', 'description': 'Popis 3 bez obrázku'},
  ];

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
          // AddPostPage(),
          // SearchPage(),
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
            }          });
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
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.white10,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd.MM.yyyy').format(post['date']),
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 8),
                if (post['imageUrl'].isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      post['imageUrl'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                SizedBox(height: 8),
                Text(post['description']),
              ],
            ),
          ),
        );
      },
    );
  }
}