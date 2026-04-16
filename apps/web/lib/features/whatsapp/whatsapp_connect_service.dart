import '../../shared/api/api_client.dart';

class WhatsAppConnection {
  final String  id;
  final String  status;
  final String? phoneNumber;
  final String? phoneNumberId;
  final String? wabaId;

  const WhatsAppConnection({
    required this.id,
    required this.status,
    this.phoneNumber,
    this.phoneNumberId,
    this.wabaId,
  });

  bool get isActive => status == 'active';

  factory WhatsAppConnection.fromJson(Map<String, dynamic> json) {
    return WhatsAppConnection(
      id:            json['id']              as String,
      status:        json['status']          as String,
      phoneNumber:   json['phone_number']    as String?,
      phoneNumberId: json['phone_number_id'] as String?,
      wabaId:        json['waba_id']         as String?,
    );
  }
}

class WhatsAppConnectService {
  static Future<WhatsAppConnection?> getConnection() async {
    final data = await ApiClient.get('/api/whatsapp/connection');
    if (data['connection'] == null) return null;
    return WhatsAppConnection.fromJson(data['connection'] as Map<String, dynamic>);
  }

  static Future<WhatsAppConnection> connect({
    required String code,
    String? wabaId,
    String? phoneNumberId,
  }) async {
    final body = <String, dynamic>{'code': code};
    if (wabaId != null)        body['waba_id']         = wabaId;
    if (phoneNumberId != null) body['phone_number_id'] = phoneNumberId;

    final data = await ApiClient.post('/api/whatsapp/connect', body: body);
    return WhatsAppConnection.fromJson(data['connection'] as Map<String, dynamic>);
  }

  static Future<void> disconnect() async {
    await ApiClient.delete('/api/whatsapp/connection');
  }
}
