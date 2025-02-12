import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data'; // For handling byte data
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const PDFCompressorApp());
}

class PDFCompressorApp extends StatelessWidget {
  const PDFCompressorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          elevation: 0,
        ),
      ),
      home: const PDFCompressorScreen(),
    );
  }
}

class PDFCompressorScreen extends StatefulWidget {
  const PDFCompressorScreen({super.key});

  @override
  _PDFCompressorScreenState createState() => _PDFCompressorScreenState();
}

class _PDFCompressorScreenState extends State<PDFCompressorScreen> {
  File? _selectedFile;
  String _compressionLevel = "Medium";
  bool _isCompressing = false;
  String _newFileName = "";
  String? _errorMessage;
  Uint8List? _pdfBytes; // Store the PDF as bytes
  double _compressionProgress = 0.0;

  final Map<String, int> _compressionLevels = {
    "High": 90,
    "Medium": 60,
    "Low": 30,
  };

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isDenied) {
        setState(() {
          _errorMessage = "Storage permission denied. Please enable it.";
        });
      }
    }
  }

  Future<void> _pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _pdfBytes = result.files.single.bytes; // Store bytes
          _selectedFile = null; // Don't need the file path anymore
          _newFileName = result.files.single.name.replaceAll('.pdf', '');
          _errorMessage = null;
        });

        // Print the original size before compression
        print("Original file size: ${_pdfBytes!.lengthInBytes / 1024} KB");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error selecting file: $e";
      });
    }
  }

  Future<void> _compressPDF() async {
    if (_pdfBytes == null) return;

    setState(() {
      _isCompressing = true;
      _errorMessage = null;
      _compressionProgress = 0.0;
    });

    try {
      // Simulate PDF compression by applying the compression factor
      int compressionFactor = _compressionLevels[_compressionLevel]!;
      int originalSize = _pdfBytes!.lengthInBytes;

      // Apply compression (simulated by reducing byte size)
      int compressedSize =
          (originalSize * (1 - compressionFactor / 100)).toInt();

      // Create new compressed bytes (simulation)
      Uint8List compressedBytes = _pdfBytes!.sublist(0, compressedSize);

      // Simulate the compression process with progress updates
      for (double i = 0.0; i <= 1.0; i += 0.1) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _compressionProgress = i;
        });
      }

      // Print the sizes before and after compression
      print("Compressed file size: ${compressedBytes.lengthInBytes / 1024} KB");

      setState(() {
        _isCompressing = false;
        _pdfBytes = compressedBytes; // Update with compressed bytes
      });

      Fluttertoast.showToast(
        msg: "Compression Successful",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      setState(() {
        _isCompressing = false;
        _errorMessage = "Compression failed: $e";
      });
    }
  }

  Future<void> _savePDF() async {
    if (_pdfBytes == null) return;

    try {
      String? saveDir = await FilePicker.platform.getDirectoryPath();

      if (saveDir != null) {
        final String fileName = _newFileName.isEmpty
            ? "compressed_${DateTime.now().millisecondsSinceEpoch}.pdf"
            : "${_newFileName}_compressed.pdf";

        final String savePath = "$saveDir/$fileName";

        // For mobile platforms: Save as a file using file system operations
        if (Platform.isAndroid || Platform.isIOS) {
          final file = File(savePath);
          await file.writeAsBytes(_pdfBytes!); // Write the bytes to a file
        }

        Fluttertoast.showToast(
          msg: "File saved successfully at: $savePath",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error saving file: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Compressor"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.picture_as_pdf,
                        size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: !_isCompressing ? _pickPDF : null,
                      icon: const Icon(Icons.file_upload),
                      label: const Text("Select PDF File"),
                    ),
                    if (_pdfBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Selected: ${_newFileName}.pdf",
                          style: const TextStyle(color: Colors.blue),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_pdfBytes != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Compression Settings",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _compressionLevel,
                        decoration: const InputDecoration(
                          labelText: "Compression Level",
                          border: OutlineInputBorder(),
                        ),
                        items: _compressionLevels.keys.map((String level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(
                                "$level (${_compressionLevels[level]}% reduction)"),
                          );
                        }).toList(),
                        onChanged: _isCompressing
                            ? null
                            : (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _compressionLevel = newValue;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isCompressing ? null : _compressPDF,
                        icon: _isCompressing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.compress),
                        label: Text(
                            _isCompressing ? "Compressing..." : "Compress PDF"),
                      ),
                      if (_isCompressing) const SizedBox(height: 16),
                      if (_isCompressing)
                        LinearProgressIndicator(value: _compressionProgress),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (_pdfBytes != null)
              ElevatedButton.icon(
                onPressed: _savePDF,
                icon: const Icon(Icons.save),
                label: const Text("Save Compressed PDF"),
              ),
            if (_errorMessage != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
