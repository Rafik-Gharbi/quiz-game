import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_games/utils/helper.dart';
import 'package:quiz_games/views/widgets/app_header.dart';

import '../../services/main_controller.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          final jsonString = utf8.decode(bytes);
          _textController.text = jsonString;
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      Helper.snackBar(message: 'Error picking file: $e');
    }
  }

  Future<void> _createRoom() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or upload quiz data')),
      );
      return;
    }
    if (FirebaseAuth.instance.currentUser?.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current session not logged in')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await MainController.find.createRoom(_textController.text);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 800),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppHeader(),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Upload or Paste Quiz Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choose File'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Or paste JSON data here...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF5B7FFF)),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7FFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Create Room',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
