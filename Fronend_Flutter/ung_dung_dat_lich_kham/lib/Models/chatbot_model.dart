class ChatbotMessage {
  final String text;
  final bool isUser; // true: Tin nhắn của bệnh nhân, false: Tin nhắn của AI

  ChatbotMessage({
    required this.text,
    required this.isUser,
  });
}