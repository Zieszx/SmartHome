import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:smarthome/View/ObjectDetector.dart';
import 'package:smarthome/View/TfliteModel.dart';
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
      numResults: 2,
      threshold: 0.5,
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
      });
    }
  }

  Future _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.getImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
      _Detectimage = File(_image!.path);
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
              Text(
                _result ?? '',
                style: TextStyle(fontSize: 16),
              ),
              if (_objects != null)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _objects.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_objects[index]['label']),
                      subtitle:
                          Text('Confidence: ${_objects[index]['confidence']}'),
                    );
                  },
                ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () => ObjectDetection(_Detectimage),
                child: Text('Detect Objects Page'),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () => _speakText(recognizedText),
                child: Text('Speak Text'),
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
