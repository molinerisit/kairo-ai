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

  factory WhatsAppConnection.fromJson(Map<String, dynamic> json) => WhatsAppConnection(
    id:            json['id']              as String,
    status:        json['status']          as String,
    phoneNumber:   json['phone_number']    as String?,
    phoneNumberId: json['phone_number_id'] as String?,
    wabaId:        json['waba_id']         as String?,
  );
}

class PhoneNumberOption {
  final String phoneNumberId;
  final String displayPhone;
  final String verifiedName;
  final String wabaId;
  final String wabaName;

  const PhoneNumberOption({
    required this.phoneNumberId,
    required this.displayPhone,
    required this.verifiedName,
    required this.wabaId,
    required this.wabaName,
  });

  factory PhoneNumberOption.fromJson(Map<String, dynamic> json) => PhoneNumberOption(
    phoneNumberId: json['phone_number_id']      as String,
    displayPhone:  json['display_phone_number'] as String,
    verifiedName:  json['verified_name']        as String,
    wabaId:        json['waba_id']              as String,
    wabaName:      json['waba_name']            as String,
  );
}

class WhatsAppConnectService {
  static Future<WhatsAppConnection?> getConnection() async {
    final data = await ApiClient.get('/api/whatsapp/connection');
    if (data['connection'] == null) return null;
    return WhatsAppConnection.fromJson(data['connection'] as Map<String, dynamic>);
  }

  static Future<List<PhoneNumberOption>> getAccounts(String accessToken) async {
    final data = await ApiClient.get('/api/whatsapp/accounts?access_token=$accessToken');
    final list = data['accounts'] as List<dynamic>;
    return list.map((e) => PhoneNumberOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<WhatsAppConnection> connect({
    required String accessToken,
    required String wabaId,
    required String phoneNumberId,
  }) async {
    final data = await ApiClient.post('/api/whatsapp/connect', body: {
      'access_token':    accessToken,
      'waba_id':         wabaId,
      'phone_number_id': phoneNumberId,
    });
    return WhatsAppConnection.fromJson(data['connection'] as Map<String, dynamic>);
  }

  static Future<void> disconnect() async {
    await ApiClient.delete('/api/whatsapp/connection');
  }
}
