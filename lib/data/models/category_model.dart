import 'tx_type.dart';

class CategoryModel {
  const CategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  final int? id;
  final String name;
  final TxType type;
  final String icon;
  final int color;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'type': type.value,
    'icon': icon,
    'color': color,
  };

  factory CategoryModel.fromMap(Map<String, Object?> map) => CategoryModel(
    id: map['id'] as int,
    name: map['name'] as String,
    type: TxType.fromValue(map['type'] as String),
    icon: map['icon'] as String,
    color: map['color'] as int,
  );

  CategoryModel copyWith({String? name, String? icon, int? color}) =>
      CategoryModel(
        id: id,
        name: name ?? this.name,
        type: type,
        icon: icon ?? this.icon,
        color: color ?? this.color,
      );
}
