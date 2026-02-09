import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Renter/chats/chat_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  String currentUserId = "";
  bool loading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString("user_id") ?? "";
    setState(() => loading = false);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getChats() {
    if (currentUserId.isEmpty) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection("chats")
        .where("members", arrayContains: currentUserId)
        .orderBy("lastTimestamp", descending: true)
        .snapshots();
  }

  String extractOtherUser(List members) {
    return members.first == currentUserId ? members.last : members.first;
  }

  bool isValidUrl(String url) {
    return url.startsWith("http");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFF2C3E50),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Messages",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 24),
            onPressed: () {
              // Search functionality can be expanded here
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: ClipOval(
                child: Image.asset(
                  "assets/cargo.png",
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).iconTheme.color,



                strokeWidth: 2.5,
              ),
            )
          : Column(
              children: [
                // Search Bar
                Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => searchQuery = v),
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search conversations...",
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            size: 22,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => searchQuery = ""),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ),

                // Active Chats Horizontal List
                StreamBuilder(
                  stream: getChats(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    final chats = snapshot.data!.docs;

                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    
                    return Container(
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade500.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.circle,
                                    color: Colors.green.shade500,
                                    size: 8,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Active Now",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: chats.length > 8 ? 8 : chats.length,
                              itemBuilder: (_, index) {
                                final chatDoc = chats[index];
                                final userId =
                                    extractOtherUser(chatDoc["members"]);

                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(userId)
                                      .get(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return const SizedBox();

                                    final user = snapshot.data!;
                                    final avatar = user["avatar"] ?? "";
                                    final name = user["name"] ?? "User";

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: FadeInUp(
                                        duration: Duration(
                                            milliseconds: 300 + (index * 50)),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ChatDetailScreen(
                                                  chatId: chatDoc.id,
                                                  peerId: userId,
                                                  peerName: name,
                                                  peerAvatar: avatar,
                                                ),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(50),
                                          child: Column(
                                            children: [
                                              Stack(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.blue.shade400,
                                                          Colors.purple.shade400,
                                                        ],
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(alpha: 0.1),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    padding: const EdgeInsets.all(2.5),
                                                    child: CircleAvatar(
                                                      radius: 28,
                                                      backgroundColor:
                                                          Colors.grey.shade200,
                                                      backgroundImage: isValidUrl(avatar)
                                                          ? CachedNetworkImageProvider(
                                                              avatar)
                                                          : null,
                                                      child: !isValidUrl(avatar)
                                                          ? Icon(Icons.person,
                                                              size: 26,
                                                              color: Colors
                                                                  .grey.shade600)
                                                          : null,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 2,
                                                    right: 2,
                                                    child: Container(
                                                      width: 14,
                                                      height: 14,
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.shade500,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width: 2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              SizedBox(
                                                width: 65,
                                                child: Text(
                                                  name.split(" ").first,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.black87,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Messages List
                Expanded(
                  child: StreamBuilder(
                    stream: getChats(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).iconTheme.color,



                            strokeWidth: 2.5,
                          ),
                        );
                      }

                      final chats = snapshot.data!.docs;

                      if (chats.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No messages yet",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Start a conversation to see it here",
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: chats.length,
                        padding: const EdgeInsets.only(top: 8),
                        itemBuilder: (_, index) {
                          final chatDoc = chats[index];
                          final userId = extractOtherUser(chatDoc["members"]);
                          final lastMessage = chatDoc["lastMessage"] ?? "";
                          final timestamp = chatDoc["lastTimestamp"];

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection("users")
                                .doc(userId)
                                .get(),
                            builder: (context, snap) {
                              if (!snap.hasData) return const SizedBox();

                              final user = snap.data!;
                              final avatar = user["avatar"] ?? "";
                              final name = user["name"] ?? "Unknown";

                              // Filter by name if searching
                              if (searchQuery.isNotEmpty &&
                                  !name.toLowerCase().contains(
                                      searchQuery.toLowerCase())) {
                                return const SizedBox();
                              }

                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              
                              return SlideInUp(
                                duration:
                                    Duration(milliseconds: 350 + index * 60),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade200,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatDetailScreen(
                                              chatId: chatDoc.id,
                                              peerId: userId,
                                              peerName: name,
                                              peerAvatar: avatar,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            // Avatar with gradient border
                                            Stack(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(2.5),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.blue.shade400,
                                                        Colors.purple.shade400,
                                                      ],
                                                    ),
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 28,
                                                    backgroundColor: isDark
                                                        ? Colors.grey.shade800
                                                        : Colors.grey.shade200,
                                                    backgroundImage: isValidUrl(avatar)
                                                        ? CachedNetworkImageProvider(avatar)
                                                        : null,
                                                    child: !isValidUrl(avatar)
                                                        ? Icon(
                                                            Icons.person,
                                                            color: isDark
                                                                ? Colors.grey.shade600
                                                                : Colors.grey.shade600,
                                                            size: 28,
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 2,
                                                  right: 2,
                                                  child: Container(
                                                    width: 14,
                                                    height: 14,
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade500,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: isDark
                                                            ? const Color(0xFF1E1E1E)
                                                            : Colors.white,
                                                        width: 2.5,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 14),
                                            // Message content
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          name,
                                                          style: GoogleFonts.poppins(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 16,
                                                            color: isDark
                                                                ? Colors.white
                                                                : Colors.black87,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (timestamp != null) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: isDark
                                                                ? Colors.grey.shade800
                                                                : Colors.grey.shade100,
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                          child: Text(
                                                            timeago.format(
                                                              (timestamp as Timestamp).toDate(),
                                                              locale: 'en_short',
                                                            ),
                                                            style: GoogleFonts.inter(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w500,
                                                              color: isDark
                                                                  ? Colors.grey.shade400
                                                                  : Colors.grey.shade600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          lastMessage == "typing..."
                                                              ? "Typing..."
                                                              : lastMessage.isEmpty
                                                                  ? "No messages yet"
                                                                  : lastMessage,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: GoogleFonts.inter(
                                                            color: lastMessage == "typing..."
                                                                ? Colors.blue.shade500
                                                                : isDark
                                                                    ? Colors.grey.shade400
                                                                    : Colors.grey.shade600,
                                                            fontSize: 14,
                                                            fontStyle: lastMessage == "typing..."
                                                                ? FontStyle.italic
                                                                : FontStyle.normal,
                                                          ),
                                                        ),
                                                      ),
                                                      Icon(
                                                        Icons.chevron_right_rounded,
                                                        color: isDark
                                                            ? Colors.grey.shade600
                                                            : Colors.grey.shade400,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}