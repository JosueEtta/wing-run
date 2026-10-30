import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppUser {
  AppUser(this.id, this.name, this.best);
  final int id;
  final String name;
  final int best;
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
}

class AppDb {
  AppDb._();
  static final instance = AppDb._();
  Database? _db;

  Future<Database> get db async => _db ??= await openDatabase(
    p.join(await getDatabasesPath(), 'wing_run.db'),
    version: 1,
    onCreate: (d, _) async {
      await d.execute('CREATE TABLE users('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'name TEXT NOT NULL,'
          'best INTEGER NOT NULL DEFAULT 0)');
      await d.execute(
          'CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT)');
    },
  );

  Future<List<AppUser>> users() async {
    final rows = await (await db).query('users', orderBy: 'best DESC, name');
    return rows
        .map((r) => AppUser(r['id'] as int, r['name'] as String, r['best'] as int))
        .toList();
  }

  Future<int> addUser(String name) async =>
      (await db).insert('users', {'name': name, 'best': 0});

  Future<void> setBest(int id, int best) async => (await db)
      .update('users', {'best': best}, where: 'id = ?', whereArgs: [id]);

  Future<int?> currentId() async {
    final r = await (await db)
        .query('meta', where: 'key = ?', whereArgs: ['current_user']);
    return r.isEmpty ? null : int.tryParse(r.first['value'] as String);
  }

  Future<void> setCurrentId(int id) async => (await db).insert(
    'meta',
    {'key': 'current_user', 'value': '$id'},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

/// App-wide state: users + currently selected user (remembered in SQLite).
class Session extends ChangeNotifier {
  List<AppUser> users = [];
  int? currentId;
  final _db = AppDb.instance;

  AppUser get current =>
      users.firstWhere((u) => u.id == currentId, orElse: () => users.first);

  Future<void> load() async {
    users = await _db.users();
    if (users.isEmpty) {
      currentId = await _db.addUser('Player 1');
      users = await _db.users();
    } else {
      final saved = await _db.currentId();
      currentId = users.any((u) => u.id == saved) ? saved : users.first.id;
    }
    await _db.setCurrentId(currentId!);
    notifyListeners();
  }

  /// Returns false if the name is empty or already used.
  Future<bool> addUser(String name) async {
    name = name.trim();
    if (name.isEmpty ||
        users.any((u) => u.name.toLowerCase() == name.toLowerCase())) {
      return false;
    }
    currentId = await _db.addUser(name);
    await _db.setCurrentId(currentId!);
    users = await _db.users();
    notifyListeners();
    return true;
  }

  Future<void> select(int id) async {
    currentId = id;
    await _db.setCurrentId(id);
    notifyListeners();
  }

  Future<void> submitScore(int score) async {
    final u = current;
    if (score > u.best) {
      await _db.setBest(u.id, score);
      users = await _db.users();
      notifyListeners();
    }
  }
}

final session = Session();