import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/budget_history.dart';
import '../models/upcoming_spending.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  static String? _apiKey;

  // Initialize with API key from Hive
  static Future<void> initialize() async {
    try {
      final prefsBox = Hive.box('data');
      _apiKey = prefsBox.get('gemini_api_key');
    } catch (e) {
      print('Error initializing Gemini: $e');
    }
  }

  // Save API key to Hive
  static Future<void> saveApiKey(String apiKey) async {
    try {
      final prefsBox = Hive.box('data');
      await prefsBox.put('gemini_api_key', apiKey);
      _apiKey = apiKey;
    } catch (e) {
      print('Error saving API key: $e');
      rethrow;
    }
  }

  // Get stored API key
  static String? getApiKey() {
    return _apiKey;
  }

  // Check if API key is set
  static bool hasApiKey() {
    return _apiKey != null && _apiKey!.isNotEmpty;
  }

  // Clear API key
  static Future<void> clearApiKey() async {
    try {
      final prefsBox = Hive.box('data');
      await prefsBox.delete('gemini_api_key');
      _apiKey = null;
    } catch (e) {
      print('Error clearing API key: $e');
      rethrow;
    }
  }

  // Generate financial advice based on spending habits
  static Future<String> generateFinancialAdvice({
    required Map<String, double> categoryBudgets,
    required double monthlyIncome,
    required double fixedmonthlyExpenses,
    required double currentSavings,
    required double netCredit,
    required List<String> categoryDescriptions,
    double? upcomingExpenses,
    double? availableFunds,
    double? fixedMonthlyExpenses,
    double? savedAmount,
    String? language,
  }) async {
    // If values are not provided, fetch them from Hive
    final prefsBox = Hive.box('data');
    final String effectiveLanguage =
        language ?? prefsBox.get('language', defaultValue: 'ar');

    double effectiveUpcomingExpenses = upcomingExpenses ?? 0;
    if (upcomingExpenses == null) {
      final upcomingBox = Hive.box<UpcomingSpending>('upcoming_spending');
      effectiveUpcomingExpenses = upcomingBox.values.fold<double>(
        0.0,
        (sum, item) => sum + item.amount,
      );
    }

    double effectiveSavedAmount = savedAmount ?? 0;
    if (savedAmount == null) {
      final historyBox = Hive.box<BudgetHistory>('budget_history');
      if (historyBox.isNotEmpty) {
        effectiveSavedAmount = historyBox.values.last.nownetcredit.toDouble();
      }
    }

    double effectiveFixedMonthlyExpenses = fixedMonthlyExpenses ?? 0;
    if (fixedMonthlyExpenses == null) {
      final num mntexp = prefsBox.get("mntexp", defaultValue: 2000);
      final num annexp = prefsBox.get("annexp", defaultValue: 7000);
      effectiveFixedMonthlyExpenses =
          mntexp.toDouble() + (annexp.toDouble() / 12);
    }

    double effectiveAvailableFunds = availableFunds ?? 0;
    if (availableFunds == null) {
      final num mntinc = prefsBox.get("mntinc", defaultValue: 4300);
      final num mntnstblinc = prefsBox.get("mntnstblinc", defaultValue: 2000);
      final num mntperinc = prefsBox.get("mntperinc", defaultValue: 40);
      final num freemnt = prefsBox.get("freemnt", defaultValue: 2);
      final num mntexp = prefsBox.get("mntexp", defaultValue: 2000);
      final num annexp = prefsBox.get("annexp", defaultValue: 7000);
      final num mntsaving = prefsBox.get("mntsaving", defaultValue: 1000);

      final now = DateTime.now();
      final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;

      effectiveAvailableFunds =
          ((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
                          (1 - freemnt / 12) -
                      (mntexp + annexp / 12) -
                      (mntsaving)) /
                  daysInCurrentMonth))
              .round() *
          30.45;
    }

    if (!hasApiKey()) {
      throw Exception(
        'API key not configured. Please set your Gemini API key.',
      );
    }

    final prompt = _buildFinancialPrompt(
      categoryBudgets: categoryBudgets,
      monthlyIncome: monthlyIncome,
      fixedmonthlyExpenses: fixedmonthlyExpenses,
      currentSavings: currentSavings,
      netCredit: netCredit,
      categoryDescriptions: categoryDescriptions,
      upcomingExpenses: effectiveUpcomingExpenses,
      availableFunds: effectiveAvailableFunds,
      fixedMonthlyExpenses: effectiveFixedMonthlyExpenses,
      savedAmount: effectiveSavedAmount,
      language: effectiveLanguage,
    );

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.7 /*'maxOutputTokens': 048*/,
              },
              'safetySettings': [
                {
                  'category': 'HARM_CATEGORY_HARASSMENT',
                  'threshold': 'BLOCK_NONE',
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        return content;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your Gemini API key.');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception(
          'Error from Gemini API: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Build detailed financial prompt
  static String _buildFinancialPrompt({
    required Map<String, double> categoryBudgets,
    required double monthlyIncome,
    required double fixedmonthlyExpenses,
    required double currentSavings,
    required double netCredit,
    required List<String> categoryDescriptions,
    double? upcomingExpenses,
    double? availableFunds,
    double? fixedMonthlyExpenses,
    double? savedAmount,
    String? language,
  }) {
    // Synchronous fallback from Hive if parameters are null
    final prefsBox = Hive.box('data');
    final String finalLanguage =
        language ?? prefsBox.get('language', defaultValue: 'ar');

    final double finalUpcomingExpenses =
        upcomingExpenses ??
        Hive.box<UpcomingSpending>(
          'upcoming_spending',
        ).values.fold<double>(0.0, (sum, item) => sum + item.amount);

    double finalSavedAmount = savedAmount ?? 0;
    if (savedAmount == null) {
      final historyBox = Hive.box<BudgetHistory>('budget_history');
      if (historyBox.isNotEmpty) {
        finalSavedAmount = historyBox.values.last.nownetcredit.toDouble();
      }
    }

    double finalFixedMonthlyExpenses = fixedMonthlyExpenses ?? 0;
    if (fixedMonthlyExpenses == null) {
      final num mntexp = prefsBox.get("mntexp", defaultValue: 2000);
      final num annexp = prefsBox.get("annexp", defaultValue: 7000);
      finalFixedMonthlyExpenses = mntexp.toDouble() + (annexp.toDouble() / 12);
    }

    double finalAvailableFunds = availableFunds ?? 0;
    if (availableFunds == null) {
      final num mntinc = prefsBox.get("mntinc", defaultValue: 4300);
      final num mntnstblinc = prefsBox.get("mntnstblinc", defaultValue: 2000);
      final num mntperinc = prefsBox.get("mntperinc", defaultValue: 40);
      final num freemnt = prefsBox.get("freemnt", defaultValue: 2);
      final num mntexp = prefsBox.get("mntexp", defaultValue: 2000);
      final num annexp = prefsBox.get("annexp", defaultValue: 7000);
      final num mntsaving = prefsBox.get("mntsaving", defaultValue: 1000);

      final now = DateTime.now();
      final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;

      finalAvailableFunds =
          ((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
                          (1 - freemnt / 12) -
                      (mntexp + annexp / 12) -
                      (mntsaving)) /
                  daysInCurrentMonth))
              .round() *
          30.45;
    }

    final budgetBreakdown = categoryBudgets.entries
        .toList()
        .asMap()
        .entries
        .map((e) {
          final index = e.key;
          final entry = e.value;
          final desc = index < categoryDescriptions.length
              ? categoryDescriptions[index]
              : '';
          return '- ${entry.key}: ${entry.value.toStringAsFixed(2)} MAD ($desc)';
        })
        .join('\n');

    final totalBudget = categoryBudgets.values.fold(0.0, (a, b) => a + b);
    final variableExpenses = fixedmonthlyExpenses - finalFixedMonthlyExpenses;
    final remainingAfterFixedExpenses =
        monthlyIncome - finalFixedMonthlyExpenses;
    final projectedAfterUpcoming =
        remainingAfterFixedExpenses - finalUpcomingExpenses;

    final String promptLanguage = finalLanguage == 'ar'
        ? 'Arabic (العربية)'
        : 'English';

    return '''You are an experienced financial advisor. Analyze this person's monthly budget based on their actual spending history from their Budget page and provide personalized financial advice in $promptLanguage. Focus on:
1. Actual spending analysis and patterns from their records
2. Realistic savings opportunities
3. Budget optimization based on real spending data
4. Financial health assessment
5. Actionable recommendations

**Financial Overview (from Budget Page Data):**
- المداخيل الشهرية الكلية (Total Monthly Income): ${monthlyIncome.toStringAsFixed(2) + finalAvailableFunds.toStringAsFixed(2)} MAD
- المصاريف القارة للكراء والفواتير (Fixed Expenses - Rent & Bills): ${finalFixedMonthlyExpenses.toStringAsFixed(2)} MAD
- المصاريف المتغيرة (Variable Expenses - غير القارة): ${variableExpenses.toStringAsFixed(2)} MAD
- المتبقي بعد المصاريف القارة (Remaining After Fixed Expenses): ${remainingAfterFixedExpenses.toStringAsFixed(2)} MAD
- المصاريف غير المتوقعة (past unpredicted  Expenses): ${finalUpcomingExpenses.toStringAsFixed(2)} MAD
- المتوقع بعد المصاريف غير المتوقعة (Projected After Unexpected): ${projectedAfterUpcoming.toStringAsFixed(2)} MAD
- المبلغ المرتقب إدخاره شهرياً (Expected Monthly Savings Target): ${currentSavings.toStringAsFixed(2)} MAD
- إجمالي المبلغ المدخر (Total Accumulated Savings): ${finalSavedAmount.toStringAsFixed(2)} MAD
- متوسط الرصيد الصافي (Average Net Credit Balance): ${netCredit.toStringAsFixed(2)} MAD

**Budget Allocation by Category (Current):**
$budgetBreakdown

**Total Budget Allocated: ${totalBudget.toStringAsFixed(2)} MAD**

**Analysis Focus Areas:**
- This data is based on ACTUAL spending history tracked in the app (not estimates)
- تصنيف المصاريف: المصاريف القارة (Fixed: Rent & Bills) vs المصاريف المتغيرة (Variable: Upcoming spendings)
- Total accumulated savings: ${finalSavedAmount.toStringAsFixed(2)} MAD
- Consider seasonal patterns and upcoming obligations
- Account for free available funds when making recommendations
- Provide realistic savings targets based on historical data

Please provide:
1. **تحليل الإنفاق** (Spending Analysis) - Key patterns from actual spending history (المصاريف القارة vs المتغيرة)
2. **فرص الادخار** (Savings Opportunities) - Realistic areas to optimize spending while maintaining fixed obligations
3. **تحسين الميزانية** (Budget Optimization) - How to rebalance variable expenses based on real data, preserving essential fixed expenses
4. **الصحة المالية** (Financial Health) - Overall assessment of balance between fixed and variable spending
5. **التوصيات** (Recommendations) - Specific, actionable steps with focus on managing variable expenses while maintaining fixed obligations

Keep the advice concise, practical, and encouraging. Use $promptLanguage for the response. Reference the actual numbers provided. Emphasize that Fixed Expenses (${finalFixedMonthlyExpenses.toStringAsFixed(2)} MAD) are non-negotiable commitments for rent and utilities (الكراء والفواتير).''';
  }
}
