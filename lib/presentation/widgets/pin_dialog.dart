import 'package:flutter/material.dart';

enum PinDialogMode {
  verify,
  create,
  change,
}

class PinDialog extends StatefulWidget {
  final PinDialogMode mode;
  final String? title;
  final String? subtitle;

  const PinDialog({
    super.key,
    this.mode = PinDialogMode.verify,
    this.title,
    this.subtitle,
  });

  static Future<String?> show(
    BuildContext context, {
    PinDialogMode mode = PinDialogMode.verify,
    String? title,
    String? subtitle,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: mode != PinDialogMode.verify,
      builder: (ctx) => PinDialog(mode: mode, title: title, subtitle: subtitle),
    );
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePin = true;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _errorMessage = 'PIN must be at least 4 digits');
      return;
    }

    if (widget.mode == PinDialogMode.create || widget.mode == PinDialogMode.change) {
      final confirm = _confirmController.text.trim();
      if (pin != confirm) {
        setState(() => _errorMessage = 'PINs do not match');
        return;
      }
    }

    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCreate = widget.mode == PinDialogMode.create || widget.mode == PinDialogMode.change;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_rounded, color: theme.primaryColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title ?? (isCreate ? 'Set Security PIN' : 'Enter PIN'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.subtitle ?? (isCreate ? 'Protect locked notes with AES-256' : 'Enter your 4-6 digit PIN'),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: _obscurePin,
              maxLength: 6,
              style: const TextStyle(letterSpacing: 8, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '••••',
                counterText: '',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, size: 20),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
              onSubmitted: (_) => isCreate ? null : _submit(),
            ),
            if (isCreate) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                keyboardType: TextInputType.number,
                obscureText: _obscurePin,
                maxLength: 6,
                style: const TextStyle(letterSpacing: 8, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'Confirm PIN',
                  counterText: '',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(isCreate ? 'Save PIN' : 'Unlock'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
