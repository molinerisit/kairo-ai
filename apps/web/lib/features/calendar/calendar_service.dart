import '../../shared/api/api_client.dart';

// ── MODELOS ────────────────────────────────────────────────────────────────────

class CalendarEvent {
  final String  id;
  final String  title;
  final String? description;
  final DateTime startsAt;
  final DateTime endsAt;
  final String  status; // scheduled | confirmed | cancelled | completed
  final Map<String, dynamic> contactData;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.contactData,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id:          json['id'] as String,
    title:       json['title'] as String,
    description: json['description'] as String?,
    startsAt:    DateTime.parse(json['starts_at'] as String).toLocal(),
    endsAt:      DateTime.parse(json['ends_at']   as String).toLocal(),
    status:      json['status'] as String,
    contactData: (json['contact_data'] as Map<String, dynamic>?) ?? {},
  );
}

// ── SERVICIO ───────────────────────────────────────────────────────────────────

class CalendarService {
  // Lista los eventos del mes dado (primer → último día)
  static Future<List<CalendarEvent>> listEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    final f = from.toUtc().toIso8601String();
    final t = to.toUtc().toIso8601String();
    final data = await ApiClient.get('/api/calendar?from=${Uri.encodeComponent(f)}&to=${Uri.encodeComponent(t)}') as List<dynamic>;
    return data.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<CalendarEvent> createEvent({
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
    String? contactName,
    String? contactPhone,
  }) async {
    final body = <String, dynamic>{
      'title':     title,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at':   endsAt.toUtc().toIso8601String(),
      'contact_data': {
        if (contactName  != null && contactName.isNotEmpty)  'name':  contactName,
        if (contactPhone != null && contactPhone.isNotEmpty) 'phone': contactPhone,
      },
      'metadata': <String, dynamic>{},
    };
    if (description != null && description.isNotEmpty) body['description'] = description;

    final data = await ApiClient.post('/api/calendar', body: body) as Map<String, dynamic>;
    return CalendarEvent.fromJson(data);
  }

  static Future<CalendarEvent> updateStatus(String id, String status) async {
    final data = await ApiClient.patch('/api/calendar/$id', body: {'status': status}) as Map<String, dynamic>;
    return CalendarEvent.fromJson(data);
  }

  static Future<void> deleteEvent(String id) async {
    await ApiClient.delete('/api/calendar/$id');
  }
}
