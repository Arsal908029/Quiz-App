// ADD THIS IMPORT AT THE TOP
import 'package:flutter/material.dart'; // For Color class
class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String color;
  final int questionCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color = '#6C63FF',
    this.questionCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String? ?? '#6C63FF',
      questionCount: json['question_count'] as int? ?? 0,
    );
  }

  Color get colorValue {
    return Color(int.parse(color.replaceAll('#', '0xFF')));
  }
}