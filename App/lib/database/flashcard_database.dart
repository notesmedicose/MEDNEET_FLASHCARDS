import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/flashcard_model.dart';
import '../models/spaced_repetition_model.dart';

class FlashcardDatabase {
  static Database? _database;
  static final FlashcardDatabase instance = FlashcardDatabase._();

  FlashcardDatabase._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = '${(await getApplicationDocumentsDirectory()).path}/medneet_flashcards.db';
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE flashcards (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        classNum TEXT NOT NULL,
        chapter TEXT NOT NULL,
        chapterNum INTEGER NOT NULL,
        type TEXT NOT NULL,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        ncertRef TEXT NOT NULL,
        difficulty TEXT DEFAULT 'medium',
        tags TEXT DEFAULT '',
        deckName TEXT NOT NULL,
        interval INTEGER DEFAULT 0,
        repetitions INTEGER DEFAULT 0,
        easeFactor REAL DEFAULT 2.5,
        nextReviewDate TEXT,
        lastReviewDate TEXT,
        status INTEGER DEFAULT 0,
        timesReviewed INTEGER DEFAULT 0,
        timesCorrect INTEGER DEFAULT 0,
        bookmarked INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE xp_system (
        id INTEGER PRIMARY KEY DEFAULT 1,
        totalXP INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        streakCount INTEGER DEFAULT 0,
        lastStudyDate TEXT,
        cardsReviewedToday INTEGER DEFAULT 0,
        cardsMastered INTEGER DEFAULT 0,
        currentStreak INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_flashcards_subject ON flashcards(subject)
    ''');
    await db.execute('''
      CREATE INDEX idx_flashcards_status ON flashcards(status)
    ''');
    await db.execute('''
      CREATE INDEX idx_flashcards_next_review ON flashcards(nextReviewDate)
    ''');

    await db.insert('xp_system', {'id': 1});
  }

  Future<int> insertFlashcard(Flashcard card) async {
    final db = await database;
    return await db.insert('flashcards', card.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertFlashcards(List<Flashcard> cards) async {
    final db = await database;
    final batch = db.batch();
    for (final card in cards) {
      batch.insert('flashcards', card.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Flashcard>> getAllFlashcards() async {
    final db = await database;
    final maps = await db.query('flashcards', orderBy: 'chapterNum ASC, id ASC');
    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> getFlashcardsBySubject(String subject) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'subject = ?',
      whereArgs: [subject],
      orderBy: 'chapterNum ASC, id ASC',
    );
    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> getDueFlashcards({String? subject, int limit = 20}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    String? where;
    List<dynamic>? whereArgs;

    if (subject != null) {
      where = '(nextReviewDate IS NULL OR nextReviewDate <= ?) AND subject = ?';
      whereArgs = [now, subject];
    } else {
      where = 'nextReviewDate IS NULL OR nextReviewDate <= ?';
      whereArgs = [now];
    }

    final maps = await db.query(
      'flashcards',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'status ASC, nextReviewDate ASC',
      limit: limit,
    );
    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> getFlashcardsByDeck(String deckName) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'deckName = ?',
      whereArgs: [deckName],
      orderBy: 'id ASC',
    );
    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> getBookmarkedFlashcards() async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'bookmarked = 1',
      orderBy: 'subject ASC, chapterNum ASC',
    );
    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> searchFlashcards(String query) async {
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'front LIKE ? OR back LIKE ? OR chapter LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      limit: 50,
    );
    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<void> updateFlashcard(Flashcard card) async {
    final db = await database;
    await db.update(
      'flashcards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> toggleBookmark(String cardId) async {
    final db = await database;
    await db.execute(
      'UPDATE flashcards SET bookmarked = CASE WHEN bookmarked = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [cardId],
    );
  }

  Future<List<Deck>> getDecks() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final results = await db.rawQuery('''
      SELECT 
        deckName,
        subject,
        chapterNum,
        COUNT(*) as totalCards,
        SUM(CASE WHEN status = 0 THEN 1 ELSE 0 END) as newCards,
        SUM(CASE WHEN nextReviewDate IS NOT NULL AND nextReviewDate <= ? THEN 1 ELSE 0 END) as dueCards,
        SUM(CASE WHEN status = 3 THEN 1 ELSE 0 END) as masteredCards,
        SUM(CASE WHEN bookmarked = 1 THEN 1 ELSE 0 END) as bookmarkedCards
      FROM flashcards
      GROUP BY deckName
      ORDER BY subject ASC, chapterNum ASC
    ''', [now]);

    return results.map((map) {
      return Deck(
        name: map['deckName'] as String,
        subject: map['subject'] as String,
        chapterNum: map['chapterNum'] as int,
        totalCards: (map['totalCards'] as int?) ?? 0,
        newCards: (map['newCards'] as int?) ?? 0,
        dueCards: (map['dueCards'] as int?) ?? 0,
        masteredCards: (map['masteredCards'] as int?) ?? 0,
        bookmarkedCards: (map['bookmarkedCards'] as int?) ?? 0,
      );
    }).toList();
  }

  Future<int> getDueCount({String? subject}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    String where;
    List<dynamic> whereArgs;

    if (subject != null) {
      where = '(nextReviewDate IS NULL OR nextReviewDate <= ?) AND subject = ?';
      whereArgs = [now, subject];
    } else {
      where = 'nextReviewDate IS NULL OR nextReviewDate <= ?';
      whereArgs = [now];
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE $where',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<XPSystem> getXPSystem() async {
    final db = await database;
    final maps = await db.query('xp_system', where: 'id = 1');
    if (maps.isEmpty) {
      return XPSystem();
    }
    return XPSystem.fromMap(maps.first);
  }

  Future<void> updateXPSystem(XPSystem xp) async {
    final db = await database;
    await db.update('xp_system', xp.toMap(), where: 'id = 1');
  }

  Future<void> addXP(int amount) async {
    final xp = await getXPSystem();
    xp.totalXP += amount;

    while (xp.totalXP >= xp.nextLevelXP) {
      xp.totalXP -= xp.nextLevelXP;
      xp.level++;
    }

    final today = DateTime.now();
    if (xp.lastStudyDate != null) {
      final diff = today.difference(xp.lastStudyDate!).inDays;
      if (diff == 1) {
        xp.currentStreak++;
      } else if (diff > 1) {
        xp.currentStreak = 1;
      }
    } else {
      xp.currentStreak = 1;
    }

    xp.lastStudyDate = today;
    xp.cardsReviewedToday++;
    xp.streakCount = xp.currentStreak > xp.streakCount ? xp.currentStreak : xp.streakCount;

    await updateXPSystem(xp);
  }

  Future<void> seedFromJson(String subject) async {
    final cards = await loadFlashcardsFromJson(subject);
    if (cards.isEmpty) return;

    final db = await database;
    final existing = await db.query('flashcards',
        where: 'subject = ?', whereArgs: [subject], limit: 1);
    if (existing.isNotEmpty) return;

    await insertFlashcards(cards);
  }

  Future<List<Flashcard>> loadFlashcardsFromJson(String subject) async {
    String fileName;
    switch (subject) {
      case 'Physics':
        fileName = 'lib/data/flashcards_physics.json';
        break;
      case 'Chemistry':
        fileName = 'lib/data/flashcards_chemistry.json';
        break;
      case 'Biology':
        fileName = 'lib/data/flashcards_biology.json';
        break;
      default:
        return [];
    }

    try {
      final String jsonString = await rootBundle.loadString(fileName);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList.map((json) {
        final map = json as Map<String, dynamic>;
        return Flashcard(
          id: map['id'] as String,
          subject: map['subject'] as String,
          classNum: map['classNum'] as String,
          chapter: map['chapter'] as String,
          chapterNum: map['chapterNum'] as int,
          type: map['type'] as String,
          front: map['front'] as String,
          back: map['back'] as String,
          ncertRef: map['ncertRef'] as String? ?? '',
          difficulty: map['difficulty'] as String? ?? 'medium',
          tags: (map['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> getCardCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM flashcards')) ?? 0;
  }
}