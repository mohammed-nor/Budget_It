import 'package:flutter/material.dart';
import 'package:budget_it/services/gemini_service.dart';
import 'package:get/get.dart';

class ApiKeyManagerScreen extends StatefulWidget {
  const ApiKeyManagerScreen({super.key});

  @override
  State<ApiKeyManagerScreen> createState() => _ApiKeyManagerScreenState();
}

class _ApiKeyManagerScreenState extends State<ApiKeyManagerScreen> {
  late TextEditingController _apiKeyController;
  bool _isApiKeyVisible = false;
  bool _isSaving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    final currentKey = GeminiService.getApiKey();
    _apiKeyController = TextEditingController(text: currentKey ?? '');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_enter_api_key'.tr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await GeminiService.saveApiKey(_apiKeyController.text.trim());
      setState(() {
        _statusMessage = 'api_key_saved_success_check'.tr;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('api_key_saved_success'.tr),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_prefix'.trArgs([e.toString()])),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _clearApiKey() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('clear_api_key'.tr),
        content: Text('clear_api_key_confirmation'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              try {
                await GeminiService.clearApiKey();
                setState(() {
                  _apiKeyController.clear();
                  _statusMessage = 'api_key_cleared_success_check'.tr;
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('api_key_cleared_success'.tr),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('error_prefix'.trArgs([e.toString()])),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasApiKey = GeminiService.hasApiKey();

    return Scaffold(
      appBar: AppBar(
        title: Text('smart_advisor_setup'.tr),
        backgroundColor: Colors.green.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'about_gemini_api'.tr,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${'gemini_api_instructions'.tr}\n\n${'gemini_api_usage_info'.tr}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // API Key Input
            Text('gemini_api_key'.tr, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: !_isApiKeyVisible,
              decoration: InputDecoration(
                hintText: 'paste_gemini_api_key_hint'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _isApiKeyVisible = !_isApiKeyVisible);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Message
            if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      _statusMessage!.contains('Error') ||
                              _statusMessage!.startsWith('Error')
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _statusMessage!.contains('Error') ||
                                _statusMessage!.startsWith('Error')
                            ? Colors.red.shade200
                            : Colors.green.shade200,
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color:
                        _statusMessage!.contains('Error') ||
                                _statusMessage!.startsWith('Error')
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveApiKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade900,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        hasApiKey ? 'update_api_key'.tr : 'save_api_key'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            if (hasApiKey)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _clearApiKey,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'clear_api_key'.tr,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Current Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: hasApiKey ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    hasApiKey
                        ? 'api_key_configured'.tr
                        : 'api_key_not_configured'.tr,
                    style: TextStyle(
                      color: hasApiKey
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.w500,
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
}
