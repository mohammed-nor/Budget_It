import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

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
    double upcomingExpenses = 0,
    double availableFunds = 0,
    double fixedMonthlyExpenses = 0,
    double savedAmount = 0,
  }) async {
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
      upcomingExpenses: upcomingExpenses,
      availableFunds: availableFunds,
      fixedMonthlyExpenses: fixedMonthlyExpenses,
      savedAmount: savedAmount,
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
    double upcomingExpenses = 0,
    double availableFunds = 0,
    double fixedMonthlyExpenses = 0,
    double savedAmount = 0,
  }) {
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
    final variableExpenses = fixedmonthlyExpenses - fixedMonthlyExpenses;
    final remainingAfterFixedExpenses = monthlyIncome - fixedMonthlyExpenses;
    final projectedAfterUpcoming = remainingAfterFixedExpenses - upcomingExpenses;

    return '''You are an experienced financial advisor. Analyze this person's monthly budget based on their actual spending history from their Budget page and provide personalized financial advice in Arabic (العربية). Focus on:
1. Actual spending analysis and patterns from their records
2. Realistic savings opportunities
3. Budget optimization based on real spending data
4. Financial health assessment
5. Actionable recommendations

**Financial Overview (from Budget Page Data):**
- المداخيل الشهرية الكلية (Total Monthly Income): ${monthlyIncome.toStringAsFixed(2)} MAD
  - المداخيل الشهرية القارة (Fixed Monthly Income): ${monthlyIncome.toStringAsFixed(2)} MAD (الدخل المستقر)
- المصاريف الشهرية الكلية (Total Monthly Expenses): ${(fixedMonthlyExpenses + variableExpenses).toStringAsFixed(2)} MAD
  -  المصاريف القارة للكراء و الفواتير(Fixed Monthly Expenses - الفواتير والدائنة): ${fixedMonthlyExpenses.toStringAsFixed(2)} MAD
  - المصاريف المتغيرة (Variable Expenses - غير القارة): ${variableExpenses.toStringAsFixed(2)} MAD
- المتبقي بعد المصاريف القارة (Remaining After Fixed Expenses): ${remainingAfterFixedExpenses.toStringAsFixed(2)} MAD
- المصاريف المجدولة القادمة (Upcoming Planned Expenses): ${upcomingExpenses.toStringAsFixed(2)} MAD
- المتوقع بعد المصاريف المجدولة (Projected After Upcoming): ${projectedAfterUpcoming.toStringAsFixed(2)} MAD
- المبلغ المرتقب إدخاره شهرياً (Expected Monthly Savings Target): ${currentSavings.toStringAsFixed(2)} MAD
- إجمالي المبلغ المدخر (Total Accumulated Savings): ${savedAmount.toStringAsFixed(2)} MAD
- الأموال المتاحة الحرة (Available Free Funds): ${availableFunds.toStringAsFixed(2)} MAD
- متوسط الرصيد الصافي (Average Net Credit Balance): ${netCredit.toStringAsFixed(2)} MAD

**Budget Allocation by Category (Current):**
$budgetBreakdown

**Total Budget Allocated: ${totalBudget.toStringAsFixed(2)} MAD**

**Analysis Focus Areas:**
- This data is based on ACTUAL spending history tracked in the app (not estimates)
- تصنيف المصاريف: المصاريف القارة (mntexp + annexp) vs المصاريف المتغيرة (upcoming spendings)
- Total accumulated savings: ${savedAmount.toStringAsFixed(2)} MAD
- Consider seasonal patterns and upcoming obligations
- Account for free available funds when making recommendations
- Provide realistic savings targets based on historical data

Please provide:
1. **تحليل الإنفاق** (Spending Analysis) - Key patterns from actual spending history (المصاريف القارة vs المتغيرة)
2. **فرص الادخار** (Savings Opportunities) - Realistic areas to optimize spending while maintaining fixed obligations
3. **تحسين الميزانية** (Budget Optimization) - How to rebalance variable expenses based on real data, preserving essential fixed expenses
4. **الصحة المالية** (Financial Health) - Overall assessment of balance between fixed and variable spending
5. **التوصيات** (Recommendations) - Specific, actionable steps with focus on managing variable expenses while maintaining fixed obligations

Keep the advice concise, practical, and encouraging. Use Arabic for main headings and English for details if needed. Reference the actual numbers provided. Emphasize the importance of fixed expenses (الفواتير والدائنة) as non-negotiable commitments.''';
  }
}
