import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Simple container for per‑disease information.
class DiseaseInfo {
  final String title;
  final String description;
  final String immediateCare;
  final String consultAdvice;

  const DiseaseInfo({
    required this.title,
    required this.description,
    required this.immediateCare,
    required this.consultAdvice,
  });
}

/// Text for all 7 HAM10000 classes.
/// You can adjust wording later as needed.
const Map<String, DiseaseInfo> kDiseaseInfo = {
  'akiec': DiseaseInfo(
    title: 'Actinic keratosis / Bowen disease (possible)',
    description:
    'These are sun‑related skin changes that can sometimes develop into skin cancer if not treated.',
    immediateCare:
    'Protect the area from further sun exposure and avoid scratching or picking the lesion.',
    consultAdvice:
    'Schedule a visit with a dermatologist for assessment and to discuss possible treatment options.',
  ),
  'bcc': DiseaseInfo(
    title: 'Basal cell carcinoma (possible)',
    description:
    'Basal cell carcinoma is a common type of skin cancer that usually grows slowly and rarely spreads.',
    immediateCare:
    'Do not apply harsh chemicals or home remedies. Keep the area clean and protected from the sun.',
    consultAdvice:
    'Arrange a prompt appointment with a dermatologist to confirm the diagnosis and plan treatment.',
  ),
  'bkl': DiseaseInfo(
    title: 'Benign keratosis‑like lesion (possible)',
    description:
    'These are usually non‑cancerous growths such as seborrheic keratoses or solar lentigines.',
    immediateCare:
    'These lesions are often harmless, but avoid scratching or irritating them.',
    consultAdvice:
    'Consult a dermatologist if the lesion changes, bleeds, or becomes bothersome.',
  ),
  'df': DiseaseInfo(
    title: 'Dermatofibroma (possible)',
    description:
    'Dermatofibromas are usually small, firm, benign skin nodules caused by an overgrowth of fibrous tissue.',
    immediateCare:
    'Typically no urgent care is needed; avoid repeated trauma or shaving over the lesion.',
    consultAdvice:
    'See a dermatologist if the lesion changes, becomes painful, or you are unsure of the diagnosis.',
  ),
  'mel': DiseaseInfo(
    title: 'Melanoma (possible)',
    description:
    'Melanoma is a potentially serious type of skin cancer that can spread if not detected early.',
    immediateCare:
    'Do not delay or attempt home treatment. Protect the area from sun and avoid injury to the lesion.',
    consultAdvice:
    'Contact a dermatologist or qualified clinician as soon as possible for a full examination and possible biopsy.',
  ),
  'nv': DiseaseInfo(
    title: 'Melanocytic nevus / mole (possible)',
    description:
    'Common moles are usually benign clusters of pigment cells and often remain stable for years.',
    immediateCare:
    'Monitor this mole for changes in size, color, border, or symptoms such as itching or bleeding.',
    consultAdvice:
    'Seek a dermatologist’s opinion if this mole looks very different from others or changes rapidly.',
  ),
  'vasc': DiseaseInfo(
    title: 'Vascular lesion (possible)',
    description:
    'Vascular lesions include benign blood‑vessel growths such as hemangiomas or angiomas.',
    immediateCare:
    'Avoid trauma to the area to reduce the risk of bleeding or irritation.',
    consultAdvice:
    'Consult a dermatologist if the lesion grows quickly, bleeds, or causes discomfort.',
  ),
};

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String _label = 'No prediction yet.';
  double _probability = 0.0;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _error = null;
    });

    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _label = 'Awaiting prediction...';
      _probability = 0.0;
      _loading = true;
    });

    await _runInference();
  }

  Future<void> _runInference() async {
    if (_image == null) return;

    try {
      final uri = Uri.parse('$kBackendBaseUrl/predict');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _image!.path,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;

        final label = (result['label'] ?? 'Unknown').toString();
        final prob = result['probability'];
        final p = prob is num ? prob.toDouble() : 0.0;

        setState(() {
          _label = label;
          _probability = p;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Server error (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Inference failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _buildDiseaseInfo() {
    // Do not show info for invalid/uncertain/placeholder labels.
    if (_label == 'invalid' ||
        _label == 'uncertain' ||
        _label == 'No prediction yet.' ||
        _label == 'Awaiting prediction...') {
      return const SizedBox.shrink();
    }

    final info = kDiseaseInfo[_label];
    if (info == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(top: 16.0),
      elevation: 0,
      color: Colors.blueGrey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              info.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Immediate care',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info.immediateCare,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'When to consult a doctor',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info.consultAdvice,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'This AI result is not a medical diagnosis. '
                  'Always consult a qualified clinician for any skin concern.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_error != null) {
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (_image == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Pick or capture an image to start!',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    String title;
    String message;

    if (_label == 'invalid') {
      title = 'Image not suitable';
      message =
      'This image does not look like a skin photo. Please upload a close-up photo of a skin area.';
    } else if (_label == 'uncertain') {
      title = 'Prediction uncertain';
      message =
      'The model is not confident about this image. Please try a clearer close-up of the lesion.';
    } else {
      title = 'Prediction: $_label';
      message = 'Confidence: ${(_probability * 100).toStringAsFixed(1)}%';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.file(_image!, height: 180, width: 180, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            if (_label != 'invalid' && _label != 'uncertain') ...[
              const Text('Confidence:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: _probability.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              Text(message),
              _buildDiseaseInfo(),
            ] else
              Text(
                message,

                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

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
        title: const Text('MediScan UI'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              _buildResultCard(),
              const SizedBox(height: 16),
              if (_loading) const CircularProgressIndicator(),
              if (!_loading) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  label: const Text('Pick from Gallery'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => _pickImage(ImageSource.camera),
                  label: const Text('Use Camera'),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Upload or capture a skin image to see model predictions!',
                style: TextStyle(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
