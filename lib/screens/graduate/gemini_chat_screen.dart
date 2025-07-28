import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../widgets/rive_loading_indicator.dart'; // Import RiveLoadingIndicator

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({super.key});

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  GenerativeModel? _model;
  bool _apiKeyMissing = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    const apiKey = 'AIzaSyARqrwtpV9ddvoWq7-DfIRV5bPKwPG-TO4';
    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _apiKeyMissing = true;
      });
      print('GEMINI_API_KEY not found in .env file');
      return;
    }
    _model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey);
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _messages.add({'text': _controller.text, 'isUser': true});
    });

    final userText = _controller.text;
    _controller.clear();

    if (_model == null) {
      setState(() {
        _messages.add({
          'text': 'Model is not initialized. Please check your API key.',
          'isUser': false
        });
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await _model!.generateContent([Content.text(userText)]);
      final responseText = response.text;

      setState(() {
        if (responseText == null || responseText.isEmpty) {
          _messages.add({
            'text': 'Received an empty response from the model.',
            'isUser': false
          });
        } else {
          _messages.add({'text': responseText, 'isUser': false});
        }
      });
    } catch (e) {
      print('Error generating content: $e');
      setState(() {
        _messages.add({
          'text':
              'An error occurred. Please check your API key, network connection, and billing status.',
          'isUser': false
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Gemini'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _apiKeyMissing
                ? const Center(
                    child: Text(
                      'GEMINI_API_KEY is missing.',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageBubble(
                        text: message['text'],
                        isUser: message['isUser'],
                      );
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: RiveLoadingIndicator(), // Replaced here
            ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (text) => _sendMessage(),
              enabled: !_apiKeyMissing,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: theme.colorScheme.primary),
            onPressed: _isLoading || _apiKeyMissing ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String? text;
  final bool isUser;

  const MessageBubble({
    super.key,
    this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment =
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color =
        isUser ? theme.colorScheme.primary : theme.colorScheme.surface;
    final textColor =
        isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
              ),
            ],
          ),
          child: Text(
            text ?? '', // Use null-aware operator for safety
            style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.5, end: 0);
  }
}