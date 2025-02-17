import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:versatool_app/currency_convertor.dart';
import 'package:versatool_app/image_downloader.dart';
import 'package:versatool_app/image_to_pdf.dart';
import 'package:versatool_app/insta_downloader.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() {
  runApp(const VersaToolApp());
}

class VersaToolApp extends StatelessWidget {
  const VersaToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Versa Tool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ImageToPdfScreen(),
    const YoutubeVideoDownloaderScreen(),
    const InstagramDownloaderScreen(),
    const CurrencyConverterApp(),
    const ImageDownloaderScreen(),
  ];

  final List<String> _titles = [
    "Image to PDF",
    "YouTube Video Downloader",
    "Instagram Story Downloader",
    "Currency Converter",
    "Image Downloader",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: "Image to PDF",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_collection),
            label: "YouTube Downloader",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: "Downloader",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: "Currency",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: "Image Downloader",
          ),
        ],
      ),
    );
  }
}

// YouTube Video Downloader Screen
class YoutubeVideoDownloaderScreen extends StatefulWidget {
  const YoutubeVideoDownloaderScreen({super.key});

  @override
  _YoutubeVideoDownloaderScreenState createState() =>
      _YoutubeVideoDownloaderScreenState();
}

class _YoutubeVideoDownloaderScreenState
    extends State<YoutubeVideoDownloaderScreen> {
  final TextEditingController _urlController = TextEditingController();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? _videoTitle;
  String? _videoThumbnailUrl;
  String? _videoUrl;
  bool _isDownloading = false;
  bool _hasNotificationPermission = false;

  final yt = YoutubeExplode();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      setState(() {
        _hasNotificationPermission = result.isGranted;
      });
    } else {
      setState(() {
        _hasNotificationPermission = status.isGranted;
      });
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'download_channel',
        'Download Progress',
        description: 'Shows progress of video download',
        importance: Importance.high,
        showBadge: true,
        playSound: true,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _showDownloadProgressNotification(int progress) async {
    if (!_hasNotificationPermission) return;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_channel',
      'Download Progress',
      channelDescription: 'Shows progress of video download',
      importance: Importance.high,
      priority: Priority.high,
      maxProgress: 100,
      progress: progress,
      showProgress: true,
      onlyAlertOnce: true,
      channelShowBadge: true,
      autoCancel: false,
    );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Downloading Video...',
      '$progress% Completed',
      platformChannelSpecifics,
      payload: 'progress_notification',
    );
  }

  void _startDownload() async {
    if (_videoUrl != null && !_isDownloading) {
      if (!_hasNotificationPermission) {
        // Show dialog to request permission
        final result = await Permission.notification.request();
        setState(() {
          _hasNotificationPermission = result.isGranted;
        });
        if (!result.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notification permission is required for download progress updates'),
            ),
          );
          return;
        }
      }

      setState(() {
        _isDownloading = true;
      });

      try {
        // Simulate download progress
        for (int i = 0; i <= 100; i++) {
          await Future.delayed(const Duration(milliseconds: 50));
          await _showDownloadProgressNotification(i);
        }

        // Show completion notification
        await _flutterLocalNotificationsPlugin.show(
          0,
          'Download Complete!',
          'Your YouTube video has been downloaded.',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'download_channel',
              'Download Complete',
              channelDescription: 'Notifies when download is complete',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              channelShowBadge: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: 'download_complete',
        );
      } catch (e) {
        debugPrint('Error showing notification: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error showing download notification'),
          ),
        );
      }

      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _fetchVideoPreview(String url) async {
    try {
      var video = await yt.videos.get(url);
      setState(() {
        _videoTitle = video.title;
        _videoThumbnailUrl = video.thumbnails.highResUrl;
        _videoUrl = url;
      });
    } catch (e) {
      setState(() {
        _videoTitle = 'Error fetching video details';
        _videoThumbnailUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_collection,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              const Text(
                "Download YouTube Videos Quickly!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Simply paste the YouTube video URL below and get the video downloaded in no time.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Enter YouTube Video URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.link),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (url) {
                  if (url.isNotEmpty) {
                    _fetchVideoPreview(url);
                  } else {
                    setState(() {
                      _videoTitle = null;
                      _videoThumbnailUrl = null;
                      _videoUrl = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              if (_videoThumbnailUrl != null) ...[
                Image.network(
                  _videoThumbnailUrl!,
                  height: 200,
                  width: 300,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 16),
                Text(
                  _videoTitle ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
              ElevatedButton.icon(
                onPressed: _startDownload,
                icon: const Icon(Icons.download_rounded),
                label:
                    Text(_isDownloading ? 'Downloading...' : 'Download Video'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
