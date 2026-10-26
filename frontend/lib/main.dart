import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SmartDbApp());
}

class SmartDbApp extends StatelessWidget {
  const SmartDbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartDB AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6558D3)),
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String? queryInfo;

  ChatMessage({required this.text, required this.isUser, this.queryInfo});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Android Emulator:
  static const String apiUrl = 'http://10.0.2.2:8000';

  // Para Flutter Windows usa:
  // static const String apiUrl = 'http://127.0.0.1:8000';

  final TextEditingController inputController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  final List<ChatMessage> messages = [
    ChatMessage(
      text:
          '¡Hola! Soy SmartDB AI 👋\n\n'
          'Puedo consultar los datos de tu base de datos, '
          'analizar problemas y recomendar soluciones.\n\n'
          '¿Qué deseas investigar hoy?',
      isUser: false,
    ),
  ];

  bool loading = false;

  Future<void> sendMessage([String? suggestion]) async {
    final question = (suggestion ?? inputController.text).trim();

    if (question.isEmpty || loading) return;

    setState(() {
      messages.add(ChatMessage(text: question, isUser: true));

      loading = true;
      inputController.clear();
    });

    scrollToBottom();

    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'pregunta': question}),
          )
          .timeout(const Duration(seconds: 90));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = decoded as Map<String, dynamic>;

        addAssistantMessage(
          data['respuesta']?.toString() ??
              'No se recibió una respuesta válida.',
          queryInfo: describeQuery(data),
        );
      } else {
        final detail = decoded is Map ? decoded['detail']?.toString() : null;

        addAssistantMessage(
          'No se pudo procesar la consulta.\n'
          '${detail ?? 'Error HTTP ${response.statusCode}'}',
        );
      }
    } catch (e) {
      addAssistantMessage(
        'No pude conectar con FastAPI.\n\n'
        'Comprueba que el servidor esté ejecutándose '
        'y que apiUrl corresponda a tu dispositivo.\n\n'
        'Detalle: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
        scrollToBottom();
      }
    }
  }

  void addAssistantMessage(String text, {String? queryInfo}) {
    if (!mounted) return;

    setState(() {
      messages.add(
        ChatMessage(text: text, isUser: false, queryInfo: queryInfo),
      );
    });

    scrollToBottom();
  }

  String? describeQuery(Map<String, dynamic> data) {
    final intent = data['intencion']?.toString();
    if (intent == null) return null;

    final params = data['parametros'];
    final paramsText = params is Map && params.isNotEmpty
        ? ' (${params.entries.map((e) => '${e.key}: ${e.value}').join(', ')})'
        : '';

    return 'Consulta: $intent$paramsText · '
        '${data['registros_analizados'] ?? 0} registros';
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void clearChat() {
    if (loading) return;

    setState(() {
      messages.clear();

      messages.add(
        ChatMessage(
          text: 'Conversación nueva. ¿Qué deseas consultar?',
          isUser: false,
        ),
      );
    });
  }

  @override
  void dispose() {
    inputController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFEAE7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.psychology_alt_rounded,
                color: Color(0xFF6558D3),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SmartDB AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Asistente inteligente',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Nueva conversación',
            onPressed: clearChat,
            icon: const Icon(Icons.add_comment_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                itemCount: messages.length + (loading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return const TypingIndicator();
                  }

                  final message = messages[index];

                  return MessageBubble(message: message);
                },
              ),
            ),

            if (messages.length == 1 && !loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    suggestionChip(
                      '📦 Revisar inventario',
                      '¿Qué productos necesitan reposición?',
                    ),
                    suggestionChip(
                      '📊 Analizar datos',
                      'Analiza todos los productos y '
                          'recomienda mejoras.',
                    ),
                    suggestionChip(
                      '💡 Buscar soluciones',
                      '¿Qué problemas identificas en '
                          'los datos y cómo los solucionarías?',
                    ),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEAEAF0))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: inputController,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Pregunta sobre tus datos...',
                        filled: true,
                        fillColor: const Color(0xFFF4F4F8),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: IconButton.filled(
                      onPressed: loading ? null : () => sendMessage(),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF6558D3),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget suggestionChip(String label, String question) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFDEDAF8)),
      onPressed: () => sendMessage(question),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: user
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!user) ...[
            const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFEAE7FF),
              child: Icon(
                Icons.psychology_alt_rounded,
                color: Color(0xFF6558D3),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: user ? const Color(0xFF6558D3) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(user ? 18 : 4),
                  bottomRight: Radius.circular(user ? 4 : 18),
                ),
                border: user
                    ? null
                    : Border.all(color: const Color(0xFFEAEAF0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: user ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (message.queryInfo != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EFFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storage_rounded,
                            size: 14,
                            color: Color(0xFF6558D3),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              message.queryInfo!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6558D3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (user) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16, left: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFEAE7FF),
            child: Icon(
              Icons.psychology_alt_rounded,
              color: Color(0xFF6558D3),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Analizando tus datos...',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6558D3),
            ),
          ),
        ],
      ),
    );
  }
}