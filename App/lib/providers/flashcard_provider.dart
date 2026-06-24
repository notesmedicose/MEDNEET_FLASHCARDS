import 'package:flutter/material.dart';
import '../database/flashcard_database.dart';
import '../models/flashcard_model.dart';
import '../models/spaced_repetition_model.dart';

class FlashcardProvider extends ChangeNotifier {
  final FlashcardDatabase _db = FlashcardDatabase.instance;

  List<Deck> _decks = [];
  List<Flashcard> _currentCards = [];
  Flashcard? _currentCard;
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isFlipped = false;
  String _selectedSubject = 'All';
  String _searchQuery = '';
  XPSystem _xpSystem = XPSystem();
  bool _isInitialized = false;
  bool _showConfetti = false;
  int _lastXpGained = 0;

  // Getters
  List<Deck> get decks => _decks;
  List<Flashcard> get currentCards => _currentCards;
  Flashcard? get currentCard => _currentCard;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get isFlipped => _isFlipped;
  String get selectedSubject => _selectedSubject;
  String get searchQuery => _searchQuery;
  XPSystem get xpSystem => _xpSystem;
  bool get isInitialized => _isInitialized;
  bool get showConfetti => _showConfetti;
  int get lastXpGained => _lastXpGained;
  bool get hasMoreCards => _currentIndex < _currentCards.length;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Seed data from JSON if needed
      await _db.seedFromJson('Physics');
      await _db.seedFromJson('Chemistry');
      await _db.seedFromJson('Biology');

      _xpSystem = await _db.getXPSystem();
      await loadDecks();
      _isInitialized = true;
    } catch (e) {
      print('Initialization error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDecks() async {
    _decks = await _db.getDecks();
    notifyListeners();
  }

  Future<void> setSubject(String subject) async {
    _selectedSubject = subject;
    await loadDecks();
    notifyListeners();
  }

  Future<void> loadDueCards() async {
    _isLoading = true;
    notifyListeners();

    _currentCards = await _db.getDueFlashcards(
      subject: _selectedSubject == 'All' ? null : _selectedSubject,
      limit: 50,
    );

    _currentIndex = 0;
    _isFlipped = false;
    _currentCard = _currentCards.isNotEmpty ? _currentCards[0] : null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDeckCards(String deckName) async {
    _isLoading = true;
    notifyListeners();

    _currentCards = await _db.getFlashcardsByDeck(deckName);
    _currentIndex = 0;
    _isFlipped = false;
    _currentCard = _currentCards.isNotEmpty ? _currentCards[0] : null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadBookmarkedCards() async {
    _isLoading = true;
    notifyListeners();

    _currentCards = await _db.getBookmarkedFlashcards();
    _currentIndex = 0;
    _isFlipped = false;
    _currentCard = _currentCards.isNotEmpty ? _currentCards[0] : null;
    _isLoading = false;
    notifyListeners();
  }

  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  Future<void> reviewCard(int quality) async {
    if (_currentCard == null) return;

    // Apply SM-2 algorithm
    final updatedCard = SM2Algorithm.applyReview(_currentCard!, quality);
    await _db.updateFlashcard(updatedCard);

    // Calculate and add XP
    final xpGained = SM2Algorithm.calculateXP(_currentCard!, quality);
    await _db.addXP(xpGained);
    _lastXpGained = xpGained;
    _xpSystem = await _db.getXPSystem();

    // Show confetti for good/easy reviews
    if (quality >= 2) {
      _showConfetti = true;
    }

    // Move to next card
    _currentIndex++;
    _isFlipped = false;

    if (_currentIndex < _currentCards.length) {
      _currentCard = _currentCards[_currentIndex];
    } else {
      _currentCard = null;
    }

    notifyListeners();

    // Auto-hide confetti
    if (_showConfetti) {
      Future.delayed(const Duration(seconds: 2), () {
        _showConfetti = false;
        notifyListeners();
      });
    }

    await loadDecks(); // Refresh deck stats
  }

  Future<void> toggleBookmark([String? cardId]) async {
    final targetId = cardId ?? _currentCard?.id;
    if (targetId == null) return;
    await _db.toggleBookmark(targetId);
    
    // Update local provider state so UI updates immediately
    final index = _currentCards.indexWhere((c) => c.id == targetId);
    if (index != -1) {
      _currentCards[index] = _currentCards[index].copyWith(bookmarked: !_currentCards[index].bookmarked);
    }
    
    if (_currentCard?.id == targetId) {
      _currentCard = _currentCard!.copyWith(bookmarked: !_currentCard!.bookmarked);
    }

    await loadDecks();
    notifyListeners();
  }

  bool get isCurrentCardBookmarked {
    if (_currentCard == null) return false;
    return _currentCards
        .firstWhere((c) => c.id == _currentCard!.id,
            orElse: () => _currentCard!)
        .bookmarked;
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      await loadDueCards();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _currentCards = await _db.searchFlashcards(query);
    _currentIndex = 0;
    _isFlipped = false;
    _currentCard = _currentCards.isNotEmpty ? _currentCards[0] : null;
    _isLoading = false;
    notifyListeners();
  }

  int getDueCountForSubject(String subject) {
    return _decks
        .where((d) => d.subject == subject)
        .fold(0, (sum, deck) => sum + deck.dueCards + deck.newCards);
  }

  int getTotalCards() {
    return _decks.fold(0, (sum, d) => sum + d.totalCards);
  }

  int getMasteredCards() {
    return _decks.fold(0, (sum, d) => sum + d.masteredCards);
  }

  double get overallProgress {
    final total = getTotalCards();
    if (total == 0) return 0.0;
    return getMasteredCards() / total;
  }

  void resetConfetti() {
    _showConfetti = false;
    notifyListeners();
  }

  Future<void> addOrUpdateCard(Flashcard card) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.insertFlashcard(card);
      await loadDecks();
      // Reload current cards if we are currently looking at a deck
      if (_currentCards.isNotEmpty) {
        final firstCard = _currentCards.first;
        if (firstCard.deckName == card.deckName || firstCard.subject == card.subject) {
          await loadDeckCards(firstCard.deckName);
        }
      }
    } catch (e) {
      debugPrint('Error adding/updating card: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteCard(String cardId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _db.deleteFlashcard(cardId);
      await loadDecks();
      // Remove from current local lists
      _currentCards.removeWhere((c) => c.id == cardId);
      if (_currentCard?.id == cardId) {
        if (_currentIndex < _currentCards.length) {
          _currentCard = _currentCards[_currentIndex];
        } else {
          _currentIndex = _currentCards.isNotEmpty ? _currentCards.length - 1 : 0;
          _currentCard = _currentCards.isNotEmpty ? _currentCards[_currentIndex] : null;
        }
      }
    } catch (e) {
      debugPrint('Error deleting card: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitReport({
    required String cardId,
    required String cardFront,
    required String reason,
    required String comment,
    required String reportedBy,
  }) async {
    final report = {
      'id': 'rep_${DateTime.now().millisecondsSinceEpoch}_${cardId.hashCode}',
      'cardId': cardId,
      'cardFront': cardFront,
      'reason': reason,
      'comment': comment,
      'reportedBy': reportedBy,
      'reportedAt': DateTime.now().toIso8601String(),
      'status': 'pending',
    };
    await _db.insertReport(report);
  }

  Future<List<Map<String, dynamic>>> loadReports() async {
    return await _db.getAllReports();
  }

  Future<void> resolveReport(String reportId) async {
    await _db.deleteReport(reportId);
    notifyListeners();
  }
}