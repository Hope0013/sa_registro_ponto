import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/user_model.dart';
import '../models/workplace_model.dart';
import '../models/punch_model.dart';

class DatabaseService {
  // Instancia unica (singleton) para gerenciar o banco em todo o app
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  // Retorna a instancia do banco SQLite aberta e pronta para uso
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ponto_eletronico.db');
    return _database!;
  }

  // Inicializa o banco de dados e ajusta o driver para Windows caso necessario
  Future<Database> _initDB(String filePath) async {
    // Configura o sqflite FFI caso o app seja executado no Windows desktop
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Cria as tabelas necessarias no primeiro acesso ao banco de dados
  Future<void> _createDB(Database db, int version) async {
    // Tabela de usuarios
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nif TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Tabela com informacoes da empresa e coordenadas de raio permitido
    await db.execute('''
      CREATE TABLE workplaces (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radiusMeters REAL NOT NULL
      )
    ''');

    // Tabela de registros de ponto com localizacao e tipo de autenticacao
    await db.execute('''
      CREATE TABLE punches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userNif TEXT NOT NULL,
        userName TEXT NOT NULL,
        punchType TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        distanceMeters REAL NOT NULL,
        isValidLocation INTEGER NOT NULL,
        authenticationType TEXT NOT NULL
      )
    ''');

    // Insere dados de teste padrao para facilitar a avaliacao do professor
    await _insertDefaultSeed(db);
  }

  // Insere um usuario e uma empresa padrao para testes imediatos
  Future<void> _insertDefaultSeed(Database db) async {
    await db.insert('users', {
      'nif': '123456',
      'name': 'Carlos Desenvolvedor',
      'email': 'carlos@empresa.com',
      'password': '123456',
    });

    // Ponto padrao da empresa (Avenida Paulista, SP como referencia inicial)
    await db.insert('workplaces', {
      'name': 'Empresa Matriz - Sede',
      'latitude': -23.561414,
      'longitude': -46.655881,
      'radiusMeters': 100.0,
    });
  }

  // Registra um novo usuario no banco
  Future<int> registerUser(UserModel user) async {
    final db = await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Realiza a busca do usuario por NIF ou e-mail com senha
  Future<UserModel?> login(String identifier, String password) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: '(nif = ? OR email = ?) AND password = ?',
      whereArgs: [identifier.trim(), identifier.trim(), password],
    );

    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  // Busca usuario apenas pelo NIF ou email (usado na autenticacao biometrica)
  Future<UserModel?> getUserByIdentifier(String identifier) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'nif = ? OR email = ?',
      whereArgs: [identifier.trim(), identifier.trim()],
    );

    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  // Retorna o primeiro usuario cadastrado (util para atalho de biometria)
  Future<UserModel?> getFirstUser() async {
    final db = await database;
    final results = await db.query('users', limit: 1);
    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  // Retorna as configuracoes da empresa
  Future<WorkplaceModel> getWorkplace() async {
    final db = await database;
    final results = await db.query('workplaces', limit: 1);

    if (results.isNotEmpty) {
      return WorkplaceModel.fromMap(results.first);
    }

    // Retorna padrao de seguranca caso nao encontre
    return WorkplaceModel(
      name: 'Empresa Matriz',
      latitude: -23.561414,
      longitude: -46.655881,
      radiusMeters: 100.0,
    );
  }

  // Atualiza as coordenadas da empresa (permite ao professor definir onde esta para testar)
  Future<void> updateWorkplace(WorkplaceModel workplace) async {
    final db = await database;
    final count = await db.update(
      'workplaces',
      workplace.toMap(),
      where: 'id = ?',
      whereArgs: [workplace.id ?? 1],
    );

    if (count == 0) {
      await db.insert('workplaces', workplace.toMap());
    }
  }

  // Grava o registro de ponto no banco SQLite
  Future<int> insertPunch(PunchModel punch) async {
    final db = await database;
    return await db.insert('punches', punch.toMap());
  }

  // Busca o historico de pontos do usuario logado em ordem decrescente (mais recentes primeiro)
  Future<List<PunchModel>> getPunchesByUser(String userNif) async {
    final db = await database;
    final results = await db.query(
      'punches',
      where: 'userNif = ?',
      whereArgs: [userNif],
      orderBy: 'timestamp DESC',
    );

    return results.map((map) => PunchModel.fromMap(map)).toList();
  }

  // Busca todos os pontos salvos
  Future<List<PunchModel>> getAllPunches() async {
    final db = await database;
    final results = await db.query(
      'punches',
      orderBy: 'timestamp DESC',
    );

    return results.map((map) => PunchModel.fromMap(map)).toList();
  }

  // Limpa os registros de ponto para testes
  Future<void> clearPunches() async {
    final db = await database;
    await db.delete('punches');
  }
}
