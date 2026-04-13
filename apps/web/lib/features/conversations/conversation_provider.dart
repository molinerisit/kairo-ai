import 'dart:async';
import 'package:flutter/material.dart';
import 'conversation_service.dart';

class ConversationProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  Conversation?      _selected;
  List<Message>      _messages      = [];

  bool    _isLoadingList     = false;
  bool    _isLoadingMessages = false;
  bool    _isSending         = false;
  bool    _isInvokingAgent   = false;
  String? _agentSuggestion;
  String? _error;

  Timer? _pollTimer;

  List<Conversation> get conversations       => _conversations;
  Conversation?      get selected            => _selected;
  List<Message>      get messages            => _messages;
  bool               get isLoadingList       => _isLoadingList;
  bool               get isLoadingMessages   => _isLoadingMessages;
  bool               get isSending           => _isSending;
  bool               get isInvokingAgent     => _isInvokingAgent;
  String?            get agentSuggestion     => _agentSuggestion;
  String?            get error               => _error;

  // startPolling: inicia un timer que refresca conversaciones y mensajes cada 10s.
  // Seguro llamarlo varias veces — cancela el timer anterior si ya había uno.
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _silentRefresh());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  // _silentRefresh: refresca sin mostrar spinner para no hacer flickering.
  Future<void> _silentRefresh() async {
    try {
      final updated = await ConversationService.listConversations();

      // Actualizar lista solo si hay cambios para evitar rebuilds innecesarios
      final prevIds    = _conversations.map((c) => '${c.id}${c.lastMessageAt}').toSet();
      final newIds     = updated.map((c) => '${c.id}${c.lastMessageAt}').toSet();
      final listChanged = prevIds.length != newIds.length || !prevIds.containsAll(newIds);

      if (listChanged) {
        _conversations = updated;
        notifyListeners();
      }

      // Si hay una conversación seleccionada, refrescar sus mensajes también
      if (_selected != null) {
        final msgs = await ConversationService.listMessages(_selected!.id);
        if (msgs.length != _messages.length) {
          _messages = msgs;
          notifyListeners();
        }
      }
    } catch (_) {
      // Silencioso: no mostrar error en polling automático
    }
  }

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

  // invokeAgent: pide al secretario que genere una respuesta y la guarda como sugerencia.
  // El backend ya la guardó en la DB como mensaje assistant.
  Future<void> invokeAgent() async {
    if (_selected == null) return;
    _isInvokingAgent = true;
    _agentSuggestion = null;
    _error = null;
    notifyListeners();
    try {
      _agentSuggestion = await ConversationService.invokeAgent(_selected!.id);
      // Recargar mensajes para mostrar el mensaje assistant que el backend guardó
      _messages = await ConversationService.listMessages(_selected!.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isInvokingAgent = false;
      notifyListeners();
    }
  }

  void clearAgentSuggestion() {
    _agentSuggestion = null;
    notifyListeners();
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
