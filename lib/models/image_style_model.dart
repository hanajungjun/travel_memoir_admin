class ImageStyleModel {
  final String id;
  final String title; // 한국어 타이틀
  final String titleEn; // 영어 타이틀 (추가)
  final String prompt;
  final bool isEnabled;
  final String? thumbnailUrl;
  final int sortOrder;

  ImageStyleModel({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.prompt,
    required this.isEnabled,
    this.thumbnailUrl,
    this.sortOrder = 0,
  });

  factory ImageStyleModel.fromMap(Map<String, dynamic> map) {
    return ImageStyleModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      titleEn: map['title_en'] as String? ?? '', // DB의 title_en 매핑
      prompt: map['prompt'] as String? ?? '',
      isEnabled: map['is_enabled'] as bool? ?? true,
      thumbnailUrl: map['thumbnail_url'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  ImageStyleModel copyWith({
    String? title,
    String? titleEn,
    String? prompt,
    bool? isEnabled,
    String? thumbnailUrl,
    int? sortOrder,
  }) {
    return ImageStyleModel(
      id: id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      prompt: prompt ?? this.prompt,
      isEnabled: isEnabled ?? this.isEnabled,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
