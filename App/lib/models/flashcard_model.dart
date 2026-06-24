class Flashcard {
  final String id;
  final String subject; // Physics, Chemistry, Biology
  final String classNum; // 11 or 12
  final String chapter;
  final int chapterNum;
  final String type; // concept, formula, recall
  final String front;
  final String back;
  final String ncertRef;
  final String difficulty; // easy, medium, hard
  final List<String> tags;
  final String deckName;

  // SM-2 fields
  int interval; // days
  int repetitions; // number of consecutive correct responses
  double easeFactor; // starting at 2.5
  DateTime? nextReviewDate;
  DateTime? lastReviewDate;
  int status; // 0=new, 1=learning, 2=review, 3=mastered

  // XP tracking
  int timesReviewed;
  int timesCorrect;
  bool bookmarked;

  Flashcard({
    required this.id,
    required this.subject,
    required this.classNum,
    required this.chapter,
    required this.chapterNum,
    required this.type,
    required this.front,
    required this.back,
    required this.ncertRef,
    this.difficulty = 'medium',
    this.tags = const [],
    String? deckName,
    this.interval = 0,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.nextReviewDate,
    this.lastReviewDate,
    this.status = 0,
    this.timesReviewed = 0,
    this.timesCorrect = 0,
    this.bookmarked = false,
  }) : deckName = deckName ?? chapter;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'classNum': classNum,
      'chapter': chapter,
      'chapterNum': chapterNum,
      'type': type,
      'front': front,
      'back': back,
      'ncertRef': ncertRef,
      'difficulty': difficulty,
      'tags': tags.join(','),
      'deckName': deckName,
      'interval': interval,
      'repetitions': repetitions,
      'easeFactor': easeFactor,
      'nextReviewDate': nextReviewDate?.toIso8601String(),
      'lastReviewDate': lastReviewDate?.toIso8601String(),
      'status': status,
      'timesReviewed': timesReviewed,
      'timesCorrect': timesCorrect,
      'bookmarked': bookmarked ? 1 : 0,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as String,
      subject: map['subject'] as String,
      classNum: map['classNum'] as String,
      chapter: map['chapter'] as String,
      chapterNum: map['chapterNum'] as int,
      type: map['type'] as String,
      front: map['front'] as String,
      back: map['back'] as String,
      ncertRef: map['ncertRef'] as String,
      difficulty: map['difficulty'] as String? ?? 'medium',
      tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
      deckName: map['deckName'] as String?,
      interval: map['interval'] as int? ?? 0,
      repetitions: map['repetitions'] as int? ?? 0,
      easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
      nextReviewDate: map['nextReviewDate'] != null ? DateTime.parse(map['nextReviewDate'] as String) : null,
      lastReviewDate: map['lastReviewDate'] != null ? DateTime.parse(map['lastReviewDate'] as String) : null,
      status: map['status'] as int? ?? 0,
      timesReviewed: map['timesReviewed'] as int? ?? 0,
      timesCorrect: map['timesCorrect'] as int? ?? 0,
      bookmarked: (map['bookmarked'] as int?) == 1,
    );
  }

  Flashcard copyWith({
    String? subject,
    String? classNum,
    String? chapter,
    int? chapterNum,
    String? type,
    String? front,
    String? back,
    String? ncertRef,
    String? difficulty,
    List<String>? tags,
    String? deckName,
    int? interval,
    int? repetitions,
    double? easeFactor,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
    int? status,
    int? timesReviewed,
    int? timesCorrect,
    bool? bookmarked,
  }) {
    return Flashcard(
      id: id,
      subject: subject ?? this.subject,
      classNum: classNum ?? this.classNum,
      chapter: chapter ?? this.chapter,
      chapterNum: chapterNum ?? this.chapterNum,
      type: type ?? this.type,
      front: front ?? this.front,
      back: back ?? this.back,
      ncertRef: ncertRef ?? this.ncertRef,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      deckName: deckName ?? this.deckName,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      status: status ?? this.status,
      timesReviewed: timesReviewed ?? this.timesReviewed,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      bookmarked: bookmarked ?? this.bookmarked,
    );
  }

  String get subjectEmoji {
    switch (subject) {
      case 'Physics':
        return '⚡';
      case 'Chemistry':
        return '🧪';
      case 'Biology':
        return '🧬';
      default:
        return '📚';
    }
  }

  String get typeLabel {
    switch (type) {
      case 'concept':
        return 'Concept';
      case 'formula':
        return 'Formula';
      case 'recall':
        return 'Quick Recall';
      default:
        return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 0:
        return 'New';
      case 1:
        return 'Learning';
      case 2:
        return 'Review';
      case 3:
        return 'Mastered';
      default:
        return 'New';
    }
  }
}

class Deck {
  final String name;
  final String subject;
  final int chapterNum;
  final int totalCards;
  final int newCards;
  final int dueCards;
  final int masteredCards;
  final int bookmarkedCards;

  Deck({
    required this.name,
    required this.subject,
    required this.chapterNum,
    required this.totalCards,
    required this.newCards,
    required this.dueCards,
    required this.masteredCards,
    this.bookmarkedCards = 0,
  });

  double get progress => totalCards > 0 ? masteredCards / totalCards : 0.0;
}