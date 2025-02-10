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

      // Try to determine the media type from the URL
      _mediaType = url.contains('.mp4') ? 'video' : 'image';

      // Attempt to directly fetch the URL to verify it's accessible
      final response = await http.head(Uri.parse(url));

      if (response.statusCode == 200) {
        // If the content type header is available, use it to determine media type
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
      // If file isn't downloaded yet, share the URL
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Instagram Downloader',
                style: TextStyle(color: Colors.white),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade400,
                      Colors.pink.shade400,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.download_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              labelText: 'Instagram Link',
                              hintText: 'Paste Instagram media link here',
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
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _fetchMedia,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                            icon: const Icon(Icons.search),
                            label: Text(
                                _isLoading ? 'Fetching...' : 'Fetch Media'),
                          ),
                        ],
                      ),
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
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (_mediaType == 'image')
                              ClipRRect(
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
                              )
                            else
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.video_library,
                                      size: 64, color: Colors.grey),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _downloadMedia,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.download),
                                  label: const Text('Download'),
                                ),
                                ElevatedButton.icon(
                                  onPressed:
                                      _mediaUrl.isNotEmpty ? _shareMedia : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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
