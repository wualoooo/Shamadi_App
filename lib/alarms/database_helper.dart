import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Alarm {
  final int? id;
  final String time;
  final List<String> days;
  bool isActive;

  Alarm({this.id, required this.time, required this.days, this.isActive = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'days': days.join(','),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'],
      time: map['time'],
      days: map['days'].isNotEmpty ? map['days'].split(',') : [],
      isActive: map['isActive'] == 1,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'alarms.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE alarms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        time TEXT NOT NULL,
        days TEXT NOT NULL,
        isActive INTEGER NOT NULL
      )
    ''');
  }

  Future<List<Alarm>> getAlarms() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('alarms');
    return List.generate(maps.length, (i) {
      return Alarm.fromMap(maps[i]);
    });
  }

  Future<int> insertAlarm(Alarm alarm) async {
    final Database db = await database;
    return await db.insert('alarms', alarm.toMap());
  }

  Future<int> updateAlarm(Alarm alarm) async {
    final Database db = await database;
    return await db.update(
      'alarms',
      alarm.toMap(),
      where: 'id = ?',
      whereArgs: [alarm.id],
    );
  }

  Future<int> deleteAlarm(int id) async {
    final Database db = await database;
    return await db.delete(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}