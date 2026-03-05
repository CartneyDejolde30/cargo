import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:animate_do/animate_do.dart';
import '../../../config/cache_config.dart';
import '../../../services/imgbb_upload_service.dart';
import 'package:cargo/widgets/online_status_indicator.dart';

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
    if (selectedImage == null) {
      print('❌ No image selected!');
      return;
    }

    print('🚀 Starting ImgBB image upload...');
    print('📁 Image path: ${selectedImage!.path}');

    try {
      if (!mounted) return;
      setState(() => isUploading = true);

      // Upload to ImgBB
      print('📤 Uploading to ImgBB...');
      final result = await ImgBBUploadService.uploadImage(
        selectedImage!,
        name: 'chat_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}',
      );

      print('✅ Upload completed!');
      print('🔗 Image URL: ${result.displayUrl}');
      print('📊 Image size: ${result.width}x${result.height}');
      print('💾 File size: ${(result.size / 1024).toStringAsFixed(2)} KB');

      // ✅ Check mounted before setState
      if (!mounted) return;
      setState(() => isUploading = false);

      // Send message with ImgBB URL
      await _sendMessage(imageUrl: result.displayUrl);
      
      print('✅ Image sent successfully!');
    } catch (e) {
      print('❌ Upload error: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      // ✅ Check mounted before setState
      if (!mounted) return;
      setState(() => isUploading = false);
      
      if (mounted) {
        String errorMessage = 'Failed to upload image';
        String errorDetails = '';
        
        final errorString = e.toString();
        
        if (errorString.contains('No internet connection') || 
            errorString.contains('SocketException')) {
          errorMessage = 'No internet connection';
          errorDetails = 'Please check your network and try again';
        } else if (errorString.contains('timeout') || 
                   errorString.contains('Upload timeout')) {
          errorMessage = 'Upload timed out';
          errorDetails = 'Slow connection. Please try again';
        } else if (errorString.contains('File too large')) {
          errorMessage = 'Image too large';
          errorDetails = 'Maximum file size is 32MB';
        } else if (errorString.contains('does not exist')) {
          errorMessage = 'Image file not found';
          errorDetails = 'Please select the image again';
        } else if (errorString.contains('ImgBB Error:')) {
          errorMessage = 'ImgBB API Error';
          errorDetails = errorString.replaceAll('Exception: ImgBB Error: ', '');
        } else if (errorString.contains('Network error')) {
          errorMessage = 'Network error';
          errorDetails = 'Could not connect to image server';
        } else {
          errorMessage = 'Upload failed';
          errorDetails = errorString.replaceAll('Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage, 
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (errorDetails.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    errorDetails, 
                    style: GoogleFonts.inter(
                      fontSize: 12, 
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _uploadImage(),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: isDark
          ? const Color(0xFF1A1A1A)
          : const Color(0xFF2C3E50),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.white,
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
                  child: OnlineStatusBadge(
                    userId: widget.peerId,
                    size: 12,
                    showBorder: true,
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
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  isPeerTyping
                      ? Text(
                          'typing...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.greenAccent.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : OnlineStatusIndicator(
                          userId: widget.peerId,
                          showText: true,
                          size: 8,
                          onlineColor: Colors.greenAccent.shade400,
                          offlineColor: Colors.white.withValues(alpha: 0.6),
                        ),
                ],
              ),
            ),
          ],
        ),
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
                    color: Colors.black.withValues(alpha :0.05),
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
    .withValues(alpha :value),
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
            color: Colors.black.withValues(alpha :0.1),
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
                  color: Colors.black.withValues(alpha :0.6),
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
                if (msg["image"] != null && msg["image"] != "")
                  GestureDetector(
                    onTap: () {
                      final imageUrl = msg["image"] as String;
                      print('🖼️ Tapped image, opening viewer for: $imageUrl');
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (_, __, ___) => FullImageView(imageUrl),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                        ),
                      );
                    },
                    child: Hero(
                      tag: msg["image"],
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: msg["image"],
                          width: 250,
                          fit: BoxFit.cover,
                          cacheManager: ChatImageCacheManager.instance,
                          fadeInDuration: const Duration(milliseconds: 300),
                          fadeOutDuration: const Duration(milliseconds: 300),
                          cacheKey: msg["image"], // Explicit cache key
                          errorListener: (error) {
                            print('❌ Thumbnail error: $error');
                          },
                          placeholder: (context, url) {
                            print('⏳ Loading thumbnail for: $url');
                            return Container(
                              width: 250,
                              height: 250,
                              color: Theme.of(context).colorScheme.outlineVariant,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(strokeWidth: 2),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Loading...',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          errorWidget: (context, url, error) {
                            print('❌ Thumbnail load error: $error for URL: $url');
                            
                            // Determine error type
                            String errorMessage = 'Failed to load';
                            String errorDetails = '';
                            IconData errorIcon = Icons.broken_image;
                            
                            if (error.toString().contains('SocketException') || 
                                error.toString().contains('Failed host lookup') ||
                                error.toString().contains('Connection timed out') ||
                                error.toString().contains('Connection closed') ||
                                error.toString().contains('Connection reset')) {
                              errorMessage = 'Unstable connection';
                              errorDetails = 'Network keeps dropping';
                              errorIcon = Icons.wifi_off;
                            } else if (error.toString().contains('TimeoutException') ||
                                       error.toString().contains('timeout')) {
                              errorMessage = 'Slow connection';
                              errorDetails = 'Taking too long';
                              errorIcon = Icons.access_time;
                            } else if (error.toString().contains('404')) {
                              errorMessage = 'Image not found';
                              errorDetails = 'Link expired';
                              errorIcon = Icons.search_off;
                            }
                            
                            return Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(errorIcon, size: 50, color: Colors.grey.shade600),
                                  const SizedBox(height: 12),
                                  Text(
                                    errorMessage,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  if (errorDetails.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      errorDetails,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          print('🔄 Retrying image load: $url');
                                          // Clear cache and retry
                                          await ChatImageCacheManager.instance.removeFile(url);
                                          if (context.mounted) {
                                            setState(() {});
                                          }
                                        },
                                        icon: const Icon(Icons.refresh, size: 16),
                                        label: const Text('Retry'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () {
                                          // Open in full screen to try again
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => FullImageView(url),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.open_in_full, size: 16),
                                        label: const Text('Full View'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                if (msg["text"] != "")
                  Container(
                    margin: msg["image"] != "" ? const EdgeInsets.only(top: 8) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withBlue(180),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isMe
                          ? null
                          : Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                      ),
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
                                  ? Colors.white.withValues(alpha :0.2)
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
                                    ? Colors.white.withValues(alpha :0.7)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
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
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                onPressed: _showImagePicker,
                tooltip: 'Attach image',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  onChanged: (v) => _setTyping(v.isNotEmpty),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    suffixIcon: _messageController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.emoji_emotions_outlined,
                              color: Colors.grey.shade600,
                              size: 22,
                            ),
                            onPressed: () {
                              // Emoji picker can be added here
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withBlue(200),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                    padding: const EdgeInsets.all(14),
                    child: isUploading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Icon(
                            selectedImage != null ? Icons.send_rounded : Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
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
  
  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🖼️ FullImageView - Opening image: $url');
    
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Download feature coming soon', style: GoogleFonts.inter()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
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
                cacheManager: ChatImageCacheManager.instance,
                fadeInDuration: const Duration(milliseconds: 500),
                fadeOutDuration: const Duration(milliseconds: 300),
                cacheKey: url, // Explicit cache key
                httpHeaders: const {
                  'User-Agent': 'Mozilla/5.0', // Some CDNs require this
                },
                errorListener: (error) {
                  print('❌ Full image error: $error');
                },
                placeholder: (context, url) {
                  print('⏳ Loading full image: $url');
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading image...',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorWidget: (context, url, error) {
                  print('❌ Image load error in FullImageView: $error');
                  print('❌ Failed URL: $url');
                  
                  // Determine error type
                  String errorMessage = 'Failed to load image';
                  String errorDetails = '';
                  IconData errorIcon = Icons.broken_image;
                  
                  if (error.toString().contains('SocketException') || 
                      error.toString().contains('Failed host lookup') ||
                      error.toString().contains('Connection timed out') ||
                      error.toString().contains('Connection closed') ||
                      error.toString().contains('Connection reset')) {
                    errorMessage = 'Unstable Network Connection';
                    errorDetails = 'Your connection is dropping. Try moving to a better location or switch networks.';
                    errorIcon = Icons.wifi_off;
                  } else if (error.toString().contains('TimeoutException') ||
                             error.toString().contains('timeout')) {
                    errorMessage = 'Connection Timeout';
                    errorDetails = 'Image is taking too long to load. Your connection may be slow.';
                    errorIcon = Icons.access_time;
                  } else if (error.toString().contains('404')) {
                    errorMessage = 'Image Not Found';
                    errorDetails = 'This image may have been deleted or the link expired.';
                    errorIcon = Icons.search_off;
                  } else {
                    errorDetails = error.toString();
                  }
                  
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              errorIcon,
                              color: Colors.white70,
                              size: 80,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              errorMessage,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              errorDetails,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    print('🔄 Retrying full image load: $url');
                                    // Clear cache and force reload
                                    await ChatImageCacheManager.instance.removeFile(url);
                                    // Pop and push again to trigger reload
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FullImageView(url),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Go Back'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white38),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.lightbulb_outline,
                                        color: Colors.yellowAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Troubleshooting Tips:',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTipItem('Check your WiFi or mobile data'),
                                  _buildTipItem('Try switching between WiFi and mobile data'),
                                  _buildTipItem('Move to a location with better signal'),
                                  _buildTipItem('The image may load faster after retry'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}