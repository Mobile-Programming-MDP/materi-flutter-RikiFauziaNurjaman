import 'package:cepu_app/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final CollectionReference _postCollection = _database.collection(
    'post',
  );

  static Future<void> addPost(Post post) async {
    Map<String, dynamic> newNote = {
      'image': post.image,
      'description': post.description,
      'category': post.category,
      'latitude': post.latitude,
      'longitude': post.longitude,
      'user_id': post.userId,
      'fullName': post.fullName,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    await _postCollection.add(newNote);
  }

  static Future<void> updatePost(Post post) async {
    Map<String, dynamic> updatedNote = {
      'image': post.image,
      'description': post.description,
      'latitude': post.latitude,
      'longitude': post.longitude,
      'created_at': post.createdAt,
      'user_id': post.userId,
      'fullName': post.fullName,
      'updated_at': FieldValue.serverTimestamp(),
    };
    await _postCollection.doc(post.id).update(updatedNote);
  }

  static Stream<List<Post>> getPostList() {
    return _postCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Post(
          id: doc.id,
          image: data['image'],
          description: data['description'],
          category: data['category'],
          createdAt: data['created_at'] != null
              ? data['created_at'] as Timestamp
              : null,
          updatedAt: data['updated_at'] != null
              ? data['updated_at'] as Timestamp
              : null,
          latitude: data['latitude'],
          longitude: data['longitude'],
          userId: data['user_id'],
          fullName: data['fullName'],
        );
      }).toList();
    });
  }

  static Future<void> deletePost(Post post) async {
    await _postCollection.doc(post.id).delete();
  }

  static Future<QuerySnapshot> retrievePost() async {
    return await _postCollection.get();
  }

  static Stream<List<Post>> getPostListByCategory(String? category) {
    Query query = _postCollection;
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Post(
          id: doc.id,
          image: data['image'],
          description: data['description'],
          category: data['category'],
          createdAt: data['created_at'] != null
              ? data['created_at'] as Timestamp
              : null,
          updatedAt: data['updated_at'] != null
              ? data['updated_at'] as Timestamp
              : null,
          latitude: data['latitude'],
          longitude: data['longitude'],
          userId: data['user_id'],
          fullName: data['fullName'],
        );
      }).toList();
    });
  }
}
