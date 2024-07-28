import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class OcrScreen extends StatefulWidget {
  @override
  _OcrScreenState createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String _selectedModel = 'Printed Text';
  String _extractedText = '';
  bool _isDarkMode = false; // Track dark mode state
  FontWeight _fontWeight = FontWeight.normal; // Default font weight
  FontStyle _fontStyle = FontStyle.normal; // Default font style
  String _fontFamily = 'Roboto'; // Default font family

  // Define font styles and families
  List<Map<String, dynamic>> _fontStyles = [
    {'name': 'Normal', 'weight': FontWeight.normal, 'style': FontStyle.normal},
    {'name': 'Bold', 'weight': FontWeight.bold, 'style': FontStyle.normal},
    {'name': 'Italic', 'weight': FontWeight.normal, 'style': FontStyle.italic},
    {
      'name': 'Bold Italic',
      'weight': FontWeight.bold,
      'style': FontStyle.italic
    },
  ];

  List<String> _fontFamilies = [
    'Roboto',
    'SFPro',
    'Montserrat',
    'Lato',
  ];
  bool isLoad = false;
  String ngrokBaseUrl = 'https://15f3-102-43-208-57.ngrok-free.app';

  Future<void> _correctText(String text) async {
    print("Text before correct ${text}");
    final url =
        Uri.parse('$ngrokBaseUrl/correct_text'); // Replace with your API URL

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'text': text,
      }),
    );
    setState(() {
      isLoad = false;
    });
    print("Resss  ${response.statusCode}");
    print("Resss  ${response.body}");
    if (response.statusCode == 200) {
      print('Text Corrected successfully');
      final responseData = jsonDecode(response.body);
      print('Response: $responseData');
      setState(() {
        _extractedText = responseData["corrected_text"];
      });
      print("Text After correct ${responseData["corrected_text"]}");
    } else {
      print('Request failed with status: ${response.statusCode}');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      isLoad = true;
    });
    final url = Uri.parse('$ngrokBaseUrl/predict'); // Replace with your API URL
    final request = http.MultipartRequest('POST', url);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // The field name expected by the server
        imageFile.path,
      ),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Image Uploaded Successfully'),
      //     duration: Duration(milliseconds: 200),
      //     backgroundColor: Colors.green,
      //   ),
      // );

      print('Image uploaded successfully');
      final responseString = await response.stream.bytesToString();
      final responseData = json.decode(responseString);
      print(responseData);
      setState(() {
        _extractedText = responseData["result"];
      });
      _correctText(responseData["result"]);
    } else {
      print('Image upload failed');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File? croppedFile = await _cropImage(pickedFile.path);
      if (croppedFile != null) {
        setState(() {
          _image = croppedFile;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      File? croppedFile = await _cropImage(pickedFile.path);
      if (croppedFile != null) {
        setState(() {
          _image = croppedFile;
        });
      }
    }
  }

  Future<File?> _cropImage(String filePath) async {
    File? croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      androidUiSettings: AndroidUiSettings(
        toolbarTitle: 'Crop Image',
        toolbarColor: _isDarkMode
            ? Colors.deepPurple.shade700 // Dark mode toolbar color
            : Colors.deepPurple.shade300,
        // Light mode toolbar color
        toolbarWidgetColor: Colors.white,
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: false,
      ),
      iosUiSettings: IOSUiSettings(
        minimumAspectRatio: 1.0,
      ),
    );
    return croppedFile;
  }

  Future<void> _performOcr() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select or take an image first')),
      );
      return;
    }
    if (_selectedModel.toLowerCase().contains("hand")) {
      _uploadImage(_image!);
    } else {
      setState(() {
        isLoad = true;
      });
      final inputImage = InputImage.fromFile(_image!);
      final textRecognizer = TextRecognizer();

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      setState(() {
        _extractedText = recognizedText.text;
      });
      _correctText(recognizedText.text);
    }
  }

  void _copyTextToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _toggleDarkMode(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  void _setFontStyle(int index) {
    setState(() {
      _fontWeight = _fontStyles[index]['weight'];
      _fontStyle = _fontStyles[index]['style'];
    });
  }

  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text('Font Style:'),
              Wrap(
                spacing: 10,
                children: _fontStyles.map((font) {
                  return ElevatedButton(
                    onPressed: () => _setFontStyle(_fontStyles.indexOf(font)),
                    child: Text(font['name']),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text('Font Family:'),
              Wrap(
                spacing: 10,
                children: _fontFamilies.map((family) {
                  return ElevatedButton(
                    onPressed: () => _setFontFamily(family),
                    child: Text(family),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dark Mode'),
                  Switch(
                    value: _isDarkMode,
                    onChanged: _toggleDarkMode,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _setFontFamily(String family) {
    setState(() {
      _fontFamily = family;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Textify'),
        // Changed app title to 'Textify'
        centerTitle: true,
        elevation: 0,
        backgroundColor: _isDarkMode
            ? Colors.deepPurple.shade700 // Dark mode app bar color
            : Colors.deepPurple.shade300,
        // Light mode app bar color
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showSettingsPanel,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height * 0.4),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _image == null
                  ? const Center(
                      child: Padding(

                        padding: EdgeInsets.symmetric(vertical: 58.0),
                        child: Text(
                          'No image selected.',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                      ),
                    ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.image),
                    label: Text('Gallery'),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          _isDarkMode
                              ? Colors
                                  .deepPurple.shade700 // Dark mode button color
                              : Colors.deepPurple
                                  .shade300), // Light mode button color
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                      shape: MaterialStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Camera'),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          _isDarkMode
                              ? Colors
                                  .deepPurple.shade900 // Dark mode button color
                              : Colors.deepPurple
                                  .shade500), // Light mode button color
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                      shape: MaterialStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedModel,
                items: <String>['Printed Text', 'Handwritten Text']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedModel = newValue!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Select Model',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _performOcr,
                child: Text('Submit'),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(_isDarkMode
                      ? Colors.deepPurple.shade700 // Dark mode button color
                      : Colors.deepPurple.shade300), // Light mode button color
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
                  shape: MaterialStateProperty.all<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (!isLoad)
                GestureDetector(
                  onLongPress: () {
                    _copyTextToClipboard(_extractedText);
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _extractedText.isEmpty
                          ? 'Extracted Text'
                          : _extractedText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _fontWeight,
                        fontStyle: _fontStyle,
                        fontFamily: _fontFamily,
                        // Apply selected font family
                        color: _extractedText.isEmpty
                            ? Colors.grey.shade400
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              if (isLoad)
                const Center(
                  child: CircularProgressIndicator(),
                )
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.black : Colors.deepPurple,
              ),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Font Style'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _showSettingsPanel(); // Show the font style settings
              },
            ),
            ListTile(
              title: Text('Dark Mode'),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
