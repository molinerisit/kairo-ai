import '../../shared/api/api_client.dart';

// Modelos
class Conversation {
  final String id;
  final String channel;
  final String? contactPhone;
  final String? contactName;
  final String status;
  final String? lastMessageAt;

  Conversation({
    required this.id,
    required this.channel,
    this.contactPhone,
    this.contactName,
    required this.status,
    this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id:            json['id'] as String,
    channel:       json['channel'] as String,
    contactPhone:  json['contact_phone'] as String?,
    contactName:   json['contact_name'] as String?,
    status:        json['status'] as String,
    lastMessageAt: json['last_message_at'] as String?,
  );
}

class Message {
  final String id;
  final String conversationId;
  final String role;    // 'user' | 'assistant'
  final String content;
  final String? agentType;
  final String createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.agentType,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id:             json['id'] as String,
    conversationId: json['conversation_id'] as String,
    role:           json['role'] as String,
    content:        json['content'] as String,
    agentType:      json['agent_type'] as String?,
    createdAt:      json['created_at'] as String,
  );
}

// ── Servicio ──────────────────────────────────────────────────────

class ConversationService {
  static Future<List<Conversation>> listConversations() async {
    final data = await ApiClient.get('/api/conversations') as List;
    return data.map((c) => Conversation.fromJson(c as Map<String, dynamic>)).toList();
  }

  static Future<Conversation> createConversation({
    String channel = 'whatsapp',
    String? contactPhone,
    String? contactName,
  }) async {
    final data = await ApiClient.post('/api/conversations', body: {
      'channel': channel,
      'contact_phone': contactPhone,
      'contact_name':  contactName,
    });
    return Conversation.fromJson(data as Map<String, dynamic>);
  }

  static Future<Conversation> updateStatus(String id, String status) async {
    final data = await ApiClient.patch('/api/conversations/$id', body: {'status': status});
    return Conversation.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<Message>> listMessages(String conversationId) async {
    final data = await ApiClient.get('/api/conversations/$conversationId/messages') as List;
    return data.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
  }

  // invokeAgent: llama al agente secretario para generar una sugerencia de respuesta.
  // El backend guarda el mensaje assistant en DB y devuelve {response, tokensUsed, latencyMs}.
  static Future<String> invokeAgent(String conversationId) async {
    final data = await ApiClient.post('/api/conversations/$conversationId/agent') as Map<String, dynamic>;
    return data['response'] as String;
  }

  static Future<Message> sendMessage({
    required String conversationId,
    required String role,
    required String content,
    String? agentType,
  }) async {
    final data = await ApiClient.post(
      '/api/conversations/$conversationId/messages',
      body: {
        'role': role,
        'content': content,
        'agent_type': agentType,
      },
    );
    return Message.fromJson(data as Map<String, dynamic>);
  }

  // simulate: envía un mensaje como si viniera de WhatsApp.
  // El backend crea/reutiliza una conversación, llama al agente y devuelve
  // el conversationId para que el frontend navegue a esa conversación.
  static Future<String> simulate({
    required String message,
    String contactName = 'Cliente de prueba',
  }) async {
    final data = await ApiClient.post(
      '/api/webhook/simulate',
      body: {'message': message, 'contact_name': contactName},
    ) as Map<String, dynamic>;
    return data['conversationId'] as String;
  }
}
