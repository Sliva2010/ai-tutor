import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════
//  HabitBreaker — Брось вредные привычки
//  25+ функций, анимации, крутой дизайн
// ═══════════════════════════════════════════════════════

void main() {
  runApp(const HabitBreakerApp());
}

// ── Модель привычки ──
class Habit {
  String id;
  String name;
  String emoji;
  DateTime startDate;
  int streakDays;
  int totalRelapses;
  int xp;
  int level;
  List<MoodEntry> moodHistory;
  List<String> notes;
  bool isArchived;

  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.startDate,
    this.streakDays = 0,
    this.totalRelapses = 0,
    this.xp = 0,
    this.level = 1,
    List<MoodEntry>? moodHistory,
    List<String>? notes,
    this.isArchived = false,
  })  : moodHistory = moodHistory ?? [],
        notes = notes ?? [];

  int get daysSinceStart => DateTime.now().difference(startDate).inDays;
  String get statusText {
    if (streakDays == 0) return 'Начни сегодня! 💪';
    if (streakDays < 3) return '$streakDays дня без срывов 🔥';
    if (streakDays < 7) return '$streakDays дней без срывов ';
    if (streakDays < 30) return '$streakDays дней — ты крут! 🏆';
    return '$streakDays дней — легенда! 👑';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'startDate': startDate.toIso8601String(),
        'streakDays': streakDays,
        'totalRelapses': totalRelapses,
        'xp': xp,
        'level': level,
        'moodHistory': moodHistory.map((m) => m.toJson()).toList(),
        'notes': notes,
        'isArchived': isArchived,
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'],
        name: j['name'],
        emoji: j['emoji'],
        startDate: DateTime.parse(j['startDate']),
        streakDays: j['streakDays'] ?? 0,
        totalRelapses: j['totalRelapses'] ?? 0,
        xp: j['xp'] ?? 0,
        level: j['level'] ?? 1,
        moodHistory: (j['moodHistory'] as List?)
                ?.map((m) => MoodEntry.fromJson(m))
                .toList() ??
            [],
        notes: List<String>.from(j['notes'] ?? []),
        isArchived: j['isArchived'] ?? false,
      );
}

class MoodEntry {
  DateTime date;
  int mood; // 1-5
  String note;
  MoodEntry({required this.date, required this.mood, this.note = ''});
  Map<String, dynamic> toJson() =>
      {'date': date.toIso8601String(), 'mood': mood, 'note': note};
  factory MoodEntry.fromJson(Map<String, dynamic> j) =>
      MoodEntry(date: DateTime.parse(j['date']), mood: j['mood'], note: j['note'] ?? '');
}

// ── Мотивационные цитаты ──
const List<Map<String, String>> quotes = [
  {'text': 'Каждый день без привычки — это победа.', 'author': 'Неизвестный'},
  {'text': 'Сила не в том, чтобы никогда не падать, а в том, чтобы подниматься каждый раз.', 'author': 'Нельсон Мандела'},
  {'text': 'Ты сильнее, чем думаешь.', 'author': 'Аноним'},
  {'text': 'Один день за раз. Один шаг за раз.', 'author': 'Аноним'},
  {'text': 'Свобода начинается с отказа от зависимости.', 'author': 'Аноним'},
  {'text': 'Твоя лучшая версия ещё впереди.', 'author': 'Аноним'},
  {'text': 'Боль временна, гордость навсегда.', 'author': 'Аноним'},
  {'text': 'Не считай дни — делай так, чтобы дни считались.', 'author': 'Мухаммед Али'},
  {'text': 'Ты уже прошёл через самое сложное — решение начать.', 'author': 'Аноним'},
  {'text': 'Привычка формируется за 21 день. Ты справишься!', 'author': 'Максвелл Мальц'},
  {'text': 'Маленькие шаги приводят к большим переменам.', 'author': 'Аноним'},
  {'text': 'Ты не одинок в этой борьбе.', 'author': 'Аноним'},
];

// ── Советы ──
const List<String> tips = [
  '🧘 Попробуй медитацию 5 минут в день — это снижает тягу.',
  '🏃 Физическая активность помогает справиться со стрессом.',
  '💧 Пей больше воды — это улучшает самочувствие.',
  '😴 Высыпайся — усталость провоцирует срывы.',
  '📝 Веди дневник — записывай свои мысли и чувства.',
  '🎯 Ставь маленькие цели на каждый день.',
  '🧊 Когда тянет — выпей стакан холодной воды и подожди 10 минут.',
  ' Убери триггеры — удали контакты, приложения, места.',
  '🤝 Расскажи близкому человеку о своём решении.',
  '🎉 Награждай себя за каждый достигнутый рубеж.',
  '🌅 Начни утро с позитивной мысли.',
  '📖 Читай истории людей, которые справились.',
  '🎵 Слушай музыку, которая поднимает настроение.',
  ' Гуляй на свежем воздухе каждый день.',
  '🍎 Ешь здоровую пищу — это влияет на настроение.',
];

// ── Достижения ──
const List<Map<String, dynamic>> achievements = [
  {'id': 'first_day', 'name': 'Первый шаг', 'desc': '1 день без срыва', 'icon': '🌱', 'xp': 10},
  {'id': 'week_1', 'name': 'Неделя силы', 'desc': '7 дней без срыва', 'icon': '🔥', 'xp': 50},
  {'id': 'two_weeks', 'name': 'Две недели', 'desc': '14 дней без срыва', 'icon': '⚡', 'xp': 100},
  {'id': 'month', 'name': 'Месяц свободы', 'desc': '30 дней без срыва', 'icon': '🏆', 'xp': 250},
  {'id': 'quarter', 'name': 'Квартал', 'desc': '90 дней без срыва', 'icon': '💎', 'xp': 500},
  {'id': 'half_year', 'name': 'Полгода', 'desc': '180 дней без срыва', 'icon': '👑', 'xp': 1000},
  {'id': 'year', 'name': 'Год свободы', 'desc': '365 дней без срыва', 'icon': '🌟', 'xp': 2000},
  {'id': 'relapse_comeback', 'name': 'Феникс', 'desc': 'Вернуться после срыва', 'icon': '🔥', 'xp': 30},
  {'id': 'mood_master', 'name': 'Мастер настроения', 'desc': 'Записать 10 записей настроения', 'icon': '😊', 'xp': 40},
  {'id': 'note_writer', 'name': 'Дневник', 'desc': 'Написать 5 заметок', 'icon': '📝', 'xp': 35},
];

// ── Пресеты привычек ──
const List<Map<String, String>> habitPresets = [
  {'name': 'Курение', 'emoji': '🚬'},
  {'name': 'Алкоголь', 'emoji': '🍺'},
  {'name': 'Сахар', 'emoji': '🍬'},
  {'name': 'Фастфуд', 'emoji': '🍔'},
  {'name': 'Соцсети', 'emoji': '📱'},
  {'name': 'Игры', 'emoji': '🎮'},
  {'name': 'Кофеин', 'emoji': '☕'},
  {'name': 'Газировка', 'emoji': '🥤'},
  {'name': 'Жирная пища', 'emoji': '🍟'},
  {'name': 'Своя привычка', 'emoji': '⚡'},
];

// ── Данные приложения ──
class AppData {
  List<Habit> habits = [];
  bool darkMode = false;
  bool hapticsEnabled = true;
  bool notificationsEnabled = true;
  String userName = '';
  int totalXp = 0;
  int totalLevel = 1;

  Habit? get activeHabit => habits.where((h) => !h.isArchived).firstOrNull;

  AppData();

  Map<String, dynamic> toJson() => {
        'habits': habits.map((h) => h.toJson()).toList(),
        'darkMode': darkMode,
        'hapticsEnabled': hapticsEnabled,
        'notificationsEnabled': notificationsEnabled,
        'userName': userName,
        'totalXp': totalXp,
        'totalLevel': totalLevel,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    final data = AppData()
      ..habits = (j['habits'] as List?)?.map((h) => Habit.fromJson(h)).toList() ?? []
      ..darkMode = j['darkMode'] ?? false
      ..hapticsEnabled = j['hapticsEnabled'] ?? true
      ..notificationsEnabled = j['notificationsEnabled'] ?? true
      ..userName = j['userName'] ?? ''
      ..totalXp = j['totalXp'] ?? 0
      ..totalLevel = j['totalLevel'] ?? 1;
    return data;
  }
}

// ── Сервис данных ──
class DataService {
  static final DataService _instance = DataService._();
  factory DataService() => _instance;
  DataService._();

  AppData data = AppData();
  static const String _key = 'habitbreaker_data';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json != null) {
        data = AppData.fromJson(jsonDecode(json));
      }
    } catch (_) {}
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(data.toJson()));
    } catch (_) {}
  }

  void addHabit(String name, String emoji) {
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      emoji: emoji,
      startDate: DateTime.now(),
    );
    data.habits.add(habit);
    save();
  }

  void relapse(Habit habit) {
    habit.totalRelapses++;
    habit.streakDays = 0;
    habit.startDate = DateTime.now();
    save();
  }

  void addXp(int amount) {
    data.totalXp += amount;
    data.totalLevel = (data.totalXp / 100).floor() + 1;
    save();
  }

  void addMood(Habit habit, int mood, String note) {
    habit.moodHistory.add(MoodEntry(date: DateTime.now(), mood: mood, note: note));
    if (habit.moodHistory.length >= 10) addXp(40);
    save();
  }

  void addNote(Habit habit, String note) {
    habit.notes.add(note);
    if (habit.notes.length >= 5) addXp(35);
    save();
  }

  void deleteHabit(String id) {
    data.habits.removeWhere((h) => h.id == id);
    save();
  }

  void archiveHabit(String id) {
    final h = data.habits.firstWhere((h) => h.id == id);
    h.isArchived = true;
    save();
  }

  void updateDays() {
    for (final h in data.habits) {
      if (!h.isArchived) {
        h.streakDays = h.daysSinceStart;
      }
    }
    save();
  }

  Future<void> exportData() async {
    // Имитация экспорта
  }
}

// ═══════════════════════════════════════════════════════
//  АНИМИРОВАННЫЕ КОМПОНЕНТЫ
// ═══════════════════════════════════════════════════════

// Confetti Widget
class ConfettiWidget extends StatefulWidget {
  final bool show;
  const ConfettiWidget({super.key, required this.show});
  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _generateParticles();
  }

  void _generateParticles() {
    final random = math.Random();
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange, Colors.pink];
    _particles.clear();
    for (int i = 0; i < 60; i++) {
      _particles.add(_Particle(
        color: colors[random.nextInt(colors.length)],
        x: random.nextDouble() * 2 - 1,
        y: random.nextDouble() * 2 - 1,
        size: random.nextDouble() * 8 + 4,
        delay: random.nextDouble() * 0.5,
        rotation: random.nextDouble() * 360,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        _controller.forward(from: 0);
        return Stack(
          children: _particles.map((p) {
            final progress = math.max(0.0, (_controller.value - p.delay) / (1 - p.delay));
            if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
            final curved = Curves.easeOutCubic.transform(progress);
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 + p.x * curved * 200,
              top: MediaQuery.of(context).size.height / 2 + p.y * curved * 300 - progress * 200,
              child: Transform.rotate(
                angle: p.rotation * progress * math.pi,
                child: Container(
                  width: p.size,
                  height: p.size,
                  decoration: BoxDecoration(
                    color: p.color.withOpacity(1 - progress),
                    borderRadius: BorderRadius.circular(p.size / 2),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _Particle {
  final Color color;
  final double x, y, size, delay, rotation;
  _Particle({required this.color, required this.x, required this.y, required this.size, required this.delay, required this.rotation});
}

// Animated Progress Ring
class AnimatedProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final Color color;
  final String text;
  final String subtext;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 200,
    required this.color,
    required this.text,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(progress: progress, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOut,
                builder: (context, value, _) => Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(subtext, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) => old.progress != progress;
}

// Pulsing Button
class PulsingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color color;
  final double size;

  const PulsingButton({super.key, required this.onPressed, required this.child, required this.color, this.size = 56});

  @override
  State<PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<PulsingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final pulse = math.sin(_controller.value * 2 * math.pi) * 0.15 + 1;
          return Transform.scale(
            scale: pulse,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(child: widget.child),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Animated Counter
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle style;
  const AnimatedCounter({super.key, required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, val, _) => Text(val.toString(), style: style),
    );
  }
}

// Slide Transition Page
class SlideRoute extends PageRouteBuilder {
  final Widget page;
  SlideRoute(this.page)
      : super(
          pageBuilder: (context, animation, secondary) => page,
          transitionsBuilder: (context, animation, secondary, child) {
            final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

// ═══════════════════════════════════════════════════════
//  ГЛАВНОЕ ПРИЛОЖЕНИЕ
// ═══════════════════════════════════════════════════════

class HabitBreakerApp extends StatefulWidget {
  const HabitBreakerApp({super.key});
  @override
  State<HabitBreakerApp> createState() => _HabitBreakerAppState();
}

class _HabitBreakerAppState extends State<HabitBreakerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await DataService().load();
    DataService().updateDays();
    final data = DataService().data;
    setState(() => _themeMode = data.darkMode ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme() {
    setState(() => _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
    DataService().data.darkMode = _themeMode == ThemeMode.dark;
    DataService().save();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitBreaker',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: SplashScreen(onReady: () {}),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: brightness,
      ),
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF5F7FA),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SPLASH SCREEN
// ═══════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  final VoidCallback onReady;
  const SplashScreen({super.key, required this.onReady});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.of(context).pushReplacement(SlideRoute(const HomeScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            final scale = progress < 0.3 ? progress / 0.3 : 1.0;
            final opacity = progress < 0.2 ? progress / 0.2 : (progress > 0.8 ? (1 - progress) / 0.2 : 1.0);
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, val, _) => Transform.scale(
                        scale: 0.5 + val * 0.5,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFF6C63FF), const Color(0xFFE91E63)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.fitness_center, size: 60, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'HabitBreaker',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Брось вредные привычки',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: progress,
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 6,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════
//  ГЛАВНЫЙ ЭКРАН
// ═══════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
    final List<Widget> _screens = [
    const DashboardScreen(),
    const HabitsScreen(),
    const StatsScreen(),
    const AchievementsScreen(),
    const SettingsScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Главная'),
                _buildNavItem(1, Icons.list_alt_rounded, 'Привычки'),
                _buildNavItem(2, Icons.bar_chart_rounded, 'Статистика'),
                _buildNavItem(3, Icons.emoji_events_rounded, 'Награды'),
                _buildNavItem(4, Icons.settings_rounded, 'Настройки'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C63FF).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6C63FF) : (isDark ? Colors.grey[500] : Colors.grey[400]),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF6C63FF) : (isDark ? Colors.grey[500] : Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  DASHBOARD
// ═══════════════════════════════════════════════════════

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late AppData _data;

  @override
  void initState() {
    super.initState();
    _data = DataService().data;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeHabit = _data.activeHabit;
    final quote = quotes[DateTime.now().day % quotes.length];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6C63FF), const Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Text(
                                _data.userName.isEmpty ? '👤' : _data.userName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _data.userName.isEmpty ? 'Привет!' : 'Привет, ${_data.userName}!',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  'Уровень ${_data.totalLevel} • ${_data.totalXp} XP',
                                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quote card
                  _buildQuoteCard(quote, isDark),
                  const SizedBox(height: 16),

                  // Active habit card
                  if (activeHabit != null) _buildActiveHabitCard(activeHabit, isDark),

                  // Quick stats
                  _buildQuickStats(isDark),
                  const SizedBox(height: 16),

                  // Tip of the day
                  _buildTipCard(isDark),
                  const SizedBox(height: 16),

                  // Mood tracker
                  if (activeHabit != null) _buildMoodTracker(activeHabit, isDark),

                  // SOS Button
                  _buildSOSButton(isDark),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(Map<String, String> quote, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF),
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF8F0FF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: const Color(0xFF6C63FF), size: 20),
              const SizedBox(width: 8),
              Text('Цитата дня', style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF6C63FF))),
            ],
          ),
          const SizedBox(height: 8),
          Text(quote['text']!, style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          Text('— ${quote['author']}', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildActiveHabitCard(Habit habit, bool isDark) {
    final progress = math.min(1.0, habit.streakDays / 30.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6C63FF), const Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Без: ${habit.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(habit.statusText, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedProgressRing(
            progress: progress,
            size: 150,
            color: Colors.white,
            text: '${habit.streakDays} дн.',
            subtext: 'из 30 дней',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('🔥', '${habit.streakDays}', 'дней'),
              _statItem('⭐', '${habit.xp}', 'XP'),
              _statItem('📊', 'Ур.${habit.level}', 'уровень'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildQuickStats(bool isDark) {
    final habits = _data.habits.where((h) => !h.isArchived).toList();
    final totalDays = habits.fold<int>(0, (sum, h) => sum + h.streakDays);
    final totalRelapses = habits.fold<int>(0, (sum, h) => sum + h.totalRelapses);

    return Row(
      children: [
        Expanded(child: _quickStatCard('🎯', 'Привычек', '${habits.length}', isDark)),
        const SizedBox(width: 12),
        Expanded(child: _quickStatCard('📅', 'Дней всего', '$totalDays', isDark)),
        const SizedBox(width: 12),
        Expanded(child: _quickStatCard('🔄', 'Срывов', '$totalRelapses', isDark)),
      ],
    );
  }

  Widget _quickStatCard(String emoji, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildTipCard(bool isDark) {
    final tip = tips[DateTime.now().day % tips.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lightbulb, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Совет дня', style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF10B981), fontSize: 13)),
                const SizedBox(height: 2),
                Text(tip, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTracker(Habit habit, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mood, color: const Color(0xFF6C63FF)),
              const SizedBox(width: 8),
              const Text('Как настроение?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _moodButton('😢', 1, habit),
              _moodButton('😕', 2, habit),
              _moodButton('😐', 3, habit),
              _moodButton('🙂', 4, habit),
              _moodButton('😄', 5, habit),
            ],
          ),
          if (habit.moodHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Последние записи:', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[500])),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: habit.moodHistory.take(7).map((m) {
                  final emojis = ['😢', '', '😐', '🙂', '😄'];
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(emojis[m.mood - 1], style: const TextStyle(fontSize: 18)),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _moodButton(String emoji, int mood, Habit habit) {
    return GestureDetector(
      onTap: () {
        DataService().addMood(habit, mood, '');
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Настроение записано! $emoji'), duration: const Duration(seconds: 1)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  Widget _buildSOSButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        showDialog(
          context: context,
          builder: (ctx) => _SOSDialog(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.flash_on, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('SOS — Тянет сорваться?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Нажми для экстренной помощи', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SOS DIALOG
// ═══════════════════════════════════════════════════════

class _SOSDialog extends StatefulWidget {
  @override
  State<_SOSDialog> createState() => _SOSDialogState();
}

class _SOSDialogState extends State<_SOSDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;

  final List<Map<String, String>> _steps = [
    {'title': '🫁 Дыши глубоко', 'desc': 'Вдох на 4 счёта, задержи на 4, выдох на 4. Повтори 5 раз.'},
    {'title': '💧 Выпей воды', 'desc': 'Выпей стакан холодной воды медленными глотками.'},
    {'title': '🧊 Подержи лёд', 'desc': 'Возьми кубик льда в руку и сосредоточься на ощущении холода.'},
    {'title': '📞 Позвони другу', 'desc': 'Позвони кому-то, кто тебя поддержит.'},
    {'title': ' Прогуляйся', 'desc': 'Выйди на улицу и прогуляйся 10 минут.'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🆘 Экстренная помощь', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey(_currentStep),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(step['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(step['desc']!, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
                    child: const Text('← Назад'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _currentStep < _steps.length - 1
                        ? () => setState(() => _currentStep++)
                        : () => Navigator.pop(context),
                    child: Text(_currentStep < _steps.length - 1 ? 'Далее →' : 'Готово ✓'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════
//  HABITS SCREEN
// ═══════════════════════════════════════════════════════

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  late AppData _data;

  @override
  void initState() {
    super.initState();
    _data = DataService().data;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habits = _data.habits.where((h) => !h.isArchived).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Мои привычки', style: TextStyle(fontWeight: FontWeight.bold)),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddHabitDialog(),
              ),
            ],
          ),
          if (habits.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎯', style: const TextStyle(fontSize: 60)),
                    const SizedBox(height: 16),
                    Text(
                      'Добавь привычку,\nот которой хочешь избавиться',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _showAddHabitDialog,
                      child: const Text('Добавить привычку'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final habit = habits[index];
                  return _buildHabitCard(habit, isDark, index);
                }, childCount: habits.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 100),
      curve: Curves.easeOut,
      builder: (context, val, child) => Transform.translate(
        offset: Offset(0, 50 * (1 - val)),
        child: Opacity(opacity: val, child: child),
      ),
      child: Dismissible(
        key: Key(habit.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) {
          DataService().deleteHabit(habit.id);
          setState(() => _data = DataService().data);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(habit.emoji, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '🔥 ${habit.streakDays} дней • ⭐ ${habit.xp} XP • Ур.${habit.level}',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: math.min(1.0, habit.streakDays / 30.0),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                onSelected: (val) {
                  if (val == 'relapse') {
                    DataService().relapse(habit);
                    DataService().addXp(30);
                    setState(() => _data = DataService().data);
                    HapticFeedback.mediumImpact();
                  } else if (val == 'note') {
                    _showNoteDialog(habit);
                  } else if (val == 'archive') {
                    DataService().archiveHabit(habit.id);
                    setState(() => _data = DataService().data);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'relapse', child: Text('🔄 Срыв — начать заново')),
                  const PopupMenuItem(value: 'note', child: Text('📝 Добавить заметку')),
                  const PopupMenuItem(value: 'archive', child: Text('📦 В архив')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddHabitDialog(onAdded: () {
        Navigator.pop(ctx);
        setState(() => _data = DataService().data);
      }),
    );
  }

  void _showNoteDialog(Habit habit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📝 Заметка'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Запиши свои мысли...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                DataService().addNote(habit, controller.text.trim());
                setState(() => _data = DataService().data);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  ADD HABIT DIALOG
// ═══════════════════════════════════════════════════════

class _AddHabitDialog extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddHabitDialog({required this.onAdded});

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  String _selectedPreset = 'Своя привычка';
  String _selectedEmoji = '⚡';
  final _customController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('➕ Новая привычка', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: habitPresets.map((p) {
                final isSelected = _selectedPreset == p['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPreset = p['name']!;
                      _selectedEmoji = p['emoji']!;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6C63FF) : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p['emoji']!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          p['name']!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700]),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_selectedPreset == 'Своя привычка')
              TextField(
                controller: _customController,
                decoration: const InputDecoration(
                  labelText: 'Название привычки',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final name = _selectedPreset == 'Своя привычка'
                      ? (_customController.text.trim().isEmpty ? 'Привычка' : _customController.text.trim())
                      : _selectedPreset;
                  DataService().addHabit(name, _selectedEmoji);
                  DataService().addXp(20);
                  widget.onAdded();
                  HapticFeedback.mediumImpact();
                },
                child: const Text('Начать путь к свободе! 🚀', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  STATS SCREEN
// ═══════════════════════════════════════════════════════

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late AppData _data;

  @override
  void initState() {
    super.initState();
    _data = DataService().data;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habits = _data.habits.where((h) => !h.isArchived).toList();
    final bestStreak = habits.isEmpty ? 0 : habits.map((h) => h.streakDays).reduce((a, b) => a > b ? a : b);
    final totalDays = habits.fold<int>(0, (sum, h) => sum + h.streakDays);
    final avgMood = habits.fold<double>(0, (sum, h) {
      if (h.moodHistory.isEmpty) return sum;
      return sum + h.moodHistory.map((m) => m.mood).reduce((a, b) => a + b) / h.moodHistory.length;
    }) / (habits.where((h) => h.moodHistory.isNotEmpty).isEmpty ? 1 : habits.where((h) => h.moodHistory.isNotEmpty).length);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Статистика', style: TextStyle(fontWeight: FontWeight.bold)),
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // XP Progress
                _buildXPProgress(isDark),
                const SizedBox(height: 16),

                // Key metrics
                Row(
                  children: [
                    Expanded(child: _metricCard('🏆', 'Лучшая серия', '$bestStreak дн.', isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _metricCard('📅', 'Всего дней', '$totalDays', isDark)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _metricCard('😊', 'Среднее настроение', avgMood > 0 ? avgMood.toStringAsFixed(1) : '—', isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _metricCard('📝', 'Заметок', '${habits.fold<int>(0, (s, h) => s + h.notes.length)}', isDark)),
                  ],
                ),
                const SizedBox(height: 16),

                // Mood chart
                if (habits.any((h) => h.moodHistory.isNotEmpty))
                  _buildMoodChart(habits, isDark),

                const SizedBox(height: 16),

                // Habits breakdown
                _buildHabitsBreakdown(habits, isDark),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPProgress(bool isDark) {
    final xpInLevel = _data.totalXp % 100;
    final progress = xpInLevel / 100.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Уровень ${_data.totalLevel}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('${_data.totalXp} XP всего', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text('$xpInLevel / 100 XP до следующего уровня', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _metricCard(String emoji, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          AnimatedCounter(value: int.tryParse(value) ?? 0, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildMoodChart(List<Habit> habits, bool isDark) {
    final allMoods = habits.expand((h) => h.moodHistory).toList()..sort((a, b) => b.date.compareTo(a.date));
    final recent = allMoods.take(14).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: const Color(0xFF6C63FF)),
              const SizedBox(width: 8),
              const Text('График настроения', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: recent.reversed.map((m) {
                final height = m.mood * 16.0;
                final colors = [Colors.red, Colors.orange, Colors.amber, Colors.lightGreen, Colors.green];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 12,
                      height: height,
                      decoration: BoxDecoration(
                        color: colors[m.mood - 1],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('14 дн. назад', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[500] : Colors.grey[400])),
              Text('Сегодня', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[500] : Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsBreakdown(List<Habit> habits, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 По привычкам', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...habits.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(h.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(h.name, style: const TextStyle(fontSize: 14))),
                    Text('${h.streakDays} дн.', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  ACHIEVEMENTS SCREEN
// ═══════════════════════════════════════════════════════

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late AppData _data;

  @override
  void initState() {
    super.initState();
    _data = DataService().data;
  }

  bool _isUnlocked(Map<String, dynamic> a) {
    final habit = _data.activeHabit;
    if (habit == null) return false;
    switch (a['id']) {
      case 'first_day': return habit.streakDays >= 1;
      case 'week_1': return habit.streakDays >= 7;
      case 'two_weeks': return habit.streakDays >= 14;
      case 'month': return habit.streakDays >= 30;
      case 'quarter': return habit.streakDays >= 90;
      case 'half_year': return habit.streakDays >= 180;
      case 'year': return habit.streakDays >= 365;
      case 'relapse_comeback': return habit.totalRelapses > 0 && habit.streakDays >= 1;
      case 'mood_master': return habit.moodHistory.length >= 10;
      case 'note_writer': return habit.notes.length >= 5;
      default: return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unlocked = achievements.where(_isUnlocked).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Достижения', style: TextStyle(fontWeight: FontWeight.bold)),
            floating: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 40)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$unlocked / ${achievements.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('достижений получено', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final a = achievements[index];
                final isUnlocked = _isUnlocked(a);
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + index * 100),
                  curve: Curves.easeOut,
                  builder: (context, val, child) => Transform.scale(scale: val, child: child),
                  child: _AchievementCard(achievement: a, isUnlocked: isUnlocked, isDark: isDark),
                );
              }, childCount: achievements.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Map<String, dynamic> achievement;
  final bool isUnlocked;
  final bool isDark;

  const _AchievementCard({required this.achievement, required this.isUnlocked, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : (isDark ? const Color(0xFF0D1117) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? const Color(0xFFF59E0B) : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.2), blurRadius: 15)]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: isUnlocked ? 1.0 : 0.3,
            child: Text(achievement['icon'], style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 8),
          Text(
            achievement['name'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? null : (isDark ? Colors.grey[600] : Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement['desc'],
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[500] : Colors.grey[400]),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isUnlocked ? const Color(0xFFF59E0B).withOpacity(0.2) : (isDark ? Colors.grey[800] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isUnlocked ? '✅ +${achievement['xp']} XP' : '🔒 +${achievement['xp']} XP',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isUnlocked ? const Color(0xFFF59E0B) : (isDark ? Colors.grey[600] : Colors.grey[400])),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SETTINGS SCREEN
// ═══════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppData _data;

  @override
  void initState() {
    super.initState();
    _data = DataService().data;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.bold)),
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile
                _settingsSection(isDark, '👤 Профиль', [
                  _settingsTile(
                    isDark,
                    'Имя',
                    _data.userName.isEmpty ? 'Не указано' : _data.userName,
                    onTap: () => _showNameDialog(),
                  ),
                ]),
                const SizedBox(height: 16),

                // Appearance
                _settingsSection(isDark, '🎨 Оформление', [
                  _settingsTile(
                    isDark,
                    'Тёмная тема',
                    '',
                    trailing: Switch(
                      value: _data.darkMode,
                      onChanged: (val) {
                        setState(() => _data.darkMode = val);
                        DataService().data.darkMode = val;
                        DataService().save();
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Preferences
                _settingsSection(isDark, '⚙️ Настройки', [
                  _settingsTile(
                    isDark,
                    'Вибрация',
                    '',
                    trailing: Switch(
                      value: _data.hapticsEnabled,
                      onChanged: (val) {
                        setState(() => _data.hapticsEnabled = val);
                        DataService().data.hapticsEnabled = val;
                        DataService().save();
                      },
                    ),
                  ),
                  _settingsTile(
                    isDark,
                    'Уведомления',
                    '',
                    trailing: Switch(
                      value: _data.notificationsEnabled,
                      onChanged: (val) {
                        setState(() => _data.notificationsEnabled = val);
                        DataService().data.notificationsEnabled = val;
                        DataService().save();
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Data
                _settingsSection(isDark, '💾 Данные', [
                  _settingsTile(isDark, 'Экспорт данных', '', onTap: _exportData),
                  _settingsTile(isDark, 'Очистить все данные', '', onTap: _clearData, danger: true),
                ]),
                const SizedBox(height: 16),

                // About
                _settingsSection(isDark, 'ℹ️ О приложении', [
                  _settingsTile(isDark, 'Версия', '1.0.0'),
                  _settingsTile(isDark, 'Разработчик', 'Sliva2010'),
                ]),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsSection(bool isDark, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[500])),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _settingsTile(bool isDark, String title, String subtitle, {Widget? trailing, VoidCallback? onTap, bool danger = false}) {
    return ListTile(
      title: Text(title, style: TextStyle(color: danger ? Colors.red : null)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[500])) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showNameDialog() {
    final controller = TextEditingController(text: _data.userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('👤 Ваше имя'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Введите имя'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              setState(() => _data.userName = controller.text.trim());
              DataService().data.userName = controller.text.trim();
              DataService().save();
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    final json = jsonEncode(DataService().data.toJson());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Данные экспортированы! (${json.length} символов)'), duration: const Duration(seconds: 2)),
    );
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Очистить данные?'),
        content: const Text('Все привычки, статистика и достижения будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              DataService().data = AppData();
              DataService().save();
              setState(() => _data = DataService().data);
              Navigator.pop(ctx);
              Navigator.pop(ctx);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
