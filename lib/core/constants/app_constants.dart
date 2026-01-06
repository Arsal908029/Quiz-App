class AppConstants {
  static const String appName = 'Quiz Master';
  static const String supabaseUrl = 'https://polnuwlmfuujpaohssiw.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvbG51d2xtZnV1anBhb2hzc2l3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1NTE4MDUsImV4cCI6MjA4MTEyNzgwNX0.am5jBfeC-7dcitMIGpxwpDVppiyMi9omyC8vXxDjoZc';
  
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