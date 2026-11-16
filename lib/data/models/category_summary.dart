class CategorySummary {
  const CategorySummary({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.total,
    required this.count,
  });

  final int categoryId;
  final String name;
  final String icon;
  final int color;
  final int total;
  final int count;

  factory CategorySummary.fromMap(Map<String, Object?> map) => CategorySummary(
    categoryId: map['id'] as int,
    name: map['name'] as String,
    icon: map['icon'] as String,
    color: map['color'] as int,
    total: (map['total'] as num).toInt(),
    count: (map['cnt'] as num).toInt(),
  );
}
