import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';

class LostItemRegisterScreen extends ConsumerStatefulWidget {
  final String roomId;
  final Map<String, dynamic>? extra;

  const LostItemRegisterScreen({super.key, required this.roomId, this.extra});

  @override
  ConsumerState<LostItemRegisterScreen> createState() =>
      _LostItemRegisterScreenState();
}

class _LostItemRegisterScreenState
    extends ConsumerState<LostItemRegisterScreen> {
  Uint8List? _photo;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _photo = bytes);
    }
  }

  Future<void> _submit() async {
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真を撮影してください')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final service = ref.read(lostItemServiceProvider);
      final userName = ref.read(currentUserNameProvider);
      await service.addLostItem(
        roomId: widget.roomId,
        roomNumber: widget.extra?['roomNumber'] ?? '',
        floorName: widget.extra?['floorName'] ?? '',
        photo: _photo!,
        registeredBy: userName,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomNumber = widget.extra?['roomNumber'] ?? '';
    final floorName = widget.extra?['floorName'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('忘れ物登録 - $floorName $roomNumber号室'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('写真', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_photo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _photo!,
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(_photo == null ? 'カメラで撮影' : '撮り直す'),
              onPressed: _pickPhoto,
            ),
            const SizedBox(height: 24),
            const Text('説明（任意）',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '忘れ物の詳細を入力（任意）',
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('登録する'),
                onPressed: _submit,
              ),
          ],
        ),
      ),
    );
  }
}
