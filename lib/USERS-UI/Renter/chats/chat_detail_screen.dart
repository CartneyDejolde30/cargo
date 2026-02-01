import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:animate_do/animate_do.dart';

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

class _ChatDetailScreenState extends State<ChatDetailScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String currentUserId = "";
  bool isTyping = false;
  bool isPeerTyping = false;
  File? selectedImage;
  bool isUploading = false;
  String? replyingToMessage;
  String? replyingToText;

  CollectionReference get messageRef =>
      FirebaseFirestore.instance.collection("chats").doc(widget.chatId).collection("messages");

  @override
  void initState() {
    super.initState();
    _loadUser();
    _listenToPeerTyping();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------- USER SETUP ----------------------

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString("user_id") ?? "";
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
    }
  }

  void _listenToPeerTyping() {
    FirebaseFirestore.instance.collection("chats").doc(widget.chatId).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey("${widget.peerId}_typing")) {
          setState(() {
            isPeerTyping = data["${widget.peerId}_typing"] ?? false;
          });
        }
      }
    });
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

    try {
      final now = FieldValue.serverTimestamp();

      await messageRef.add({
        "text": text,
        "senderId": currentUserId,
        "receiverId": widget.peerId,
        "timestamp": now,
        "seen": false,
        "image": imageUrl ?? "",
        "replyTo": replyingToMessage ?? "",
        "replyText": replyingToText ?? "",
      });

      await FirebaseFirestore.instance.collection("chats").doc(widget.chatId).update({
        "lastMessage": imageUrl != null ? "📷 Photo" : text,
        "lastSender": currentUserId,
        "lastTimestamp": now,
        "seen": false,
      });

      _messageController.clear();
      selectedImage = null;
      replyingToMessage = null;
      replyingToText = null;
      setState(() {});
      _setTyping(false);

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ---------------------- IMAGE PICKING ----------------------

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      selectedImage = File(img.path);
      setState(() {});
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera);

    if (img != null) {
      selectedImage = File(img.path);
      setState(() {});
    }
  }

  Future<void> _uploadImage() async {
    if (selectedImage == null) return;

    try {
      setState(() => isUploading = true);

      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref("chat_images/$fileName");

      await ref.putFile(selectedImage!);
      final url = await ref.getDownloadURL();

      setState(() => isUploading = false);

      await _sendMessage(imageUrl: url);
    } catch (e) {
      setState(() => isUploading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ---------------------- MESSAGE ACTIONS ----------------------

  void _showMessageOptions(QueryDocumentSnapshot msg) {
    final isMe = msg["senderId"] == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration:  BoxDecoration(
          color: Theme.of(context).colorScheme.surface,          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.blue),
              title: Text('Reply', style: GoogleFonts.inter()),
              onTap: () {
                setState(() {
                  replyingToMessage = msg.id;
                  replyingToText = msg["text"];
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.green),
              title: Text('Copy', style: GoogleFonts.inter()),
              onTap: () {
                Clipboard.setData(ClipboardData(text: msg["text"]));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message copied', style: GoogleFonts.inter()),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(msg);
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(QueryDocumentSnapshot msg) async {
    await msg.reference.delete();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message deleted', style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration:  BoxDecoration(
          color: Theme.of(context).colorScheme.surface,          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: Text('Choose from Gallery', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: Text('Take Photo', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
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

  bool isValidUrl(String url) {
    return url.startsWith("http");
  }

  // ---------------------- UI ----------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          if (replyingToMessage != null) _buildReplyPreview(),
          if (selectedImage != null) _previewSelectedImage(),
          if (isPeerTyping) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
       icon: Icon(
          Icons.arrow_back_ios,
          color: Theme.of(context).iconTheme.color,
        ),

        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () {
          if (isValidUrl(widget.peerAvatar)) {
            Navigator.push(
              context,
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => FullImageView(widget.peerAvatar),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            );
          }
        },
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,                  backgroundImage: isValidUrl(widget.peerAvatar)
                      ? CachedNetworkImageProvider(widget.peerAvatar)
                      : null,
                  child: !isValidUrl(widget.peerAvatar)
                      ? Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.outline,
                            )

                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,

                    ),
                  ),
                  Text(
                    isPeerTyping ? 'typing...' : 'Active now',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isPeerTyping
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,

                      fontStyle: isPeerTyping ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.outlineVariant,              backgroundImage: isValidUrl(widget.peerAvatar)
                  ? CachedNetworkImageProvider(widget.peerAvatar)
                  : null,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildTypingDot(0),
                  const SizedBox(width: 4),
                  _buildTypingDot(1),
                  const SizedBox(width: 4),
                  _buildTypingDot(2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 100)),
      builder: (context, double value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context)
    .colorScheme
    .outline
    .withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,

                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  replyingToText ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: Colors.grey.shade600),
            onPressed: () => setState(() {
              replyingToMessage = null;
              replyingToText = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _previewSelectedImage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              selectedImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () => setState(() => selectedImage = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child:  Icon(Icons.close, color: Theme.of(context).colorScheme.surface, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getMessages(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).iconTheme.color,



              strokeWidth: 2.5,
            ),
          );
        }

        final messages = snapshot.data!.docs;

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,

                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a message to start the conversation',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.outline,

                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (_, i) {
            final msg = messages[i];
            final isMe = msg["senderId"] == currentUserId;
            
            // Check if we should show timestamp
            bool showTimestamp = false;
            if (i == messages.length - 1) {
              showTimestamp = true;
            } else {
              final nextMsg = messages[i + 1];
              final currentTime = (msg["timestamp"] as Timestamp?)?.toDate();
              final nextTime = (nextMsg["timestamp"] as Timestamp?)?.toDate();
              
              if (currentTime != null && nextTime != null) {
                final diff = currentTime.difference(nextTime).inMinutes;
                showTimestamp = diff > 30;
              }
            }

            return Column(
              children: [
                if (showTimestamp && msg["timestamp"] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      timeago.format((msg["timestamp"] as Timestamp).toDate()),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                _buildMessageBubble(msg, isMe),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(QueryDocumentSnapshot msg, bool isMe) {
    final data = msg.data() as Map<String, dynamic>;
    final hasReply = data.containsKey("replyTo") && data["replyTo"] != null && data["replyTo"] != "";
    
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => _showMessageOptions(msg),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (msg["image"] != "")
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => FullImageView(msg["image"]),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                      ),
                    ),
                    child: Hero(
                      tag: msg["image"],
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: msg["image"],
                          width: 250,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 250,
                            height: 250,
                            color: Theme.of(context).colorScheme.outlineVariant,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (msg["text"] != "")
                  Container(
                    margin: msg["image"] != "" ? const EdgeInsets.only(top: 8) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,

                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasReply)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                 color: isMe
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.outline,

                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              data["replyText"] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Text(
                          msg["text"],
                          style: GoogleFonts.inter(
                            color: isMe
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,

                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (msg["timestamp"] != null)
                      Text(
                        _formatTime((msg["timestamp"] as Timestamp).toDate()),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        msg["seen"] ? Icons.done_all : Icons.done,
                        size: 14,
                        color: msg["seen"]
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,

                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,

                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.add_photo_alternate_outlined, color: Theme.of(context).colorScheme.onSurface),
                onPressed: _showImagePicker,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                ),
                child: TextField(
                  controller: _messageController,
                  onChanged: (v) => _setTyping(v.isNotEmpty),
                  style: GoogleFonts.inter(fontSize: 15),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.outline),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.purple.shade600],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade300.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isUploading
                      ? null
                      : () => selectedImage != null ? _uploadImage() : _sendMessage(),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: isUploading
                        ?  SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.surface,                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            selectedImage != null ? Icons.upload : Icons.send_rounded,
                            color: Theme.of(context).colorScheme.surface,                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullImageView extends StatelessWidget {
  final String url;

  const FullImageView(this.url, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
         backgroundColor: Theme.of(context).colorScheme.surface,





        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Hero(
            tag: url,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) =>  Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.surface,                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}