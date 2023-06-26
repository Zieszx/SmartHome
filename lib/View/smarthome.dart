import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:smarthome/View/TfliteModel.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class SmartHomeScreen extends StatefulWidget {
  @override
  _SmartHomeScreenState createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  late FlutterTts flutterTts;
  PickedFile? _image;
  String recognizedText = '';
  Interpreter? _interpreter;
  List<dynamic>? _recognitions;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _loadModel();
  }

  Future _loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset('assets/model.tflite',
          options: interpreterOptions);
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.getImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
      recognizedText = '';
      _recognitions = null;
    });
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

  Future _speakText(String recognizedText) async {
    print(recognizedText);
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1);
    await flutterTts.speak("TEXT TO SPEECH IS WORKING");
  }

  // Future _performObjectDetection() async {
  //   if (_image != null) {
  //     final image = await _image?.readAsBytes();
  //     final recognitions = await _interpreter!.run(image!);
  //     setState(() {
  //       _recognitions = recognitions;
  //     });
  //   }
  // }

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
              // ElevatedButton(
              //   onPressed: _image != null ? _performObjectDetection : null,
              //   child: Text('Detect Objects'),
              // ),
              SizedBox(height: 20.0),
              if (_recognitions != null)
                Column(
                  children: [
                    for (var recognition in _recognitions!)
                      Text(
                          '${recognition['label']} (${recognition['confidence'].toStringAsFixed(2)})'),
                  ],
                ),
              SizedBox(height: 20.0),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () => _speakText(recognizedText),
                child: Text('Speak Text'),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () => TfliteModel(),
                child: Text('Object Detector'),
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
