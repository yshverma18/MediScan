import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'main.dart';          // for MainScreen
import 'user_session.dart';

class PatientFormPage extends StatefulWidget {
  const PatientFormPage({super.key});

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _sex = 'Female';
  String _skinType = 'Type II';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$kBackendBaseUrl/users/register').replace(
        queryParameters: {
          'email': _emailCtrl.text.trim(),
          'name': _nameCtrl.text.trim(),
          'password': _passwordCtrl.text,
          // age/sex/skinType can be wired to backend later if needed
        },
      );

      final res = await http.post(uri);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final id = data['id'] as int;
        final email = data['email'] as String;
        final name = (data['name'] ?? '') as String;

        await UserSession.saveUser(id, name, email);

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        setState(() {
          _error =
          'Server error (${res.statusCode}) while creating account.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not connect to server: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MediScan – Patient Info')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create your account',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please provide basic information. This helps personalize your skin assessments.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Enter your email';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Create a password' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _sex,
                  decoration: const InputDecoration(
                    labelText: 'Sex',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                    DropdownMenuItem(
                      value: 'Prefer not to say',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _sex = v ?? _sex),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _skinType,
                  decoration: const InputDecoration(
                    labelText: 'Skin type (Fitzpatrick)',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Type I',
                      child: Text('Type I – Very fair, burns easily'),
                    ),
                    DropdownMenuItem(
                      value: 'Type II',
                      child: Text('Type II – Fair, usually burns'),
                    ),
                    DropdownMenuItem(
                      value: 'Type III',
                      child: Text('Type III – Medium'),
                    ),
                    DropdownMenuItem(
                      value: 'Type IV',
                      child: Text('Type IV – Olive / brown'),
                    ),
                    DropdownMenuItem(
                      value: 'Type V',
                      child: Text('Type V – Dark brown'),
                    ),
                    DropdownMenuItem(
                      value: 'Type VI',
                      child: Text('Type VI – Deeply pigmented'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _skinType = v ?? _skinType),
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Create account & continue'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'MediScan does not provide a medical diagnosis. '
                      'For any skin concern, consult a qualified clinician.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
