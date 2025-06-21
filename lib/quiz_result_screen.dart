import 'package:flutter/material.dart';
import 'package:quizds/home.page.dart';
import 'package:quizds/quiz_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utlis/global.color.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Translation function using MyMemory API
Future<String> translateText(String text, String targetLang) async {
  // Define static translations for common UI elements
  final Map<String, Map<String, String>> staticTranslations = {
    "en": {
      "Quiz Results": "Quiz Results",
      "Score: ": "Score: ",
      "Perfect! You got everything right!":
          "Perfect! You got everything right!",
      "Well done! You have a good score.": "Well done! You have a good score.",
      "You can do better. Try again!": "You can do better. Try again!",
      "Answer Details": "Answer Details",
      "Your answer: ": "Your answer: ",
      "Correct answer: ": "Correct answer: ",
      "Back to Home": "Back to Home",
      "Try Again": "Try Again",
      "Performance": "Performance",
      "Accuracy": "Accuracy",
      "Questions Answered": "Questions Answered",
      "Excellent": "Excellent",
      "Good": "Good",
      "Needs Improvement": "Needs Improvement",
      "Performance Summary": "Performance Summary",
      "Correct Answers": "Correct Answers",
      "Question": "Question",
    },
    "fr": {
      "Quiz Results": "Résultats du Quiz",
      "Score: ": "Score: ",
      "Perfect! You got everything right!": "Parfait ! Vous avez tout réussi !",
      "Well done! You have a good score.":
          "Bien joué ! Vous avez un bon score.",
      "You can do better. Try again!":
          "Vous pouvez faire mieux. Essayez encore !",
      "Answer Details": "Détails des réponses",
      "Your answer: ": "Votre réponse: ",
      "Correct answer: ": "Réponse correcte: ",
      "Back to Home": "Retour à l'accueil",
      "Try Again": "Réessayer",
      "Performance": "Performance",
      "Accuracy": "Précision",
      "Questions Answered": "Questions répondues",
      "Excellent": "Excellent",
      "Good": "Bien",
      "Needs Improvement": "À améliorer",
      "Performance Summary": "Résumé des performances",
      "Correct Answers": "Réponses correctes",
      "Question": "Question",
    },
    "ar": {
      "Quiz Results": "نتائج الاختبار",
      "Score: ": "النتيجة: ",
      "Perfect! You got everything right!":
          "مثالي! لقد أجبت على كل شيء بشكل صحيح!",
      "Well done! You have a good score.": "أحسنت! لديك نتيجة جيدة.",
      "You can do better. Try again!": "يمكنك أن تفعل أفضل. حاول مرة أخرى!",
      "Answer Details": "تفاصيل الإجابات",
      "Your answer: ": "إجابتك: ",
      "Correct answer: ": "الإجابة الصحيحة: ",
      "Back to Home": "العودة للرئيسية",
      "Try Again": "حاول مرة أخرى",
      "Performance": "الأداء",
      "Accuracy": "الدقة",
      "Questions Answered": "الأسئلة المجابة",
      "Excellent": "ممتاز",
      "Good": "جيد",
      "Needs Improvement": "يحتاج تحسين",
      "Performance Summary": "ملخص الأداء",
      "Correct Answers": "الإجابات الصحيحة",
      "Question": "سؤال",
    }
  };

  // Check if we have a static translation
  if (staticTranslations.containsKey(targetLang) &&
      staticTranslations[targetLang]!.containsKey(text)) {
    return staticTranslations[targetLang]![text]!;
  }

  // Return original text if target language is English
  if (targetLang == 'en') {
    return text;
  }

  // Use MyMemory API for translation
  try {
    // Clean and encode the text properly
    String cleanText = text.trim();
    if (cleanText.isEmpty) return text;

    // URL encode the text to handle special characters and spaces
    String encodedText = Uri.encodeQueryComponent(cleanText);
    String langPair = "en|$targetLang";

    final Uri uri = Uri.parse(
      'https://api.mymemory.translated.net/get?q=$encodedText&langpair=$langPair',
    );

    print("🌍 [Result] Translating: '$cleanText' to $targetLang");

    final response = await http.get(uri).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print("⏰ [Result] Translation API timeout");
        throw TimeoutException(
            'Translation timeout', const Duration(seconds: 10));
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['responseData'] != null &&
          data['responseData']['translatedText'] != null) {
        String translatedText =
            data['responseData']['translatedText'].toString().trim();

        // Check for API errors or invalid translations
        if (translatedText.isNotEmpty &&
            !translatedText.contains("PLEASE SELECT TWO DISTINCT LANGUAGES") &&
            !translatedText.contains("INVALID LANGUAGE PAIR") &&
            !translatedText.contains("MYMEMORY WARNING") &&
            translatedText.toLowerCase() != cleanText.toLowerCase()) {
          print(
              "✅ [Result] Translation successful: '$cleanText' → '$translatedText'");
          return translatedText;
        } else {
          print("❌ [Result] Translation failed or invalid: '$translatedText'");
        }
      } else {
        print("❌ [Result] Invalid response structure");
      }
    } else {
      print("❌ [Result] API returned status code: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ [Result] Translation error: $e");
  }

  // Return original text if translation fails
  print("🔄 [Result] Returning original text: '$text'");
  return text;
}

class QuizResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final List<Map<String, dynamic>> questions;
  final List<String> userAnswers;
  final String language;
  final String? category;
  final String? difficulty;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.questions,
    required this.userAnswers,
    this.language = "fr",
    this.category,
    this.difficulty,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _fadeController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreController.forward();
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _getPerformanceMessage() {
    if (widget.score == widget.total) {
      return "Perfect! You got everything right!";
    } else if (widget.score > widget.total / 2) {
      return "Well done! You have a good score.";
    } else {
      return "You can do better. Try again!";
    }
  }

  String _getPerformanceLevel() {
    double percentage = widget.score / widget.total;
    if (percentage >= 0.9) return "Excellent";
    if (percentage >= 0.7) return "Good";
    return "Needs Improvement";
  }

  Color _getPerformanceColor() {
    double percentage = widget.score / widget.total;
    if (percentage >= 0.9) return Colors.green;
    if (percentage >= 0.7) return Colors.orange;
    return Colors.red;
  }

  // Function to reset current quiz score (not best score)
  Future<void> _resetCurrentQuizScore() async {
    if (widget.category != null && widget.difficulty != null) {
      final prefs = await SharedPreferences.getInstance();
      String currentScoreKey =
          "${widget.category}_${widget.difficulty}_current_score";
      await prefs.remove(currentScoreKey);
      print(
          "🔄 Reset current quiz score for ${widget.category} ${widget.difficulty}");
    }
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 30),
                  _buildScoreCard(),
                  const SizedBox(height: 20),
                  _buildPerformanceStats(),
                  const SizedBox(height: 20),
                  _buildQuestionReview(),
                  const SizedBox(height: 30),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
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
                  future: translateText("Quiz Results", widget.language),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Quiz Results",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: GlobalColor.mainColor,
                    ),
                  ),
                ),
                FutureBuilder<String>(
                  future: translateText("Performance Summary", widget.language),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Performance Summary",
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
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getPerformanceColor().withOpacity(0.1),
              _getPerformanceColor().withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getPerformanceColor().withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: _getPerformanceColor().withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Performance Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getPerformanceColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.score == widget.total
                    ? Icons.emoji_events
                    : widget.score > widget.total / 2
                        ? Icons.thumb_up
                        : Icons.trending_up,
                size: 40,
                color: _getPerformanceColor(),
              ),
            ),
            const SizedBox(height: 20),

            // Animated Score Display
            AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (context, child) {
                return FutureBuilder<String>(
                  future: translateText("Score: ", widget.language),
                  builder: (context, snapshot) => Text(
                    "${snapshot.data ?? "Score: "}${_scoreAnimation.value.round()}/${widget.total}",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getPerformanceColor(),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Performance Message
            FutureBuilder<String>(
              future: translateText(_getPerformanceMessage(), widget.language),
              builder: (context, snapshot) => Text(
                snapshot.data ?? _getPerformanceMessage(),
                style: TextStyle(
                  fontSize: 18,
                  color: GlobalColor.textColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Performance Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _getPerformanceColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: FutureBuilder<String>(
                future: translateText(_getPerformanceLevel(), widget.language),
                builder: (context, snapshot) => Text(
                  snapshot.data ?? _getPerformanceLevel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStats() {
    double accuracy = widget.score / widget.total;

    return Container(
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
          FutureBuilder<String>(
            future: translateText("Performance", widget.language),
            builder: (context, snapshot) => Text(
              snapshot.data ?? "Performance",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GlobalColor.textColor,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "Accuracy",
                  "${(accuracy * 100).round()}%",
                  Icons.track_changes,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  "Questions Answered",
                  "${widget.total}",
                  Icons.quiz,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder<String>(
                    future: translateText("Correct Answers", widget.language),
                    builder: (context, snapshot) => Text(
                      snapshot.data ?? "Correct Answers",
                      style: TextStyle(
                        fontSize: 14,
                        color: GlobalColor.textColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                  Text(
                    "${widget.score}/${widget.total}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GlobalColor.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: accuracy,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_getPerformanceColor()),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildQuestionReview() {
    return Container(
      width: double.infinity,
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
            child: FutureBuilder<String>(
              future: translateText("Answer Details", widget.language),
              builder: (context, snapshot) => Text(
                snapshot.data ?? "Answer Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GlobalColor.textColor,
                ),
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.total,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey[200],
              height: 1,
            ),
            itemBuilder: (context, index) {
              var question = widget.questions[index];
              String userAnswer = widget.userAnswers[index];
              String correctAnswer = question['correct_answer'];
              bool isCorrect = userAnswer == correctAnswer;

              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isCorrect ? Icons.check : Icons.close,
                            color: isCorrect ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FutureBuilder<String>(
                            future: translateText("Question", widget.language),
                            builder: (context, snapshot) => Text(
                              "${snapshot.data ?? "Question"} ${index + 1}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: GlobalColor.textColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<String>(
                      future:
                          translateText(question["question"], widget.language),
                      builder: (context, snapshot) => Text(
                        snapshot.data ?? question["question"],
                        style: TextStyle(
                          fontSize: 14,
                          color: GlobalColor.textColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // User Answer
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.withOpacity(0.05)
                            : Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCorrect
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<String>(
                            future:
                                translateText("Your answer: ", widget.language),
                            builder: (context, snapshot) => Text(
                              snapshot.data ?? "Your answer: ",
                              style: TextStyle(
                                fontSize: 12,
                                color: GlobalColor.textColor.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<String>(
                            future: translateText(userAnswer, widget.language),
                            builder: (context, snapshot) => Text(
                              snapshot.data ?? userAnswer,
                              style: TextStyle(
                                fontSize: 14,
                                color: isCorrect
                                    ? Colors.green[800]
                                    : Colors.red[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!isCorrect) ...[
                      const SizedBox(height: 8),
                      // Correct Answer
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
                              future: translateText(
                                  "Correct answer: ", widget.language),
                              builder: (context, snapshot) => Text(
                                snapshot.data ?? "Correct answer: ",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: GlobalColor.textColor.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder<String>(
                              future:
                                  translateText(correctAnswer, widget.language),
                              builder: (context, snapshot) => Text(
                                snapshot.data ?? correctAnswer,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Back to Home Button
        Container(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColor.mainColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                FutureBuilder<String>(
                  future: translateText("Back to Home", widget.language),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Back to Home",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Try Again Button
        Container(
          width: double.infinity,
          height: 55,
          child: OutlinedButton(
            onPressed: () async {
              // Store context before async operation
              final navigator = Navigator.of(context);

              // Reset current quiz score
              await _resetCurrentQuizScore();

              // Navigate to configuration page with proper stack management
              if (mounted) {
                // First go back to HomePage, clearing all other routes
                navigator.pushNamedAndRemoveUntil('/home', (route) => false);

                // Then navigate to QuizSettingsScreen
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuizSettingsScreen(),
                      ),
                    );
                  }
                });
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: GlobalColor.mainColor, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.refresh,
                  color: GlobalColor.mainColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                FutureBuilder<String>(
                  future: translateText("Try Again", widget.language),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Try Again",
                    style: TextStyle(
                      color: GlobalColor.mainColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
