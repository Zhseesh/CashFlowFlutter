class Category {
  final int? id;
  final String name;
  final String type;
  final String iconName;
  final String colorHex;

  const Category({
    this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type,
        'icon_name': iconName,
        'color_hex': colorHex,
      };

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: m['type'] as String,
        iconName: m['icon_name'] as String,
        colorHex: m['color_hex'] as String,
      );

  static const List<Category> defaults = [
    Category(name: 'Gaji', type: 'INCOME', iconName: 'salary', colorHex: '#10B981'),
    Category(name: 'Usaha', type: 'INCOME', iconName: 'business', colorHex: '#14B8A6'),
    Category(name: 'Investasi', type: 'INCOME', iconName: 'investment', colorHex: '#0EA5E9'),
    Category(name: 'Lainnya', type: 'INCOME', iconName: 'other', colorHex: '#6366F1'),
    Category(name: 'Makanan', type: 'EXPENSE', iconName: 'food', colorHex: '#F59E0B'),
    Category(name: 'Transportasi', type: 'EXPENSE', iconName: 'transport', colorHex: '#EF4444'),
    Category(name: 'Tagihan', type: 'EXPENSE', iconName: 'bill', colorHex: '#E11D48'),
    Category(name: 'Belanja', type: 'EXPENSE', iconName: 'shopping', colorHex: '#EC4899'),
    Category(name: 'Kesehatan', type: 'EXPENSE', iconName: 'health', colorHex: '#8B5CF6'),
    Category(name: 'Hiburan', type: 'EXPENSE', iconName: 'entertainment', colorHex: '#A855F7'),
  ];
}