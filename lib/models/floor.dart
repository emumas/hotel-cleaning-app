import 'package:cloud_firestore/cloud_firestore.dart';

class Floor {
  final String id;
  final String name;
  final int order;
  final DateTime createdAt;

  const Floor({
    required this.id,
    required this.name,
    required this.order,
    required this.createdAt,
  });

  factory Floor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Floor(
      id: doc.id,
      name: data['name'] as String,
      order: data['order'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'order': order,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Floor copyWith({String? name, int? order}) => Floor(
        id: id,
        name: name ?? this.name,
        order: order ?? this.order,
        createdAt: createdAt,
      );
}
