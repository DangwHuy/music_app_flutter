import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// A simple data class for messages
class _Message {
  final String text;
  final bool isFromUser;

  _Message(this.text, this.isFromUser);
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_Message> _messages = [];
  bool _isLoading = false;

  late final GenerativeModel _model;

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  @override
  void initState() {
    super.initState();

    // --- DEBUGGING: Check if the API key was loaded --- 
    if (_apiKey.isEmpty) {
      print('CRITICAL ERROR: GEMINI_API_KEY was not found!');
    } else {
      print('API Key loaded successfully.');
    }
    // -----------------------------------------------------

    _model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);

    _messages.add(_Message('Xin chào! Bạn cần tôi giúp gì hôm nay?', false));
  }

  void _sendMessage() async {
    final text = _controller.text;
    if (text.isEmpty) return;

    setState(() {
      _messages.insert(0, _Message(text, true));
      _isLoading = true;
    });
    _controller.clear();

    try {
      final response = await _model.generateContent([Content.text(text)]);
      final aiResponse = response.text ?? 'Xin lỗi, tôi không thể trả lời câu hỏi này.';

      setState(() {
        _messages.insert(0, _Message(aiResponse, false));
        _isLoading = false;
      });
    } catch (e) {

      // --- DEBUGGING: Print the actual API error --- 
      print('API ERROR: $e');
      // --------------------------------------------------

      setState(() {
        _messages.insert(0, _Message('Đã xảy ra lỗi, vui lòng thử lại.', false));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Trò chuyện với AI'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Align(
                    alignment: message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.isFromUser ? Colors.blue : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(message.text, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Hỏi AI bất cứ điều gì...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: Colors.grey.shade800,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
