import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class SmartHomeScreen extends StatefulWidget {
  @override
  _SmartHomeScreenState createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  late FlutterTts flutterTts;
  PickedFile? _image;
  String recognizedText = '';

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
  }

  Future _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.getImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
      recognizedText = '';
    });
  }

  Future _performOCR() async {
    if (_image != null) {
      final text = await FlutterTesseractOcr.extractText(_image!.path);
      setState(() {
        recognizedText = text;
      });
    }
  }

  Future _speakText() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(recognizedText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null) Image.file(File(_image!.path)),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Select Image'),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _image != null ? _performOCR : null,
              child: Text('Extract Text'),
            ),
            SizedBox(height: 20.0),
            Text(recognizedText),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: recognizedText.isNotEmpty ? _speakText : null,
              child: Text('Speak Text'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}
