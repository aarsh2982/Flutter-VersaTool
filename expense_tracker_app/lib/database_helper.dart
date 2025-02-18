import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/item_model.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expense_tracker.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE salary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL
      )
    ''');

    await db.insert('salary', {'amount': 0.0}); // Default salary = 0
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE salary (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL
        )
      ''');
      await db.insert('salary', {'amount': 0.0});
    }
  }

  // Insert an item
  Future<int> insertItem(Item item) async {
    Database db = await database;
    return await db.insert('items', item.toMap());
  }

  // Retrieve all items
  Future<List<Item>> getItems() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('items');
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  // Update an item
  Future<int> updateItem(Item item) async {
    Database db = await database;
    return await db
        .update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  // Delete an item
  Future<int> deleteItem(int id) async {
    Database db = await database;
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // Get Salary
  Future<double> getSalary() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query('salary');
    return result.isNotEmpty ? result.first['amount'] : 0.0;
  }

  // Update Salary
  Future<void> updateSalary(double newSalary) async {
    Database db = await database;
    await db.update('salary', {'amount': newSalary});
  }
}
