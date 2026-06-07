import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

const kBgTop       = Color(0xFF1A0A00);
const kBgBottom    = Color(0xFFC97A3A);
const kCardBg      = Color(0xFF1E0A00);
const kInputBg     = Color(0xFF2E0F05);
const kInputBorder = Color(0xFF7A3810);
const kAccent      = Color(0xFFC97A3A);
const kAccentDark  = Color(0xFF8B4A18);
const kTextLight   = Color(0xFFF5E8D0);
const kTextMuted   = Color(0xFFB88A60);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Art Studio
  final _promptCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String _artStatus = '';
  bool _isPainting = false;

  // Chat Studio
  final _chatCtrl = TextEditingController();
  final _chatScrollCtrl = ScrollController();
  final List<Map<String, String>> _chatHistory = [];
  final List<Map<String, String>> _chatMessages = [];
  String _chatStatus = '';
  bool _isChatting = false;
  bool _isListening = false;

  // Native Android Speech Recognition channel
  static const _speechChannel = MethodChannel('com.robomunch/speech');

  @override
  void initState() {
    super.initState();
    // Listen for speech results from native Android
    _speechChannel.setMethodCallHandler((call) async {
      if (call.method == 'onSpeechResult') {
        final text = call.arguments as String? ?? '';
        setState(() {
          _chatCtrl.text = text;
          _isListening = false;
          _chatStatus = '';
        });
      } else if (call.method == 'onSpeechError') {
        setState(() {
          _isListening = false;
          _chatStatus = 'Voice error, try again.';
        });
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechChannel.invokeMethod('stopListening');
      setState(() => _isListening = false);
      return;
    }
    setState(() {
      _isListening = true;
      _chatStatus = 'Listening...';
      _chatCtrl.clear();
    });
    try {
      await _speechChannel.invokeMethod('startListening');
    } catch (e) {
      setState(() {
        _isListening = false;
        _chatStatus = 'Voice not available: $e';
      });
    }
  }

  Future<void> _generateImage() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _isPainting = true;
      _artStatus = 'Generating image (~20-40s)...';
      _imageBytes = null;
    });
    try {
      final b64 = await ApiService.paint(prompt);
      setState(() {
        _imageBytes = base64Decode(b64);
        _artStatus = '✨ Done!';
      });
    } catch (e) {
      setState(() => _artStatus = 'Error: $e');
    } finally {
      setState(() => _isPainting = false);
    }
  }

  Future<void> _sendMessage() async {
    final message = _chatCtrl.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _chatMessages.add({'role': 'user', 'content': message});
      _chatHistory.add({'role': 'user', 'content': message});
      _chatCtrl.clear();
      _isChatting = true;
      _chatStatus = 'RoboMunch is thinking...';
    });
    _scrollChat();
    try {
      final reply = await ApiService.chat(
        message: message,
        history: List.from(_chatHistory)..removeLast(),
      );
      setState(() {
        _chatMessages.add({'role': 'assistant', 'content': reply});
        _chatHistory.add({'role': 'assistant', 'content': reply});
        _chatStatus = '';
      });
    } catch (e) {
      setState(() => _chatStatus = 'Error: $e');
    } finally {
      setState(() => _isChatting = false);
      _scrollChat();
    }
  }

  void _scrollChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kBgTop, Color(0xFF5C2200), kBgBottom],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildArtStudio(),
                    const SizedBox(height: 20),
                    _buildChatStudio(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: kCardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kInputBorder.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'ROBO',
                  style: TextStyle(color: kTextLight, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                TextSpan(
                  text: 'MUNCH',
                  style: TextStyle(color: kAccent, fontSize: 14, letterSpacing: 4),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 26,
            backgroundColor: kAccentDark,
            child: const Icon(Icons.face, color: kTextLight, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildArtStudio() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kInputBorder.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Text('Art Studio', style: TextStyle(color: kTextMuted, letterSpacing: 3, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0403),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kInputBorder),
            ),
            child: _isPainting
                ? const Center(child: CircularProgressIndicator(color: kAccent))
                : _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : const Center(
                        child: Text(
                          'Your masterpiece will appear here…',
                          style: TextStyle(color: kTextMuted, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: kInputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kInputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptCtrl,
                    style: const TextStyle(color: kTextLight),
                    decoration: const InputDecoration(
                      hintText: 'Type your prompt here.',
                      hintStyle: TextStyle(color: kTextMuted),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _generateImage(),
                  ),
                ),
                _circleButton(icon: Icons.palette, onTap: _isPainting ? null : _generateImage),
              ],
            ),
          ),
          if (_artStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_artStatus, style: const TextStyle(color: kTextMuted, fontStyle: FontStyle.italic, fontSize: 12), textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }

  Widget _buildChatStudio() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kInputBorder.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Text('Chat Studio', style: TextStyle(color: kTextMuted, letterSpacing: 3, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kInputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kInputBorder),
            ),
            child: _chatMessages.isEmpty
                ? const Text(
                    'MUNCH: Hello! I am RoboMunch, your digital artist companion.',
                    style: TextStyle(color: kTextMuted, fontStyle: FontStyle.italic, fontSize: 13),
                  )
                : ListView.separated(
                    controller: _chatScrollCtrl,
                    itemCount: _chatMessages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final msg = _chatMessages[i];
                      final isUser = msg['role'] == 'user';
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: isUser ? 'YOU: ' : 'MUNCH: ',
                              style: TextStyle(
                                color: isUser ? const Color(0xFFE8C490) : kAccent,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(text: msg['content'], style: const TextStyle(color: kTextLight, fontSize: 13)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _circleButton(
                icon: _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : kAccentDark,
                onTap: _toggleListening,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: kInputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kInputBorder),
                  ),
                  child: TextField(
                    controller: _chatCtrl,
                    style: const TextStyle(color: kTextLight),
                    decoration: const InputDecoration(
                      hintText: 'Type your message here.',
                      hintStyle: TextStyle(color: kTextMuted),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _circleButton(icon: Icons.send, onTap: _isChatting ? null : _sendMessage),
            ],
          ),
          if (_chatStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_chatStatus, style: const TextStyle(color: kTextMuted, fontStyle: FontStyle.italic, fontSize: 12), textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap, Color color = kAccentDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: onTap == null ? kInputBg : color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8)],
        ),
        child: Icon(icon, color: kTextLight, size: 20),
      ),
    );
  }
}