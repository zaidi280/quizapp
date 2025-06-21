import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quiz_result_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utlis/global.color.dart';
import 'dart:math' as math;

Future<String> translateText(String text, String targetLang) async {
  // Define static translations for common UI elements to avoid API issues
  final Map<String, Map<String, String>> staticTranslations = {
    "en": {
      "Quiz - ": "Quiz - ",
      "Question ": "Question ",
      "Time Left: ": "Time Left: ",
      " s": " s",
      "Reset Scores": "Reset Scores",
      "Score: ": "Score: ",
      "Progress: ": "Progress: ",
      "Plenty of time": "Plenty of time",
      "Hurry up!": "Hurry up!",
      "Time running out!": "Time running out!",
    },
    "fr": {
      "Quiz - ": "Quiz - ",
      "Question ": "Question ",
      "Time Left: ": "Temps restant: ",
      " s": " s",
      "Reset Scores": "Réinitialiser les scores",
      "Score: ": "Score: ",
      "Progress: ": "Progrès: ",
      "Plenty of time": "Beaucoup de temps",
      "Hurry up!": "Dépêchez-vous!",
      "Time running out!": "Le temps s'épuise!",
    },
    "ar": {
      "Quiz - ": "اختبار - ",
      "Question ": "سؤال ",
      "Time Left: ": "الوقت المتبقي: ",
      " s": " ث",
      "Reset Scores": "إعادة تعيين النتائج",
      "Score: ": "النتيجة: ",
      "Progress: ": "التقدم: ",
      "Plenty of time": "وقت كافي",
      "Hurry up!": "أسرع!",
      "Time running out!": "الوقت ينفد!",
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

    print("🌍 Translating: '$cleanText' to $targetLang");
    print("🔗 API URL: $uri");

    final response = await http.get(uri).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        print("⏰ Translation API timeout");
        throw TimeoutException(
            'Translation timeout', const Duration(seconds: 15));
      },
    );

    print("📡 Response Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("📄 Response Data: $data");

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
          print("✅ Translation successful: '$cleanText' → '$translatedText'");
          return translatedText;
        } else {
          print("❌ Translation failed or invalid: '$translatedText'");
        }
      } else {
        print("❌ Invalid response structure");
      }
    } else {
      print("❌ API returned status code: ${response.statusCode}");
      print("📄 Response body: ${response.body}");
    }
  } catch (e) {
    print("❌ Translation error: $e");
  }

  // Return original text if translation fails
  print("🔄 Returning original text: '$text'");
  return text;
}

class QuizScreen extends StatefulWidget {
  final List<dynamic> questions;
  final String category;
  final String difficulty;
  final String language;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.category,
    required this.difficulty,
    required this.language,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int currentQuestionIndex = 0;
  int score = 0;
  bool isAnswered = false;
  String? selectedAnswer;
  Timer? timer;
  int timeLeft = 15;
  List<String> answers = [];
  final List<String> _userAnswers = [];
  late AudioPlayer _audioPlayer;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  Map<String, dynamic>?
      _currentQuestion; // Store the current translated question
  bool _isLoadingQuestion = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Initialize animations
    _fadeController = AnimationController(
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

    _loadPreferences();
    _loadQuestion();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      soundEnabled = prefs.getBool('sound_enabled') ?? true;
      vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<Map<String, dynamic>> _translateQuestion(int index) async {
    var question = widget.questions[index];
    String targetLang = widget.language;

    print("Original Question: ${question["question"]}"); // Debug original
    print("Target Language: $targetLang"); // Debug target language

    // If target language is English, return original
    if (targetLang == 'en') {
      return question;
    }

    // For all non-English languages, translate everything
    try {
      print("🔄 Starting translation for language: $targetLang");

      String translatedQuestion =
          await translateText(question["question"], targetLang);
      List<String> translatedAnswers = [];

      // Translate all incorrect answers
      for (String answer in question["incorrect_answers"]) {
        String translatedAnswer = await translateText(answer, targetLang);
        translatedAnswers.add(translatedAnswer);
        print("🔄 Translated answer: '$answer' → '$translatedAnswer'");
      }

      // Translate correct answer
      String correctAnswer =
          await translateText(question["correct_answer"], targetLang);

      print("Translated Question: $translatedQuestion"); // Debug translated
      print(
          "Translated Correct Answer: $correctAnswer"); // Debug correct answer

      return {
        "question": translatedQuestion,
        "incorrect_answers": translatedAnswers,
        "correct_answer": correctAnswer,
      };
    } catch (e) {
      print("Translation failed, using original: $e");
      return question; // Fallback to original if translation fails
    }
  }

  void _loadQuestion() async {
    setState(() {
      _isLoadingQuestion = true;
      isAnswered = false;
      selectedAnswer = null;
      answers = [];
    });

    // Reset animations
    _fadeController.reset();

    final translated = await _translateQuestion(currentQuestionIndex);
    setState(() {
      _currentQuestion = translated;
      answers = List<String>.from(translated["incorrect_answers"]);
      answers.add(translated["correct_answer"]);
      answers.shuffle();
      _isLoadingQuestion = false;
    });

    // Start animations
    _fadeController.forward();
    _startTimer();
  }

  void _startTimer() {
    // Ensure any existing timer is canceled
    timer?.cancel();
    timeLeft = 15;

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return; // Prevent updates if widget is disposed
      if (timeLeft > 0 && !isAnswered) {
        setState(() {
          timeLeft--;
        });
      } else if (timeLeft == 0 && !isAnswered) {
        timer.cancel();
        _nextQuestion();
      }
    });
  }

  void _playSound(String sound) async {
    if (soundEnabled) {
      try {
        await _audioPlayer.setSource(AssetSource('sounds/$sound'));
        await _audioPlayer.resume();
      } catch (e) {
        print("Error loading sound file: $e");
      }
    }
  }

  void _vibrate() {
    if (vibrationEnabled) {
      Vibration.vibrate();
    }
  }

  void _checkAnswer(String answer) {
    if (isAnswered || _isLoadingQuestion) return; // Prevent multiple selections

    setState(() {
      isAnswered = true;
      selectedAnswer = answer;
      timer?.cancel();
      _userAnswers.add(answer);
    });

    // Use the current question data directly to avoid race conditions
    if (_currentQuestion != null) {
      if (answer == _currentQuestion!["correct_answer"]) {
        score++;
        _playSound("correct_answer_sound.mp3");
      } else {
        _playSound("wrong_answer_sound.mp3");
      }
      _vibrate();
    }

    // Add a delay to show the result before moving to the next question
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (selectedAnswer == null) _userAnswers.add("No answer");
    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      _loadQuestion();
    } else {
      _saveScore();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            score: score,
            total: widget.questions.length,
            questions: widget.questions.cast<Map<String, dynamic>>(),
            userAnswers: _userAnswers,
            language: widget.language,
            category: widget.category,
            difficulty: widget.difficulty,
          ),
        ),
      );
    }
  }

  void _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    String scoreKey = "${widget.category}_${widget.difficulty}_score";
    int bestScore = prefs.getInt(scoreKey) ?? 0;
    if (score > bestScore) await prefs.setInt(scoreKey, score);
  }

  void _resetScore() async {
    final prefs = await SharedPreferences.getInstance();
    String scoreKey = "${widget.category}_${widget.difficulty}_score";
    await prefs.remove(scoreKey);
    setState(() => score = 0);
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
            colors: [
              GlobalColor.mainColor.withOpacity(0.1),
              Colors.white,
              GlobalColor.mainColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoadingQuestion
              ? _buildLoadingState()
              : _currentQuestion == null
                  ? _buildErrorState()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: 20),
                            _buildProgressCard(),
                            const SizedBox(height: 20),
                            _buildQuestionCard(),
                            const SizedBox(height: 20),
                            _buildTimerCard(),
                            const SizedBox(height: 20),
                            _buildAnswersSection(),
                            const SizedBox(height: 20),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                Text(
                  'Loading Question...',
                  style: TextStyle(
                    fontSize: 16,
                    color: GlobalColor.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading question',
              style: TextStyle(
                fontSize: 18,
                color: GlobalColor.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again',
              style: TextStyle(
                fontSize: 14,
                color: GlobalColor.textColor.withOpacity(0.7),
              ),
            ),
          ],
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
                  future: translateText("Quiz - ", widget.language),
                  builder: (context, snapshot) => Text(
                    "${snapshot.data ?? "Quiz - "}${widget.category}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: GlobalColor.mainColor,
                    ),
                  ),
                ),
                Text(
                  widget.difficulty.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    color: GlobalColor.textColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
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
                  Icons.star,
                  color: GlobalColor.mainColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                FutureBuilder<String>(
                  future: translateText("Score: ", widget.language),
                  builder: (context, snapshot) => Text(
                    "${snapshot.data ?? "Score: "}$score",
                    style: TextStyle(
                      fontSize: 14,
                      color: GlobalColor.mainColor,
                      fontWeight: FontWeight.bold,
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

  Widget _buildProgressCard() {
    double progress = (currentQuestionIndex + 1) / widget.questions.length;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FutureBuilder<String>(
                future: translateText("Progress: ", widget.language),
                builder: (context, snapshot) => Text(
                  "${snapshot.data ?? "Progress: "}${currentQuestionIndex + 1}/${widget.questions.length}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GlobalColor.textColor,
                  ),
                ),
              ),
              Text(
                "${(progress * 100).round()}%",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GlobalColor.mainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(GlobalColor.mainColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.blue[100]!.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              FutureBuilder<String>(
                future: translateText("Question ", widget.language),
                builder: (context, snapshot) => Text(
                  "${snapshot.data ?? "Question "}${currentQuestionIndex + 1}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GlobalColor.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentQuestion!["question"],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: GlobalColor.textColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    Color timerColor = timeLeft > 10
        ? Colors.green
        : timeLeft > 5
            ? Colors.orange
            : Colors.red;

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
      child: Row(
        children: [
          // Timer Circle with Number Only
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: timerColor,
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                timeLeft.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: timerColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Timer Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: translateText("Time Left: ", widget.language),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Time Left: ",
                    style: TextStyle(
                      fontSize: 16,
                      color: GlobalColor.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: translateText(
                    timeLeft > 10
                        ? "Plenty of time"
                        : timeLeft > 5
                            ? "Hurry up!"
                            : "Time running out!",
                    widget.language,
                  ),
                  builder: (context, snapshot) => Text(
                    snapshot.data ??
                        (timeLeft > 10
                            ? "Plenty of time"
                            : timeLeft > 5
                                ? "Hurry up!"
                                : "Time running out!"),
                    style: TextStyle(
                      fontSize: 14,
                      color: timerColor,
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

  Widget _buildAnswersSection() {
    return Column(
      children: answers.asMap().entries.map((entry) {
        int index = entry.key;
        String answer = entry.value;
        bool isCorrect = answer == _currentQuestion!["correct_answer"];
        bool isSelected = selectedAnswer == answer;

        Color backgroundColor = Colors.white;
        Color borderColor = Colors.grey[300]!;
        Color textColor = GlobalColor.textColor;
        IconData? icon;

        if (isAnswered) {
          if (isCorrect) {
            backgroundColor = Colors.green[50]!;
            borderColor = Colors.green;
            textColor = Colors.green[800]!;
            icon = Icons.check_circle;
          } else if (isSelected) {
            backgroundColor = Colors.red[50]!;
            borderColor = Colors.red;
            textColor = Colors.red[800]!;
            icon = Icons.cancel;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isAnswered ? null : () => _checkAnswer(answer),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: borderColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: icon != null
                            ? Icon(icon, color: borderColor, size: 20)
                            : Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: borderColor,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        answer,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _fadeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
