import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String mentorId;
  final List<String> memberIds;
  final List<String> tags;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.mentorId,
    required this.memberIds,
    required this.tags,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'mentorId': mentorId,
      'memberIds': memberIds,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GroupModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      mentorId: data['mentorId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> createGroup({
    required String name,
    required String description,
    required String mentorId,
    required List<String> tags,
  }) async {
    try {
      final docRef = _firestore.collection('groups').doc();
      final newGroup = GroupModel(
        id: docRef.id,
        name: name,
        description: description,
        mentorId: mentorId,
        memberIds: [mentorId], // The mentor is automatically a member
        tags: tags,
        createdAt: DateTime.now(),
      );

      await docRef.set(newGroup.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  Stream<List<GroupModel>> getGroups() {
    return _firestore
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GroupModel.fromDocument(doc)).toList();
    });
  }
}
