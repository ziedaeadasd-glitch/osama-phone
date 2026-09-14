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
    this.phoneNumber = '+9647722882273',
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
      phoneNumber: json['phone_number'] ?? '+9647722882273',
      whatsappNumber: json['whatsapp_number'] ?? '+9647722882273',
      programmingWhatsapp: json['programming_whatsapp'] ?? '+9647722882273',
      mapsUrl: json['maps_url'] ?? 'https://www.google.com/maps/place/%D8%A7%D8%B3%D8%A7%D9%85%D8%A9+%D9%81%D9%88%D9%86%E2%80%AD/@36.3758306,43.1444241,17z/data=!3m1!4b1!4m6!3m5!1s0x400795005c1f6575:0xaff461d7e686bd2d!8m2!3d36.3758263!4d43.1418492!16s%2Fg%2F11w409hr2y?entry=ttu',
      programmingManager: json['programming_manager'] ?? 'زيد إياد',
      salaryStatus: json['salary_status'] ?? 'نعم',
      salaryNotes: json['salary_notes'] ?? 'رواتب المتقاعدين والموظفين والرعاية الاجتماعية متوفرة الآن',
    );
  }
}

/// 5. البيانات الافتراضية المدمجة في التطبيق
class DefaultAppData {
  static List<Product> get defaultPhones => [
    Product(
      id: 1,
      category: 'phones',
      name: 'iPhone 15 Pro Max',
      price: 1199.0,
      description: 'ذاكرة 256GB - بطارية 100% - جميع الألوان متوفرة مع ضمان أسامة فون',
      imageUrl: 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800&auto=format&fit=crop&q=80',
    ),
    Product(
      id: 2,
      category: 'phones',
      name: 'Samsung Galaxy S24 Ultra',
      price: 1050.0,
      description: 'ذاكرة 512GB - ذكاء اصطناعي Galaxy AI - قلم S-Pen - كاميرا 200MP',
      imageUrl: 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=800&auto=format&fit=crop&q=80',
    ),
    Product(
      id: 3,
      category: 'phones',
      name: 'iPhone 14 Pro',
      price: 850.0,
      description: 'ذاكرة 128GB - نظافة 100% - ضمان فحص شامل في المحل',
      imageUrl: 'https://images.unsplash.com/photo-1663499482523-1c0c1bae4ce1?w=800&auto=format&fit=crop&q=80',
    ),
    Product(
      id: 4,
      category: 'phones',
      name: 'Xiaomi 14 Ultra',
      price: 920.0,
      description: 'كاميرات Leica احترافية - شحن فائق السرعة 90W - أداء جبار',
      imageUrl: 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=800&auto=format&fit=crop&q=80',
    ),
  ];

  static List<Product> get defaultAccessories => [
    Product(
      id: 101,
      category: 'accessories',
      name: 'شاحن أنكر الأصلي 65W GaN',
      price: 35.0,
      description: 'شاحن سريع يدعم جميع هواتف آيفون وسامسونج واللابتوبات بتقنية IQ3',
      imageUrl: 'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?w=800&auto=format&fit=crop&q=80',
    ),
    Product(
      id: 102,
      category: 'accessories',
      name: 'سماعات AirPods Pro 2 الأصلية',
      price: 210.0,
      description: 'عزل ضوضاء نشط فائق - صوت مكاني - منفذ Type-C - ضمان رسمي',
      imageUrl: 'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=800&auto=format&fit=crop&q=80',
    ),
    Product(
      id: 103,
      category: 'accessories',
      name: 'باور بانك Joyroom 30000mAh',
      price: 28.0,
      description: 'شحن سريع 22.5W - شاشة رقمية لعرض نسبة الشحن - منافذ متعددة',
      imageUrl: 'https://images.unsplash.com/photo-1609592807904-453716a4be74?w=800&auto=format&fit=crop&q=80',
    ),
    Product(
      id: 104,
      category: 'accessories',
      name: 'بكج حماية شاشة وكفر مغناطيسي MagSafe',
      price: 15.0,
      description: 'زجاج مضاد للكسر والخدش مع حماية لعدسات الكاميرا وكفر شفاف مضاد للاصفرار',
      imageUrl: 'https://images.unsplash.com/photo-1601593346740-925612772716?w=800&auto=format&fit=crop&q=80',
    ),
  ];

  static List<ServiceItem> get defaultProgramming => [
    ServiceItem(
      id: 201,
      type: 'programming',
      title: 'تخطي وفك حسابات آيكلود (iCloud Bypass)',
      description: 'خدمة فك وتخطي حسابات iCloud لجميع موديلات الآيفون والآيباد مع تفعيل الشبكة والإشعارات',
      price: 'حسب الموديل',
      managerNote: 'بإدارة: زيد إياد - +9647722882273',
      imageUrl: 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=600&auto=format&fit=crop',
    ),
    ServiceItem(
      id: 202,
      type: 'programming',
      title: 'فك الشفرات الدولية وإصلاح شبكات السيم كارد',
      description: 'فك شفرات الهواتف الأمريكية والأوروبية المقفلة على شبكات AT&T, T-Mobile, Verizon وإصلاح الشبكة',
      price: 'حسب الشبكة',
      managerNote: 'بإدارة: زيد إياد - +9647722882273',
      imageUrl: 'https://images.unsplash.com/photo-1563770660941-20978e870e26?w=600&auto=format&fit=crop',
    ),
    ServiceItem(
      id: 203,
      type: 'programming',
      title: 'تفليش رومات رسمية وتحديث الأنظمة المعلقة',
      description: 'حل مشاكل التعليق على الشعار (Bootloop) وتثبيت أحدث الإصدارات الرسمية لهواتف سامسونج وشاومي وآيفون',
      price: '10,000 د.ع',
      managerNote: 'بإدارة: زيد إياد - +9647722882273',
      imageUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600&auto=format&fit=crop',
    ),
    ServiceItem(
      id: 204,
      type: 'programming',
      title: 'حملات إعلانات وترويج ممول لجميع المنصات',
      description: 'إنشاء وإدارة حملات إعلانية ممولة باحترافية على فيسبوك، إنستغرام، سناب شات، تيك توك، ويوتيوب لزيادة المبيعات والمتابعين',
      price: 'تبدأ من \$10',
      managerNote: 'بإدارة: زيد إياد - +9647722882273',
      imageUrl: 'https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=600&auto=format&fit=crop',
    ),
  ];

  static List<ServiceItem> get defaultMaintenance => [
    ServiceItem(
      id: 301,
      type: 'maintenance',
      title: 'تبديل شاشات أصلية (OLED / LCD)',
      description: 'تبديل شاشات وكالة لجميع أنواع الآيفون والسامسونج والشاومي مع فحص التاتش ونقل TrueTone',
      price: 'فحص مجاني',
      imageUrl: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600&auto=format&fit=crop',
    ),
    ServiceItem(
      id: 302,
      type: 'maintenance',
      title: 'تبديل بطاريات أصلية مع ضمان',
      description: 'بطاريات أصلية عالية الجودة مع إظهار نسبة صحة البطارية وضمان 6 أشهر ضد الانتفاخ أو الهبوط السريع',
      price: 'حسب الموديل',
      imageUrl: 'https://images.unsplash.com/photo-1619725002198-6a689b72f41d?w=600&auto=format&fit=crop',
    ),
    ServiceItem(
      id: 303,
      type: 'maintenance',
      title: 'تصليح أعطال البورد والمعالجات والآيسيات',
      description: 'صيانة احترافية بالمايكروسكوب لأعطال الشحن، الإشارة، الباور، والتعرض للماء مع قطع غيار أصلية',
      price: 'حسب الفحص',
      imageUrl: 'https://images.unsplash.com/photo-1597740985671-2a8a3b80502e?w=600&auto=format&fit=crop',
    ),
  ];

  static List<ServiceItem> get defaultFinancial => [
    ServiceItem(
      id: 401,
      type: 'financial',
      title: 'صرف رواتب بطاقة كي كارد (Qi Card)',
      description: 'صرف فوري لرواتب المتقاعدين والموظفين وشبكة الحماية الاجتماعية مع كشف حساب مجاني',
      price: 'عمولة رسمية',
      managerNote: 'متوفر الصرف الآن',
      imageUrl: 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=600&auto=format&fit=crop',
    ),
    ServiceItem(
      id: 402,
      type: 'financial',
      title: 'محفظة زين كاش (ZainCash)',
      description: 'إيداع وسحب فوري، تحويل أموال لكافة المحافظات، وتعبئة رصيد ودفع الفواتير',
      price: 'فوري وسريع',
      managerNote: 'وكيل معتمد',
      imageUrl: 'https://images.unsplash.com/photo-1563013544-824ae1b704d3?w=600&auto=format&fit=crop',
    ),
    ServiceItem(
      id: 403,
      type: 'financial',
      title: 'محفظة آسيا باي (AsiaPay)',
      description: 'خدمات الإيداع والسحب والتحويل المالي المعتمد لجميع مشتركي آسيا حوالة وآسيا باي',
      price: 'فوري وسريع',
      managerNote: 'وكيل معتمد',
      imageUrl: 'https://images.unsplash.com/photo-1556742049-0a67e55722c6?w=600&auto=format&fit=crop',
    ),
  ];
}

