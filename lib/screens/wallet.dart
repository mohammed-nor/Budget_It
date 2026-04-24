import 'package:budget_it/services/styles%20and%20constants.dart';
import 'package:budget_it/services/gemini_service.dart';
import 'package:budget_it/screens/api_key_manager_screen.dart';
import 'package:budget_it/models/budget_history.dart';
import 'package:budget_it/models/upcoming_spending.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:budget_it/utils/language_controller.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Box budgetsBox;
  late Box dataBox;

  String? _aiAdvice;
  bool _isLoadingAdvice = false;
  String? _adviceError;
  DateTime? _lastAdviceTime;

  final List<SpendingCategory> categories = [
    SpendingCategory(
      title: 'personal_expenses',
      description: 'personal_expenses_desc',
      budget: 150,
    ),
    SpendingCategory(
      title: 'home_expenses',
      description: 'home_expenses_desc',
      budget: 500,
    ),
    SpendingCategory(
      title: 'transport',
      description: 'transport_desc',
      budget: 200,
    ),
    SpendingCategory(
      title: 'entertainment',
      description: 'entertainment_desc',
      budget: 100,
    ),
    SpendingCategory(
      title: 'emergency',
      description: 'emergency_desc',
      budget: 100,
    ),
    SpendingCategory(
      title: 'other_expenses',
      description: 'other_expenses_desc',
      budget: 250,
    ),
  ];

  final double maxIncrement = 3000;
  double monthlyIncrement = 3000;

  final Color cardColor = const Color.fromRGBO(30, 30, 30, 1.0);
  final List<double> incrementRatios = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  @override
  void initState() {
    super.initState();
    budgetsBox = Hive.box('budgets');
    dataBox = Hive.box('data');

    GeminiService.initialize();

    // Load previously saved advice
    _loadSavedAdvice();

    for (var i = 0; i < categories.length; i++) {
      final saved = budgetsBox.get(categories[i].title);
      if (saved != null) categories[i].budget = saved;
      super.initState();
      cardcolor = prefsdata.get(
        "cardcolor",
        defaultValue: const Color.fromRGBO(20, 20, 20, 1.0),
      );
    }
  }

  // Helper method to determine if theme is dark
  bool _isDarkTheme() {
    final cardColor = prefsdata.get(
      "cardcolor",
      defaultValue: const Color.fromRGBO(20, 20, 20, 1.0),
    );
    if (cardColor is Color) {
      final luminance = cardColor.computeLuminance();
      return luminance < 0.5;
    }
    return true;
  }

  // Helper method to get text color based on theme
  Color _getTextColor() {
    return _isDarkTheme() ? Colors.white : Colors.black87;
  }

  // Helper method to get secondary text color based on theme
  Color _getSecondaryTextColor() {
    return _isDarkTheme() ? Colors.white70 : Colors.black54;
  }

  void _loadSavedAdvice() {
    final savedAdvice = dataBox.get('ai_advice');
    final savedTimestamp = dataBox.get('ai_advice_timestamp');

    if (savedAdvice != null) {
      setState(() {
        _aiAdvice = savedAdvice;
        if (savedTimestamp != null) {
          _lastAdviceTime = DateTime.parse(savedTimestamp);
        }
      });
    }
  }

  void _saveAdviceToStorage(String advice) {
    try {
      dataBox.put('ai_advice', advice);
      dataBox.put('ai_advice_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving advice to storage: $e');
    }
  }

  double getCategoryIncrement(int index) {
    return monthlyIncrement * incrementRatios[index];
  }

  void saveCategoryUpdate(int index, double amount) {
    final keyDate = '${categories[index].title}_lastUpdateDate';
    final keyAmount = '${categories[index].title}_lastUpdateAmount';
    budgetsBox.put(keyDate, DateTime.now().toIso8601String());
    budgetsBox.put(keyAmount, amount);
  }

  double getCurrentBudget(int index) {
    final keyDate = '${categories[index].title}_lastUpdateDate';
    final keyAmount = '${categories[index].title}_lastUpdateAmount';
    final lastUpdateDateStr = budgetsBox.get(keyDate);
    final lastUpdateAmount = budgetsBox.get(
      keyAmount,
      defaultValue: categories[index].budget,
    );

    if (lastUpdateDateStr == null) return categories[index].budget;

    final lastUpdateDate = DateTime.parse(lastUpdateDateStr);
    final now = DateTime.now();
    final daysPassed = now.difference(lastUpdateDate).inDays;

    final dailyDecrement = getCategoryIncrement(index) / 30.5;
    final newBudget = lastUpdateAmount - (daysPassed * dailyDecrement);

    return newBudget < 0 ? 0 : newBudget;
  }

  Future<void> _fetchFinancialAdvice() async {
    if (!GeminiService.hasApiKey()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('configure_api_key_msg'.tr),
          action: SnackBarAction(
            label: 'setup'.tr,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApiKeyManagerScreen(),
                ),
              );
              if (result == true && mounted) {
                _fetchFinancialAdvice();
              }
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingAdvice = true;
      _adviceError = null;
    });

    try {
      // Get income and spending data from budget page (prefsdata)
      final num mntinc = prefsdata.get("mntinc", defaultValue: 4300);
      final num mntnstblinc = prefsdata.get("mntnstblinc", defaultValue: 2000);
      final num mntperinc = prefsdata.get("mntperinc", defaultValue: 40);
      final num freemnt = prefsdata.get("freemnt", defaultValue: 2);
      final num mntexp = prefsdata.get("mntexp", defaultValue: 2000);
      final num annexp = prefsdata.get("annexp", defaultValue: 7000);
      final num mntsaving = prefsdata.get("mntsaving", defaultValue: 1000);

      // Calculate daily spending using budget page formula
      final now = DateTime.now();
      final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
      final num mntSpending =
          ((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
                          (1 - freemnt / 12) -
                      (mntexp + annexp / 12) -
                      (mntsaving)) /
                  daysInCurrentMonth))
              .round() *
          30.45;

      // Get data from Budget page (budget_history box)
      final budgetHistoryBox = Hive.box<BudgetHistory>('budget_history');
      final upcomingSpendingBox = Hive.box<UpcomingSpending>(
        'upcoming_spending',
      );

      // Calculate total net credit from history
      double totalNetCredit = 0;
      int recordCount = 0;

      for (var i = 0; i < budgetHistoryBox.length; i++) {
        final history = budgetHistoryBox.getAt(i);
        if (history != null) {
          totalNetCredit += history.nownetcredit;
          recordCount++;
        }
      }

      final averageNetCredit = recordCount > 0
          ? totalNetCredit / recordCount
          : 0;

      // Get upcoming spending to include in analysis
      double upcomingExpenses = 0;
      for (var i = 0; i < upcomingSpendingBox.length; i++) {
        final upcoming = upcomingSpendingBox.getAt(i);
        if (upcoming != null) {
          upcomingExpenses += upcoming.amount;
        }
      }

      final categoryBudgets = <String, double>{};
      for (var category in categories) {
        categoryBudgets[category.title] = getCurrentBudget(
          categories.indexOf(category),
        );
      }

      // Calculate saved amount from budget history
      // Represents total accumulated net credit
      double savedAmount = 0;

      if (budgetHistoryBox.isNotEmpty) {
        final latestHistory = budgetHistoryBox.getAt(
          budgetHistoryBox.length - 1,
        );
        if (latestHistory != null) {
          savedAmount = latestHistory.nownetcredit.toDouble();
        }
      }

      final advice = await GeminiService.generateFinancialAdvice(
        categoryBudgets: categoryBudgets,
        monthlyIncome: mntinc.toDouble(),
        fixedmonthlyExpenses: mntexp.toDouble(),
        currentSavings: mntsaving.toDouble(),
        netCredit: averageNetCredit.toDouble(),
        categoryDescriptions: categories.map((c) => c.description).toList(),
        upcomingExpenses: upcomingExpenses,
        availableFunds: mntSpending.toDouble(),
        savedAmount: savedAmount,
        language: Get.locale?.languageCode ?? 'ar',
      );

      if (mounted) {
        setState(() {
          _aiAdvice = advice;
          _lastAdviceTime = DateTime.now();
          _isLoadingAdvice = false;
        });
        // Save advice to storage
        _saveAdviceToStorage(advice);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _adviceError = e.toString();
          _isLoadingAdvice = false;
        });
      }
    }
  }

  void _openApiKeyManager() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ApiKeyManagerScreen()),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = Get.locale?.languageCode == 'ar';
    return ValueListenableBuilder(
      valueListenable: prefsdata.listenable(
        keys: ['cardcolor', 'fontsize1', 'fontSize1'],
      ),
      builder: (context, box, child) {
        double fontSize1 = box.get("fontsize1", defaultValue: 15.toDouble());
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              // AI Financial Advisor Section
              Card(
                color: prefsdata.get(
                  "cardcolor",
                  defaultValue: Color.fromRGBO(20, 20, 20, 1.0),
                ),
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: isAr
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Text(
                                'smart_advisor'.tr,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: _getTextColor(),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.key, color: Colors.green),
                            onPressed: _openApiKeyManager,
                            tooltip: 'configure_api_key_tooltip'.tr,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'get_advice_msg'.tr,
                        textAlign: Get.locale?.languageCode == 'ar'
                            ? TextAlign.right
                            : TextAlign.left,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getSecondaryTextColor(),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingAdvice)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade900.withOpacity(0.2),
                                Colors.blue.shade800.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.blue.shade400.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade700.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'analyzing_data'.tr,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.blue.shade300,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'please_wait'.tr,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.blue.shade400,
                                        fontSize: 12,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_adviceError != null)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade900.withOpacity(0.25),
                                Colors.red.shade800.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red.shade400.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade700.withOpacity(
                                        0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade300,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'error_fetching_advice'.tr,
                                      style: TextStyle(
                                        color: Colors.red.shade300,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _adviceError!.replaceAll('Exception: ', ''),
                                style: TextStyle(
                                  color: Colors.red.shade200,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_aiAdvice != null)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade900.withOpacity(0.3),
                                Colors.green.shade800.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.shade400.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade700.withOpacity(
                                        0.4,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.auto_awesome,
                                      color: Colors.green.shade300,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'personalized_advice'.tr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.green.shade300,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Advice Content with Markdown Rendering (RTL for Arabic)
                              Directionality(
                                textDirection: Get.locale?.languageCode == 'ar'
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                child: MarkdownBody(
                                  data: _aiAdvice!,
                                  selectable: true,
                                  styleSheet: MarkdownStyleSheet(
                                    h1: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.green.shade300,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    h2: Theme.of(context).textTheme.titleLarge
                                        ?.copyWith(
                                          color: Colors.green.shade300,
                                          fontWeight: FontWeight.bold,
                                        ),
                                    h3: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(
                                          color: Colors.green.shade300,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    p: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(
                                          color: _getTextColor(),
                                          fontSize: 13,
                                          height: 1.8,
                                        ),
                                    strong: TextStyle(
                                      color: Colors.green.shade300,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    em: TextStyle(
                                      color: Colors.green.shade200,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                    listBullet: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: _getTextColor(),
                                          fontSize: 13,
                                          height: 1.6,
                                        ),
                                    code: TextStyle(
                                      backgroundColor: Colors.green.shade900
                                          .withOpacity(0.3),
                                      color: Colors.green.shade200,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                    blockquoteDecoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Colors.green.shade400,
                                          width: 4,
                                        ),
                                      ),
                                      color: Colors.green.shade900.withOpacity(
                                        0.15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Divider
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade700.withOpacity(0.3),
                                      Colors.green.shade700.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Last Updated
                              if (_lastAdviceTime != null)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: Colors.green.shade400,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'last_updated'.tr,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.green.shade400,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _lastAdviceTime!
                                          .toLocal()
                                          .toString()
                                          .split('.')[0],
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Colors.green.shade300,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        )
                      else
                        Text(
                          'press_for_advice'.tr,
                          textAlign: Get.locale?.languageCode == 'ar'
                              ? TextAlign.right
                              : TextAlign.left,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _getSecondaryTextColor(),
                                fontSize: 13,
                              ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingAdvice
                              ? null
                              : _fetchFinancialAdvice,
                          icon: Icon(
                            _isLoadingAdvice
                                ? Icons.schedule
                                : (_aiAdvice != null
                                      ? Icons.refresh
                                      : Icons.lightbulb_outline),
                            size: 20,
                          ),
                          label: Text(
                            _aiAdvice != null
                                ? 'update_advice'.tr
                                : 'get_advice_btn'.tr,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: _getTextColor(),
                            disabledBackgroundColor: Colors.green.shade900
                                .withOpacity(0.4),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: Colors.green.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ...List.generate(categories.length, (index) {
                return BudgetCard(
                  category: categories[index],
                  onBudgetChanged: (newValue) {
                    setState(() {
                      categories[index].budget = newValue;
                      budgetsBox.put(categories[index].title, newValue);
                      saveCategoryUpdate(index, newValue);
                    });
                  },
                  cardColor: cardColor,
                  index: index,
                  getCategoryIncrement: getCategoryIncrement,
                  getCurrentBudget: getCurrentBudget,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class BudgetCard extends StatelessWidget {
  final SpendingCategory category;
  final Function(double) onBudgetChanged;
  final Color cardColor;
  final int index;
  final double Function(int) getCategoryIncrement;
  final double Function(int) getCurrentBudget;

  const BudgetCard({
    super.key,
    required this.category,
    required this.onBudgetChanged,
    required this.cardColor,
    required this.index,
    required this.getCategoryIncrement,
    required this.getCurrentBudget,
  });

  @override
  Widget build(BuildContext context) {
    // Helper methods for theme-aware colors
    bool isDarkTheme() {
      final cardColor = prefsdata.get(
        "cardcolor",
        defaultValue: const Color.fromRGBO(20, 20, 20, 1.0),
      );
      if (cardColor is Color) {
        final luminance = cardColor.computeLuminance();
        return luminance < 0.5;
      }
      return true;
    }

    Color getTextColor() => isDarkTheme() ? Colors.white : Colors.black87;
    Color getSecondaryTextColor() =>
        isDarkTheme() ? Colors.white70 : Colors.black54;

    final List<double> incrementRatios = [0.55, 0.20, 0.10, 0.05, 0.05, 0.05];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: prefsdata.get(
          "cardcolor",
          defaultValue: Color.fromRGBO(20, 20, 20, 1.0),
        ),
        //gradient: const LinearGradient(colors: [Color(0xFF232323), Color(0xFF1A1A1A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: Colors.green.withOpacity(0.15), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          mainAxisAlignment: Get.locale?.languageCode == 'ar'
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.wallet,
                    color: Colors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.title.tr,
                    textAlign: Get.locale?.languageCode == 'ar'
                        ? TextAlign.right
                        : TextAlign.left,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: getTextColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              category.description.tr,
              textAlign: Get.locale?.languageCode == 'ar'
                  ? TextAlign.right
                  : TextAlign.left,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: getSecondaryTextColor(),
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(
                text: getCurrentBudget(index).toStringAsFixed(2),
              ),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'remaining'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.green, width: 1.2),
                ),
                labelStyle: const TextStyle(color: Colors.white),
                floatingLabelAlignment: FloatingLabelAlignment.center,
                suffixText: LanguageController.to.currency.value,
                filled: true,
                fillColor: Colors.black.withOpacity(0.15),
              ),
              style: TextStyle(
                color: getTextColor(),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  onBudgetChanged(double.parse(value));
                }
              },
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => onBudgetChanged(category.budget - 5),
                  child: const Text('-5'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade900,
                    foregroundColor: getTextColor(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => onBudgetChanged(category.budget - 1),
                  child: const Text('-1'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade900,
                    foregroundColor: getTextColor(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => onBudgetChanged(category.budget + 1),
                  child: const Text('+1'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => onBudgetChanged(category.budget + 5),
                  child: const Text('+5'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SpendingCategory {
  final String title;
  final String description;
  double budget;

  SpendingCategory({
    required this.title,
    required this.description,
    required this.budget,
  });
}
