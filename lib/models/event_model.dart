import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String venue;
  final String startDate;
  final String endDate;
  final String category;
  final String hostingBranch;
  final String imageUrl;
  final int passLimit;
  final int seatsFilled;
  final bool isOpenToAll;
  final DateTime? createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.hostingBranch,
    required this.imageUrl,
    required this.passLimit,
    required this.seatsFilled,
    required this.isOpenToAll,
    this.createdAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      venue: data['venue'] ?? '',
      startDate: data['startDate'] ?? '',
      endDate: data['endDate'] ?? '',
      category: data['category'] ?? 'General',
      hostingBranch: data['hostingBranch'] ?? 'Universal',
      imageUrl: data['imageUrl'] ?? '',
      passLimit: data['passLimit'] ?? 0,
      seatsFilled: data['seatsFilled'] ?? 0,
      isOpenToAll: data['isOpenToAll'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'venue': venue,
      'startDate': startDate,
      'endDate': endDate,
      'category': category,
      'hostingBranch': hostingBranch,
      'imageUrl': imageUrl,
      'passLimit': passLimit,
      'seatsFilled': seatsFilled,
      'isOpenToAll': isOpenToAll,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}