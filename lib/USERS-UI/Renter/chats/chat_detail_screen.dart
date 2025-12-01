import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String peerId;
  final String peerName;
  final String peerAvatar;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.peerId,
    required this.peerName,
    required this.peerAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  String currentUserId = "";
  bool isTyping = false;

  CollectionReference get messageRef =>
      FirebaseFirestore.instance.collection("chats").doc(widget.chatId).collection("messages");

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // ---------------------- USER SETUP ----------------------

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString("user_id") ?? "";

    print("DEBUG: Logged in user → $currentUserId");

    await _createChatIfNeeded();
    setState(() {});
    _markMessagesSeen();
  }

  Future<void> _createChatIfNeeded() async {
    final chatDoc = FirebaseFirestore.instance.collection("chats").doc(widget.chatId);
    final exists = await chatDoc.get();

    if (!exists.exists) {
      await chatDoc.set({
        "members": [currentUserId, widget.peerId],
        "lastMessage": "",
        "lastSender": "",
        "peerAvatar": widget.peerAvatar,
        "peerName": widget.peerName,
        "createdAt": FieldValue.serverTimestamp(),
        "seen": false,
      });
      print("CHAT CREATED ✔");
    }
  }

  // ---------------------- MESSAGE HANDLING ----------------------

  Future<void> _markMessagesSeen() async {
    if (currentUserId.isEmpty) return;

    final unreadMessages = await messageRef
        .where("receiverId", isEqualTo: currentUserId)
        .where("seen", isEqualTo: false)
        .get();

    for (final doc in unreadMessages.docs) {
      doc.reference.update({"seen": true});
    }

    FirebaseFirestore.instance.collection("chats").doc(widget.chatId).update({"seen": true});
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    final now = FieldValue.serverTimestamp();

    await messageRef.add({
      "text": text,
      "senderId": currentUserId,
      "receiverId": widget.peerId,
      "timestamp": now,
      "seen": false,
      "image": imageUrl ?? "",
    });

    await FirebaseFirestore.instance.collection("chats").doc(widget.chatId).update({
      "lastMessage": imageUrl != null ? "📷 Photo" : text,
      "lastSender": currentUserId,
      "lastTimestamp": now,
      "seen": false,
    });

    _messageController.clear();
    _setTyping(false);
  }

  // ---------------------- IMAGE PICKING ----------------------

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref("chat_images/$fileName");

      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();

      _sendMessage(imageUrl: url);
    }
  }

  // ---------------------- STREAMS ----------------------

  Stream<QuerySnapshot> _getMessages() {
    return messageRef.orderBy("timestamp", descending: true).snapshots();
  }

  void _setTyping(bool value) {
    if (value == isTyping) return;

    isTyping = value;
    FirebaseFirestore.instance.collection("chats").doc(widget.chatId).update({
      "${currentUserId}_typing": value,
    });

    setState(() {});
  }

  // ---------------------- UI ----------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(backgroundImage: NetworkImage(widget.peerAvatar)),
          const SizedBox(width: 10),
          Text(widget.peerName, style: GoogleFonts.poppins(fontSize: 16)),
          const SizedBox(width: 6),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection("chats").doc(widget.chatId).snapshots(),
            builder: (_, snap) {
              final typing = snap.hasData && snap.data?["${widget.peerId}_typing"] == true;
              return Text(
                typing ? "typing..." : "",
                style: const TextStyle(fontSize: 12, color: Colors.green, fontStyle: FontStyle.italic),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getMessages(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final messages = snapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
        );
      },
    );
  }

  Widget _buildMessageBubble(QueryDocumentSnapshot msg) {
    final isMe = msg["senderId"] == currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (msg["image"] != "")
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(msg["image"], width: 180),
            ),

          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg["text"],
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
          ),

          if (isMe)
            Text(
              msg["seen"] ? "Seen ✔" : "Delivered",
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.image), onPressed: _pickImage),
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (v) => _setTyping(v.isNotEmpty),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.black,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
