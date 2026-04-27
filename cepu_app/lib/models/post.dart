import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  String? id;
  String? imageUrl;
  String? description;
  String? category;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  String? userId;
  String? fullname;
  String? latitude;
  String? longitude;

  Post({
    this.id,
    this.imageUrl,
    this.description,
    this.category,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.fullname,
    this.latitude,
    this.longitude,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      imageUrl: data['imageUrl'],
      description: data['description'],
      category: data['category'],
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      userId: data['userId'],
      fullname: data['fullname'],
      latitude: data['latitude'],
      longitude: data['longitude'],
    );
  }
}
