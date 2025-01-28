import 'package:flutter/material.dart';
import 'package:versatool_app/insta_downloader.dart';
import 'image_to_pdf.dart';

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

  // Screens for each functionality
  final List<Widget> _screens = [
    const ImageToPdfScreen(),
    const PdfCompressorScreen(),
    const Mp4ToMp3Screen(),
    const InstagramDownloaderScreen(),
    const CurrencyConverterScreen(),
  ];

  // Titles for AppBar
  final List<String> _titles = [
    "Image to PDF",
    "PDF Compressor",
    "MP4 to MP3 Converter",
    "Instagram Story Downloader",
    "Currency Converter",
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
            icon: Icon(Icons.compress),
            label: "PDF Compressor",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_video),
            label: "MP4 to MP3",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: "Downloader",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: "Currency",
          ),
        ],
      ),
    );
  }
}

// Screen: Image to PDF

// Screen: PDF Compressor
class PdfCompressorScreen extends StatelessWidget {
  const PdfCompressorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compress,
              size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          const Text(
            "Compress PDF files easily!",
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

// Screen: MP4 to MP3 Converter
class Mp4ToMp3Screen extends StatelessWidget {
  const Mp4ToMp3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_video,
              size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          const Text(
            "Convert videos to MP3 audio!",
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

// Screen: Currency Converter
class CurrencyConverterScreen extends StatelessWidget {
  const CurrencyConverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.attach_money,
              size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          const Text(
            "Convert currencies instantly!",
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
