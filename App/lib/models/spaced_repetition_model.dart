import 'flashcard_model.dart';

class SM2Algorithm {
  /// Implements the SM-2 algorithm for spaced repetition.
  /// Returns updated Flashcard with new scheduling.
  /// quality: 0=Again(complete blackout), 1=Hard, 2=Good, 3=Easy
  static Flashcard applyReview(Flashcard card, int quality) {
    if (quality < 0 || quality > 3) {
      throw ArgumentError('Quality must be between 0 and 3');
    }

    double newEaseFactor = card.easeFactor;
    int newInterval = card.interval;
    int newRepetitions = card.repetitions;
    int newStatus = card.status;

    if (quality < 2) {
      // Failed recall - reset
      newRepetitions = 0;
      newInterval = 1;
      newStatus = 1; // learning
    } else {
      // Successful recall
      switch (newRepetitions) {
        case 0:
          newInterval = 1;
          break;
        case 1:
          newInterval = 3;
          break;
        default:
          newInterval = (card.interval * newEaseFactor).round();
          break;
      }
      newRepetitions++;
      if (newStatus < 2) newStatus = 2; // review
    }

    // Update ease factor
    newEaseFactor = newEaseFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEaseFactor < 1.3) {
      newEaseFactor = 1.3;
    }

    // Check for mastered (interval >= 30 days and repetitions >= 5)
    if (newInterval >= 30 && newRepetitions >= 5) {
      newStatus = 3; // mastered
    }

    final now = DateTime.now();
    return card.copyWith(
      interval: newInterval,
      repetitions: newRepetitions,
      easeFactor: newEaseFactor,
      nextReviewDate: now.add(Duration(days: newInterval)),
      lastReviewDate: now,
      status: newStatus,
      timesReviewed: card.timesReviewed + 1,
      timesCorrect: quality >= 2 ? card.timesCorrect + 1 : card.timesCorrect,
    );
  }

  /// Calculate the XP earned from a review
  static int calculateXP(Flashcard card, int quality) {
    int baseXP = 2; // base for any review
    switch (quality) {
      case 0: // Again
        return baseXP;
      case 1: // Hard
        return baseXP + 2;
      case 2: // Good
        return baseXP + 5;
      case 3: // Easy
        return baseXP + 10;
      default:
        return baseXP;
    }
  }

  /// Percentage progress for a card
  static double cardProgress(Flashcard card) {
    if (card.status == 3) return 1.0;
    if (card.status == 0) return 0.0;
    if (card.repetitions == 0) return 0.1;
    return (card.repetitions / 5.0).clamp(0.1, 0.9);
  }
}

class XPSystem {
  int totalXP;
  int level;
  int xpToNextLevel;
  int streakCount;
  DateTime? lastStudyDate;
  int cardsReviewedToday;
  int cardsMastered;
  int currentStreak;

  XPSystem({
    this.totalXP = 0,
    this.level = 1,
    this.xpToNextLevel = 100,
    this.streakCount = 0,
    this.lastStudyDate,
    this.cardsReviewedToday = 0,
    this.cardsMastered = 0,
    this.currentStreak = 0,
  });

  static const int xpPerLevel = 500;

  int get nextLevelXP => level * xpPerLevel;
  double get levelProgress => totalXP / nextLevelXP;

  Map<String, dynamic> toMap() {
    return {
      'totalXP': totalXP,
      'level': level,
      'streakCount': streakCount,
      'lastStudyDate': lastStudyDate?.toIso8601String(),
      'cardsReviewedToday': cardsReviewedToday,
      'cardsMastered': cardsMastered,
      'currentStreak': currentStreak,
    };
  }

  factory XPSystem.fromMap(Map<String, dynamic> map) {
    return XPSystem(
      totalXP: map['totalXP'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      streakCount: map['streakCount'] as int? ?? 0,
      lastStudyDate: map['lastStudyDate'] != null ? DateTime.parse(map['lastStudyDate'] as String) : null,
      cardsReviewedToday: map['cardsReviewedToday'] as int? ?? 0,
      cardsMastered: map['cardsMastered'] as int? ?? 0,
      currentStreak: map['currentStreak'] as int? ?? 0,
    );
  }
}