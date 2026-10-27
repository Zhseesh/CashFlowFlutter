class Wallet {
  final int? id;
  final String name;
  final int createdAt;

  const Wallet({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'created_at': createdAt,
      };

  factory Wallet.fromMap(Map<String, dynamic> m) => Wallet(
        id: m['id'] as int?,
        name: m['name'] as String,
        createdAt: m['created_at'] as int,
      );
}