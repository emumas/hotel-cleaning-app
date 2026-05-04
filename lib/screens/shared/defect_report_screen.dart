import 'dart:io' if (dart.library.html) 'dart:html';
import 'dart:typed_data'; // Add this import for Uint8List
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hotel_cleaning_app/models/defect_report.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';

class DefectReportScreen extends ConsumerStatefulWidget {
  final String roomId;
  final Map<String, dynamic>? extra;

  const DefectReportScreen({super.key, required this.roomId, this.extra});

  @override
  ConsumerState<DefectReportScreen> createState() => _DefectReportScreenState();
}

class _DefectReportScreenState extends ConsumerState<DefectReportScreen> {
  DefectLocation? _selectedLocation;
  final List<XFile> _photos = []; // Changed from List<File> to List<XFile>
  final _notesController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _photos.add(picked)); // Store XFile directly
    }
  }

  Future<void> _submit() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('場所を選択してください')),
      );
      return;
    }
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真を1枚以上追加してください')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = ref.read(defectServiceProvider);
      final userName = ref.read(currentUserNameProvider);

      final List<Uint8List> photosData = [];
      for (final xFile in _photos) {
        photosData.add(await xFile.readAsBytes()); // Convert XFile to Uint8List
      }

      await service.addDefectReport(
        roomId: widget.roomId,
        roomNumber: widget.extra?['roomNumber'] ?? '',
        floorName: widget.extra?['floorName'] ?? '',
        location: _selectedLocation!,
        photosData: photosData, // Pass photosData instead of _photos
        registeredBy: userName,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
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
        title: Text('不具合報告 - $floorName $roomNumber号室'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('場所', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DefectLocation.values.map((loc) {
                return ChoiceChip(
                  label: Text(loc.displayName),
                  selected: _selectedLocation == loc,
                  onSelected: (_) =>
                      setState(() => _selectedLocation = loc),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('写真', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_photos.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  itemBuilder: (context, i) => Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: MemoryImage(File(_photos[i].path).readAsBytesSync()), // Display XFile as MemoryImage
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _photos.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('カメラで撮影'),
              onPressed: _pickPhoto,
            ),
            const SizedBox(height: 24),
            const Text('メモ（任意）',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '詳細を入力（任意）',
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('報告する'),
                onPressed: _submit,
              ),
          ],
        ),
      ),
    );
  }
}
