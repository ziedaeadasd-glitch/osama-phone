/**
 * =========================================================================
 * تطبيق "أسامة فون" (Osama Phone) - السيرفر المحلي وقاعدة البيانات
 * Local Backend: Node.js (Express) + SQLite3 + Multer
 * =========================================================================
 */

const express = require('express');
const cors = require('cors');
const multer = require('multer');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// كلمة السر والتوكن السري الخاص بالمدير
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'osama2026';
const ADMIN_SECRET_TOKEN = 'osama_phone_admin_secure_token_2026';

// -------------------------------------------------------------
// 1. إعداد مسارات التخزين والـ Middleware
// -------------------------------------------------------------
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// تفعيل CORS للسماح لتطبيق Flutter بالتواصل مع السيرفر
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// إتاحة مجلد الصور كملفات ثابتة مع تفعيل الهيدرز
app.use('/uploads', (req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Cross-Origin-Resource-Policy', 'cross-origin');
  next();
}, express.static(uploadsDir));

// دالة مساعدة لحفظ الصور المرسلة بصيغة Base64
function saveBase64Image(base64Str, prefix = 'product') {
  if (!base64Str || typeof base64Str !== 'string') return '';
  try {
    const matches = base64Str.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
    let buffer;
    let ext = '.png';
    if (matches && matches.length === 3) {
      buffer = Buffer.from(matches[2], 'base64');
      const mime = matches[1];
      if (mime.includes('jpeg') || mime.includes('jpg')) ext = '.jpg';
      else if (mime.includes('webp')) ext = '.webp';
    } else {
      buffer = Buffer.from(base64Str, 'base64');
    }
    const filename = `${prefix}_${Date.now()}_${Math.round(Math.random() * 1e4)}${ext}`;
    fs.writeFileSync(path.join(uploadsDir, filename), buffer);
    return `/uploads/${filename}`;
  } catch (e) {
    console.error('Error saving base64 image:', e);
    return '';
  }
}

// -------------------------------------------------------------
// 2. إعداد Multer لرفع وحفظ الصور محلياً
// -------------------------------------------------------------
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const uniqueName = `product_${Date.now()}_${Math.round(Math.random() * 1e4)}${ext}`;
    cb(null, uniqueName);
  }
});

const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'image/gif'];
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('نوع الملف غير مدعوم! يرجى رفع صورة فقط (JPG, PNG, WEBP).'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 10 * 1024 * 1024 } // الحد الأقصى 10 ميجابايت
});

// -------------------------------------------------------------
// 3. إعداد وتهيئة قاعدة بيانات SQLite
// -------------------------------------------------------------
const dbPath = path.join(__dirname, 'database.sqlite');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ خطأ في الاتصال بقاعدة بيانات SQLite:', err.message);
  } else {
    console.log('📦 تم الاتصال بقاعدة بيانات SQLite بنجاح.');
    initDatabase();
  }
});

function initDatabase() {
  db.serialize(() => {
    // جدول المنتجات (موبايلات، إكسسوارات، إلخ)
    db.run(`
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        currency TEXT DEFAULT 'USD',
        description TEXT,
        image_url TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // جدول الخدمات (برمجة، صيانة، وأجهزة مبرمجة مع صور)
    db.run(`
      CREATE TABLE IF NOT EXISTS services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL, -- 'programming' أو 'maintenance'
        title TEXT NOT NULL,
        description TEXT,
        price TEXT,
        manager_note TEXT,
        image_url TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // التأكد من وجود عمود image_url في جدول services
    db.run(`ALTER TABLE services ADD COLUMN image_url TEXT`, () => {});

    // جدول أسعار الصيرفة والعملات
    db.run(`
      CREATE TABLE IF NOT EXISTS exchange_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currency_name TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        buy_rate REAL NOT NULL,
        sell_rate REAL NOT NULL,
        notes TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // جدول الإعدادات العامة للمحل (رقم الواتساب، رابط خرائط جوجل، إلخ)
    db.run(`
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    `);

    // إضافة البيانات الافتراضية إذا كانت الجداول فارغة
    seedInitialData();
  });
}

function seedInitialData() {
  // إعدادات المتجر الافتراضية وحالة الرواتب
  const initialSettings = [
    { key: 'store_name', value: 'أسامة فون - Osama Phone' },
    { key: 'phone_number', value: '07722882273' },
    { key: 'whatsapp_number', value: '+9647722882273' },
    { key: 'programming_whatsapp', value: '+9647722882273' },
    { key: 'maps_url', value: 'https://www.google.com/maps/place/%D8%A7%D8%B3%D8%A7%D9%85%D8%A9+%D9%81%D9%88%D9%86%E2%80%AD/@36.3758306,43.1444241,17z/data=!3m1!4b1!4m6!3m5!1s0x400795005c1f6575:0xaff461d7e686bd2d!8m2!3d36.3758263!4d43.1418492!16s%2Fg%2F11w409hr2y?entry=ttu' },
    { key: 'programming_manager', value: 'زيد إياد' },
    { key: 'salary_status', value: 'نعم' }, // نعم أو لا
    { key: 'salary_notes', value: 'رواتب المتقاعدين والموظفين والرعاية الاجتماعية متوفرة الآن' }
  ];

  initialSettings.forEach(s => {
    db.run(`INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)`, [s.key, s.value]);
  });

  // التحقق من وجود منتجات أولية
  db.get(`SELECT COUNT(*) as count FROM products`, (err, row) => {
    if (!err && row && row.count === 0) {
      const stmt = db.prepare(`INSERT INTO products (category, name, price, currency, description, image_url) VALUES (?, ?, ?, ?, ?, ?)`);
      stmt.run('phones', 'iPhone 15 Pro Max', 1199, 'USD', 'ذاكرة 256 جيجابايت - تيتانيوم طبيعي - ضمان سنة', '');
      stmt.run('phones', 'Samsung Galaxy S24 Ultra', 1150, 'USD', 'ذاكرة 512 جيجابايت - معالج سنابدراجون - تيتانيوم رمادي', '');
      stmt.run('accessories', 'شاحن أنكر أصلي 65W GaN', 35, 'USD', 'شاحن سريع يدعم جميع الأجهزة الذكية واللابتوبات', '');
      stmt.run('accessories', 'سماعات AirPods Pro 2', 220, 'USD', 'إلغاء الضوضاء النشط مع علبة شحن USB-C', '');
      stmt.finalize();
    }
  });

  // تعبئة خدمات البرمجة والترويج والصيانة والخدمات المالية
  db.run(`DELETE FROM services WHERE 1=0`); // تأكيد

  // التحقق من بيانات الصيرفة
  db.get(`SELECT COUNT(*) as count FROM exchange_rates`, (err, row) => {
    if (!err && row && row.count === 0) {
      const stmt = db.prepare(`INSERT INTO exchange_rates (currency_name, currency_code, buy_rate, sell_rate, notes) VALUES (?, ?, ?, ?, ?)`);
      stmt.run('دولار أمريكي / دينار عراقي (100$)', 'USD_IQD', 152500, 153500, 'سعر الصرف اللحظي للـ 100 دولار');
      stmt.run('حوالات ويسترن يونيون وزين كاش', 'TRANSFERS', 1, 1, 'تحويل فوري مباشر بأقل عمولة');
      stmt.finalize();
    }
  });
}

// -------------------------------------------------------------
// 4. حماية الـ Middleware للأدمن (Admin Authentication)
// -------------------------------------------------------------
function requireAdmin(req, res, next) {
  const token = req.headers['x-admin-token'] || req.headers['authorization'];
  if (token && (token === ADMIN_SECRET_TOKEN || token === `Bearer ${ADMIN_SECRET_TOKEN}`)) {
    return next();
  }
  return res.status(401).json({
    success: false,
    message: 'غير مصرح! يجب توفير رمز الأدمن السري للقيام بهذه العملية.'
  });
}

// -------------------------------------------------------------
// 5. المسارات والـ API Endpoints
// -------------------------------------------------------------

// مسار فحص حالة السيرفر
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    app: 'Osama Phone Local Backend',
    time: new Date().toISOString()
  });
});

// --- تسجيل دخول الأدمن ---
app.post('/api/admin/login', (req, res) => {
  const { password } = req.body;
  if (password === ADMIN_PASSWORD) {
    res.json({
      success: true,
      message: 'تم تسجيل الدخول بنجاح!',
      token: ADMIN_SECRET_TOKEN
    });
  } else {
    res.status(401).json({
      success: false,
      message: 'كلمة المرور غير صحيحة!'
    });
  }
});

// --- مسارات المنتجات (Products) ---

// جلب المنتجات مع إمكانية التصفية بالقسم
app.get('/api/products', (req, res) => {
  const { category } = req.query;
  let sql = `SELECT * FROM products ORDER BY id DESC`;
  let params = [];

  if (category) {
    sql = `SELECT * FROM products WHERE category = ? ORDER BY id DESC`;
    params = [category];
  }

  db.all(sql, params, (err, rows) => {
    if (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
    // تعديل مسار الصورة ليكون رابطاً كاملاً إذا وجدت
    const host = req.protocol + '://' + req.get('host');
    const products = rows.map(p => ({
      ...p,
      image_full_url: p.image_url ? (p.image_url.startsWith('http') ? p.image_url : `${host}${p.image_url}`) : null
    }));
    res.json({ success: true, count: products.length, data: products });
  });
});

// جلب منتج واحد بالمعرف
app.get('/api/products/:id', (req, res) => {
  db.get(`SELECT * FROM products WHERE id = ?`, [req.params.id], (err, row) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (!row) return res.status(404).json({ success: false, message: 'المنتج غير موجود' });
    
    const host = req.protocol + '://' + req.get('host');
    const product = {
      ...row,
      image_full_url: row.image_url ? (row.image_url.startsWith('http') ? row.image_url : `${host}${row.image_url}`) : null
    };
    res.json({ success: true, data: product });
  });
});

// إضافة منتج جديد (محمي للأدمن مع رفع صورة)
app.post('/api/products', requireAdmin, upload.single('image'), (req, res) => {
  const { category, name, price, currency, description } = req.body;

  if (!category || !name || !price) {
    return res.status(400).json({
      success: false,
      message: 'يرجى إدخال الحقول المطلوبة (القسم، الاسم، السعر)!'
    });
  }

  let imageUrl = req.file ? `/uploads/${req.file.filename}` : '';
  if (!imageUrl && req.body.image_base64) {
    imageUrl = saveBase64Image(req.body.image_base64, 'product');
  }
  if (!imageUrl && req.body.image_url) {
    imageUrl = req.body.image_url;
  }

  const sql = `INSERT INTO products (category, name, price, currency, description, image_url) VALUES (?, ?, ?, ?, ?, ?)`;
  const params = [category, name, parseFloat(price), currency || 'USD', description || '', imageUrl];

  db.run(sql, params, function (err) {
    if (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
    const host = req.protocol + '://' + req.get('host');
    res.status(201).json({
      success: true,
      message: 'تم إضافة المنتج بنجاح!',
      data: {
        id: this.lastID,
        category,
        name,
        price: parseFloat(price),
        currency: currency || 'USD',
        description: description || '',
        image_url: imageUrl,
        image_full_url: imageUrl ? `${host}${imageUrl}` : null
      }
    });
  });
});

// تعديل منتج (محمي للأدمن)
app.put('/api/products/:id', requireAdmin, upload.single('image'), (req, res) => {
  const { category, name, price, currency, description } = req.body;
  const productId = req.params.id;

  db.get(`SELECT * FROM products WHERE id = ?`, [productId], (err, current) => {
    if (err || !current) {
      return res.status(404).json({ success: false, message: 'المنتج غير موجود' });
    }

    let imageUrl = current.image_url;
    if (req.file) {
      imageUrl = `/uploads/${req.file.filename}`;
      // حذف الصورة القديمة من القرص إذا كانت محلية
      if (current.image_url && current.image_url.startsWith('/uploads/')) {
        const oldFile = path.join(__dirname, current.image_url);
        if (fs.existsSync(oldFile)) fs.unlinkSync(oldFile);
      }
    }

    const sql = `
      UPDATE products 
      SET category = ?, name = ?, price = ?, currency = ?, description = ?, image_url = ?
      WHERE id = ?
    `;
    const params = [
      category || current.category,
      name || current.name,
      price !== undefined ? parseFloat(price) : current.price,
      currency || current.currency,
      description !== undefined ? description : current.description,
      imageUrl,
      productId
    ];

    db.run(sql, params, function (err) {
      if (err) return res.status(500).json({ success: false, error: err.message });
      res.json({ success: true, message: 'تم تحديث بيانات المنتج بنجاح!' });
    });
  });
});

// حذف منتج (محمي للأدمن)
app.delete('/api/products/:id', requireAdmin, (req, res) => {
  const productId = req.params.id;

  db.get(`SELECT * FROM products WHERE id = ?`, [productId], (err, product) => {
    if (err || !product) {
      return res.status(404).json({ success: false, message: 'المنتج غير موجود' });
    }

    // حذف ملف الصورة من القرص
    if (product.image_url && product.image_url.startsWith('/uploads/')) {
      const filePath = path.join(__dirname, product.image_url);
      if (fs.existsSync(filePath)) {
        try { fs.unlinkSync(filePath); } catch (e) { console.error('خطأ في حذف ملف الصورة:', e); }
      }
    }

    db.run(`DELETE FROM products WHERE id = ?`, [productId], function (err) {
      if (err) return res.status(500).json({ success: false, error: err.message });
      res.json({ success: true, message: 'تم حذف المنتج بنجاح!' });
    });
  });
});

// --- مسارات الخدمات (البرمجة، الصيانة، وأجهزة البرمجة) ---
app.get('/api/services', (req, res) => {
  const { type } = req.query;
  let sql = `SELECT * FROM services ORDER BY id DESC`;
  let params = [];
  if (type) {
    sql = `SELECT * FROM services WHERE type = ? ORDER BY id DESC`;
    params = [type];
  }
  db.all(sql, params, (err, rows) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    const host = req.protocol + '://' + req.get('host');
    const services = rows.map(s => ({
      ...s,
      image_full_url: s.image_url ? (s.image_url.startsWith('http') ? s.image_url : `${host}${s.image_url}`) : null
    }));
    res.json({ success: true, count: services.length, data: services });
  });
});

app.post('/api/services', requireAdmin, upload.single('image'), (req, res) => {
  const { type, title, description, price, manager_note } = req.body;
  if (!type || !title) {
    return res.status(400).json({ success: false, message: 'نوع الخدمة وعنوانها مطلوبان!' });
  }

  let imageUrl = req.file ? `/uploads/${req.file.filename}` : '';
  if (!imageUrl && req.body.image_base64) {
    imageUrl = saveBase64Image(req.body.image_base64, 'service');
  }
  if (!imageUrl && req.body.image_url) {
    imageUrl = req.body.image_url;
  }
  const sql = `INSERT INTO services (type, title, description, price, manager_note, image_url) VALUES (?, ?, ?, ?, ?, ?)`;
  db.run(sql, [type, title, description || '', price || '', manager_note || '', imageUrl], function (err) {
    if (err) return res.status(500).json({ success: false, error: err.message });
    const host = req.protocol + '://' + req.get('host');
    res.status(201).json({
      success: true,
      message: 'تمت إضافة الخدمة بنجاح!',
      data: {
        id: this.lastID,
        type,
        title,
        description: description || '',
        price: price || '',
        manager_note: manager_note || '',
        image_url: imageUrl,
        image_full_url: imageUrl ? `${host}${imageUrl}` : null
      }
    });
  });
});

app.delete('/api/services/:id', requireAdmin, (req, res) => {
  const serviceId = req.params.id;
  db.get(`SELECT * FROM services WHERE id = ?`, [serviceId], (err, service) => {
    if (service && service.image_url && service.image_url.startsWith('/uploads/')) {
      const filePath = path.join(__dirname, service.image_url);
      if (fs.existsSync(filePath)) {
        try { fs.unlinkSync(filePath); } catch (e) {}
      }
    }
    db.run(`DELETE FROM services WHERE id = ?`, [serviceId], function (err) {
      if (err) return res.status(500).json({ success: false, error: err.message });
      res.json({ success: true, message: 'تم حذف الخدمة بنجاح!' });
    });
  });
});

// --- مسارات أسعار الصيرفة ---
app.get('/api/exchange-rates', (req, res) => {
  db.all(`SELECT * FROM exchange_rates ORDER BY id ASC`, (err, rows) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, data: rows });
  });
});

app.post('/api/exchange-rates', requireAdmin, (req, res) => {
  const { currency_name, currency_code, buy_rate, sell_rate, notes } = req.body;
  if (!currency_name || !buy_rate || !sell_rate) {
    return res.status(400).json({ success: false, message: 'يرجى إدخال اسم العملة وأسعار الشراء والبيع!' });
  }

  const sql = `INSERT INTO exchange_rates (currency_name, currency_code, buy_rate, sell_rate, notes) VALUES (?, ?, ?, ?, ?)`;
  db.run(sql, [currency_name, currency_code || 'CUSTOM', buy_rate, sell_rate, notes || ''], function (err) {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.status(201).json({ success: true, message: 'تم إضافة سعر الصرف بنجاح!', id: this.lastID });
  });
});

app.put('/api/exchange-rates/:id', requireAdmin, (req, res) => {
  const { buy_rate, sell_rate, notes } = req.body;
  const sql = `UPDATE exchange_rates SET buy_rate = ?, sell_rate = ?, notes = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`;
  db.run(sql, [buy_rate, sell_rate, notes || '', req.params.id], function (err) {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, message: 'تم تحديث أسعار الصرف بنجاح!' });
  });
});

// --- مسارات الإعدادات العامة (الموقع، الواتساب، الهاتف) ---
app.get('/api/settings', (req, res) => {
  db.all(`SELECT * FROM settings`, (err, rows) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    const config = {};
    rows.forEach(r => { config[r.key] = r.value; });
    res.json({ success: true, data: config });
  });
});

app.put('/api/settings', requireAdmin, (req, res) => {
  const settings = req.body; // { key: value, ... }
  const keys = Object.keys(settings);

  db.serialize(() => {
    const stmt = db.prepare(`INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)`);
    keys.forEach(k => {
      stmt.run(k, String(settings[k]));
    });
    stmt.finalize((err) => {
      if (err) return res.status(500).json({ success: false, error: err.message });
      res.json({ success: true, message: 'تم تحديث إعدادات المتجر بنجاح!' });
    });
  });
});

// -------------------------------------------------------------
// 6. تشغيل السيرفر
// -------------------------------------------------------------
app.listen(PORT, '0.0.0.0', () => {
  console.log(`
  =============================================================
  🚀 سيرفر "أسامة فون" (Osama Phone) يعمل الآن بنجاح!
  🌐 المنفذ المحلي: http://localhost:${PORT}
  📁 مجلد رفع الصور: ${uploadsDir}
  🗄️ قاعدة البيانات: SQLite (${dbPath})
  🔑 كلمة مرور المدير الافتراضية: osama2026
  =============================================================
  `);
});
