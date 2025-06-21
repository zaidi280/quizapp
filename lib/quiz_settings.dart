import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'quiz_screen.dart';
import 'utlis/global.color.dart';

Future<String> translateText(String text, String targetLang) async {
  // Define static translations for common UI elements to avoid API issues
  final Map<String, Map<String, String>> staticTranslations = {
    "en": {
      "Configuration Quiz": "Quiz Settings",
      "Personnalisez votre expérience": "Customize your experience",
      "Configuration du Quiz": "Quiz Configuration",
      "Catégorie": "Category",
      "Difficulté": "Difficulty",
      "Nombre de Questions": "Number of Questions",
      "Langue": "Language",
      "Préférences": "Preferences",
      "Activer le Son": "Enable Sound",
      "Effets sonores pendant le quiz": "Sound effects during quiz",
      "Activer les Vibrations": "Enable Vibrations",
      "Retour haptique pour les réponses": "Haptic feedback for answers",
      "Résumé de Configuration": "Configuration Summary",
      "Questions": "Questions",
      "Commencer le Quiz": "Start Quiz",
    },
    "fr": {
      "Configuration Quiz": "Configuration Quiz",
      "Personnalisez votre expérience": "Personnalisez votre expérience",
      "Configuration du Quiz": "Configuration du Quiz",
      "Catégorie": "Catégorie",
      "Difficulté": "Difficulté",
      "Nombre de Questions": "Nombre de Questions",
      "Langue": "Langue",
      "Préférences": "Préférences",
      "Activer le Son": "Activer le Son",
      "Effets sonores pendant le quiz": "Effets sonores pendant le quiz",
      "Activer les Vibrations": "Activer les Vibrations",
      "Retour haptique pour les réponses": "Retour haptique pour les réponses",
      "Résumé de Configuration": "Résumé de Configuration",
      "Questions": "Questions",
      "Commencer le Quiz": "Commencer le Quiz",
    },
    "ar": {
      "Configuration Quiz": "إعداد الاختبار",
      "Personnalisez votre expérience": "خصص تجربتك",
      "Configuration du Quiz": "إعداد الاختبار",
      "Catégorie": "الفئة",
      "Difficulté": "الصعوبة",
      "Nombre de Questions": "عدد الأسئلة",
      "Langue": "اللغة",
      "Préférences": "التفضيلات",
      "Activer le Son": "تفعيل الصوت",
      "Effets sonores pendant le quiz": "المؤثرات الصوتية أثناء الاختبار",
      "Activer les Vibrations": "تفعيل الاهتزاز",
      "Retour haptique pour les réponses": "ردود فعل لمسية للإجابات",
      "Résumé de Configuration": "ملخص الإعداد",
      "Questions": "أسئلة",
      "Commencer le Quiz": "بدء الاختبار",
    }
  };

  // Check if we have a static translation
  if (staticTranslations.containsKey(targetLang) &&
      staticTranslations[targetLang]!.containsKey(text)) {
    return staticTranslations[targetLang]![text]!;
  }

  // Fallback to API translation
  try {
    const String apiKey = "fa9fe8b39e5b7565f34f";
    String langPair = "en|$targetLang";

    final Uri uri = Uri.parse(
      'https://api.mymemory.translated.net/get?q=$text&langpair=$langPair&key=$apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String translatedText = data['responseData']['translatedText'];

      // Check if the translation contains error messages
      if (translatedText.contains("PLEASE SELECT TWO DISTINCT LANGUAGES") ||
          translatedText.contains("INVALID LANGUAGE PAIR")) {
        return text; // Return original text if translation failed
      }

      return translatedText;
    } else {
      return text;
    }
  } catch (e) {
    return text; // Return original text if any error occurs
  }
}

class QuizSettingsScreen extends StatefulWidget {
  const QuizSettingsScreen({super.key});

  @override
  State<QuizSettingsScreen> createState() => _QuizSettingsScreenState();
}

class _QuizSettingsScreenState extends State<QuizSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String selectedCategory = "Animals";
  String selectedDifficulty = "easy";
  int selectedQuestions = 5;
  String selectedLanguage = "en";
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  // Use int values for OpenTDB categories
  final Map<String, int> categoryMap = {
    "Animals": 27,
    "Vehicles": 28,
    "History": 23,
  };

  final Map<String, String> languageMap = {
    "English": "en",
    "Français": "fr",
    "عربي": "ar",
  };

  // List of languages supported by OpenTDB
  final List<String> openTdbSupportedLanguages = ["en", "fr"];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _loadPreferences();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      soundEnabled = prefs.getBool('sound_enabled') ?? true;
      vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  void _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('sound_enabled', soundEnabled);
    prefs.setBool('vibration_enabled', vibrationEnabled);
  }

  Future<void> _startQuiz() async {
    int categoryId = categoryMap[selectedCategory]!;
    // Use English as fallback for OpenTDB if language isn't supported
    String apiLang = openTdbSupportedLanguages.contains(selectedLanguage)
        ? selectedLanguage
        : "en";
    String apiUrl =
        "https://opentdb.com/api.php?amount=$selectedQuestions&category=$categoryId&difficulty=$selectedDifficulty&type=multiple&lang=$apiLang";

    print("OpenTDB API URL: $apiUrl"); // Debug URL
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("OpenTDB Response: $data"); // Debug response
      List<dynamic> questions = data["results"];
      if (questions.isNotEmpty) {
        // Check for invalid language pair error in questions
        bool hasInvalidQuestions = questions.any(
            (q) => q["question"].contains("INVALID LANGUAGE PAIR SPECIFIED"));
        if (hasInvalidQuestions) {
          _showError(await translateText(
              "This language is not supported for the selected category. Falling back to English and translating.",
              selectedLanguage));
          // Fetch in English and let QuizScreen translate
          apiUrl =
              "https://opentdb.com/api.php?amount=$selectedQuestions&category=$categoryId&difficulty=$selectedDifficulty&type=multiple&lang=en";
          final fallbackResponse = await http.get(Uri.parse(apiUrl));
          if (fallbackResponse.statusCode == 200) {
            final fallbackData = json.decode(fallbackResponse.body);
            questions = fallbackData["results"];
          } else {
            _showError(await translateText(
                "Error loading questions.", selectedLanguage));
            return;
          }
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(
                questions: questions,
                category: selectedCategory,
                difficulty: selectedDifficulty,
                language: selectedLanguage,
              ),
            ),
          );
        }
      } else {
        _showError(await translateText(
            "No questions found for these settings.", selectedLanguage));
      }
    } else {
      _showError(
          await translateText("Error loading questions.", selectedLanguage));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 30),
                    _buildQuizConfigCard(),
                    const SizedBox(height: 20),
                    _buildPreferencesCard(),
                    const SizedBox(height: 20),
                    _buildSummaryCard(),
                    const SizedBox(height: 30),
                    _buildStartButton(),
                    const SizedBox(height: 20),
                  ],
                ),
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
                  future: translateText("Configuration Quiz", selectedLanguage),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Configuration Quiz",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: GlobalColor.mainColor,
                    ),
                  ),
                ),
                FutureBuilder<String>(
                  future: translateText(
                      "Personnalisez votre expérience", selectedLanguage),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Personnalisez votre expérience",
                    style: TextStyle(
                      fontSize: 16,
                      color: GlobalColor.textColor,
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

  Widget _buildQuizConfigCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GlobalColor.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.quiz,
                  color: GlobalColor.mainColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              FutureBuilder<String>(
                future:
                    translateText("Configuration du Quiz", selectedLanguage),
                builder: (context, snapshot) => Text(
                  snapshot.data ?? "Configuration du Quiz",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GlobalColor.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCustomDropdown(
            label: "Catégorie",
            value: selectedCategory,
            items: categoryMap.keys.toList(),
            icon: Icons.category,
            onChanged: (value) => setState(() => selectedCategory = value!),
          ),
          const SizedBox(height: 16),
          _buildCustomDropdown(
            label: "Difficulté",
            value: selectedDifficulty,
            items: ["easy", "medium", "hard"],
            icon: Icons.trending_up,
            onChanged: (value) => setState(() => selectedDifficulty = value!),
          ),
          const SizedBox(height: 16),
          _buildNumberDropdown(),
          const SizedBox(height: 16),
          _buildLanguageDropdown(),
        ],
      ),
    );
  }

  Widget _buildCustomDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: GlobalColor.mainColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: translateText(label, selectedLanguage),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? label,
                    style: TextStyle(
                      fontSize: 12,
                      color: GlobalColor.textColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    items: items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 16,
                            color: GlobalColor.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberDropdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.numbers,
            color: GlobalColor.mainColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future:
                      translateText("Nombre de Questions", selectedLanguage),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Nombre de Questions",
                    style: TextStyle(
                      fontSize: 12,
                      color: GlobalColor.textColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedQuestions,
                    isExpanded: true,
                    items: [5, 10, 15].map((number) {
                      return DropdownMenuItem<int>(
                        value: number,
                        child: Text(
                          number.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: GlobalColor.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedQuestions = value!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.language,
            color: GlobalColor.mainColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: translateText("Langue", selectedLanguage),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Langue",
                    style: TextStyle(
                      fontSize: 12,
                      color: GlobalColor.textColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: languageMap.keys.firstWhere(
                        (key) => languageMap[key] == selectedLanguage),
                    isExpanded: true,
                    items: languageMap.keys.map((language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(
                          language,
                          style: TextStyle(
                            fontSize: 16,
                            color: GlobalColor.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedLanguage = languageMap[value!]!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              FutureBuilder<String>(
                future: translateText("Préférences", selectedLanguage),
                builder: (context, snapshot) => Text(
                  snapshot.data ?? "Préférences",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GlobalColor.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSwitchTile(
            title: "Activer le Son",
            subtitle: "Effets sonores pendant le quiz",
            value: soundEnabled,
            icon: Icons.volume_up,
            onChanged: (value) {
              setState(() => soundEnabled = value);
              _savePreferences();
            },
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: "Activer les Vibrations",
            subtitle: "Retour haptique pour les réponses",
            value: vibrationEnabled,
            icon: Icons.vibration,
            onChanged: (value) {
              setState(() => vibrationEnabled = value);
              _savePreferences();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? GlobalColor.mainColor : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: translateText(title, selectedLanguage),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: GlobalColor.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: translateText(subtitle, selectedLanguage),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: GlobalColor.textColor.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: GlobalColor.mainColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.preview,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              FutureBuilder<String>(
                future:
                    translateText("Résumé de Configuration", selectedLanguage),
                builder: (context, snapshot) => Text(
                  snapshot.data ?? "Résumé de Configuration",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GlobalColor.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryItem("Catégorie", selectedCategory, Icons.category),
          _buildSummaryItem(
              "Difficulté", selectedDifficulty, Icons.trending_up),
          _buildSummaryItem(
              "Questions", "$selectedQuestions questions", Icons.numbers),
          _buildSummaryItem(
              "Langue",
              languageMap.keys
                  .firstWhere((key) => languageMap[key] == selectedLanguage),
              Icons.language),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue[700],
            size: 18,
          ),
          const SizedBox(width: 12),
          FutureBuilder<String>(
            future: translateText(label, selectedLanguage),
            builder: (context, snapshot) => Text(
              "${snapshot.data ?? label}: ",
              style: TextStyle(
                fontSize: 14,
                color: GlobalColor.textColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: GlobalColor.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GlobalColor.mainColor,
            GlobalColor.mainColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: GlobalColor.mainColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _startQuiz,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                FutureBuilder<String>(
                  future: translateText("Commencer le Quiz", selectedLanguage),
                  builder: (context, snapshot) => Text(
                    snapshot.data ?? "Commencer le Quiz",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
