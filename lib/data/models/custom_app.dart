/// BBZCloud Mobile - Custom App Model
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:bbzcloud_mobil/core/utils/validators.dart';

class CustomApp {
  final String id;
  final String title;
  final String url;
  final Color color;
  final IconData icon;
  final int? userId;
  final int orderIndex;
  final bool isVisible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomApp({
    required this.id,
    required this.title,
    required this.url,
    required this.color,
    required this.icon,
    this.userId,
    required this.orderIndex,
    this.isVisible = true,
    this.createdAt,
    this.updatedAt,
  }) {
    // Validate on construction
    Validators.validateString(title, 'title', maxLength: 100);
    Validators.validateUrl(url);
  }

  /// Create CustomApp from database map
  factory CustomApp.fromMap(Map<String, dynamic> map) {
    return CustomApp(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      color: Color(int.parse(map['color'] as String)),
      icon: IconData(
        int.parse(map['icon'] as String),
        fontFamily: 'MaterialIcons',
      ),
      userId: map['user_id'] as int?,
      orderIndex: map['order_index'] as int,
      isVisible: (map['is_visible'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert CustomApp to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'color': color.value.toString(),
      'icon': icon.codePoint.toString(),
      if (userId != null) 'user_id': userId,
      'order_index': orderIndex,
      'is_visible': isVisible ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a new CustomApp with generated ID
  factory CustomApp.create({
    required String title,
    required String url,
    required Color color,
    IconData icon = Icons.apps,
    int? userId,
    int orderIndex = 0,
    bool isVisible = true,
  }) {
    const uuid = Uuid();
    final now = DateTime.now();
    
    return CustomApp(
      id: uuid.v4(),
      title: title,
      url: url,
      color: color,
      icon: icon,
      userId: userId,
      orderIndex: orderIndex,
      isVisible: isVisible,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy with method for immutability
  CustomApp copyWith({
    String? id,
    String? title,
    String? url,
    Color? color,
    IconData? icon,
    int? userId,
    int? orderIndex,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomApp(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      userId: userId ?? this.userId,
      orderIndex: orderIndex ?? this.orderIndex,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CustomApp(id: $id, title: $title, url: $url, visible: $isVisible)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CustomApp &&
        other.id == id &&
        other.title == title &&
        other.url == url;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ url.hashCode;
  }
}
