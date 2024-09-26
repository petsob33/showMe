import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';

class SharedPostListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  final Function() onRefresh;
  final bool showUsername;

  SharedPostListWidget({
    required this.posts,
    required this.onRefresh,
    this.showUsername = false,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(child: Text('No posts to display'));
    }

    return RefreshIndicator(
      onRefresh: () async => await onRefresh(),
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
                        showUsername && post['username'] != null
                            ? post['username']
                            : DateFormat('dd.MM.yyyy').format(post['date']),
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                if (post['images'] != null && (post['images'] as List).isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return ImageViewerDialog(images: post['images']);
                        },
                      );
                    },
                    child: Container(
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

class ImageViewerDialog extends StatefulWidget {
  final List<dynamic> images;

  ImageViewerDialog({required this.images});

  @override
  _ImageViewerDialogState createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentPage + 1} / ${widget.images.length}',
                    style: TextStyle(color: Colors.white),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Center(
                      child: _buildBase64Image(widget.images[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
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

      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Container(
            color: Colors.grey[700],
            child: Center(child: Text('Error loading image', style: TextStyle(color: Colors.white))),
          );
        },
      );
    } catch (e) {
      print('Error decoding base64: $e');
      return Container(
        color: Colors.grey[700],
        child: Center(child: Text('Invalid image format', style: TextStyle(color: Colors.white))),
      );
    }
  }
}