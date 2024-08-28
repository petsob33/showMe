import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddPostPage extends StatefulWidget {
  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  DateTime selectedDate = DateTime.now();
  String? imageUrl;
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

  void _selectImage() {
    // Implementujte výběr obrázku
    setState(() {
      imageUrl = 'https://placekitten.com/200/200';
    });
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
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Popis'),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Implementujte přidání příspěvku
                Navigator.pop(context);
              },
              child: Text('Přidat příspěvek'),
            ),
          ],
        ),
      ),
    );
  }
}