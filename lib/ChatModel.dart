
class ChatModel {
  final String text;
  final String? originalText;
  final DateTime time;
  final String msgLanguage;

  ChatModel({
    required this.text,
    this.originalText,
    DateTime? time,
    required this.msgLanguage,
  }) : time = time ?? DateTime.now();

  ChatModel copyWith({
    String? text,
    String? originalText,
    DateTime? time,
    String? msgLanguage,
  }) {
    return ChatModel(
      text: text ?? this.text,
      originalText: originalText ?? this.originalText,
      time: time ?? this.time,
      msgLanguage: msgLanguage ?? this.msgLanguage,
    );
  }
}