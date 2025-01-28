import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class InstagramDownloaderScreen extends StatefulWidget {
  const InstagramDownloaderScreen({super.key});

  @override
  State<InstagramDownloaderScreen> createState() =>
      _InstagramDownloaderScreenState();
}

class _InstagramDownloaderScreenState extends State<InstagramDownloaderScreen> {
  TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String _mediaUrl = '';
  String _mediaType = '';
  File? _downloadedFile;

  // Function to simulate fetching media from an Instagram link
  Future<void> _fetchMedia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = _urlController.text.trim();
      if (url.isEmpty) {
        Fluttertoast.showToast(msg: "Please enter a valid Instagram URL.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Simulate API call to fetch the media URL (this is just a placeholder)
      await Future.delayed(const Duration(seconds: 2));

      // Placeholder media URL and type
      setState(() {
        _mediaUrl = url;
        _mediaType =
            "image"; // Simulate fetching an image (handle video/audio accordingly)
        _isLoading = false;
      });

      Fluttertoast.showToast(msg: "Media fetched successfully!");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: "Failed to fetch media.");
    }
  }

  // Function to download the media
  Future<void> _downloadMedia() async {
    try {
      final response = await http.get(Uri.parse(_mediaUrl));

      if (response.statusCode == 200) {
        // Get the app's document directory to save the media
        final directory = await getApplicationDocumentsDirectory();
        final fileName = _mediaUrl.split('/').last;
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);

        // Save the media
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _downloadedFile = file;
        });

        Fluttertoast.showToast(msg: "Media downloaded: $filePath");
      } else {
        Fluttertoast.showToast(msg: "Failed to download media.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error downloading media.");
    }
  }

  // Share the downloaded media
  void _shareMedia() {
    if (_downloadedFile != null) {
      Share.shareXFiles([XFile(_downloadedFile!.path)]);
    } else {
      Fluttertoast.showToast(msg: "No media available to share.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            // Wrap the Column with a SingleChildScrollView
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon and Heading
                Icon(
                  Icons.download,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Download Instagram Media",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Instagram URL input field
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: "Instagram Link",
                    hintText: "Paste Instagram media link here",
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                // Fetch button
                ElevatedButton(
                  onPressed: _fetchMedia,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Fetch Media"),
                ),
                const SizedBox(height: 16),

                // Display loading spinner if media is being fetched
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_mediaUrl.isNotEmpty)
                  Column(
                    children: [
                      // Media Preview (image/video)
                      if (_mediaType == "image") ...[
                        Image.network(
                          _mediaUrl,
                          height: 250,
                          width: 250,
                          fit: BoxFit.cover,
                        )
                      ] else if (_mediaType == "video") ...[
                        // You can use a package like video_player to display video
                        const Icon(Icons.video_library,
                            size: 150, color: Colors.grey),
                      ] else ...[
                        const Icon(Icons.error, size: 150, color: Colors.grey),
                      ],

                      const SizedBox(height: 16),

                      // Buttons for download and share
                      ElevatedButton(
                        onPressed: _downloadMedia,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Download Media"),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _shareMedia,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Share Downloaded Media"),
                      ),
                    ],
                  ),
                // Show downloaded media if available
                if (_downloadedFile != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        Text(
                            "Downloaded Media: ${_downloadedFile!.path.split('/').last}",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _shareMedia,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Share Media"),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
