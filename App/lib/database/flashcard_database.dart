import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/flashcard_model.dart';
import '../models/spaced_repetition_model.dart';

class FlashcardDatabase {
  static Database? _database;
  static final FlashcardDatabase instance = FlashcardDatabase._();

  // In-memory web fallback stores
  final List<Flashcard> _webFlashcards = [];
  XPSystem _webXpSystem = XPSystem();
  final List<Map<String, dynamic>> _webReports = [];

  FlashcardDatabase._();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite database is not supported on web. Use in-memory fallbacks.');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = '${(await getApplicationDocumentsDirectory()).path}/medneet_flashcards.db';
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    await db.execute('''
      CREATE TABLE reports (
        id TEXT PRIMARY KEY,
        cardId TEXT NOT NULL,
        cardFront TEXT NOT NULL,
        reason TEXT NOT NULL,
        comment TEXT,
        reportedBy TEXT NOT NULL,
        reportedAt TEXT NOT NULL,
        status TEXT DEFAULT 'pending'
      )
    ''');

    await db.insert('xp_system', {'id': 1});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE reports (
          id TEXT PRIMARY KEY,
          cardId TEXT NOT NULL,
          cardFront TEXT NOT NULL,
          reason TEXT NOT NULL,
          comment TEXT,
          reportedBy TEXT NOT NULL,
          reportedAt TEXT NOT NULL,
          status TEXT DEFAULT 'pending'
        )
      ''');
    }
  }

  Future<int> insertFlashcard(Flashcard card) async {
    if (kIsWeb) {
      final idx = _webFlashcards.indexWhere((c) => c.id == card.id);
      if (idx != -1) {
        _webFlashcards[idx] = card;
      } else {
        _webFlashcards.add(card);
      }
      return 1;
    }
    final db = await database;
    return await db.insert('flashcards', card.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertFlashcards(List<Flashcard> cards) async {
    if (kIsWeb) {
      for (final card in cards) {
        await insertFlashcard(card);
      }
      return;
    }
    final db = await database;
    final batch = db.batch();
    for (final card in cards) {
      batch.insert('flashcards', card.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Flashcard>> getAllFlashcards() async {
    if (kIsWeb) {
      final list = List<Flashcard>.from(_webFlashcards);
      list.sort((a, b) {
        final comp = a.chapterNum.compareTo(b.chapterNum);
        if (comp != 0) return comp;
        return a.id.compareTo(b.id);
      });
      return list;
    }
    final db = await database;
    final maps = await db.query('flashcards', orderBy: 'chapterNum ASC, id ASC');
    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> getFlashcardsBySubject(String subject) async {
    if (kIsWeb) {
      final list = _webFlashcards.where((c) => c.subject == subject).toList();
      list.sort((a, b) {
        final comp = a.chapterNum.compareTo(b.chapterNum);
        if (comp != 0) return comp;
        return a.id.compareTo(b.id);
      });
      return list;
    }
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
    if (kIsWeb) {
      final nowStr = DateTime.now().toIso8601String();
      final list = _webFlashcards.where((c) {
        final isDue = c.nextReviewDate == null || c.nextReviewDate!.toIso8601String().compareTo(nowStr) <= 0;
        if (subject != null) {
          return isDue && c.subject == subject;
        }
        return isDue;
      }).toList();
      list.sort((a, b) {
        final statusComp = a.status.compareTo(b.status);
        if (statusComp != 0) return statusComp;
        if (a.nextReviewDate == null && b.nextReviewDate == null) return 0;
        if (a.nextReviewDate == null) return -1;
        if (b.nextReviewDate == null) return 1;
        return a.nextReviewDate!.compareTo(b.nextReviewDate!);
      });
      return list.take(limit).toList();
    }

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
    if (kIsWeb) {
      return _webFlashcards.where((c) => c.deckName == deckName).toList();
    }
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
    if (kIsWeb) {
      final list = _webFlashcards.where((c) => c.bookmarked).toList();
      list.sort((a, b) {
        final comp = a.subject.compareTo(b.subject);
        if (comp != 0) return comp;
        return a.chapterNum.compareTo(b.chapterNum);
      });
      return list;
    }
    final db = await database;
    final maps = await db.query(
      'flashcards',
      where: 'bookmarked = 1',
      orderBy: 'subject ASC, chapterNum ASC',
    );
    return maps.map((map) => Flashcard.fromMap(map)).toList();
  }

  Future<List<Flashcard>> searchFlashcards(String query) async {
    if (kIsWeb) {
      final q = query.toLowerCase();
      return _webFlashcards.where((c) {
        return c.front.toLowerCase().contains(q) ||
               c.back.toLowerCase().contains(q) ||
               c.chapter.toLowerCase().contains(q);
      }).take(50).toList();
    }
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
    if (kIsWeb) {
      final idx = _webFlashcards.indexWhere((c) => c.id == card.id);
      if (idx != -1) {
        _webFlashcards[idx] = card;
      }
      return;
    }
    final db = await database;
    await db.update(
      'flashcards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> toggleBookmark(String cardId) async {
    if (kIsWeb) {
      final idx = _webFlashcards.indexWhere((c) => c.id == cardId);
      if (idx != -1) {
        final card = _webFlashcards[idx];
        _webFlashcards[idx] = card.copyWith(bookmarked: !card.bookmarked);
      }
      return;
    }
    final db = await database;
    await db.execute(
      'UPDATE flashcards SET bookmarked = CASE WHEN bookmarked = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [cardId],
    );
  }

  Future<List<Deck>> getDecks() async {
    if (kIsWeb) {
      final nowStr = DateTime.now().toIso8601String();
      final decksMap = <String, Map<String, dynamic>>{};
      for (final card in _webFlashcards) {
        final name = card.deckName;
        if (!decksMap.containsKey(name)) {
          decksMap[name] = {
            'deckName': name,
            'subject': card.subject,
            'chapterNum': card.chapterNum,
            'totalCards': 0,
            'newCards': 0,
            'dueCards': 0,
            'masteredCards': 0,
            'bookmarkedCards': 0,
          };
        }
        final map = decksMap[name]!;
        map['totalCards'] = (map['totalCards'] as int) + 1;
        if (card.status == 0) {
          map['newCards'] = (map['newCards'] as int) + 1;
        }
        if (card.nextReviewDate != null && card.nextReviewDate!.toIso8601String().compareTo(nowStr) <= 0) {
          map['dueCards'] = (map['dueCards'] as int) + 1;
        }
        if (card.status == 3) {
          map['masteredCards'] = (map['masteredCards'] as int) + 1;
        }
        if (card.bookmarked) {
          map['bookmarkedCards'] = (map['bookmarkedCards'] as int) + 1;
        }
      }
      final List<Deck> decks = decksMap.values.map((map) {
        return Deck(
          name: map['deckName'] as String,
          subject: map['subject'] as String,
          chapterNum: map['chapterNum'] as int,
          totalCards: map['totalCards'] as int,
          newCards: map['newCards'] as int,
          dueCards: map['dueCards'] as int,
          masteredCards: map['masteredCards'] as int,
          bookmarkedCards: map['bookmarkedCards'] as int,
        );
      }).toList();
      decks.sort((a, b) {
        final subjectComp = a.subject.compareTo(b.subject);
        if (subjectComp != 0) return subjectComp;
        return a.chapterNum.compareTo(b.chapterNum);
      });
      return decks;
    }

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
    if (kIsWeb) {
      final nowStr = DateTime.now().toIso8601String();
      return _webFlashcards.where((c) {
        final isDue = c.nextReviewDate == null || c.nextReviewDate!.toIso8601String().compareTo(nowStr) <= 0;
        if (subject != null) {
          return isDue && c.subject == subject;
        }
        return isDue;
      }).length;
    }

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
    if (kIsWeb) {
      return _webXpSystem;
    }
    final db = await database;
    final maps = await db.query('xp_system', where: 'id = 1');
    if (maps.isEmpty) {
      return XPSystem();
    }
    return XPSystem.fromMap(maps.first);
  }

  Future<void> updateXPSystem(XPSystem xp) async {
    if (kIsWeb) {
      _webXpSystem = xp;
      return;
    }
    final db = await database;
    await db.update('xp_system', xp.toMap(), where: 'id = 1');
  }

  Future<void> addXP(int amount) async {
    if (kIsWeb) {
      final xp = _webXpSystem;
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
      _webXpSystem = xp;
      return;
    }

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
    if (kIsWeb) {
      final existing = _webFlashcards.any((c) => c.subject == subject);
      if (existing) return;
      final cards = await loadFlashcardsFromJson(subject);
      _webFlashcards.addAll(cards);
      return;
    }

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
    if (kIsWeb) {
      return _webFlashcards.length;
    }
    final db = await database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM flashcards')) ?? 0;
  }

  // Admin and Report support methods
  Future<void> deleteFlashcard(String cardId) async {
    if (kIsWeb) {
      _webFlashcards.removeWhere((c) => c.id == cardId);
      _webReports.removeWhere((r) => r['cardId'] == cardId);
      return;
    }
    final db = await database;
    await db.delete('flashcards', where: 'id = ?', whereArgs: [cardId]);
    await db.delete('reports', where: 'cardId = ?', whereArgs: [cardId]);
  }

  Future<void> insertReport(Map<String, dynamic> report) async {
    if (kIsWeb) {
      _webReports.add(report);
      return;
    }
    final db = await database;
    await db.insert('reports', report, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllReports() async {
    if (kIsWeb) {
      return List<Map<String, dynamic>>.from(_webReports);
    }
    final db = await database;
    return await db.query('reports', orderBy: 'reportedAt DESC');
  }

  Future<void> deleteReport(String reportId) async {
    if (kIsWeb) {
      _webReports.removeWhere((r) => r['id'] == reportId);
      return;
    }
    final db = await database;
    await db.delete('reports', where: 'id = ?', whereArgs: [reportId]);
  }
}