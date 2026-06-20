class AppConstants {
  static const String appName = 'Quiz Master';
  static const String supabaseUrl = 'https://yccnzggrercqfswikhnc.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_3qRXZV0OtMTQhVCagRA7KQ_VqkWEiEv';
  
  static const List<String> categories = [
    'Science',
    'History',
    'Geography',
    'Mathematics',
    'Technology',
    'Sports',
    'Entertainment',
    'General Knowledge'
  ];
  
  static const Map<String, String> categoryIcons = {
    'Science': '🔬',
    'History': '📜',
    'Geography': '🌍',
    'Mathematics': '🧮',
    'Technology': '💻',
    'Sports': '⚽',
    'Entertainment': '🎬',
    'General Knowledge': '🧠',
  };
  
  static const Map<String, String> categoryColors = {
    'Science': '#4CAF50',
    'History': '#FF9800',
    'Geography': '#2196F3',
    'Mathematics': '#9C27B0',
    'Technology': '#607D8B',
    'Sports': '#E91E63',
    'Entertainment': '#FF5722',
    'General Knowledge': '#00BCD4',
  };
}