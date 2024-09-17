import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserEmail;

  const ChatPage({required this.chatId, required this.otherUserEmail});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> _sendMessage({String? imageUrl}) async {
    if (_messageController.text.isNotEmpty || imageUrl != null) {
      String message = _messageController.text;
      String senderId = _auth.currentUser!.uid;

      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'message': imageUrl ?? message,
        'timestamp': Timestamp.now(),
        'type': imageUrl != null ? 'image' : 'text',
      });

      _messageController.clear();
    }
  }

  Future<void> _pickAndSendImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      File file = File(pickedFile.path);

      try {
        // Upload to Firebase Storage
        TaskSnapshot snapshot = await FirebaseStorage.instance
            .ref('chat_images/$fileName')
            .putFile(file);
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Send the image message
        _sendMessage(imageUrl: downloadUrl);
      } catch (e) {}
    }
  }

  Future<void> _deleteChat() async {
    try {
      await _firestore.collection('chats').doc(widget.chatId).delete();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.otherUserEmail}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              bool? confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Chat'),
                  content:
                      const Text('Are you sure you want to delete this chat?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm ?? false) {
                _deleteChat();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data =
                        docs[index].data() as Map<String, dynamic>;
                    bool isSender = data['senderId'] == _auth.currentUser!.uid;
                    bool isImage = data['type'] == 'image';
                    String messageId = docs[index].id;

                    return Dismissible(
                      key: Key(messageId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Message'),
                            content: const Text(
                                'Are you sure you want to delete this message?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _deleteMessage(messageId);
                      },
                      child: ListTile(
                        title: Align(
                          alignment: isSender
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: GestureDetector(
                            onLongPress: () async {
                              bool? confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Message'),
                                  content: const Text(
                                      'Are you sure you want to delete this message?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm ?? false) {
                                _deleteMessage(messageId);
                              }
                            },
                            child: isImage
                                ? Image.network(
                                    data['message'],
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          isSender ? Colors.blue : Colors.grey,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      data['message'],
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Enter your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
