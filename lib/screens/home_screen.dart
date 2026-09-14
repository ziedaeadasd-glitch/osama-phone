import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../widgets/adaptive_image.dart';
import 'admin_login_screen.dart';
import 'admin_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StoreSettings _settings = StoreSettings();
  bool _isLoading = true;

  // قوائم البيانات مهيأة مسبقاً بالبيانات الكاملة للمتجر
  List<Product> _phones = DefaultAppData.defaultPhones;
  List<Product> _accessories = DefaultAppData.defaultAccessories;
  List<ServiceItem> _programmingServices = DefaultAppData.defaultProgramming;
  List<ServiceItem> _maintenanceServices = DefaultAppData.defaultMaintenance;
  List<ServiceItem> _financialServices = DefaultAppData.defaultFinancial;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _isLoading = false;
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// تحميل وتحديث البيانات من السيرفر العالمي
  Future<void> _loadAllData() async {
    try {
      final results = await Future.wait([
        ApiService.getSettings(),
        ApiService.getProducts(category: 'phones'),
        ApiService.getProducts(category: 'accessories'),
        ApiService.getServices(type: 'programming'),
        ApiService.getServices(type: 'maintenance'),
        ApiService.getServices(type: 'financial'),
      ]);

      if (!mounted) return;
      setState(() {
        final newSettings = results[0] as StoreSettings;
        final newPhones = results[1] as List<Product>;
        final newAccessories = results[2] as List<Product>;
        final newProgramming = results[3] as List<ServiceItem>;
        final newMaintenance = results[4] as List<ServiceItem>;
        final newFinancial = results[5] as List<ServiceItem>;

        _settings = newSettings;
        if (newPhones.isNotEmpty) _phones = newPhones;
        if (newAccessories.isNotEmpty) _accessories = newAccessories;
        if (newProgramming.isNotEmpty) _programmingServices = newProgramming;
        if (newMaintenance.isNotEmpty) _maintenanceServices = newMaintenance;
        if (newFinancial.isNotEmpty) _financialServices = newFinancial;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// حوار تعديل رابط السيرفر العالمي / المحلي
  void _showServerConfigDialog() async {
    final currentUrl = await ApiService.getBaseUrl();
    final controller = TextEditingController(text: currentUrl);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF161F30),
          title: Row(
            children: [
              const Icon(Icons.cloud_sync, color: Color(0xFF0EA5E9)),
              const SizedBox(width: 8),
              Text(
                'ربط السيرفر العالمي / المحلي',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر السيرفر أو أدخل الرابط السحابي للاتصال ومزامنة الصور والبيانات:',
                style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),
              // أزرار الاختيار السريع
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.language, size: 16),
                      label: Text('سيرفر عالمي', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setDlgState(() {
                          controller.text = 'https://osama-phone-api.onrender.com';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.wifi, size: 16),
                      label: Text('سيرفر محلي', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setDlgState(() {
                          controller.text = 'http://10.0.2.2:10000';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0B0F19),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.link, color: Color(0xFF0EA5E9)),
                  hintText: 'https://osama-phone-api.onrender.com',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check, size: 16),
              label: Text('حفظ واتصال', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              onPressed: () async {
                await ApiService.setBaseUrl(controller.text);
                if (!mounted) return;
                Navigator.pop(ctx);
                _loadAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حفظ رابط السيرفر وجارٍ مزامنة البيانات والمنتجات...', style: GoogleFonts.cairo()),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// فحص حالة الأدمن والتوجيه
  void _handleAdminClick() async {
    final isAdmin = await ApiService.isAdminLoggedIn();
    if (!mounted) return;
    if (isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      ).then((_) => _loadAllData());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      ).then((_) => _loadAllData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo.png',
                height: 34,
                width: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.phone_android, color: Color(0xFF0EA5E9), size: 24),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'أسامة فون',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'إعدادات السيرفر',
            icon: const Icon(Icons.wifi, color: Color(0xFF0EA5E9)),
            onPressed: _showServerConfigDialog,
          ),
          IconButton(
            tooltip: 'لوحة تحكم المدير',
            icon: const Icon(Icons.admin_panel_settings, color: Color(0xFF10B981)),
            onPressed: _handleAdminClick,
          ),
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadAllData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: const Color(0xFF0EA5E9),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF0EA5E9),
          indicatorWeight: 3,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.smartphone), text: 'موبايلات'),
            Tab(icon: Icon(Icons.headphones), text: 'إكسسوارات'),
            Tab(icon: Icon(Icons.code), text: 'برمجة وترويج'),
            Tab(icon: Icon(Icons.build), text: 'صيانة'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'تحويلات ورواتب'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0EA5E9)),
                  SizedBox(height: 16),
                  Text('جارٍ الاتصال بالسيرفر المحلي وتحميل البيانات...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAllData,
              color: const Color(0xFF0EA5E9),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductsGrid(_phones, 'phones'),
                  _buildProductsGrid(_accessories, 'accessories'),
                  _buildProgrammingSection(),
                  _buildMaintenanceSection(),
                  _buildFinancialAndSalarySection(),
                ],
              ),
            ),
      // الشريط الثابت في الأسفل مع زر الموقع والواتساب المباشر
      bottomNavigationBar: _buildFixedBottomBar(),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. شبكة المنتجات (موبايلات / إكسسوارات)
  // ---------------------------------------------------------------------------
  Widget _buildProductsGrid(List<Product> products, String category) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category == 'phones' ? Icons.phone_android : Icons.headphones,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد منتجات معروضة حالياً في هذا القسم',
              style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        final displayImg = (item.imageFullUrl != null && item.imageFullUrl!.isNotEmpty)
            ? item.imageFullUrl!
            : (item.imageUrl.isNotEmpty ? item.imageUrl : null);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة المنتج
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF0F172A),
                  child: AdaptiveImageWidget(
                    imageUrl: displayImg,
                    placeholder: _buildImagePlaceholder(),
                  ),
                ),
              ),
              // تفاصيل المنتج
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // السعر
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.price} \$',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // زر الطلب عبر واتساب
                          SizedBox(
                            width: double.infinity,
                            height: 34,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.chat, size: 16),
                              label: Text('طلب بالواتساب', style: GoogleFonts.cairo(fontSize: 11)),
                              onPressed: () {
                                final msg = 'مرحباً أسامة فون، أرغب بشراء المنتج:\n'
                                    '📌 الاسم: ${item.name}\n'
                                    '💰 السعر: ${item.price} \$\n'
                                    'هل المنتج متوفر لديكم؟';
                                ApiService.launchWhatsApp(phone: '+9647722882273', message: msg);
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, color: Colors.white24, size: 40),
          const SizedBox(height: 4),
          Text('أسامة فون', style: GoogleFonts.cairo(fontSize: 10, color: Colors.white24)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. قسم البرمجة والترويج (زيد إياد - مانشيت متحرك + إعلانات المنصات)
  // ---------------------------------------------------------------------------
  Widget _buildProgrammingSection() {
    final completedDevices = _programmingServices.where((s) => s.status == 'completed' || s.type == 'completed_programming').toList();
    final standardServices = _programmingServices.where((s) => s.status != 'completed' && s.type != 'completed_programming').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
      children: [
        // 1. مانشيت متحرك
        _buildMarqueeBanner(),
        const SizedBox(height: 14),

        // 2. بانر الإدارة البارز
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0369A1), Color(0xFF0F172A)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.terminal, color: Color(0xFF38BDF8), size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'قسم السوفتوير والبرمجة والترويج',
                          style: GoogleFonts.cairo(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'بإدارة: زيد إياد',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFDE047), // أصفر فخم
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () {
                  ApiService.launchWhatsApp(
                    phone: '+9647722882273',
                    message: 'مرحباً أستاذ زيد إياد، أود الاستفسار وطلب خدمات البرمجة أو الترويج الممول.',
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF25D366).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'واتساب مباشر لزيد إياد: +9647722882273',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF25D366),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. قسم الأجهزة التي تم اكتمالها في البرمجة
        if (completedDevices.isNotEmpty) ...[
          _buildCompletedHeader(
            title: '📱 الأجهزة التي تم اكتمال برمجتها وجاهزة للاستلام:',
            count: completedDevices.length,
            badgeColor: const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          ...completedDevices.map((device) => _buildCompletedDeviceCard(device, isProgramming: true)),
          const SizedBox(height: 22),
        ],

        // 4. شبكة خدمات الترويج على منصات التواصل الاجتماعي
        _buildSocialAdsSection(),
        const SizedBox(height: 22),

        // 5. خدمات السوفتوير وتخطي الآيكلود والأجهزة المبرمجة
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'خدمات السوفتوير والأجهزة المبرمجة:',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            Text(
              '${standardServices.length} خدمة',
              style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF38BDF8)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...standardServices.map((service) => _buildServiceCard(service, isProgramming: true)),
      ],
    );
  }

  /// قسم الترويج على المنصات (فيسبوك، إنستا، سناب، يوتيوب، تيك توك)
  Widget _buildSocialAdsSection() {
    final platforms = [
      {
        'name': 'فيسبوك (Facebook Ads)',
        'desc': 'ترويج صفحات، زيادة المبيعات، واستهداف دقيق للمناطق والمحافظات',
        'icon': Icons.facebook,
        'color': const Color(0xFF1877F2),
      },
      {
        'name': 'إنستغرام (Instagram Ads)',
        'desc': 'ترويج ريلز وبوستات، زيادة متابعين حقيقيين، وبناء هوية تجارية قوية',
        'icon': Icons.camera_alt,
        'color': const Color(0xFFE1306C),
      },
      {
        'name': 'سناب شات (Snapchat Ads)',
        'desc': 'حملات إعلانية وفلاتر مخصصة لوصول سريع جداً للجمهور والشباب',
        'icon': Icons.chat_bubble,
        'color': const Color(0xFFF59E0B),
      },
      {
        'name': 'تيك توك (TikTok Ads)',
        'desc': 'ترويج مقاطع الفيديو وحسابات تجارية لآلاف المشاهدات والتفاعل',
        'icon': Icons.music_note,
        'color': const Color(0xFF00F2FE),
      },
      {
        'name': 'يوتيوب (YouTube Ads)',
        'desc': 'إعلانات فيديو تسبق المقاطع وزيادة مشاهدات واشتراكات القنوات',
        'icon': Icons.play_circle_filled,
        'color': const Color(0xFFEF4444),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.campaign, color: Color(0xFFFDE047), size: 24),
            const SizedBox(width: 8),
            Text(
              'الترويج والإعلانات الممولة (Social Media Ads):',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...platforms.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: (p['color'] as Color).withOpacity(0.3)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (p['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(p['icon'] as IconData, color: p['color'] as Color, size: 26),
                ),
                title: Text(
                  p['name'] as String,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                subtitle: Text(
                  p['desc'] as String,
                  style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF94A3B8)),
                ),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  icon: const Icon(Icons.chat, size: 14),
                  label: Text('طلب ترويج', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final msg = 'مرحباً أستاذ زيد إياد، أود عمل حملة ترويجية على منصة:\n'
                        '📢 المنصة: ${p['name']}\n'
                        'هل يمكن معرفة الباقات والتفاصيل؟';
                    ApiService.launchWhatsApp(phone: '+9647722882273', message: msg);
                  },
                ),
              ),
            )),
      ],
    );
  }

  /// ويدجت المانشيت الإخباري المتحرك
  Widget _buildMarqueeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, size: 15, color: Colors.black),
                const SizedBox(width: 2),
                Text(
                  'شريط الأخبار',
                  style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MarqueeTickerWidget(
              text: '⚡ بأدارة زيد اياد كل ماتحتاجه ⚡ تخطي حسابات آيكلود ⚡ فك شفرات دولية ⚡ رومات وسوفتوير ⚡ ترويج ممول فيسبوك وإنستغرام وسناب وتيك توك ويوتيوب ⚡ واتساب: +9647722882273 ⚡ بأدارة زيد اياد كل ماتحتاجه ⚡',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFDE047),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. قسم الصيانة (Maintenance Section)
  // ---------------------------------------------------------------------------
  Widget _buildMaintenanceSection() {
    final completedDevices = _maintenanceServices.where((s) => s.status == 'completed' || s.type == 'completed_maintenance').toList();
    final standardServices = _maintenanceServices.where((s) => s.status != 'completed' && s.type != 'completed_maintenance').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF0F172A)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF34D399), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.handyman, color: Colors.white, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مركز صيانة أسامة فون المعتمد',
                      style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'تبديل شاشات، صيانة بورد، تغيير بطاريات أصلية بضمان',
                      style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFFD1FAE5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // قسم الأجهزة المكتملة في الصيانة
        if (completedDevices.isNotEmpty) ...[
          _buildCompletedHeader(
            title: '🔧 الأجهزة التي تم اكتمال صيانتها وجاهزة للاستلام:',
            count: completedDevices.length,
            badgeColor: const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          ...completedDevices.map((device) => _buildCompletedDeviceCard(device, isProgramming: false)),
          const SizedBox(height: 22),
        ],

        Text(
          'خدمات الصيانة السريعة وتصليح الأعطال:',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
        ),
        const SizedBox(height: 10),
        ...standardServices.map((service) => _buildServiceCard(service, isProgramming: false)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. قسم التحويلات والرواتب (زين كاش، كي كارد، آسيا بي، وحالة الرواتب نعم/لا)
  // ---------------------------------------------------------------------------
  Widget _buildFinancialAndSalarySection() {
    final isSalaryAvailable = _settings.salaryStatus == 'نعم';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // 1. بطاقة حالة توزيع الرواتب (نعم / لا)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF161F30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSalaryAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSalaryAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: isSalaryAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'حالة توزيع الرواتب اليوم:',
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSalaryAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isSalaryAvailable ? 'متوفرة الآن (نعم ✅)' : 'غير متوفرة (لا ❌)',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _settings.salaryNotes.isNotEmpty
                    ? _settings.salaryNotes
                    : (isSalaryAvailable
                        ? 'توزيع رواتب المتقاعدين والموظفين والرعاية الاجتماعية مستمر في المحل.'
                        : 'عذراً، توزيع الرواتب غير متاح حالياً. سيتم الإعلان فور توفرها.'),
                style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. بطاقات الخدمات المالية (زين كاش، كي كارد، آسيا بي)
        Text(
          'خدمات السحب والتحويل المالي المعتمدة:',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 12),

        // كرت زين كاش
        _buildFinancialCard(
          title: 'سحب وإيداع فلوس - زين كاش (ZainCash)',
          desc: 'سحب كاش فوري وإيداع بمحفظة زين كاش لجميع الخطوط بأقل عمولة.',
          icon: Icons.phone_android,
          badgeColor: const Color(0xFFEC008C), // لون زين كاش
        ),

        // كرت كي كارد
        _buildFinancialCard(
          title: 'خدمات بطاقة كي كارد (Qi Card) وصرف الرواتب',
          desc: 'صرف رواتب المتقاعدين والرعاية والموظفين، إصدار وتجديد الماستر كارد.',
          icon: Icons.credit_card,
          badgeColor: const Color(0xFFF59E0B), // لون كي كارد الذهبي
        ),

        // كرت آسيا بي
        _buildFinancialCard(
          title: 'خدمات آسيا بي (AsiaPay)',
          desc: 'سحب وتحويل الأموال فورياً عبر محفظة آسيا بي بأمان وسرعة.',
          icon: Icons.account_balance,
          badgeColor: const Color(0xFF0284C7),
        ),

        // إضافة أي خدمات مالية مسجلة بالسيرفر
        ..._financialServices.map((service) => _buildServiceCard(service, isProgramming: false)),
      ],
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color badgeColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: badgeColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: badgeColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              icon: const Icon(Icons.chat, size: 14),
              label: Text('طلب كاش', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () {
                final msg = 'مرحباً أسامة فون، أود الاستفسار عن الخدمة المالية التالية:\n'
                    '💳 الخدمة: $title\n'
                    'هل الخدمة متوفرة حالياً لديكم؟';
                ApiService.launchWhatsApp(phone: '+9647722882273', message: msg);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedHeader({required String title, required int count, required Color badgeColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor.withOpacity(0.4)),
          ),
          child: Text(
            '$count جهاز جاهز',
            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedDeviceCard(ServiceItem device, {required bool isProgramming}) {
    final displayImg = (device.imageFullUrl != null && device.imageFullUrl!.isNotEmpty)
        ? device.imageFullUrl!
        : ((device.imageUrl != null && device.imageUrl!.isNotEmpty) ? device.imageUrl : null);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط علوي أخضر مميز
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF047857)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.task_alt, color: Color(0xFF34D399), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'تم الاكتمال بنجاح - جاهز للاستلام ✅',
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isProgramming ? 'سوفتوير' : 'صيانة',
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

          // صورة الجهاز إذا توفرت
          if (displayImg != null)
            Container(
              width: double.infinity,
              height: 180,
              color: const Color(0xFF0F172A),
              child: AdaptiveImageWidget(
                imageUrl: displayImg,
                placeholder: const Center(
                  child: Icon(Icons.phone_android, size: 48, color: Colors.white24),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.title,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  device.description,
                  style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFFCBD5E1)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (device.managerNote.isNotEmpty)
                      Flexible(
                        child: Text(
                          device.managerNote,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFDE047),
                          ),
                        ),
                      )
                    else
                      const SizedBox(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.chat, size: 16),
                      label: Text(
                        'استفسار الاستلام',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        final phone = isProgramming ? '+9647722882273' : _settings.whatsappNumber;
                        final msg = 'مرحباً، أود الاستفسار عن استلام جهازي المكتمل:\n'
                            '📱 الجهاز: ${device.title}\n'
                            '📝 التفاصيل: ${device.description}\n'
                            'متى يمكنني الحضور للمحل واستلامه؟';
                        ApiService.launchWhatsApp(phone: phone, message: msg);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // كرت الخدمات العامة (برمجة، صيانة، أجهزة مبرمجة بالصور)
  // ---------------------------------------------------------------------------
  Widget _buildServiceCard(ServiceItem service, {required bool isProgramming}) {
    final displayImg = (service.imageFullUrl != null && service.imageFullUrl!.isNotEmpty)
        ? service.imageFullUrl!
        : ((service.imageUrl != null && service.imageUrl!.isNotEmpty) ? service.imageUrl : null);
    final hasImage = displayImg != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            Container(
              width: double.infinity,
              height: 190,
              color: const Color(0xFF0F172A),
              child: AdaptiveImageWidget(
                imageUrl: displayImg,
                placeholder: const Center(
                  child: Icon(Icons.phone_iphone, size: 50, color: Colors.white24),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        service.title,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                    ),
                    if (service.price.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.4)),
                        ),
                        child: Text(
                          service.price,
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  service.description,
                  style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (service.managerNote.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isProgramming
                              ? const Color(0xFFFDE047).withOpacity(0.12)
                              : const Color(0xFF34D399).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          service.managerNote,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isProgramming ? const Color(0xFFFDE047) : const Color(0xFF34D399),
                          ),
                        ),
                      )
                    else
                      const SizedBox(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.chat, size: 16),
                      label: Text(
                        isProgramming ? 'طلب البرمجة واتساب' : 'طلب الصيانة واتساب',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        final phone = isProgramming ? '+9647722882273' : _settings.whatsappNumber;
                        final msg = 'مرحباً، أود الاستفسار وطلب الخدمة التالية:\n'
                            '📌 العنوان: ${service.title}\n'
                            '📝 التفاصيل: ${service.description}\n'
                            'هل الخدمة متاحة لديكم حالياً؟';
                        ApiService.launchWhatsApp(phone: phone, message: msg);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. الشريط الثابت في الأسفل مع زر الخريطة والاتصال
  // ---------------------------------------------------------------------------
  Widget _buildFixedBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: const Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // زر موقعنا على الخارطة
            Expanded(
              flex: 5,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA4335), // أحمر خرائط جوجل
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.location_on, size: 20),
                label: Text(
                  'موقعنا على الخارطة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  ApiService.launchGoogleMaps(_settings.mapsUrl);
                },
              ),
            ),
            const SizedBox(width: 10),
            // زر الواتساب المباشر
            Expanded(
              flex: 5,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // أخضر واتساب
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat, size: 20),
                label: Text(
                  'تواصل معنا واتساب',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  ApiService.launchWhatsApp(
                    phone: '+9647722882273',
                    message: 'مرحباً أسامة فون، أود الاستفسار عن خدماتكم ومنتجاتكم.',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شريط متحرك انسيابي لعرض الإعلانات والأخبار
class MarqueeTickerWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity;

  const MarqueeTickerWidget({
    super.key,
    required this.text,
    this.style,
    this.velocity = 40.0,
  });

  @override
  State<MarqueeTickerWidget> createState() => _MarqueeTickerWidgetState();
}

class _MarqueeTickerWidgetState extends State<MarqueeTickerWidget> {
  late final ScrollController _scrollController;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    if (_isScrolling) return;
    _isScrolling = true;

    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted || !_scrollController.hasClients) break;
      
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) {
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      final durationMs = ((maxScroll / widget.velocity) * 1000).toInt().clamp(4000, 40000);
      
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          maxScroll,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        );
      }

      if (!mounted || !_scrollController.hasClients) break;
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          Text(widget.text, style: widget.style),
          const SizedBox(width: 40),
          Text(widget.text, style: widget.style),
        ],
      ),
    );
  }
}
