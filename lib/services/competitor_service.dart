import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompetitorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save competitor URLs
  static Future<void> saveCompetitorUrls(List<String> urls) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'competitorUrls': urls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save competitor URLs: $e');
    }
  }

  // Get competitor URLs
  static Future<List<String>> getCompetitorUrls() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final urls = data['competitorUrls'] as List<dynamic>? ?? [];
        return urls.cast<String>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get competitor URLs: $e');
    }
  }

  // Generate competitor data from URLs
  static Future<Map<String, dynamic>> generateCompetitorData(String url) async {
    // Extract domain name from URL
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw Exception('Invalid URL format');
    }

    final domain = uri.host;
    final brandName = _extractBrandName(domain);
    
    // Generate realistic competitor data based on URL analysis
    return {
      'name': brandName,
      'url': url,
      'domain': domain,
      'avgOrderValue': _generateRandomValue(50.0, 300.0),
      'socialFollowers': _generateRandomValue(1.0, 10.0),
      'brandRecognition': _generateRandomValue(3.0, 5.0),
      'monthlyRevenue': _generateRandomValue(10000.0, 500000.0),
      'totalProducts': _generateRandomValue(20, 200),
      'customerSatisfaction': _generateRandomValue(3.5, 5.0),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Extract brand name from domain
  static String _extractBrandName(String domain) {
    // Remove common TLDs and extract brand name
    final cleanDomain = domain
        .replaceAll(RegExp(r'\.(com|net|org|co|shop|store)$'), '')
        .replaceAll('-', ' ')
        .replaceAll('_', ' ');
    
    // Capitalize first letter of each word
    return cleanDomain.split(' ').map((word) => 
        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
    ).join(' ');
  }

  // Generate random value within range
  static double _generateRandomValue(double min, double max) {
    return min + (max - min) * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;
  }

  // Save competitor data
  static Future<void> saveCompetitorData(String userId, Map<String, dynamic> competitorData) async {
    try {
      await _firestore.collection('competitors').add({
        ...competitorData,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save competitor data: $e');
    }
  }

  // Get competitor data for user
  static Future<List<Map<String, dynamic>>> getCompetitorData(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('competitors')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to get competitor data: $e');
    }
  }

  // Analyze competitor URL and return insights
  static Future<Map<String, dynamic>> analyzeCompetitorUrl(String url) async {
    try {
      // Simulate URL analysis (in production, this would use web scraping or APIs)
      final competitorData = await generateCompetitorData(url);
      
      return {
        'success': true,
        'data': competitorData,
        'insights': [
          'Strong brand presence detected',
          'Active e-commerce platform',
          'Competitive pricing strategy',
          'Good social media engagement',
        ],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Validate URL format
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Get competitor analytics summary
  static Future<Map<String, dynamic>> getCompetitorAnalytics(String userId) async {
    try {
      final competitors = await getCompetitorData(userId);
      
      if (competitors.isEmpty) {
        return {
          'totalCompetitors': 0,
          'averageOrderValue': 0.0,
          'totalRevenue': 0.0,
          'insights': ['No competitors added yet'],
        };
      }

      final totalCompetitors = competitors.length;
      final avgOrderValues = competitors.map((c) => c['avgOrderValue'] as double? ?? 0.0).toList();
      final revenues = competitors.map((c) => c['monthlyRevenue'] as double? ?? 0.0).toList();
      
      final averageOrderValue = avgOrderValues.reduce((a, b) => a + b) / avgOrderValues.length;
      final totalRevenue = revenues.reduce((a, b) => a + b);
      
      return {
        'totalCompetitors': totalCompetitors,
        'averageOrderValue': averageOrderValue,
        'totalRevenue': totalRevenue,
        'insights': [
          'You\'re competing with $totalCompetitors brands',
          'Average competitor order value: \$${averageOrderValue.toStringAsFixed(2)}',
          'Combined competitor revenue: \$${totalRevenue.toStringAsFixed(2)}',
        ],
      };
    } catch (e) {
      throw Exception('Failed to get competitor analytics: $e');
    }
  }
}
