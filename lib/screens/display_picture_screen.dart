import 'package:flutter/material.dart';
import 'dart:io';
import 'vision_api_service.dart';

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  bool _isLoading = true;
  String? _prediction;
  late VisionApiService _visionApiService;

  @override
  void initState() {
    super.initState();
    _visionApiService = VisionApiService(
        'sk-proj-BVGIbSJZO9YYqkoouf0ET3BlbkFJfADaCUc3zo0xthvvqp0p');
    _identifyPokemon();
  }

  Future<void> _identifyPokemon() async {
    final imageFile = File(widget.imagePath);
    try {
      final prediction = await _visionApiService.identifyPokemon(imageFile);
      setState(() {
        _prediction = prediction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _prediction = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Image.file(File(widget.imagePath)),
                if (_prediction != null)
                  Text(
                    'Prediction: $_prediction',
                    style: const TextStyle(fontSize: 20),
                  ),
                if (_prediction == null)
                  const Text(
                    'No prediction available',
                    style: TextStyle(fontSize: 20),
                  ),
              ],
            ),
    );
  }
}
