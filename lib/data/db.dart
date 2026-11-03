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

  Future<void> renameUser(int id, String name) async => (await db)
      .update('users', {'name': name}, where: 'id = ?', whereArgs: [id]);

  Future<void> deleteUser(int id) async =>
      (await db).delete('users', where: 'id = ?', whereArgs: [id]);

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
  static const maxName = 12;

  List<AppUser> users = [];
  int? currentId;
  final _db = AppDb.instance;

  AppUser get current =>
      users.firstWhere((u) => u.id == currentId, orElse: () => users.first);

  Future<void> load() async {
    users = await _db.users();
    // No users yet = first launch: the home screen asks for a name.
    if (users.isNotEmpty) {
      final saved = await _db.currentId();
      currentId = users.any((u) => u.id == saved) ? saved : users.first.id;
      await _db.setCurrentId(currentId!);
    }
    notifyListeners();
  }

  /// Trims and collapses inner spaces, so "Ann  Lee" and "Ann Lee" match.
  String _clean(String name) => name.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// One rule for create AND rename. Returns an error message, or null if the
  /// name is valid. Names are unique, ignoring case. [exceptId] lets a user
  /// keep (or re-case) their own name when renaming.
  String? validateName(String name, {int? exceptId}) {
    final n = _clean(name);
    if (n.isEmpty) return 'Enter a name';
    if (n.length > maxName) return 'Max $maxName characters';
    final taken = users.any(
            (u) => u.id != exceptId && u.name.toLowerCase() == n.toLowerCase());
    return taken ? 'This name is already used' : null;
  }

  /// Returns false if the name is empty, too long or already used.
  Future<bool> addUser(String name) async {
    if (validateName(name) != null) return false;
    currentId = await _db.addUser(_clean(name));
    await _db.setCurrentId(currentId!);
    users = await _db.users();
    notifyListeners();
    return true;
  }

  /// Returns an error message, or null when the user was renamed.
  Future<String?> renameUser(int id, String name) async {
    final error = validateName(name, exceptId: id);
    if (error != null) return error;
    await _db.renameUser(id, _clean(name));
    users = await _db.users();
    notifyListeners();
    return null;
  }

  /// Returns false when this is the last user (at least one must remain).
  /// If the deleted user was the current one, the top-ranked remaining user
  /// becomes current.
  Future<bool> deleteUser(int id) async {
    if (users.length <= 1) return false;
    await _db.deleteUser(id);
    users = await _db.users();
    if (currentId == id) {
      currentId = users.first.id;
      await _db.setCurrentId(currentId!);
    }
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