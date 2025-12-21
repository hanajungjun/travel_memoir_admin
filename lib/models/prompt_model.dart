class PromptModel {
  final String id;
  final String title;
  final String content;
  final bool isActive;

  PromptModel({
    required this.id,
    required this.title,
    required this.content,
    required this.isActive,
  });

  factory PromptModel.fromMap(Map<String, dynamic> map) {
    return PromptModel(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      isActive: map['is_active'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_active': isActive,
    };
  }

  PromptModel copyWith({
    String? title,
    String? content,
    bool? isActive,
  }) {
    return PromptModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      isActive: isActive ?? this.isActive,
    );
  }
}
