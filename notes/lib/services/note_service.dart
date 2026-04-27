import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notes/models/note.dart';

class NoteService {
  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final CollectionReference _notesCollection = _database.collection(
    "notes",
  );

  static Future<void> addNote(Note note) async {
    Map<String, dynamic> newNote = {
      "title": note.title,
      "description": note.description,
      "image_base64": note.imageBase64,
      "created_at": FieldValue.serverTimestamp(),
      "updated_at": FieldValue.serverTimestamp(),
      "latitude": note.latitude,
      "longitude": note.longitude,
    };
    await _notesCollection.add(newNote);
  }

  static Stream<List<Note>> getNoteList() {
    return _notesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Note(
          id: doc.id,
          title: data["title"],
          description: data["description"],
          imageBase64: data["image_base64"],
          createdAt: data["created_at"] != null
              ? data["created_at"] as Timestamp
              : null,
          updatedAt: data["updated_at"] != null
              ? data["updated_at"] as Timestamp
              : null,
          latitude: data["latitude"],
          longitude: data["longitude"],
        );
      }).toList();
    });
  }

  static Future<void> updateNote(Note note) async {
    Map<String, dynamic> updatedNote = {
      "title": note.title,
      "description": note.description,
      "image_base64": note.imageBase64,
      "updated_at": FieldValue.serverTimestamp(),
      "latitude": note.latitude,
      "longitude": note.longitude,
    };
    await _notesCollection.doc(note.id).update(updatedNote);
  }

  static Future<void> deleteNote(Note note) async {
    await _notesCollection.doc(note.id).delete();
  }
}
