import '../../shared/api/api_client.dart';

// ── MODELOS ────────────────────────────────────────────────────────────────────

class ServiceItem {
  String name;
  double? price;
  ServiceItem({required this.name, this.price});

  factory ServiceItem.fromJson(Map<String, dynamic> j) =>
      ServiceItem(name: j['name'] as String, price: (j['price'] as num?)?.toDouble());

  Map<String, dynamic> toJson() => {
    'name': name,
    if (price != null) 'price': price,
  };
}

class FaqItem {
  String q;
  String a;
  FaqItem({required this.q, required this.a});

  factory FaqItem.fromJson(Map<String, dynamic> j) =>
      FaqItem(q: j['q'] as String, a: j['a'] as String);

  Map<String, dynamic> toJson() => {'q': q, 'a': a};
}

class BusinessProfile {
  final String  id;
  String        name;
  String?       tone;
  String?       description;
  String?       address;
  String?       whatsapp;
  Map<String, String>  hours;
  List<ServiceItem>    services;
  List<FaqItem>        faqs;

  BusinessProfile({
    required this.id,
    required this.name,
    this.tone,
    this.description,
    this.address,
    this.whatsapp,
    required this.hours,
    required this.services,
    required this.faqs,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> j) => BusinessProfile(
    id:          j['id'] as String,
    name:        j['name'] as String? ?? '',
    tone:        j['tone'] as String?,
    description: j['description'] as String?,
    address:     j['address'] as String?,
    whatsapp:    j['whatsapp'] as String?,
    hours:    Map<String, String>.from(j['hours'] as Map? ?? {}),
    services: (j['services'] as List? ?? [])
        .map((e) => ServiceItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    faqs:     (j['faqs'] as List? ?? [])
        .map((e) => FaqItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

// ── SERVICIO ───────────────────────────────────────────────────────────────────

class SettingsService {
  static Future<BusinessProfile> getProfile() async {
    final data = await ApiClient.get('/api/business-profile') as Map<String, dynamic>;
    return BusinessProfile.fromJson(data);
  }

  static Future<BusinessProfile> updateProfile(Map<String, dynamic> body) async {
    final data = await ApiClient.patch('/api/business-profile', body: body) as Map<String, dynamic>;
    return BusinessProfile.fromJson(data);
  }
}
