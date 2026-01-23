import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/logo/mediscan_logo.png',
            height: 36,
            width: 36,
          ),
        ),
        title: const Text('About MediScan'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MediScan: Skin Disease Classifier',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CarouselSlider(
                options: CarouselOptions(
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  enlargeCenterPage: true,
                ),
                items: [
                  Image.network(
                    'https://picsum.photos/seed/mediscan1/500/300',
                    fit: BoxFit.cover,
                  ),
                  Image.network(
                    'https://picsum.photos/seed/mediscan2/500/300',
                    fit: BoxFit.cover,
                  ),
                  Image.network(
                    'https://picsum.photos/seed/mediscan3/500/300',
                    fit: BoxFit.cover,
                  ),
                ].map((i) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: i,
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'MediScan helps users identify skin diseases using state-of-the-art machine learning. Just upload an image, and get instant results powered by deep learning.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Features:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text('• Easy image upload.'),
              const Text('• Fast AI predictions.'),
              const Text('• Real-time results.'),
              const SizedBox(height: 16),
              const Text(
                'Developed with love by Flutter and FastAPI.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
