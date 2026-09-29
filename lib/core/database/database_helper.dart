import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kasir.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _ensureIndexes,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE menu (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price INTEGER,
        image TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total INTEGER,
        payment_method TEXT,
        paid_amount INTEGER,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER,
        name TEXT,
        price INTEGER,
        qty INTEGER
      )
    ''');

    await _createIndexes(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createIndexes(db);
    }
  }

  Future<void> _ensureIndexes(Database db) async {
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_created_at
      ON transactions(created_at)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_transaction_items_transaction_id
      ON transaction_items(transaction_id)
    ''');
  }

  // ================= MENU =================

  Future<List<Map<String, dynamic>>> getMenus() async {
    final db = await database;
    return db.query('menu');
  }

  Future<void> addMenu(String name, int price, String image) async {
    final db = await database;
    await db.insert('menu', {'name': name, 'price': price, 'image': image});
  }

  Future<void> updateMenu(int id, String name, int price, String image) async {
    final db = await database;
    await db.update(
      'menu',
      {'name': name, 'price': price, 'image': image},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteMenu(int id) async {
    final db = await database;
    await db.delete('menu', where: 'id = ?', whereArgs: [id]);
  }

  // ================= TRANSAKSI =================

  Future<int> insertTransaction(
    int total,
    List<Map<String, dynamic>> items,
    String paymentMethod,
    int paidAmount,
  ) async {
    final db = await database;

    final trxId = await db.insert('transactions', {
      'total': total,
      'payment_method': paymentMethod,
      'paid_amount': paidAmount,
      'created_at': DateTime.now().toIso8601String(),
    });

    for (final item in items) {
      await db.insert('transaction_items', {
        'transaction_id': trxId,
        'name': item['name'],
        'price': item['price'],
        'qty': item['qty'],
      });
    }

    return trxId;
  }

  Future<List<Map<String, dynamic>>> getDetailTransaksi(int trxId) async {
    final db = await database;
    return db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [trxId],
    );
  }

  // ================= REPORT (GLOBAL) =================

  Future<int> getTotalPenjualan() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM transactions',
    );
    return result.first['total'] == null ? 0 : result.first['total'] as int;
  }

  Future<int> getTotalTransaksi() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions',
    );
    return result.first['count'] as int;
  }

  Future<List<Map<String, dynamic>>> getAllTransaksi() async {
    final db = await database;
    return db.query('transactions', orderBy: 'created_at DESC');
  }

  // ================= REPORT PER TANGGAL =================

  Future<List<Map<String, dynamic>>> getTransaksiByDate(String date) async {
    final db = await database;
    return db.query(
      'transactions',
      where: 'created_at LIKE ?',
      whereArgs: ['$date%'],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> getTotalPenjualanByDate(String date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM transactions WHERE created_at LIKE ?',
      ['$date%'],
    );
    return result.first['total'] == null ? 0 : result.first['total'] as int;
  }

  Future<int> getTotalTransaksiByDate(String date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions WHERE created_at LIKE ?',
      ['$date%'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, dynamic>?> getTransaksiById(int id) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  //==Menu terjual Hari ini==//
  Future<List<Map<String, dynamic>>> getMenuTerjual(String date) async {
    final db = await database;

    return await db.rawQuery(
      '''
    SELECT ti.name, SUM(ti.qty) as total_qty
    FROM transaction_items ti
    JOIN transactions t ON ti.transaction_id = t.id
    WHERE t.created_at LIKE ?
    GROUP BY ti.name
    ORDER BY total_qty DESC
  ''',
      ['$date%'],
    );
  }

  //==Menu Tidak Laku Hari ini==//
  Future<List<Map<String, dynamic>>> getMenuTidakLaku(String date) async {
    final db = await database;

    return await db.rawQuery(
      '''
    SELECT m.name
    FROM menu m
    WHERE m.name NOT IN (
      SELECT ti.name
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.created_at LIKE ?
    )
  ''',
      ['$date%'],
    );
  }

  // ================= REPORT RANGE (MINGGUAN & BULANAN) =================

  // TOTAL PENJUALAN RANGE
  Future<int> getTotalPenjualanRange(String start, String end) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT SUM(total) as total 
    FROM transactions 
    WHERE date(created_at) BETWEEN date(?) AND date(?)
    ''',
      [start, end],
    );

    return result.first['total'] == null ? 0 : result.first['total'] as int;
  }

  // ================= REPORT RANGE (MINGGUAN & BULANAN) =================

  Future<int> getTotalPenjualanByRange(String start, String end) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
    SELECT SUM(total) as total 
    FROM transactions 
    WHERE date(created_at) BETWEEN date(?) AND date(?)
    ''',
      [start, end],
    );
    return result.first['total'] == null ? 0 : result.first['total'] as int;
  }

  Future<int> getTotalTransaksiByRange(String start, String end) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
    SELECT COUNT(*) as count 
    FROM transactions 
    WHERE date(created_at) BETWEEN date(?) AND date(?)
    ''',
      [start, end],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getTransaksiByRange(
    String start,
    String end,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''
    SELECT * FROM transactions 
    WHERE date(created_at) BETWEEN date(?) AND date(?) 
    ORDER BY created_at DESC
    ''',
      [start, end],
    );
  }

  Future<List<Map<String, dynamic>>> getMenuTerjualByRange(
    String start,
    String end,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''
    SELECT ti.name, SUM(ti.qty) as total_qty
    FROM transaction_items ti
    JOIN transactions t ON ti.transaction_id = t.id
    WHERE date(t.created_at) BETWEEN date(?) AND date(?)
    GROUP BY ti.name
    ORDER BY total_qty DESC
    ''',
      [start, end],
    );
  }

  Future<List<Map<String, dynamic>>> getMenuTidakLakuByRange(
    String start,
    String end,
  ) async {
    final db = await database;
    return db.rawQuery(
      '''
    SELECT m.name
    FROM menu m
    WHERE m.name NOT IN (
      SELECT ti.name
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      WHERE date(t.created_at) BETWEEN date(?) AND date(?)
    )
    ''',
      [start, end],
    );
  }
}
