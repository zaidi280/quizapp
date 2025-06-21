import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utlis/global.color.dart';
import 'dart:math' as math;

// Translation function
Future<String> translateText(String text, String targetLang) async {
  // Define static translations for common UI elements
  final Map<String, Map<String, String>> staticTranslations = {
    "en": {
      "Leaderboard": "Leaderboard",
      "My Best Scores": "My Best Scores",
      "All Quiz Results": "All Quiz Results",
      "Category": "Category",
      "Difficulty": "Difficulty",
      "Best Score": "Best Score",
      "Total Quizzes": "Total Quizzes",
      "Average Score": "Average Score",
      "Perfect Scores": "Perfect Scores",
      "No scores yet": "No scores yet",
      "Start taking quizzes to see your scores here!":
          "Start taking quizzes to see your scores here!",
      "Easy": "Easy",
      "Medium": "Medium",
      "Hard": "Hard",
      "Excellent": "Excellent",
      "Good": "Good",
      "Needs Improvement": "Needs Improvement",
      "Performance": "Performance",
      "Statistics": "Statistics",
      "Achievement": "Achievement",
      "Quiz Master": "Quiz Master",
      "Knowledge Seeker": "Knowledge Seeker",
      "Beginner": "Beginner",
      "Loading Scores...": "Loading Scores...",
    },
    "fr": {
      "Leaderboard": "Classement",
      "My Best Scores": "Mes Meilleurs Scores",
      "All Quiz Results": "Tous les Résultats de Quiz",
      "Category": "Catégorie",
      "Difficulty": "Difficulté",
      "Best Score": "Meilleur Score",
      "Total Quizzes": "Total Quiz",
      "Average Score": "Score Moyen",
      "Perfect Scores": "Scores Parfaits",
      "No scores yet": "Aucun score pour le moment",
      "Start taking quizzes to see your scores here!":
          "Commencez à faire des quiz pour voir vos scores ici!",
      "Easy": "Facile",
      "Medium": "Moyen",
      "Hard": "Difficile",
      "Excellent": "Excellent",
      "Good": "Bien",
      "Needs Improvement": "À améliorer",
      "Performance": "Performance",
      "Statistics": "Statistiques",
      "Achievement": "Réussite",
      "Quiz Master": "Maître du Quiz",
      "Knowledge Seeker": "Chercheur de Connaissances",
      "Beginner": "Débutant",
      "Loading Scores...": "Chargement des scores...",
    },
    "ar": {
      "Leaderboard": "لوحة المتصدرين",
      "My Best Scores": "أفضل نتائجي",
      "All Quiz Results": "جميع نتائج الاختبارات",
      "Category": "الفئة",
      "Difficulty": "الصعوبة",
      "Best Score": "أفضل نتيجة",
      "Total Quizzes": "إجمالي الاختبارات",
      "Average Score": "متوسط النتيجة",
      "Perfect Scores": "النتائج المثالية",
      "No scores yet": "لا توجد نتائج بعد",
      "Start taking quizzes to see your scores here!":
          "ابدأ في إجراء الاختبارات لرؤية نتائجك هنا!",
      "Easy": "سهل",
      "Medium": "متوسط",
      "Hard": "صعب",
      "Excellent": "ممتاز",
      "Good": "جيد",
      "Needs Improvement": "يحتاج تحسين",
      "Performance": "الأداء",
      "Statistics": "الإحصائيات",
      "Achievement": "الإنجاز",
      "Quiz Master": "خبير الاختبارات",
      "Knowledge Seeker": "باحث المعرفة",
      "Beginner": "مبتدئ",
      "Loading Scores...": "تحميل النتائج...",
    }
  };

  // Check if we have a static translation
  if (staticTranslations.containsKey(targetLang) &&
      staticTranslations[targetLang]!.containsKey(text)) {
    return staticTranslations[targetLang]![text]!;
  }

  // Return original text if no translation found
  return text;
}

// Score data model
class QuizScore {
  final String category;
  final String difficulty;
  final int score;
  final int totalQuestions;

  QuizScore({
    required this.category,
    required this.difficulty,
    required this.score,
    this.totalQuestions = 10, // Default assumption
  });

  double get percentage =>
      totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;

  String get performanceLevel {
    if (percentage >= 90) return "Excellent";
    if (percentage >= 70) return "Good";
    return "Needs Improvement";
  }

  Color get performanceColor {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }
}

class LeaderboardScreen extends StatefulWidget {
  final String category;
  final String difficulty;
  final String language;

  const LeaderboardScreen({
    super.key,
    required this.category,
    required this.difficulty,
    this.language = "fr",
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  List<QuizScore> allScores = [];
  bool isLoading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _loadAllScores();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadAllScores() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    List<QuizScore> scores = [];

    // Get all keys from SharedPreferences
    Set<String> keys = prefs.getKeys();

    // Filter keys that match the score pattern: "category_difficulty_score"
    for (String key in keys) {
      if (key.endsWith('_score') && key.split('_').length >= 3) {
        List<String> parts = key.split('_');
        if (parts.length >= 3) {
          // Remove '_score' from the end and reconstruct category and difficulty
          String scoreKey = parts.removeLast(); // Remove 'score'
          if (scoreKey == 'score') {
            String difficulty = parts.removeLast();
            String category =
                parts.join('_'); // In case category has underscores

            int score = prefs.getInt(key) ?? 0;
            if (score > 0) {
              // Only include scores greater than 0
              scores.add(QuizScore(
                category: category,
                difficulty: difficulty,
                score: score,
                totalQuestions: 10, // Assuming 10 questions per quiz
              ));
            }
          }
        }
      }
    }

    // Sort scores by performance (highest percentage first)
    scores.sort((a, b) => b.percentage.compareTo(a.percentage));

    setState(() {
      allScores = scores;
      isLoading = false;
    });

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: GlobalColor.getGradientColors(context),
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? _buildLoadingState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        if (allScores.isEmpty)
                          _buildEmptyState()
                        else ...[
                          _buildStatisticsCard(),
                          const SizedBox(height: 20),
                          _buildScoresList(),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GlobalColor.getCardBackgroundColor(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: GlobalColor.getShadowColor(context),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(GlobalColor.mainColor),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                FutureBuilder<String>(
                  future: translateText("Loading Scores...", widget.language),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? 'Chargement des scores...',
                    style: TextStyle(
                      fontSize: 16,
                      color: GlobalColor.getTextPrimaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GlobalColor.getCardBackgroundColor(context),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: GlobalColor.getShadowColor(context),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: GlobalColor.mainColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: translateText("Leaderboard", widget.language),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Leaderboard",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: GlobalColor.mainColor,
                    ),
                  ),
                ),
                FutureBuilder<String>(
                  future: translateText("My Best Scores", widget.language),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "My Best Scores",
                    style: TextStyle(
                      fontSize: 14,
                      color: GlobalColor.getTextSecondaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: GlobalColor.mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: GlobalColor.mainColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  "${allScores.length}",
                  style: TextStyle(
                    fontSize: 14,
                    color: GlobalColor.mainColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: GlobalColor.mainColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 50,
                color: GlobalColor.mainColor,
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<String>(
              future: translateText("No scores yet", widget.language),
              builder: (context, snapshot) => Text(
                snapshot.data ?? "No scores yet",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: GlobalColor.textColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<String>(
              future: translateText(
                  "Start taking quizzes to see your scores here!",
                  widget.language),
              builder: (context, snapshot) => Text(
                snapshot.data ??
                    "Start taking quizzes to see your scores here!",
                style: TextStyle(
                  fontSize: 14,
                  color: GlobalColor.textColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (allScores.isEmpty) return const SizedBox.shrink();

    // Calculate statistics
    double totalPercentage =
        allScores.fold(0, (sum, score) => sum + score.percentage);
    double averagePercentage = totalPercentage / allScores.length;
    int perfectScores =
        allScores.where((score) => score.percentage == 100).length;
    int excellentScores =
        allScores.where((score) => score.percentage >= 90).length;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: GlobalColor.mainColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                FutureBuilder<String>(
                  future: translateText("Statistics", widget.language),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Statistics",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: GlobalColor.textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    "Total Quizzes",
                    "${allScores.length}",
                    Icons.quiz,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    "Average Score",
                    "${averagePercentage.round()}%",
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    "Perfect Scores",
                    "$perfectScores",
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    "Excellent",
                    "$excellentScores",
                    Icons.star,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Achievement Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    GlobalColor.mainColor.withOpacity(0.1),
                    GlobalColor.mainColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: GlobalColor.mainColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getAchievementIcon(),
                    color: GlobalColor.mainColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: translateText("Achievement", widget.language),
                          builder: (context, snapshot) => Text(
                            snapshot.data ?? "Achievement",
                            style: TextStyle(
                              fontSize: 12,
                              color: GlobalColor.textColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                        FutureBuilder<String>(
                          future: translateText(
                              _getAchievementLevel(), widget.language),
                          builder: (context, snapshot) => Text(
                            snapshot.data ?? _getAchievementLevel(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: GlobalColor.mainColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: translateText(label, widget.language),
            builder: (context, snapshot) => Text(
              snapshot.data ?? label,
              style: TextStyle(
                fontSize: 12,
                color: GlobalColor.textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAchievementIcon() {
    if (allScores.length >= 10) return Icons.emoji_events;
    if (allScores.length >= 5) return Icons.star;
    return Icons.local_fire_department;
  }

  String _getAchievementLevel() {
    if (allScores.length >= 10) return "Quiz Master";
    if (allScores.length >= 5) return "Knowledge Seeker";
    return "Beginner";
  }

  Widget _buildScoresList() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    color: GlobalColor.mainColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  FutureBuilder<String>(
                    future: translateText("All Quiz Results", widget.language),
                    builder: (context, snapshot) => Text(
                      snapshot.data ?? "All Quiz Results",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GlobalColor.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allScores.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey[200],
                height: 1,
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) {
                final score = allScores[index];
                return _buildScoreItem(score, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(QuizScore score, int index) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getRankColors(index),
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Score Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatCategoryName(score.category),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: GlobalColor.textColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(score.difficulty)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getDifficultyColor(score.difficulty)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: FutureBuilder<String>(
                        future: translateText(
                            _formatDifficultyName(score.difficulty),
                            widget.language),
                        builder: (context, snapshot) => Text(
                          snapshot.data ??
                              _formatDifficultyName(score.difficulty),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getDifficultyColor(score.difficulty),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    // Score Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: score.performanceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${score.score}/${score.totalQuestions}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: score.performanceColor,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Percentage
                    Text(
                      "${score.percentage.round()}%",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: score.performanceColor,
                      ),
                    ),

                    const Spacer(),

                    // Performance Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: score.performanceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FutureBuilder<String>(
                        future: translateText(
                            score.performanceLevel, widget.language),
                        builder: (context, snapshot) => Text(
                          snapshot.data ?? score.performanceLevel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score.percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(score.performanceColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getRankColors(int index) {
    if (index == 0) return [Colors.amber[400]!, Colors.amber[600]!]; // Gold
    if (index == 1) return [Colors.grey[400]!, Colors.grey[600]!]; // Silver
    if (index == 2) return [Colors.brown[400]!, Colors.brown[600]!]; // Bronze
    return [GlobalColor.mainColor.withOpacity(0.7), GlobalColor.mainColor];
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return GlobalColor.mainColor;
    }
  }

  String _formatCategoryName(String category) {
    // Capitalize first letter and replace underscores with spaces
    return category
        .split('_')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }

  String _formatDifficultyName(String difficulty) {
    return difficulty[0].toUpperCase() + difficulty.substring(1).toLowerCase();
  }
}
