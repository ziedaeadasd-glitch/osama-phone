/// =========================================================================
/// نماذج البيانات (Data Models) لتطبيق أسامة فون
/// =========================================================================

/// 1. نموذج المنتج (هواتف، إكسسوارات)
class Product {
  final int id;
  final String category; // 'phones' أو 'accessories'
  final String name;
  final double price;
  final String currency;
  final String description;
  final String imageUrl;
  final String? imageFullUrl;
  final String? createdAt;

  Product({
    required this.id,
    required this.category,
    required this.name,
    required this.price,
    this.currency = 'USD',
    required this.description,
    required this.imageUrl,
    this.imageFullUrl,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      category: json['category'] ?? 'phones',
      name: json['name'] ?? '',
      price: json['price'] != null ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
      currency: json['currency'] ?? 'USD',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      imageFullUrl: json['image_full_url'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'price': price,
      'currency': currency,
      'description': description,
      'image_url': imageUrl,
    };
  }
}

/// 2. نموذج الخدمات (برمجة، صيانة، وأجهزة مبرمجة مع صور)
class ServiceItem {
  final int id;
  final String type; // 'programming' أو 'maintenance'
  final String title;
  final String description;
  final String price;
  final String managerNote;
  final String? imageUrl;
  final String? imageFullUrl;
  final String? createdAt;

  ServiceItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.price,
    this.managerNote = '',
    this.imageUrl,
    this.imageFullUrl,
    this.createdAt,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      type: json['type'] ?? 'programming',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '',
      managerNote: json['manager_note'] ?? '',
      imageUrl: json['image_url'],
      imageFullUrl: json['image_full_url'],
      createdAt: json['created_at'],
    );
  }
}

/// 3. نموذج أسعار الصيرفة والعملات
class ExchangeRate {
  final int id;
  final String currencyName;
  final String currencyCode;
  final double buyRate;
  final double sellRate;
  final String notes;
  final String? updatedAt;

  ExchangeRate({
    required this.id,
    required this.currencyName,
    required this.currencyCode,
    required this.buyRate,
    required this.sellRate,
    this.notes = '',
    this.updatedAt,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      currencyName: json['currency_name'] ?? '',
      currencyCode: json['currency_code'] ?? '',
      buyRate: json['buy_rate'] != null ? double.tryParse(json['buy_rate'].toString()) ?? 0.0 : 0.0,
      sellRate: json['sell_rate'] != null ? double.tryParse(json['sell_rate'].toString()) ?? 0.0 : 0.0,
      notes: json['notes'] ?? '',
      updatedAt: json['updated_at'],
    );
  }
}

/// 4. نموذج إعدادات المتجر العامة
class StoreSettings {
  final String storeName;
  final String phoneNumber;
  final String whatsappNumber;
  final String programmingWhatsapp;
  final String mapsUrl;
  final String programmingManager;
  final String salaryStatus; // 'نعم' أو 'لا'
  final String salaryNotes;

  StoreSettings({
    this.storeName = 'أسامة فون - Osama Phone',
    this.phoneNumber = '07722882273',
    this.whatsappNumber = '+9647722882273',
    this.programmingWhatsapp = '+9647722882273',
    this.mapsUrl = 'https://www.google.com/maps/place/%D8%A7%D8%B3%D8%A7%D9%85%D8%A9+%D9%81%D9%88%D9%86%E2%80%AD/@36.3758306,43.1444241,17z/data=!3m1!4b1!4m6!3m5!1s0x400795005c1f6575:0xaff461d7e686bd2d!8m2!3d36.3758263!4d43.1418492!16s%2Fg%2F11w409hr2y?entry=ttu',
    this.programmingManager = 'زيد إياد',
    this.salaryStatus = 'نعم',
    this.salaryNotes = 'رواتب المتقاعدين والموظفين والرعاية الاجتماعية متوفرة الآن',
  });

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      storeName: json['store_name'] ?? 'أسامة فون - Osama Phone',
      phoneNumber: json['phone_number'] ?? '07722882273',
      whatsappNumber: json['whatsapp_number'] ?? '+9647722882273',
      programmingWhatsapp: json['programming_whatsapp'] ?? '+9647722882273',
      mapsUrl: json['maps_url'] ?? 'https://www.google.com/maps/place/%D8%A7%D8%B3%D8%A7%D9%85%D8%A9+%D9%81%D9%88%D9%86%E2%80%AD/@36.3758306,43.1444241,17z/data=!3m1!4b1!4m6!3m5!1s0x400795005c1f6575:0xaff461d7e686bd2d!8m2!3d36.3758263!4d43.1418492!16s%2Fg%2F11w409hr2y?entry=ttu',
      programmingManager: json['programming_manager'] ?? 'زيد إياد',
      salaryStatus: json['salary_status'] ?? 'نعم',
      salaryNotes: json['salary_notes'] ?? 'رواتب المتقاعدين والموظفين والرعاية الاجتماعية متوفرة الآن',
    );
  }
}
