import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';

/// =========================================================================
/// خدمة الاتصال بالسيرفر المحلي والشبكة (API Service)
/// =========================================================================

class ApiService {
  // رابط السيرفر السحابي العالمي الدائم لجميع الهواتف والزبائن
  static String defaultBaseUrl = 'https://osama-phone-api.onrender.com';

  static const String _prefServerKey = 'custom_server_url';
  static const String _prefTokenKey = 'admin_token';

  /// جلب رابط السيرفر المخزن
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefServerKey) ?? defaultBaseUrl;
  }

  /// تعيين رابط سيرفر جديد (مثلاً آيبي الحاسوب 192.168.x.x عند التشغيل على هاتف حقيقي)
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
    return prefs.getString(_prefTokenKey);
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
    final token = await getAdminToken();
    return token != null && token.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // 1. تسجيل دخول المدير (Admin Login)
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> adminLogin(String password) async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/api/admin/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        await saveAdminToken(data['token']);
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'فشل تسجيل الدخول!'};
      }
    } catch (e) {
      return {'success': false, 'message': 'تعذر الاتصال بالسيرفر: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // 2. المنتجات (Products)
  // ---------------------------------------------------------------------------

  /// جلب قائمة المنتجات مع فلترة بالقسم
  static Future<List<Product>> getProducts({String? category}) async {
    try {
      final baseUrl = await getBaseUrl();
      String endpoint = '$baseUrl/api/products';
      if (category != null && category.isNotEmpty) {
        endpoint += '?category=$category';
      }

      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }

  /// إضافة منتج جديد مع صورة عبر Multer (خاص بالأدمن)
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

      // إرفاق الصورة إن وجدت (Multipart + Base64 Fallback)
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.fields['image_base64'] = base64Encode(bytes);
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      } else if (imageBytes != null) {
        request.fields['image_base64'] = base64Encode(imageBytes);
        request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: imageName ?? 'img_${DateTime.now().millisecondsSinceEpoch}.png'));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'تم إضافة المنتج بنجاح!'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'فشل إضافة المنتج'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ أثناء الإضافة: $e'};
    }
  }

  /// حذف منتج
  static Future<bool> deleteProduct(int id) async {
    try {
      final baseUrl = await getBaseUrl();
      final token = await getAdminToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/products/$id'),
        headers: {'x-admin-token': token ?? ''},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. الخدمات وأسعار الصيرفة والإعدادات
  // ---------------------------------------------------------------------------

  /// جلب خدمات البرمجة أو الصيانة
  static Future<List<ServiceItem>> getServices({String? type}) async {
    try {
      final baseUrl = await getBaseUrl();
      String endpoint = '$baseUrl/api/services';
      if (type != null) endpoint += '?type=$type';

      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((json) => ServiceItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// إضافة خدمة جديدة (برمجة أو صيانة) مع رفع صورة الجهاز للأدمن
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

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.fields['image_base64'] = base64Encode(bytes);
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      } else if (imageBytes != null) {
        request.fields['image_base64'] = base64Encode(imageBytes);
        request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: imageName ?? 'service_${DateTime.now().millisecondsSinceEpoch}.png'));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'تم إضافة الخدمة بنجاح!'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'فشل إضافة الخدمة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ أثناء إضافة الخدمة: $e'};
    }
  }

  /// حذف خدمة
  static Future<bool> deleteService(int id) async {
    try {
      final baseUrl = await getBaseUrl();
      final token = await getAdminToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/services/$id'),
        headers: {'x-admin-token': token ?? ''},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// جلب أسعار الصيرفة
  static Future<List<ExchangeRate>> getExchangeRates() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(Uri.parse('$baseUrl/api/exchange-rates'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        return items.map((json) => ExchangeRate.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// جلب الإعدادات العامة (أرقام التواصل وروابط الخرائط)
  static Future<StoreSettings> getSettings() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(Uri.parse('$baseUrl/api/settings'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StoreSettings.fromJson(data['data'] ?? {});
      }
      return StoreSettings();
    } catch (e) {
      return StoreSettings();
    }
  }

  // ---------------------------------------------------------------------------
  // 4. دوال التفاعل الخارجية (واتساب وخرائط جوجل)
  // ---------------------------------------------------------------------------

  /// فتح محادثة واتساب لشراء منتج أو الاستفسار
  static Future<void> launchWhatsApp({
    required String phone,
    required String message,
  }) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
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
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
