import 'package:flutter/material.dart';
import '../services/competitor_service.dart';

class CompetitorUrlDialog extends StatefulWidget {
  final List<String> existingUrls;
  
  const CompetitorUrlDialog({
    super.key,
    this.existingUrls = const [],
  });

  @override
  State<CompetitorUrlDialog> createState() => _CompetitorUrlDialogState();
}

class _CompetitorUrlDialogState extends State<CompetitorUrlDialog> {
  final List<TextEditingController> _controllers = [];
  final List<String> _urls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize with existing URLs or empty controllers
    final initialUrls = widget.existingUrls.length > 3 ? widget.existingUrls.take(3).toList() : widget.existingUrls;
    
    for (int i = 0; i < 3; i++) {
      _controllers.add(TextEditingController(
        text: i < initialUrls.length ? initialUrls[i] : '',
      ));
      _urls.add(i < initialUrls.length ? initialUrls[i] : '');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateUrl(int index, String value) {
    setState(() {
      _urls[index] = value;
    });
  }

  Future<void> _saveUrls() async {
    setState(() => _isLoading = true);
    
    try {
      // Filter out empty URLs and validate
      final validUrls = _urls.where((url) => url.trim().isNotEmpty).toList();
      
      // Validate URLs
      for (final url in validUrls) {
        if (!CompetitorService.isValidUrl(url)) {
          throw Exception('Invalid URL format: $url');
        }
      }
      
      // Save URLs
      await CompetitorService.saveCompetitorUrls(validUrls);
      
      // Generate competitor data for each URL
      for (final url in validUrls) {
        try {
          final competitorData = await CompetitorService.generateCompetitorData(url);
          await CompetitorService.saveCompetitorData(
            'current_user_id', // This should be the actual user ID
            competitorData,
          );
        } catch (e) {
          debugPrint('Error generating data for $url: $e');
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop(validUrls);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Competitor URLs saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving URLs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.compare_arrows, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('Add Competitor URLs'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter up to 3 competitor website URLs to analyze their sales data:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (index) => _buildUrlInput(index)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We\'ll analyze these websites to provide competitive insights and sales data.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveUrls,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save URLs'),
        ),
      ],
    );
  }

  Widget _buildUrlInput(int index) {
    final hasValue = _urls[index].isNotEmpty;
    final isValid = _urls[index].isEmpty || CompetitorService.isValidUrl(_urls[index]);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Competitor ${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _controllers[index],
            decoration: InputDecoration(
              hintText: 'https://example.com',
              prefixIcon: const Icon(Icons.link),
              suffixIcon: hasValue
                  ? Icon(
                      isValid ? Icons.check_circle : Icons.error,
                      color: isValid ? Colors.green : Colors.red,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasValue && !isValid ? Colors.red : Colors.grey,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasValue && !isValid ? Colors.red : Colors.grey,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: hasValue && !isValid ? Colors.red : Colors.blue,
                ),
              ),
            ),
            onChanged: (value) => _updateUrl(index, value),
            keyboardType: TextInputType.url,
          ),
          if (hasValue && !isValid)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Please enter a valid URL (e.g., https://example.com)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
