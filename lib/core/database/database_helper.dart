import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class DatabaseHelper {
  DatabaseHelper._private();
  static final DatabaseHelper instance = DatabaseHelper._private();

  static sql.Database? _db;

  Future<sql.Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<sql.Database> _initDb() async {
    final dbPath = await sql.getDatabasesPath();
    final dbFile = path.join(dbPath, 'couponapp.db');

    return await sql.openDatabase(
      dbFile,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        final batch = db.batch();

        batch.execute('''
          CREATE TABLE IF NOT EXISTS batches(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operator_name TEXT NOT NULL,
            location TEXT NOT NULL,
            total_coupons INTEGER NOT NULL,
            created_at DATETIME NOT NULL
          );
        ''');

        batch.execute('''
          CREATE TABLE IF NOT EXISTS boxes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            batch_id INTEGER NOT NULL,
            created_at DATETIME NOT NULL,
            FOREIGN KEY (batch_id) REFERENCES batches(id)
          );
        ''');

        batch.execute('''
          CREATE TABLE IF NOT EXISTS coupons(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            serialnumber TEXT NOT NULL,
            box_id INTEGER NOT NULL,
            amount INTEGER NOT NULL,
            created_at DATETIME NOT NULL,
            FOREIGN KEY (box_id) REFERENCES boxes(id)
          );
        ''');

        await batch.commit(noResult: true);
      },
    );
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<int> getTotalCoupons() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(id) as total FROM coupons');
    return result.isEmpty || result.first['total'] == null
        ? 0

        : result.first['total'] as int;
  }


  Future<int> getTotalBatches() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(id) as total FROM batches');
    return result.isEmpty || result.first['total'] == null
        ? 0
        : result.first['total'] as int;
  }

  Future<int> getTotalBoxes() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(id) as total FROM boxes');
    return result.isEmpty || result.first['total'] == null
        ? 0
        : result.first['total'] as int;
  }

  Future<int?> getLatestBatch() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT id FROM batches ORDER BY id DESC LIMIT 1',
    );
    return result.isEmpty ? 0 : result.first['id'] as int?;
  }

  Future<int> insertBatchData(Map<String, dynamic> batchData) async {
    final db = await instance.database;
    return await db.insert('batches', {
      'id': batchData['id'],
      'operator_name': batchData['operator_name'],
      'location': batchData['location'],
      'total_coupons': 5000,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> insertBoxData(int batchId) async {
    final db = await instance.database;
    return await db.insert('boxes', {
      'batch_id': batchId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getLastCouponSerialNumber() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT MAX(CAST(serialnumber AS INTEGER)) as maxSerial FROM coupons',
    );
    if (result.isEmpty || result.first['maxSerial'] == null) {
      return 0; // No coupons yet, start from 0
    }
    return result.first['maxSerial'] as int;
  }
  
  Future<void> insertCoupons(List<Map<String, dynamic>> coupons) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var coupon in coupons) {
      batch.insert('coupons', {
        'serialnumber': coupon['serialnumber'],
        'box_id': coupon['box_id'],
        'amount': coupon['amount'],
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }
  Future<List<Map<String, dynamic>>> getProductionReport(int batchId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      select 
        operator_name,
        location,batches.created_at,
        boxes.id as box_id,
        coupons.serialnumber,
        batches.id,
        coupons.amount,
        CASE WHEN coupons.amount = 0 THEN 'Anda Belum Beruntung' ELSE '' END AS keterangan
      from coupons 
      inner join boxes on boxes.id=coupons.box_id 
      inner join batches on batches.id=boxes.batch_id
      where batches.id = ?
      order by batches.id asc, boxes.id asc, coupons.id asc
    ''', [batchId]);
    return result;
  }
  Future<List<Map<String, dynamic>>> getBatches() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT id, operator_name, location, created_at FROM batches ORDER BY id ASC');
    return result;
  }
  Future<void> deleteAllData() async {
    final db = await instance.database;
    await db.delete('coupons');
    await db.delete('boxes');
    await db.delete('batches');
  }
}
