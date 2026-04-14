import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/trivia_questions.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

enum _GamePhase { start, playing, gameOver }

class _TriviaScreenState extends State<TriviaScreen>
    with TickerProviderStateMixin {
  final _random = Random();

  int _score = 0;
  int _totalAnswered = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _lives = 3;
  int _highScore = 0;
  int _remainingSeconds = 15;
  _GamePhase _phase = _GamePhase.start;

  TriviaQuestion? _currentQuestion;
  String? _selectedAnswer;
  bool _showResult = false;
  bool _timeUp = false;
  Timer? _questionTimer;

  final Set<int> _usedIndices = {};

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
    _loadHighScore();
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _fadeController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _highScore = prefs.getInt('trivia_high_score') ?? 0;
    });
  }

  Future<void> _saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trivia_high_score', score);
    if (!mounted) return;
    setState(() {
      _highScore = score;
    });
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _totalAnswered = 0;
      _correctCount = 0;
      _wrongCount = 0;
      _lives = 3;
      _phase = _GamePhase.playing;
      _usedIndices.clear();
    });
    _nextQuestion();
  }

  int _pickRandomIndex() {
    if (_usedIndices.length >= triviaQuestions.length) {
      _usedIndices.clear();
    }
    int index;
    do {
      index = _random.nextInt(triviaQuestions.length);
    } while (_usedIndices.contains(index));
    _usedIndices.add(index);
    return index;
  }

  void _nextQuestion() {
    _questionTimer?.cancel();
    final index = _pickRandomIndex();
    setState(() {
      _currentQuestion = triviaQuestions[index];
      _selectedAnswer = null;
      _showResult = false;
      _timeUp = false;
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
    _questionTimer?.cancel();
    final newLives = _lives - 1;
    setState(() {
      _showResult = true;
      _timeUp = true;
      _totalAnswered++;
      _wrongCount++;
      _lives = newLives;
    });
    _resultController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (newLives <= 0) {
        _endGame();
      } else {
        _nextQuestion();
      }
    });
  }

  void _answerQuestion(String answer) {
    if (_showResult) return;
    _questionTimer?.cancel();
    final isCorrect = answer == _currentQuestion!.correctAnswer;
    final earned = isCorrect ? _remainingSeconds : 0;
    final newLives = isCorrect ? _lives : _lives - 1;
    setState(() {
      _selectedAnswer = answer;
      _showResult = true;
      _totalAnswered++;
      if (isCorrect) {
        _score += earned;
        _correctCount++;
      } else {
        _wrongCount++;
        _lives = newLives;
      }
    });
    _resultController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (newLives <= 0) {
        _endGame();
      } else {
        _nextQuestion();
      }
    });
  }

  void _endGame() {
    _questionTimer?.cancel();
    if (_score > _highScore) {
      _saveHighScore(_score);
    }
    setState(() {
      _phase = _GamePhase.gameOver;
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

  String _resultText() {
    if (_timeUp) return 'Sure doldu!';
    if (_selectedAnswer == _currentQuestion!.correctAnswer) {
      return 'Dogru! +$_remainingSeconds puan';
    }
    return 'Yanlis!';
  }

  Color _resultColor() {
    if (_timeUp) return AppColors.warning;
    if (_selectedAnswer == _currentQuestion!.correctAnswer) {
      return AppColors.success;
    }
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _GamePhase.start:
        return _buildStartScreen();
      case _GamePhase.playing:
        if (_currentQuestion == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        return _buildGameScreen();
      case _GamePhase.gameOver:
        return _buildGameOverScreen();
    }
  }

  // ---------------------------------------------------------------------------
  // START SCREEN
  // ---------------------------------------------------------------------------

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '$_highScore',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.quiz,
                    color: AppColors.primary, size: 64),
              ),
              const SizedBox(height: 28),
              const Text(
                'Telefon Trivia',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Eglenceli binlerce soru',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _infoChip(Icons.timer, '15 saniye hakkın var'),
                  const SizedBox(width: 8),
                  _infoChip(Icons.looks_two, '2 secenek'),
                  const SizedBox(width: 8),
                  _infoChip(Icons.check_circle_outline, '1 dogru'),
                ],
              ),
              const SizedBox(height: 32),
              _buildRulesCard(),
              const SizedBox(height: 36),
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
                    elevation: 0,
                  ),
                  child: const Text(
                    'Oyunu Baslat',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline,
                  color: AppColors.tertiary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Nasil Oynanir?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ruleRow(Icons.timer, 'Her soruda 15 saniye sureniz var'),
          const SizedBox(height: 10),
          _ruleRow(Icons.star,
              'Kalan sure = kazanilan puan (12 saniye kaldiysa 12 puan)'),
          const SizedBox(height: 10),
          _ruleRow(Icons.favorite, '3 yanlis bilme hakkiniz var'),
          const SizedBox(height: 10),
          _ruleRow(Icons.block, '3 hakkiniz bitince oyun sona erer'),
        ],
      ),
    );
  }

  Widget _ruleRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // GAME SCREEN
  // ---------------------------------------------------------------------------

  Widget _buildGameScreen() {
    final q = _currentQuestion!;
    final timerPercent = _remainingSeconds / 15;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => setState(() => _phase = _GamePhase.start),
        ),
        title: Text(
          'Skor: $_score',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final alive = i < _lives;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    alive ? Icons.favorite : Icons.favorite_border,
                    color: alive ? AppColors.danger : AppColors.textTertiary,
                    size: 22,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: timerPercent,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _remainingSeconds <= 5
                        ? AppColors.danger
                        : AppColors.primary,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_remainingSeconds sn',
                    style: TextStyle(
                      color: _remainingSeconds <= 5
                          ? AppColors.danger
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Soru #${_totalAnswered + 1}',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
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
                      color: _resultColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _resultText(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _resultColor(),
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

  // ---------------------------------------------------------------------------
  // GAME OVER SCREEN
  // ---------------------------------------------------------------------------

  Widget _buildGameOverScreen() {
    final isNewRecord = _score >= _highScore && _score > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Oyun Bitti!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Toplam Puan',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    if (isNewRecord) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.emoji_events,
                                color: AppColors.warning, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Yeni Rekor!',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statColumn(
                        'Toplam', '$_totalAnswered', AppColors.primary),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.surfaceLight,
                    ),
                    _statColumn('Dogru', '$_correctCount', AppColors.success),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.surfaceLight,
                    ),
                    _statColumn('Yanlis', '$_wrongCount', AppColors.danger),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _lives = 1;
                      _phase = _GamePhase.playing;
                    });
                    _nextQuestion();
                  },
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Devam Et (+1 Can)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Oxyn Trivia\'da $_score puan yaptim! Sen de bilgini test et! #OxynTrivia',
                      ),
                    );
                  },
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text('Paylas'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.tertiary,
                    side: const BorderSide(color: AppColors.tertiary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Yeniden Basla',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Ana Menu',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
