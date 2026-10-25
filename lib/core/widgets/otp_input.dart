import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';

/// Row of single-digit boxes for entering an emailed code.
/// Handles paste, overtyping and backspace-to-previous-box.
/// Call [OtpInputState.clear] through a GlobalKey to reset the boxes
/// (it does not fire [onChanged]; the caller resets its own copy of the code).
class OtpInput extends StatefulWidget {
  final int length;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const OtpInput({
    super.key,
    this.length = 6,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final List<FocusNode> _keyboardFocusNodes;
  late final List<String> _previousValues;

  String get code => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _keyboardFocusNodes = List.generate(widget.length, (_) => FocusNode());
    _previousValues = List.generate(widget.length, (_) => '');
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final k in _keyboardFocusNodes) {
      k.dispose();
    }
    super.dispose();
  }

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _syncPrevious();
    _focusNodes.first.requestFocus();
  }

  void _syncPrevious() {
    for (int i = 0; i < widget.length; i++) {
      _previousValues[i] = _controllers[i].text;
    }
  }

  void _onDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final last = widget.length - 1;

    if (digits.length >= 3) {
      // Pasted code (e.g. "123456")
      for (int i = 0; i < widget.length; i++) {
        if (i < digits.length) {
          _controllers[i].text = digits[i];
        } else {
          _controllers[i].clear();
        }
      }
      _syncPrevious();
      _focusNodes[digits.length < widget.length ? digits.length : last].requestFocus();
    } else if (digits.length == 2 && _previousValues[index].isNotEmpty) {
      // Typed over an already-filled box: keep whichever digit is new
      final newChar = digits[0] == _previousValues[index] ? digits[1] : digits[0];
      _controllers[index].text = newChar;
      _syncPrevious();
      index < last ? _focusNodes[index + 1].requestFocus() : _focusNodes[index].unfocus();
    } else if (digits.isNotEmpty) {
      _controllers[index].text = digits[digits.length - 1];
      _syncPrevious();
      index < last ? _focusNodes[index + 1].requestFocus() : _focusNodes[index].unfocus();
    } else {
      _controllers[index].clear();
      _syncPrevious();
    }

    widget.onChanged(code);
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _syncPrevious();
      widget.onChanged(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 44,
          height: 56,
          child: KeyboardListener(
            focusNode: _keyboardFocusNodes[index],
            onKeyEvent: (event) => _onKeyEvent(index, event),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNavy,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.brand, width: 2),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              onChanged: (value) => _onDigitChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}
