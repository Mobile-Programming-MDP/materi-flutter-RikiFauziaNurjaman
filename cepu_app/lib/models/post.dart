import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  String? id;
  String? image;
  String? description;
  String? category;
  String? latitude;
  String? longitude;
  String? userId;
  String? fullName;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  Post({
    this.id,
    required this.image,
    required this.description,
    required this.category,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.fullName,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      image: data['image'],
      description: data['description'],
      category: data['category'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      userId: data['user_id'],
      fullName: data['fullName'],
      createdAt: data['created_at'] as Timestamp,
      updatedAt: data['updated_at'] as Timestamp,
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'description': description,
      'image': image,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user_id': userId,
      'fullName': fullName,
    };
  }
}
