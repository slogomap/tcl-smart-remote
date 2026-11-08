import 'package:flutter/material.dart';
import '../theme/colors.dart';

class KeyboardInputDialog extends StatefulWidget {
  final Function(String text) onSendText;

  const KeyboardInputDialog({
    Key? key,
    required this.onSendText,
  }) : super(key: key);

  @override
  State<KeyboardInputDialog> createState() => _KeyboardInputDialogState();
}

class _KeyboardInputDialogState extends State<KeyboardInputDialog> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendText(text);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.keyboard, color: AppColors.tclRed),
          SizedBox(width: 10),
          Text(
            'TV Keyboard Input',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type on your phone to send keystrokes to the active search field on your TCL TV.',
            style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            autofocus: true,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Enter search query or URL...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _textController.clear(),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Send to TV'),
        ),
      ],
    );
  }
}
