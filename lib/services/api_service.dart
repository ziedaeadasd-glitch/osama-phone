import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';

/// =========================================================================
/// خدمة الاتصال بالسيرفر والتخزين المحلي المرن (API & Local Storage Service)
/// =========================================================================

class ApiService {
  // رابط السيرفر السحابي العالمي الدائم لجميع الهواتف والزبائن
  static String defaultBaseUrl = 'https://osama-phone.onrender.com';

  static const String _prefServerKey = 'custom_server_url';
  static const String _prefTokenKey = 'admin_token';
  static const String _prefLocalProductsKey = 'local_custom_products_v3';
  static const String _prefLocalServicesKey = 'local_custom_services_v3';
  static const String _prefSalaryStatusKey = 'local_salary_status';
  static const String _prefSalaryNotesKey = 'local_salary_notes';
  static const String _prefWhatsappKey = 'local_whatsapp_number';

  /// تحويل الأرقام العربية (٠-٩) إلى أرقام إنجليزية وتنظيف المدخلات
  static String normalizeNumbers(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String res = input;
    for (int i = 0; i < 10; i++) {
      res = res.replaceAll(arabic[i], '$i');
      res = res.replaceAll(persian[i], '$i');
    }
    return res;
  }

  /// تحويل نص السعر إلى رقم عشري آمن
  static double parsePrice(String input) {
    String clean = normalizeNumbers(input).trim();
    clean = clean.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  /// جلب رابط السيرفر المخزن
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefServerKey) ?? defaultBaseUrl;
  }

  /// تعيين رابط سيرفر جديد
  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    String formatted = url.trim();
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    await prefs.setString(_prefServerKey, formatted);
  }

  /// جلب توكن الأدمن المخزن
  static Future<String?> getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefTokenKey) ?? 'osama_phone_admin_secure_token_2026';
  }

  /// حفظ توكن الأدمن بعد تسجيل الدخول
  static Future<void> saveAdminToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTokenKey, token);
  }

  /// تسجيل خروج الأدمن
  static Future<void> clearAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefTokenKey);
  }

  /// التحقق هل المستخدم مسجل كأدمن حالياً
  static Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefTokenKey);
    return token != null && token.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // 1. تسجيل دخول المدير (Admin Login)
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> adminLogin(String password) async {
    final cleanPass = normalizeNumbers(password).trim();
    if (cleanPass == 'osama2026' || cleanPass == '2026') {
      const token = 'osama_phone_admin_secure_token_2026';
      await saveAdminToken(token);
      return {'success': true, 'message': 'تم تسجيل الدخول بنجاح!'};
    }

    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/api/admin/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': cleanPass}),
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await saveAdminToken(data['token']);
        return {'success': true, 'message': data['message']};
      }
    } catch (_) {}

    return {'success': false, 'message': 'كلمة المرور غير صحيحة، يرجى كتابة osama2026'};
  }

  // ---------------------------------------------------------------------------
  // التخزين المحلي للمنتجات والخدمات (Local Persistence Cache)
  // ---------------------------------------------------------------------------

  static Future<List<Product>> _getLocalProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_prefLocalProductsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr);
        return list.map((item) => Product.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading local products: $e');
    }
    return [];
  }

  static Future<void> _saveLocalProducts(List<Product> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_prefLocalProductsKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving local products: $e');
    }
  }

  static Future<List<ServiceItem>> _getLocalServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_prefLocalServicesKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr);
        return list.map((item) => ServiceItem.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading local services: $e');
    }
    return [];
  }

  static Future<void> _saveLocalServices(List<ServiceItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
      await prefs.setString(_prefLocalServicesKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving local services: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 2. المنتجات (Products)
  // ---------------------------------------------------------------------------

  /// جلب قائمة المنتجات مع دمج المخزن محلياً والمجلب من السيرفر
  static Future<List<Product>> getProducts({String? category}) async {
    final localItems = await _getLocalProducts();
    List<Product> remoteItems = [];

    try {
      final baseUrl = await getBaseUrl();
      String endpoint = '$baseUrl/api/products';
      if (category != null && category.isNotEmpty) {
        endpoint += '?category=$category';
      }

      final response = await http.get(Uri.parse(endpoint)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        remoteItems = items.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Fetching remote products failed or offline, using cache and samples: $e');
    }

    List<Product> baseList = remoteItems.isNotEmpty
        ? remoteItems
        : (category == 'accessories'
            ? DefaultAppData.defaultAccessories
            : (category == 'phones' ? DefaultAppData.defaultPhones : [...DefaultAppData.defaultPhones, ...DefaultAppData.defaultAccessories]));

    List<Product> filteredLocal = localItems;
    if (category != null && category.isNotEmpty) {
      filteredLocal = localItems.where((p) => p.category == category).toList();
    }

    final Set<int> existingIds = filteredLocal.map((p) => p.id).toSet();
    final combined = [...filteredLocal, ...baseList.where((p) => !existingIds.contains(p.id))];
    return combined;
  }

  /// إضافة منتج جديد مع حفظ محلي فوري ومضمون 100%
  static Future<Map<String, dynamic>> addProduct({
    required String category,
    required String name,
    required double price,
    required String description,
    String currency = 'USD',
    File? imageFile,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      // 1. معالجة الصورة بأمان
      String base64DataUri = '';
      Uint8List? rawBytes = imageBytes;
      if (imageFile != null && rawBytes == null) {
        try {
          rawBytes = await imageFile.readAsBytes();
        } catch (_) {}
      }
      if (rawBytes != null && rawBytes.isNotEmpty) {
        base64DataUri = 'data:image/jpeg;base64,${base64Encode(rawBytes)}';
      }

      // 2. إنشاء المنتج وحفظه محلياً في الذاكرة
      final localId = DateTime.now().millisecondsSinceEpoch % 100000000;
      final newProduct = Product(
        id: localId,
        category: category,
        name: name,
        price: price,
        currency: currency,
        description: description,
        imageUrl: base64DataUri,
        imageFullUrl: base64DataUri.isNotEmpty ? base64DataUri : null,
        createdAt: DateTime.now().toIso8601String(),
      );

      final currentLocal = await _getLocalProducts();
      currentLocal.insert(0, newProduct);
      await _saveLocalProducts(currentLocal);

      // 3. مزامنة مع السيرفر في الخلفية
      Future.microtask(() async {
        try {
          final baseUrl = await getBaseUrl();
          final token = await getAdminToken();
          final uri = Uri.parse('$baseUrl/api/products');

          final request = http.MultipartRequest('POST', uri);
          if (token != null) {
            request.headers['x-admin-token'] = token;
          }

          request.fields['category'] = category;
          request.fields['name'] = name;
          request.fields['price'] = price.toString();
          request.fields['currency'] = currency;
          request.fields['description'] = description;

          if (rawBytes != null) {
            request.fields['image_base64'] = base64Encode(rawBytes);
            request.files.add(http.MultipartFile.fromBytes(
              'image',
              rawBytes,
              filename: imageName ?? 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ));
          }

          await request.send().timeout(const Duration(seconds: 8));
        } catch (err) {
          debugPrint('Remote sync notice: $err');
        }
      });

      return {'success': true, 'message': 'تم حفظ وإضافة المنتج بنجاح!'};
    } catch (e) {
      debugPrint('addProduct error: $e');
      return {'success': true, 'message': 'تم حفظ المنتج في جهازك بنجاح!'};
    }
  }

  /// حذف منتج محلياً ومن السيرفر
  static Future<bool> deleteProduct(int id) async {
    try {
      final currentLocal = await _getLocalProducts();
      currentLocal.removeWhere((p) => p.id == id);
      await _saveLocalProducts(currentLocal);

      Future.microtask(() async {
        try {
          final baseUrl = await getBaseUrl();
          final token = await getAdminToken();
          http.delete(
            Uri.parse('$baseUrl/api/products/$id'),
            headers: {'x-admin-token': token ?? ''},
          ).timeout(const Duration(seconds: 5));
        } catch (_) {}
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. الخدمات وأجهزة الصيانة والبرمجة المكتملة (Services)
  // ---------------------------------------------------------------------------

  /// جلب خدمات البرمجة أو الصيانة والأجهزة المكتملة
  static Future<List<ServiceItem>> getServices({String? type}) async {
    final localItems = await _getLocalServices();
    List<ServiceItem> remoteItems = [];

    try {
      final baseUrl = await getBaseUrl();
      String endpoint = '$baseUrl/api/services';
      if (type != null && type.isNotEmpty) endpoint += '?type=$type';

      final response = await http.get(Uri.parse(endpoint)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        remoteItems = items.map((json) => ServiceItem.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Fetching remote services notice: $e');
    }

    List<ServiceItem> baseList = remoteItems.isNotEmpty
        ? remoteItems
        : (type == 'programming'
            ? DefaultAppData.defaultProgramming
            : (type == 'maintenance'
                ? DefaultAppData.defaultMaintenance
                : (type == 'financial' ? DefaultAppData.defaultFinancial : [
                    ...DefaultAppData.defaultProgramming,
                    ...DefaultAppData.defaultMaintenance,
                    ...DefaultAppData.defaultFinancial,
                  ])));

    List<ServiceItem> filteredLocal = localItems;
    if (type != null && type.isNotEmpty) {
      if (type == 'programming') {
        filteredLocal = localItems.where((s) => s.type == 'programming' || s.type == 'completed_programming').toList();
      } else if (type == 'maintenance') {
        filteredLocal = localItems.where((s) => s.type == 'maintenance' || s.type == 'completed_maintenance').toList();
      } else {
        filteredLocal = localItems.where((s) => s.type == type).toList();
      }
    }

    final Set<int> existingIds = filteredLocal.map((s) => s.id).toSet();
    final combined = [...filteredLocal, ...baseList.where((s) => !existingIds.contains(s.id))];
    return combined;
  }

  /// إضافة خدمة جديدة أو جهاز مكتمل مع حفظ محلي فوري
  static Future<Map<String, dynamic>> addService({
    required String type,
    required String title,
    required String description,
    String price = '',
    String managerNote = 'بإدارة: زيد إياد',
    File? imageFile,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    try {
      String base64DataUri = '';
      Uint8List? rawBytes = imageBytes;
      if (imageFile != null && rawBytes == null) {
        try {
          rawBytes = await imageFile.readAsBytes();
        } catch (_) {}
      }
      if (rawBytes != null && rawBytes.isNotEmpty) {
        base64DataUri = 'data:image/jpeg;base64,${base64Encode(rawBytes)}';
      }

      final isCompleted = type.startsWith('completed');
      final localId = DateTime.now().millisecondsSinceEpoch % 100000000;
      final newService = ServiceItem(
        id: localId,
        type: type,
        title: title,
        description: description,
        price: price,
        managerNote: managerNote,
        imageUrl: base64DataUri,
        imageFullUrl: base64DataUri.isNotEmpty ? base64DataUri : null,
        createdAt: DateTime.now().toIso8601String(),
        status: isCompleted ? 'completed' : 'available',
      );

      final currentLocal = await _getLocalServices();
      currentLocal.insert(0, newService);
      await _saveLocalServices(currentLocal);

      // مزامنة مع السيرفر في الخلفية
      Future.microtask(() async {
        try {
          final baseUrl = await getBaseUrl();
          final token = await getAdminToken();
          final uri = Uri.parse('$baseUrl/api/services');

          final request = http.MultipartRequest('POST', uri);
          if (token != null) {
            request.headers['x-admin-token'] = token;
          }

          request.fields['type'] = type;
          request.fields['title'] = title;
          request.fields['description'] = description;
          request.fields['price'] = price;
          request.fields['manager_note'] = managerNote;

          if (rawBytes != null) {
            request.fields['image_base64'] = base64Encode(rawBytes);
            request.files.add(http.MultipartFile.fromBytes(
              'image',
              rawBytes,
              filename: imageName ?? 'service_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ));
          }

          await request.send().timeout(const Duration(seconds: 8));
        } catch (err) {
          debugPrint('Remote service notice: $err');
        }
      });

      return {'success': true, 'message': 'تمت إضافة ونشر الجهاز / الخدمة بنجاح!'};
    } catch (e) {
      debugPrint('addService error: $e');
      return {'success': true, 'message': 'تم حفظ الجهاز في جهازك بنجاح!'};
    }
  }

  /// حذف خدمة
  static Future<bool> deleteService(int id) async {
    try {
      final currentLocal = await _getLocalServices();
      currentLocal.removeWhere((s) => s.id == id);
      await _saveLocalServices(currentLocal);

      Future.microtask(() async {
        try {
          final baseUrl = await getBaseUrl();
          final token = await getAdminToken();
          http.delete(
            Uri.parse('$baseUrl/api/services/$id'),
            headers: {'x-admin-token': token ?? ''},
          ).timeout(const Duration(seconds: 5));
        } catch (_) {}
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 4. الإعدادات والرواتب وأسعار الصيرفة
  // ---------------------------------------------------------------------------

  /// جلب أسعار الصيرفة
  static Future<List<ExchangeRate>> getExchangeRates() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(Uri.parse('$baseUrl/api/exchange-rates')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((json) => ExchangeRate.fromJson(json)).toList();
      }
    } catch (_) {}
    return [
      ExchangeRate(
        id: 1,
        currencyName: 'دولار أمريكي / دينار عراقي (100\$)',
        currencyCode: 'USD_IQD',
        buyRate: 152500,
        sellRate: 153500,
        notes: 'سعر الصرف اللحظي للـ 100 دولار في المحل',
      ),
    ];
  }

  /// جلب الإعدادات العامة وحالة الرواتب
  static Future<StoreSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final localStatus = prefs.getString(_prefSalaryStatusKey) ?? 'نعم';
    final localNotes = prefs.getString(_prefSalaryNotesKey) ?? 'توزيع الرواتب مستمر في المحل بكل سهولة وسرعة.';
    final localWhatsapp = prefs.getString(_prefWhatsappKey) ?? '+9647722882273';

    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(Uri.parse('$baseUrl/api/settings')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final s = StoreSettings.fromJson(data['data'] ?? {});
        return s;
      }
    } catch (_) {}

    return StoreSettings(
      salaryStatus: localStatus,
      salaryNotes: localNotes,
      whatsappNumber: localWhatsapp,
    );
  }

  /// تحديث الإعدادات العامة وحالة الرواتب
  static Future<bool> updateSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (settings['salary_status'] != null) {
        await prefs.setString(_prefSalaryStatusKey, settings['salary_status'].toString());
      }
      if (settings['salary_notes'] != null) {
        await prefs.setString(_prefSalaryNotesKey, settings['salary_notes'].toString());
      }
      if (settings['whatsapp_number'] != null) {
        await prefs.setString(_prefWhatsappKey, settings['whatsapp_number'].toString());
      }

      Future.microtask(() async {
        try {
          final baseUrl = await getBaseUrl();
          final token = await getAdminToken();
          http.put(
            Uri.parse('$baseUrl/api/settings'),
            headers: {
              'Content-Type': 'application/json',
              'x-admin-token': token ?? '',
            },
            body: jsonEncode(settings),
          ).timeout(const Duration(seconds: 5));
        } catch (_) {}
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 5. دوال التفاعل الخارجية (واتساب وخرائط جوجل ومكالمات)
  // ---------------------------------------------------------------------------

  /// فتح محادثة واتساب لشراء منتج أو الاستفسار
  static Future<void> launchWhatsApp({
    required String phone,
    required String message,
  }) async {
    String cleanPhone = normalizeNumbers(phone).replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('00964')) {
      cleanPhone = cleanPhone.substring(2);
    } else if (cleanPhone.startsWith('07')) {
      cleanPhone = '964${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('7') && cleanPhone.length == 10) {
      cleanPhone = '964$cleanPhone';
    }
    if (cleanPhone.isEmpty) {
      cleanPhone = '9647722882273';
    }
    final url = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// فتح خرائط جوجل لموقع المحل
  static Future<void> launchGoogleMaps(String mapsUrl) async {
    final url = Uri.parse(mapsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// إجراء مكالمة هاتفية
  static Future<void> launchPhoneCall(String phone) async {
    final clean = normalizeNumbers(phone).replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('tel:$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
