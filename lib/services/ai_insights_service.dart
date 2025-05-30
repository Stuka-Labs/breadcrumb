class AIInsightsService {
  static Future<String> getClientPortalInsight(String competitor) async {
    // TODO: Replace with real OpenAI API call. Use secure storage for the key.
    await Future.delayed(const Duration(milliseconds: 600));
    switch (competitor) {
      case 'CartonCloud':
        return 'You are shipping 20% faster than CartonCloud customers on average. Keep up the great work!';
      case 'ShipBob':
        return 'Your average delivery time is 0.8 days faster than ShipBob. Consider promoting this to your customers!';
      case 'Flexport':
        return 'You are on par with Flexport for delivery speed. Explore new shipping partners for further improvements.';
      default:
        return 'Your shipping performance is excellent compared to competitors.';
    }
  }
} 