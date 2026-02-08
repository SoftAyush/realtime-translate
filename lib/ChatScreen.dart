import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:translator/translator.dart';

import 'ChatModel.dart';
import 'LanguageSelector.dart';
import 'utils/languagesCode.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GoogleTranslator _translator = GoogleTranslator();
  final FocusNode _focusNode = FocusNode();

  final List<ChatModel> messages = [];
  final Map<String, String> _translationCache = {};

  String selectedLanguage = 'English';
  bool _isSending = false;

  /* ---------------- TRANSLATION ---------------- */

  Future<String> _translateText(String text) async {
    final targetCode = languagesCode[selectedLanguage] ?? 'en';
    final cacheKey = '$text-$targetCode';

    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    try {
      final result = await _translator.translate(text, to: targetCode);
      _translationCache[cacheKey] = result.text;
      return result.text;
    } catch (_) {
      return text;
    }
  }

  /* ---------------- SEND MESSAGE ---------------- */

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _controller.clear();
    _focusNode.unfocus();

    final msg = ChatModel(
      text: text,
      originalText: text,
      msgLanguage: selectedLanguage,
    );

    setState(() => messages.add(msg));
    _scrollToBottom();

    await Future.delayed(
      const Duration(microseconds: 300),
    ); // Sending animation delay

    final translated = await _translateText(text);
    if (translated != text) {
      final index = messages.indexOf(msg);
      if (index != -1) {
        setState(() {
          messages[index] = msg.copyWith(text: translated);
        });
      }
    }

    setState(() => _isSending = false);
  }

  /* ---------------- LANGUAGE ---------------- */

  void _openLanguageSelector() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LanguageSelector(selectedLanguage: selectedLanguage),
    );

    if (result != null && result != selectedLanguage) {
      setState(() => selectedLanguage = result);
      await _retranslateChat();
    }
  }

  Future<void> _retranslateChat() async {
    final selectedCode = languagesCode[selectedLanguage];

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (msg.originalText == null) continue;

      if (languagesCode[msg.msgLanguage] == selectedCode) {
        messages[i] = msg.copyWith(text: msg.originalText);
      } else {
        final translated = await _translateText(msg.originalText!);
        messages[i] = msg.copyWith(text: translated);
      }
    }

    setState(() {});
  }

  /* ---------------- IMAGE ---------------- */

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Use web-safe approach
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        print("Picked file name: ${result.files.first.name}");
      } else {
        print("No image selected");
      }
    } else {
      // Mobile (iOS/Android)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          print("Picked image path: $filePath");
        }
      } else {
        print("No image selected");
      }
    }
  }
  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Column(
        children: [
          _appBar(),
          Expanded(
            child: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0A0E21),
                        Color(0xFF1A1F38),
                        Color(0xFF0A0E21),
                      ],
                    ),
                  ),
                ),
                // Subtle pattern overlay
                Opacity(
                  opacity: 0.03,
                  child: Container(
                    decoration: BoxDecoration(
                      // image: DecorationImage(
                      //   image: AssetImage('assets/pattern.png'),
                      //   // Add your pattern asset
                      //   repeat: ImageRepeat.repeat,
                      // ),
                    ),
                  ),
                ),
                if (messages.isEmpty) _welcomeMessage(),
                _chatList(),
              ],
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      elevation: 0,
      toolbarHeight: 80,
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white.withOpacity(0.1),
          child: const Icon(Icons.support_agent, color: Color(0xFF00E5FF)),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support Chat',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "language: $selectedLanguage",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.translate, size: 20, color: Colors.white),
          ),
          onPressed: _openLanguageSelector,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _chatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (_, index) {
        return _chatBubble(messages[index], index);
      },
    );
  }

  Widget _welcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.support_agent,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Chat Support',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 16, color: Color(0xFF00E5FF)),
                const SizedBox(width: 8),
                Text(
                  'Secure and multilingual support',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatBubble(ChatModel msg, int index) {
    final time =
        '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: Colors.blueAccent,

          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (msg.originalText != null && msg.originalText != msg.text) ...[
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  msg.originalText!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (msg.originalText != null && msg.originalText != msg.text)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.translate,
                          size: 8,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Translated',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(Icons.add, color: Colors.white.withOpacity(0.8)),
            ),
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(microseconds: 300),
            width: _isSending ? 50 : 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: _isSending
                  ? const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
              shape: BoxShape.circle,
            ),
            child: _isSending
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  )
                : IconButton(
                    icon: Transform.rotate(
                      angle: -0.2,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                    onPressed: _sendMessage,
                  ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(microseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }
}
