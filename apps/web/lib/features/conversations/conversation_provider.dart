import 'package:flutter/material.dart';
import 'conversation_service.dart';

class ConversationProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  Conversation?      _selected;
  List<Message>      _messages      = [];

  bool    _isLoadingList     = false;
  bool    _isLoadingMessages = false;
  bool    _isSending         = false;
  String? _error;

  List<Conversation> get conversations       => _conversations;
  Conversation?      get selected            => _selected;
  List<Message>      get messages            => _messages;
  bool               get isLoadingList       => _isLoadingList;
  bool               get isLoadingMessages   => _isLoadingMessages;
  bool               get isSending           => _isSending;
  String?            get error               => _error;

  Future<void> loadConversations() async {
    _isLoadingList = true;
    _error = null;
    notifyListeners();
    try {
      _conversations = await ConversationService.listConversations();
      // Seleccionar la primera conversación automáticamente si hay alguna
      if (_conversations.isNotEmpty && _selected == null) {
        await selectConversation(_conversations.first);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  Future<void> selectConversation(Conversation conv) async {
    _selected          = conv;
    _messages          = [];
    _isLoadingMessages = true;
    notifyListeners();
    try {
      _messages = await ConversationService.listMessages(conv.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (_selected == null || content.trim().isEmpty) return;
    _isSending = true;
    notifyListeners();
    try {
      // Agrega el mensaje del operador (role: 'user' = mensaje del cliente/operador)
      final msg = await ConversationService.sendMessage(
        conversationId: _selected!.id,
        role: 'user',
        content: content.trim(),
      );
      _messages.add(msg);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> createConversation({
    String? contactPhone,
    String? contactName,
  }) async {
    try {
      final conv = await ConversationService.createConversation(
        contactPhone: contactPhone,
        contactName: contactName,
      );
      _conversations.insert(0, conv);
      await selectConversation(conv);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
