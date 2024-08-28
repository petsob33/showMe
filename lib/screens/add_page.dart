import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddPostPage extends StatefulWidget {
  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  DateTime selectedDate = DateTime.now();
  File? imageFile;
  TextEditingController descriptionController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPost() async {
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prosím, vyberte obrázek.')),
      );
      return;
    }

    // Převedení obrázku na base64
    List<int> imageBytes = await imageFile!.readAsBytes();
    String base64Image = base64Encode(imageBytes);

    // Příprava dat pro odeslání
    Map<String, dynamic> postData = {
      'date': DateFormat('yyyy-MM-dd').format(selectedDate),
      'description': descriptionController.text,
      'image': base64Image,
      'user':1
    };

    // Odeslání dat na API
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
        Navigator.pop(context);
      } else {
        throw Exception('Failed to submit post');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při odesílání příspěvku: $e')),
      );
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
              onPressed: _selectImage,
              child: Text('Vybrat obrázek'),
            ),
            SizedBox(height: 16),
            if (imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Popis'),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitPost,
              child: Text('Přidat příspěvek'),
            ),
          ],
        ),
      ),
    );
  }
}