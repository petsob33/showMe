import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddPostPage extends StatefulWidget {
  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  DateTime selectedDate = DateTime.now();
  List<File> mediaFiles = [];
  TextEditingController descriptionController = TextEditingController();
  int? userId;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectMedia() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        mediaFiles.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _submitPost() async {
    if (mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prosím, vyberte alespoň jeden obrázek nebo video.')),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba: Uživatelské ID není k dispozici.')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    List<String> base64MediaList = [];
    for (var file in mediaFiles) {
      List<int> mediaBytes = await file.readAsBytes();
      String base64Media = base64Encode(mediaBytes);
      base64MediaList.add(base64Media);
    }

    Map<String, dynamic> postData = {
      'date': DateFormat('yyyy-MM-dd').format(selectedDate),
      'description': descriptionController.text,
      'media': base64MediaList,
      'user': userId
    };

    try {
      final response = await http.post(
        Uri.parse('http://lifetracker.euweb.cz/save_post.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Příspěvek byl úspěšně přidán.')),
        );
        Navigator.pop(context, true); // Pass true to indicate successful post
      } else {
        throw Exception('Failed to submit post');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při odesílání příspěvku: $e')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Přidat příspěvek')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text('Vybrat datum: ${DateFormat('dd.MM.yyyy').format(selectedDate)}'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectMedia,
              child: Text('Vybrat média'),
            ),
            SizedBox(height: 16),
            if (mediaFiles.isNotEmpty)
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: mediaFiles.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(mediaFiles[index], height: 80, width: 80, fit: BoxFit.cover),
                    );
                  },
                ),
              ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Popis'),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSubmitting ? null : _submitPost,
              child: isSubmitting
                  ? CircularProgressIndicator()
                  : Text('Přidat příspěvek'),
            ),
          ],
        ),
      ),
    );
  }
}