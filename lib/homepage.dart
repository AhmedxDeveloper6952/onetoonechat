import 'package:chatapplication/chatpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String searchQuery = '';
  List<QueryDocumentSnapshot> users = [];

  void _searchUsers(String query) async {
    if (query.isNotEmpty) {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      setState(() {
        users = snapshot.docs;
      });
    } else {
      setState(() {
        users = [];
      });
    }
  }

  Future<void> _startChat(String otherUserId, String otherUserEmail) async {
    String currentUserId = _auth.currentUser!.uid;
    String chatId = currentUserId.hashCode <= otherUserId.hashCode
        ? '$currentUserId-$otherUserId'
        : '$otherUserId-$currentUserId';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatPage(chatId: chatId, otherUserEmail: otherUserEmail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Search Users',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                _searchUsers(value);
              },
              decoration: InputDecoration(
                hintText: 'Search by email',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> userData =
                    users[index].data() as Map<String, dynamic>;
                String otherUserId = users[index].id;
                String otherUserEmail = userData['email'];
                String status = userData['status'] ?? 'Unavailable';

                return Card(
                  elevation: 0,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        otherUserEmail[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      otherUserEmail,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Status: $status',
                      style: TextStyle(
                        color: status == 'online' ? Colors.green : Colors.red,
                      ),
                    ),
                    trailing: const Icon(Icons.chat_bubble_outline),
                    onTap: () => _startChat(otherUserId, otherUserEmail),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
