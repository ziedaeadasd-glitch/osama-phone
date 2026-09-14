import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../widgets/adaptive_image.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. حقول إضافة منتج
  final _productFormKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productDescController = TextEditingController();
  String _selectedCategory = 'phones';
  XFile? _productImage;
  Uint8List? _productImageBytes;

  // 2. حقول إضافة خدمة / جهاز مبرمج
  final _serviceFormKey = GlobalKey<FormState>();
  final _serviceTitleController = TextEditingController();
  final _servicePriceController = TextEditingController();
  final _serviceDescController = TextEditingController();
  String _selectedServiceType = 'programming';
  XFile? _serviceImage;
  Uint8List? _serviceImageBytes;

  // 3. حقول إعدادات الرواتب والمتجر
  String _salaryStatus = 'نعم';
  final _salaryNotesController = TextEditingController();
  final _whatsappController = TextEditingController(text: '+9647722882273');
  bool _isSavingSettings = false;

  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  // 4. قوائم الإدارة
  List<Product> _allProducts = [];
  List<ServiceItem> _allServices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productDescController.dispose();
    _serviceTitleController.dispose();
    _servicePriceController.dispose();
    _serviceDescController.dispose();
    _salaryNotesController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final products = await ApiService.getProducts();
    final services = await ApiService.getServices();
    final settings = await ApiService.getSettings();
    if (mounted) {
      setState(() {
        _allProducts = products;
        _allServices = services;
        _salaryStatus = settings.salaryStatus.isNotEmpty ? settings.salaryStatus : 'نعم';
        _salaryNotesController.text = settings.salaryNotes;
        _whatsappController.text = settings.whatsappNumber;
        _isLoading = false;
      });
    }
  }

  // --- دوال اختيار الصور ---
  Future<void> _pickProductImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _productImage = file;
          _productImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking product image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح المعرض/الكاميرا: $e', style: GoogleFonts.cairo()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _pickServiceImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _serviceImage = file;
          _serviceImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking service image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح المعرض/الكاميرا: $e', style: GoogleFonts.cairo()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // --- حفظ منتج ---
  Future<void> _submitProduct() async {
    if (!_productFormKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final rawPrice = _productPriceController.text.trim();
    final parsedPrice = ApiService.parsePrice(rawPrice);

    Map<String, dynamic> res;
    if (kIsWeb || _productImage == null) {
      res = await ApiService.addProduct(
        category: _selectedCategory,
        name: _productNameController.text.trim(),
        price: parsedPrice,
        description: _productDescController.text.trim(),
        imageBytes: _productImageBytes,
        imageName: _productImage?.name,
      );
    } else {
      res = await ApiService.addProduct(
        category: _selectedCategory,
        name: _productNameController.text.trim(),
        price: parsedPrice,
        description: _productDescController.text.trim(),
        imageFile: File(_productImage!.path),
        imageBytes: _productImageBytes,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'تم حفظ المنتج بنجاح!', style: GoogleFonts.cairo()), backgroundColor: const Color(0xFF10B981)),
      );
      _productNameController.clear();
      _productPriceController.clear();
      _productDescController.clear();
      setState(() {
        _productImage = null;
        _productImageBytes = null;
      });
      _loadAll();
      _tabController.animateTo(3); // الانتقال لتبويب إدارة المحتوى لرؤية المنتج المضاف
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'فشل إضافة المنتج', style: GoogleFonts.cairo()), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  // --- حفظ خدمة / جهاز مبرمج أو مكتمل ---
  Future<void> _submitService() async {
    if (!_serviceFormKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    String note = 'فني معتمد';
    if (_selectedServiceType == 'programming') {
      note = 'بإدارة: زيد إياد - +9647722882273';
    } else if (_selectedServiceType == 'completed_programming') {
      note = 'جاهز للاستلام - بإدارة زيد إياد';
    } else if (_selectedServiceType == 'completed_maintenance') {
      note = 'جاهز للتسليم في المحل';
    }

    final rawPrice = _servicePriceController.text.trim();
    final cleanPrice = rawPrice.isNotEmpty ? ApiService.normalizeNumbers(rawPrice) : 'تم الإنجاز ✅';

    Map<String, dynamic> res;
    if (kIsWeb || _serviceImage == null) {
      res = await ApiService.addService(
        type: _selectedServiceType,
        title: _serviceTitleController.text.trim(),
        price: cleanPrice,
        description: _serviceDescController.text.trim(),
        managerNote: note,
        imageBytes: _serviceImageBytes,
        imageName: _serviceImage?.name,
      );
    } else {
      res = await ApiService.addService(
        type: _selectedServiceType,
        title: _serviceTitleController.text.trim(),
        price: cleanPrice,
        description: _serviceDescController.text.trim(),
        managerNote: note,
        imageFile: File(_serviceImage!.path),
        imageBytes: _serviceImageBytes,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'تم حفظ ونشر الجهاز بنجاح!', style: GoogleFonts.cairo()), backgroundColor: const Color(0xFF10B981)),
      );
      _serviceTitleController.clear();
      _servicePriceController.clear();
      _serviceDescController.clear();
      setState(() {
        _serviceImage = null;
        _serviceImageBytes = null;
      });
      _loadAll();
      _tabController.animateTo(3); // الانتقال لتبويب إدارة المحتوى
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'فشل إضافة الجهاز', style: GoogleFonts.cairo()), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  // --- حذف منتج ---
  Future<void> _deleteProduct(Product item) async {
    final ok = await ApiService.deleteProduct(item.id);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف "${item.name}" بنجاح', style: GoogleFonts.cairo()), backgroundColor: const Color(0xFF10B981)),
      );
      _loadAll();
    }
  }

  // --- حذف خدمة ---
  Future<void> _deleteService(ServiceItem item) async {
    final ok = await ApiService.deleteService(item.id);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف "${item.title}" بنجاح', style: GoogleFonts.cairo()), backgroundColor: const Color(0xFF10B981)),
      );
      _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم أسامة فون', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8)),
            onPressed: _loadAll,
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            onPressed: () async {
              await ApiService.clearAdminToken();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFF0EA5E9),
          labelColor: const Color(0xFF0EA5E9),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.add_shopping_cart), text: 'إضافة منتج'),
            Tab(icon: Icon(Icons.developer_mode), text: 'إضافة خدمة / جهاز مكتمل'),
            Tab(icon: Icon(Icons.payments), text: 'الرواتب والإعدادات'),
            Tab(icon: Icon(Icons.inventory), text: 'إدارة المحتوى'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddProductTab(),
          _buildAddServiceTab(),
          _buildSalaryAndSettingsTab(),
          _buildManageTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. تبويب إضافة منتج
  // ---------------------------------------------------------------------------
  Widget _buildAddProductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Form(
            key: _productFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('القسم:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF161F30),
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 15),
                      items: const [
                        DropdownMenuItem(value: 'phones', child: Text('📱 قسم الموبايلات والأجهزة الذكية')),
                        DropdownMenuItem(value: 'accessories', child: Text('🎧 قسم الإكسسوارات والشواحن')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _productNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('اسم الجهاز / الموديل (مثال: iPhone 15 Pro Max)', Icons.phone_android),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم الجهاز أو المنتج' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _productPriceController,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('السعر بالدولار (\$ مثال: 1150 أو 1150\$)', Icons.attach_money),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال السعر' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _productDescController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('المواصفات، الذاكرة، النظافة، والضمان...', Icons.description),
                ),
                const SizedBox(height: 18),
                _buildImagePickerBox(
                  imageBytes: _productImageBytes,
                  onPick: _pickProductImage,
                  onRemove: () => setState(() {
                    _productImage = null;
                    _productImageBytes = null;
                  }),
                  title: 'صورة الجهاز (من الكاميرا أو المعرض)',
                ),
                const SizedBox(height: 24),
                _buildSubmitButton(
                  title: 'حفظ ورفع الجهاز للمتجر',
                  icon: Icons.save,
                  color: const Color(0xFF10B981),
                  onPressed: _submitProduct,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. تبويب إضافة خدمة أو جهاز مبرمج (زيد إياد برمجة)
  // ---------------------------------------------------------------------------
  Widget _buildAddServiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Form(
            key: _serviceFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0369A1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: Color(0xFFFDE047), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'إضافة جهاز تم اكتماله أو خدمة جديدة (بإدارة: زيد إياد)',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('نوع القسم / الحالة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedServiceType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF161F30),
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 15),
                      items: const [
                        DropdownMenuItem(value: 'completed_programming', child: Text('📱 جهاز تم اكتمال برمجته وجاهز للاستلام ✅')),
                        DropdownMenuItem(value: 'completed_maintenance', child: Text('🔧 جهاز تم اكتمال صيانته وجاهز للاستلام ✅')),
                        DropdownMenuItem(value: 'programming', child: Text('💻 خدمة برمجة وسوفتوير (زيد إياد)')),
                        DropdownMenuItem(value: 'maintenance', child: Text('🛠️ خدمة صيانة وتصليح هاردوير')),
                        DropdownMenuItem(value: 'financial', child: Text('💳 خدمة مالية وتحويل كاش (زين كاش، كي)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedServiceType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _serviceTitleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('عنوان الخدمة / اسم الجهاز المكتمل', Icons.title),
                  validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال العنوان أو اسم الجهاز' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _servicePriceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('السعر أو التكلفة (مثال: 25\$ أو جاهز للاستلام)', Icons.price_change),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _serviceDescController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('تفاصيل العملية، اسم صاحب الجهاز، فك قفل، تصليح شاشة...', Icons.description),
                ),
                const SizedBox(height: 18),
                _buildImagePickerBox(
                  imageBytes: _serviceImageBytes,
                  onPick: _pickServiceImage,
                  onRemove: () => setState(() {
                    _serviceImage = null;
                    _serviceImageBytes = null;
                  }),
                  title: 'صورة الجهاز المكتمل أو الخدمة (تظهر فوراً في التطبيق)',
                ),
                const SizedBox(height: 24),
                _buildSubmitButton(
                  title: 'نشر الجهاز / الخدمة في التطبيق',
                  icon: Icons.cloud_upload,
                  color: const Color(0xFF0284C7),
                  onPressed: _submitService,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. تبويب حالة الرواتب والإعدادات
  // ---------------------------------------------------------------------------
  Widget _buildSalaryAndSettingsTab() {
    final isSalaryAvailable = _salaryStatus == 'نعم';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSalaryAvailable ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSalaryAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: isSalaryAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 28),
                            const SizedBox(width: 10),
                            Text('حالة توزيع الرواتب اليوم:', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        Switch(
                          value: isSalaryAvailable,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) {
                            setState(() => _salaryStatus = val ? 'نعم' : 'لا');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSalaryAvailable ? 'حالة الرواتب: متوفرة الآن للزبائن (نعم ✅)' : 'حالة الرواتب: غير متوفرة حالياً (لا ❌)',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSalaryAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('ملاحظات وتفاصيل الرواتب المعروضة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _salaryNotesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('مثال: توزيع رواتب المتقاعدين والرعاية الاجتماعية مستمر في المحل...', Icons.edit_note),
              ),
              const SizedBox(height: 20),
              Text('رقم واتساب المتجر الرسمي:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _whatsappController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('رقم الواتساب الدولي (+9647722882273)', Icons.phone),
              ),
              const SizedBox(height: 24),
              _buildSubmitButton(
                title: _isSavingSettings ? 'جارٍ الحفظ...' : 'حفظ ونشر التعديلات فوراً',
                icon: Icons.save,
                color: const Color(0xFF10B981),
                onPressed: _saveSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSavingSettings = true);
    final ok = await ApiService.updateSettings({
      'salary_status': _salaryStatus,
      'salary_notes': _salaryNotesController.text.trim(),
      'whatsapp_number': _whatsappController.text.trim(),
    });
    if (!mounted) return;
    setState(() => _isSavingSettings = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة الرواتب والإعدادات بنجاح!', style: GoogleFonts.cairo()), backgroundColor: const Color(0xFF10B981)),
      );
      _loadAll();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حفظ الإعدادات', style: GoogleFonts.cairo()), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 4. تبويب إدارة وحذف المحتوى
  // ---------------------------------------------------------------------------
  Widget _buildManageTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('📦 المنتجات المعروضة (${_allProducts.length}):', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        const SizedBox(height: 10),
        ..._allProducts.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Container(
                  width: 54,
                  height: 54,
                  color: const Color(0xFF0F172A),
                  child: AdaptiveImageWidget(
                    imageUrl: p.imageFullUrl ?? p.imageUrl,
                    placeholder: const Icon(Icons.phone_android, color: Colors.white38),
                  ),
                ),
                title: Text(p.name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text('${p.price}\$ | ${p.category == 'phones' ? 'موبايلات' : 'إكسسوارات'}', style: GoogleFonts.cairo(color: const Color(0xFF10B981))),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                  tooltip: 'حذف المنتج',
                  onPressed: () => _deleteProduct(p),
                ),
              ),
            )),
        const Divider(height: 30, color: Color(0xFF334155)),
        Text('💻 خدمات وأجهزة البرمجة والصيانة (${_allServices.length}):', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        const SizedBox(height: 10),
        ..._allServices.map((s) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Container(
                  width: 54,
                  height: 54,
                  color: const Color(0xFF0F172A),
                  child: AdaptiveImageWidget(
                    imageUrl: s.imageFullUrl ?? s.imageUrl,
                    placeholder: const Icon(Icons.developer_mode, color: Colors.white38),
                  ),
                ),
                title: Text(s.title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text(
                  '${s.status == 'completed' ? '✅ مكتمل' : (s.type == 'programming' ? 'برمجة (زيد إياد)' : 'صيانة')} | ${s.price}',
                  style: GoogleFonts.cairo(color: s.status == 'completed' ? const Color(0xFF10B981) : const Color(0xFF38BDF8)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                  tooltip: 'حذف',
                  onPressed: () => _deleteService(s),
                ),
              ),
            )),
      ],
    );
  }

  // --- عناصر مساعدة للواجهة ---
  Widget _buildImagePickerBox({
    required Uint8List? imageBytes,
    required Function(ImageSource) onPick,
    required VoidCallback onRemove,
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF161F30),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library, color: Color(0xFF0EA5E9)),
                      title: Text('المعرض (Gallery)', style: GoogleFonts.cairo(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(ctx);
                        onPick(ImageSource.gallery);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.camera_alt, color: Color(0xFF10B981)),
                      title: Text('الكاميرا (Camera)', style: GoogleFonts.cairo(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(ctx);
                        onPick(ImageSource.camera);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF161F30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: imageBytes != null ? const Color(0xFF10B981) : const Color(0xFF334155), width: 1.5),
            ),
            child: imageBytes != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(imageBytes, fit: BoxFit.contain)),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 28),
                            onPressed: onRemove,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 40, color: Color(0xFF0EA5E9)),
                      const SizedBox(height: 6),
                      Text('اضغط لاختيار صورة من جهازك / الآيفون', style: GoogleFonts.cairo(color: const Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: _isSubmitting ? const SizedBox() : Icon(icon, size: 20),
        label: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold)),
        onPressed: _isSubmitting ? null : onPressed,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.cairo(color: Colors.white60, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF161F30),
      prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9), size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5)),
    );
  }
}
