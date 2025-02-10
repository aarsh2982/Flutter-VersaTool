import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';

class InstagramDownloaderScreen extends StatefulWidget {
  const InstagramDownloaderScreen({super.key});

  @override
  State<InstagramDownloaderScreen> createState() =>
      _InstagramDownloaderScreenState();
}

class _InstagramDownloaderScreenState extends State<InstagramDownloaderScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String _mediaUrl = '';
  String _mediaType = '';
  File? _downloadedFile;
  String _error = '';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool _isValidInstagramUrl(String url) {
    return url.contains('instagram.com') || url.contains('instagr.am');
  }

  Future<void> _fetchMedia() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _mediaUrl = '';
      _mediaType = '';
      _downloadedFile = null;
    });

    try {
      final url = _urlController.text.trim();
      if (!_isValidInstagramUrl(url)) {
        throw Exception('Please enter a valid Instagram URL');
      }

      _mediaType = url.contains('.mp4') ? 'video' : 'image';

      final response = await http.head(Uri.parse(url));

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('video')) {
          _mediaType = 'video';
        } else if (contentType.contains('image')) {
          _mediaType = 'image';
        }

        setState(() {
          _mediaUrl = url;
        });

        _showToast('Media found successfully!');
      } else {
        throw Exception('Unable to access the media URL');
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
      });
      _showToast('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadMedia() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.get(Uri.parse(_mediaUrl));
      if (response.statusCode != 200) throw Exception('Download failed');

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _mediaType == 'video' ? '.mp4' : '.jpg';
      final fileName = 'instagram_$timestamp$extension';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(response.bodyBytes);
      setState(() => _downloadedFile = file);
      _showToast('Media downloaded successfully!');
    } catch (e) {
      _showToast('Error downloading media: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareMedia() async {
    if (_downloadedFile != null) {
      try {
        await Share.shareXFiles([XFile(_downloadedFile!.path)]);
      } catch (e) {
        _showToast('Error sharing media: ${e.toString()}');
      }
    } else if (_mediaUrl.isNotEmpty) {
      try {
        await Share.share(_mediaUrl);
      } catch (e) {
        _showToast('Error sharing URL: ${e.toString()}');
      }
    } else {
      _showToast('No media available to share');
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.pink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              labelText: 'Instagram Link',
                              hintText: 'Paste Instagram media link here',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.link),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _urlController.clear(),
                              ),
                            ),
                            keyboardType: TextInputType.url,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _fetchMedia,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                          icon: const Icon(Icons.search),
                          label:
                              Text(_isLoading ? 'Fetching...' : 'Fetch Media'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_mediaUrl.isNotEmpty && _error.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: _mediaUrl,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _downloadMedia,
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _shareMedia,
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
