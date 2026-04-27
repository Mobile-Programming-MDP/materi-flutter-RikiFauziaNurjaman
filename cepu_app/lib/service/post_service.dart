import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cepu_app/models/post.dart';

class PostService {
  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final CollectionReference _postsCollection = _database.collection(
    "posts",
  );

  static Future<void> addPost(Post post) async {
    Map<String, dynamic> newPost = {
      "imageUrl": post.imageUrl,
      "description": post.description,
      "category": post.category,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
      "userId": post.userId,
      "fullname": post.fullname,
      "latitude": post.latitude,
      "longitude": post.longitude,
    };
    await _postsCollection.add(newPost);
  }

  static Stream<List<Post>> getPostList() {
    return _postsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Post.fromDocument(doc);
      }).toList();
    });
  }

  static Future<void> updatePost(Post post) async {
    Map<String, dynamic> updatedPost = {
      "imageUrl": post.imageUrl,
      "description": post.description,
      "category": post.category,
      "updatedAt": FieldValue.serverTimestamp(),
      "userId": post.userId,
      "fullname": post.fullname,
      "latitude": post.latitude,
      "longitude": post.longitude,
    };
    await _postsCollection.doc(post.id).update(updatedPost);
  }

  static Future<void> deletePost(Post post) async {
    await _postsCollection.doc(post.id).delete();
  }
}
