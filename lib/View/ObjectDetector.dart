import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class ObjectDetectorPage extends StatefulWidget {
  @override
  State<ObjectDetectorPage> createState() => _ObjectDetectorPageState();
}

class _ObjectDetectorPageState extends State<ObjectDetectorPage> {
  late String _result = "";
  late File _image;
  late List _objects = [];

  bool imageSelected = false;

  void initState() {
    super.initState();
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
        _image = image;
        imageSelected = true;
      });
    }
  }

  Future _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.getImage(source: ImageSource.gallery);
    if (pickedImage == null) return null;
    setState(() {
      _image = File(pickedImage.path);
    });
    ObjectDetection(_image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Object Detector'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              SizedBox(height: 20),
              if (imageSelected && _image != null)
                Image.file(
                  _image,
                  width: 300,
                  height: 300,
                ),
              SizedBox(height: 20),
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
            ],
          ),
        ),
      ),
    );
  }
}
