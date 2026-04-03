import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/trivia_questions.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen>
    with TickerProviderStateMixin {
  final _random = Random();
  int _score = 0;
  int _totalAnswered = 0;
  TriviaQuestion? _currentQuestion;
  String? _selectedAnswer;
  bool _showResult = false;
  Timer? _questionTimer;
  int _remainingSeconds = 15;
  bool _gameStarted = false;
  late AnimationController _fadeController;
  late AnimationController _resultController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _fadeController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _totalAnswered = 0;
      _gameStarted = true;
    });
    _nextQuestion();
  }

  void _nextQuestion() {
    _questionTimer?.cancel();
    final index = _random.nextInt(triviaQuestions.length);
    setState(() {
      _currentQuestion = triviaQuestions[index];
      _selectedAnswer = null;
      _showResult = false;
      _remainingSeconds = 15;
    });
    _fadeController.forward(from: 0);
    _startTimer();
  }

  void _startTimer() {
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _onTimeUp();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _onTimeUp() {
    if (_showResult) return;
    setState(() {
      _showResult = true;
      _totalAnswered++;
    });
    _resultController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _gameStarted) _nextQuestion();
    });
  }

  void _answerQuestion(String answer) {
    if (_showResult) return;
    _questionTimer?.cancel();
    final isCorrect = answer == _currentQuestion!.correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _showResult = true;
      _totalAnswered++;
      if (isCorrect) _score++;
    });
    _resultController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _gameStarted) _nextQuestion();
    });
  }

  Color _getOptionColor(String option) {
    if (!_showResult) return AppColors.surface;
    if (option == _currentQuestion!.correctAnswer) {
      return AppColors.success.withValues(alpha: 0.2);
    }
    if (option == _selectedAnswer &&
        option != _currentQuestion!.correctAnswer) {
      return AppColors.danger.withValues(alpha: 0.2);
    }
    return AppColors.surface;
  }

  Color _getOptionBorder(String option) {
    if (!_showResult) return AppColors.surfaceLight;
    if (option == _currentQuestion!.correctAnswer) return AppColors.success;
    if (option == _selectedAnswer &&
        option != _currentQuestion!.correctAnswer) {
      return AppColors.danger;
    }
    return AppColors.surfaceLight;
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) return _buildStartScreen();
    if (_currentQuestion == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return _buildGameScreen();
  }

  Widget _buildStartScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Telefon Trivia')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.quiz,
                    color: AppColors.primary, size: 64),
              ),
              const SizedBox(height: 32),
              const Text(
                'Telefon Trivia',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cep telefonları hakkında bilgini test et!\n1000 soru, 15 saniye süre, 2 seçenek.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Oyunu Başlat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    final q = _currentQuestion!;
    final timerPercent = _remainingSeconds / 15;

    return Scaffold(
      appBar: AppBar(
        title: Text('Skor: $_score / $_totalAnswered'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _gameStarted = false),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Timer bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: timerPercent,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _remainingSeconds <= 5 ? AppColors.danger : AppColors.primary,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '⏳ $_remainingSeconds sn',
                    style: TextStyle(
                      color: _remainingSeconds <= 5
                          ? AppColors.danger
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Soru #$_totalAnswered',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Question
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: Text(
                  q.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
              const Spacer(),
              // Options
              _buildOption('A', q.optionA),
              const SizedBox(height: 12),
              _buildOption('B', q.optionB),
              const Spacer(),
              if (_showResult)
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _resultController,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: (_selectedAnswer == q.correctAnswer
                              ? AppColors.success
                              : _selectedAnswer == null
                                  ? AppColors.warning
                                  : AppColors.danger)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _selectedAnswer == q.correctAnswer
                          ? 'Doğru! ✓'
                          : _selectedAnswer == null
                              ? 'Süre doldu!'
                              : 'Yanlış! ✗',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _selectedAnswer == q.correctAnswer
                            ? AppColors.success
                            : _selectedAnswer == null
                                ? AppColors.warning
                                : AppColors.danger,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(String label, String text) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: Material(
        color: _getOptionColor(label),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _showResult ? null : () => _answerQuestion(label),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getOptionBorder(label),
                width: 2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _showResult &&
                            label == _currentQuestion!.correctAnswer
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _showResult &&
                                label == _currentQuestion!.correctAnswer
                            ? AppColors.success
                            : AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
