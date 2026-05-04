import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_cleaning_app/core/constants/app_colors.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _error;

  void _onKeyPress(String value) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += value;
      _error = null;
    });
    if (_pin.length >= 4) _verifyPin();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(authServiceProvider);
      final role = await service.verifyPin(_pin);
      if (role != null) {
        ref.read(authProvider.notifier).state = role;
      } else {
        setState(() {
          _error = 'PINコードが正しくありません';
        debugPrint('Login Error: PIN incorrect'); // デバッグ用にエラーをコンソールに出力
          _pin = '';
        });
      }
    } on Exception catch (e) {
      setState(() {
        _error = 'エラーが発生しました: ${e.toString()}';
        _pin = '';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hotel, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'ホテル客室管理',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            _PinDisplay(pin: _pin, error: _error),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.white)
            else
              _PinKeypad(onKeyPress: _onKeyPress, onDelete: _onDelete),
          ],
        ),
      ),
    );
  }
}

class _PinDisplay extends StatelessWidget {
  final String pin;
  final String? error;

  const _PinDisplay({required this.pin, this.error});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < pin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? Colors.white : Colors.white30,
              ),
            );
          }),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 14),
          ),
        ],
      ],
    );
  }
}

class _PinKeypad extends StatelessWidget {
  final void Function(String) onKeyPress;
  final VoidCallback onDelete;

  const _PinKeypad({required this.onKeyPress, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];
    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 80, height: 80);
            return GestureDetector(
              onTap: () {
                if (key == 'del') {
                  onDelete();
                } else {
                  onKeyPress(key);
                }
              },
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white12,
                  border: Border.all(color: Colors.white30),
                ),
                alignment: Alignment.center,
                child: key == 'del'
                    ? const Icon(Icons.backspace_outlined, color: Colors.white)
                    : Text(
                        key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
