import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:tflite/tflite.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class SmartHomeScreen extends StatefulWidget {
  @override
  _SmartHomeScreenState createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  late FlutterTts flutterTts;
  PickedFile? _image;
  String recognizedText = '';
  late File _Detectimage;
  late String _result = "";
  late List _objects = [];
  bool imageSelected = false;
  List<String> _numberedObjects = [];

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    loadModel();
  }

  void loadModel() async {
    Tflite.close();
    Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future ObjectDetection(File image) async {
    final List? recognition = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    if (recognition == null) {
      setState(() {
        _result = "No object detected";
        imageSelected = true;
      });
    } else {
      setState(() {
        _objects = recognition;
        _result = "Successfully detected";
        _Detectimage = image;
        imageSelected = true;

        // Populate _numberedObjects with labels and numbering.
        _numberedObjects = recognition.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final label = entry.value['label'];
          final confidence = entry.value['confidence'];
          return '$index. $label ($confidence)';
        }).toList();
      });
    }
  }

  Future _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.getImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
        _Detectimage = File(_image!.path);
      });
    }
  }

  Future _captureImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.getImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
        _Detectimage = File(_image!.path);
      });
    }
  }

  Future _performOCR() async {
    if (_image != null) {
      final text = await FlutterTesseractOcr.extractText(_image!.path);
      setState(() {
        recognizedText = text;
        print("TEXT RETRIEVE:" + recognizedText);
      });
    }
  }

  Future _speakObject(List objects) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1);
    await flutterTts.setSpeechRate(0.5);

    for (var item in objects) {
      String label = item['label'];
      await flutterTts.speak(label);
      await Future.delayed(Duration(seconds: 1));
    }
  }

  Future _speakText(String reconizedtext) async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(reconizedtext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Home'),
      ),
      body: SingleChildScrollView(
        child: Center(
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
              SizedBox(height: 20.0),
              Text(
                _result ?? '',
                style: TextStyle(fontSize: 16),
              ),
              if (_numberedObjects.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _numberedObjects.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_numberedObjects[index]),
                    );
                  },
                ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    recognizedText = "";
                  });
                  ObjectDetection(_Detectimage);
                },
                child: Text('Detect Objects Page'),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: recognizedText != ""
                    ? () => _speakText(recognizedText)
                    : () => _speakObject(_objects),
                child: Text('Speak Text'),
              ),
              SizedBox(height: 20.0),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey,
                    width: 2.0,
                  ),
                ),
                child: IconButton(
                  onPressed: _captureImage,
                  icon: Icon(Icons.camera),
                  tooltip: 'Capture Image from Camera',
                ),
              ),
            ],
          ),
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
