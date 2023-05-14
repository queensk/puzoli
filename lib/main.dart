import 'package:flutter/material.dart';
import 'dart:math';
import 'package:pixel_api/pixel_api.dart'; // import this package
import 'package:image_cropper/image_cropper.dart'; // import this package
import 'package:collection/collection.dart'; // import this package

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(title: 'Puliza'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final pixelApi =
      PixelApi(apiKey: 'your_api_key'); // create an instance of PixelApi
  List<File> gridItems = []; // create a list of files for grid items
  List<File> originalItems = []; // create a list of files for original order
  int emptyIndex = 0;

  @override
  void initState() {
    super.initState();
    loadNewGame(); // load a new game when initializing
  }

  void loadNewGame() async {
    var photos = await pixelApi.getPhotos(); // get photos from pixel api
    var photo = photos.first; // get the first photo
    var file = await photo.download(); // download the photo as a file
    var croppedFiles = await cropImage(file); // crop the image into nine parts
    setState(() {
      gridItems = croppedFiles..shuffle(); // shuffle the grid items
      originalItems = List.from(croppedFiles); // copy the original order
      emptyIndex = Random().nextInt(9); // generate a random empty index
      gridItems.removeAt(emptyIndex); // remove one section randomly
    });
  }

  Future<List<File>> cropImage(File file) async {
    List<File> files = [];
    var image = await file.readAsBytes(); // read image bytes
    for (int i = 0; i < 9; i++) {
      int x = (i % 3) * (image.width ~/ 3); // calculate x coordinate
      int y = (i ~/ 3) * (image.height ~/ 3); // calculate y coordinate
      var croppedFile = await ImageCropper.cropImage(
        // crop the image using ImageCropper
        sourcePath: file.path,
        aspectRatioPresets: [CropAspectRatioPreset.square],
        androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
        ),
        cropStyle: CropStyle.rectangle,
        maxWidth: image.width ~/ 3,
        maxHeight: image.height ~/ 3,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        rectX: x,
        rectY: y,
      );
      files.add(croppedFile); // add the cropped file to the list
    }
    return files; // return the list of files
  }

  void swapItems(int index) {
    setState(() {
      File temp = gridItems[index];
      gridItems[index] = gridItems[emptyIndex];
      gridItems[emptyIndex] = temp;
      emptyIndex = index;
      if (ListEquality().equals(gridItems, originalItems)) {
        // check if the user has arranged them correctly
        showDialog(
          // show a popup
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('You won!'),
              content: Text('Congratulations! You solved the puzzle.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    loadNewGame(); // reload a new game
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GridView.count(
        crossAxisCount: 3,
        children: List.generate(9, (index) {
          if (index == emptyIndex) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
              ),
            );
          } else {
            return GestureDetector(
              onTap: () {
                if ((index - emptyIndex).abs() == 1 ||
                    (index - emptyIndex).abs() == 3) {
                  swapItems(index);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Center(
                  child: Image.file(gridItems[index]), // display the image file
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}
