import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:open_file/open_file.dart';

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  File? _pdfFile;

  // Select images
  Future<void> _selectImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _selectedImages = images;
      });
    }
  }

  // Crop an image
  Future<File?> _cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
      ],
    );
    return croppedFile != null ? File(croppedFile.path) : null;
  }

  // Convert selected images to PDF
  Future<void> _convertToPdf() async {
    if (_selectedImages.isEmpty) return;

    final pdf = pw.Document();
    for (var image in _selectedImages) {
      final imageFile = File(image.path);
      final imageBytes = await imageFile.readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.Image(pdfImage),
          ),
        ),
      );
    }

    // Ask user where to save the file
    final directory = await getApplicationDocumentsDirectory();
    final String? filePath = await _askForFilePath(directory.path);

    if (filePath != null) {
      final pdfFile = File(filePath);
      await pdfFile.writeAsBytes(await pdf.save());
      setState(() {
        _pdfFile = pdfFile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF successfully created: ${pdfFile.path}')),
      );

      // Open the file
      OpenFile.open(pdfFile.path);
    }
  }

  // Dialog to ask for the file path
  Future<String?> _askForFilePath(String initialPath) async {
    String? path = initialPath;
    return showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController _controller =
            TextEditingController(text: '$path/converted_images.pdf');
        return AlertDialog(
          title: const Text("Save PDF"),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: "File Path"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _controller.text);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Download the PDF file (No longer necessary since it's being opened directly)
  void _downloadPdf() {
    if (_pdfFile == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF is saved at: ${_pdfFile!.path}')),
    );
    // The file is already opened by OpenFile.open(pdfFile.path)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Upload Images Button
          ElevatedButton.icon(
            onPressed: _selectImages,
            icon: const Icon(Icons.upload),
            label: const Text("Select Images"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Preview Selected Images
          Expanded(
            child: _selectedImages.isNotEmpty
                ? GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Image.file(
                              File(_selectedImages[index].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.crop, color: Colors.white),
                              onPressed: () async {
                                final croppedFile = await _cropImage(
                                    _selectedImages[index].path);
                                if (croppedFile != null) {
                                  setState(() {
                                    _selectedImages[index] =
                                        XFile(croppedFile.path);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      "No images selected. Please upload images.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
          ),

          // Convert and Download Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _convertToPdf,
                  child: const Text("Convert to PDF"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (_pdfFile != null)
                  ElevatedButton.icon(
                    onPressed: _downloadPdf,
                    icon: const Icon(Icons.download),
                    label: const Text("Download PDF"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
