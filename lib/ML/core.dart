import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:object_detection/main.dart';

class Core extends StatefulWidget {
  const Core({super.key});

  @override
  State<Core> createState() => _CoreState();
}

class _CoreState extends State<Core> {
  bool isWorking = false;
  String result = "";
  CameraController cameraController =
      CameraController(camera[0], ResolutionPreset.high);
  CameraImage? imgCamera;

  loadModel() async {
    await Tflite.loadModel(
        model: "assets/mobilenet_v1_1.0_224.tflite",
        labels: "assets/mobilenet_v1_1.0_224.txt");
  }

  initcamera() async {
    await cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController.startImageStream((image) async {
          if (!isWorking) {
            isWorking = true;
            imgCamera = image;
            await runModelonstream();
          }
        });
      });
    });
  }

  runModelonstream() async {
    if (imgCamera != null) {
      var recognition = await Tflite.runModelOnFrame(
          bytesList: imgCamera!.planes.map((response) {
            return response.bytes;
          }).toList(),
          imageHeight: imgCamera!.height,
          imageWidth: imgCamera!.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true);
      result = "";

      for (var response in recognition!) {
        print("risav");
        result += response["label"] +
            "  " +
            (response["confidence"] as double).toStringAsFixed(2) +
            "\n\n";
      }
      setState(() {
        result;
      });
      isWorking = false;
    }
  }

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
    Tflite.close();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            imgCamera == null
                ? SizedBox(
                    height: 350,
                    child: Image.asset("assets/camera.jpg", fit: BoxFit.fill))
                : AspectRatio(
                    aspectRatio: cameraController.value.aspectRatio,
                    child: CameraPreview(cameraController)),
            imgCamera == null
                ? ElevatedButton(
                    onPressed: () async {
                      await initcamera();
                      await Future.delayed(const Duration(seconds: 5));
                      setState(() {});
                    },
                    child: const Text("Start camera"))
                : const SizedBox(),
            Center(
              child: Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(top: 30),
                child: SingleChildScrollView(
                  child: Center(
                    child: Text(
                      result,
                      style: const TextStyle(
                          backgroundColor: Colors.teal,
                          fontSize: 30,
                          color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
