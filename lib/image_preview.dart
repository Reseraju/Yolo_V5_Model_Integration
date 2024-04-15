import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_vision/flutter_vision.dart';

class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;
  final FlutterVision vision;
  final imageFile;

  const ImagePreviewScreen(
      {Key? key, required this.imageFile, required this.vision, required this.imagePath})
      : super(key: key);

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late List<Map<String, dynamic>> yoloResults;
  int imageHeight = 1;
  int imageWidth = 1;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    loadYoloModel().then((value) {
      setState(() {
        yoloResults = [];
        isLoaded = true;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> loadYoloModel() async {
    await widget.vision.loadYoloModel(
        labels: 'assets/models/labels.txt',
        modelPath: 'assets/models/yolov5n.tflite',
        modelVersion: "yolov5",
        quantization: false,
        numThreads: 2,
        useGpu: true);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Image Preview')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          widget.imageFile != null ? Image.file(widget.imageFile!) : const SizedBox(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: yoloOnImage,
                  child: const Text("Detect"),
                )
              ],
            ),
          ),
          ...displayBoxesAroundRecognizedObjects(size),
        ],
      ),
    );
  }

  Future<void> yoloOnImage() async {
    yoloResults.clear();
    Uint8List byte = await widget.imageFile!.readAsBytes();
    final image = await decodeImageFromList(byte);
    imageHeight = image.height;
    imageWidth = image.width;
    final result = await widget.vision.yoloOnImage(
        bytesList: byte,
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.8,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });
    }
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];

    double factorX = screen.width / (imageWidth);
    double imgRatio = imageWidth / imageHeight;
    double newWidth = imageWidth * factorX;
    double newHeight = newWidth / imgRatio;
    double factorY = newHeight / (imageHeight);

    double pady = (screen.height - newHeight) / 2;

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);
    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY + pady,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}

// i want to run a yolo model using loadYoloModel from 
// flutter_vision package and run the yolo model
// on an image that is selected by the user
// so when they select an image it will show the output  
// of the yolo model when they click on detect button

// if there are any objects in the image then display them
// else display "No Objects Detected
// how can we run a yolo model on a captured image or on a picked image from gallery ?
