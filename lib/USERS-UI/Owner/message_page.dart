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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Messages",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).iconTheme.color,



          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset("assets/cargo.png", width: 36),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
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
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => searchQuery = v),
                        style: GoogleFonts.inter(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search conversations...",
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: Colors.grey.shade600, size: 22),
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

                    return Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Text(
                              "Active Now",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
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
                                                              .withOpacity(0.1),
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

                      // Filter chats based on search
                      final filteredChats = searchQuery.isEmpty
                          ? chats
                          : chats.where((chat) {
                              final userId = extractOtherUser(chat["members"]);
                              // This is simplified - in production, you'd need to
                              // fetch user data to filter by name
                              return true;
                            }).toList();

                      return ListView.builder(
                        itemCount: filteredChats.length,
                        padding: const EdgeInsets.only(top: 8),
                        itemBuilder: (_, index) {
                          final chatDoc = filteredChats[index];
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

                              return SlideInUp(
                                duration:
                                    Duration(milliseconds: 350 + index * 60),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.grey.shade200,
                                          backgroundImage: isValidUrl(avatar)
                                              ? CachedNetworkImageProvider(avatar)
                                              : null,
                                          child: !isValidUrl(avatar)
                                              ? Icon(Icons.person,
                                                  color: Colors.grey.shade600)
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 12,
                                            height: 12,
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
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (timestamp != null)
                                          Text(
                                            timeago.format(
                                              (timestamp as Timestamp).toDate(),
                                              locale: 'en_short',
                                            ),
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        lastMessage == "typing..."
                                            ? "Typing..."
                                            : lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: lastMessage == "typing..."
                                              ? Colors.blue.shade600
                                              : Colors.grey.shade600,
                                          fontSize: 14,
                                          fontStyle: lastMessage == "typing..."
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                        ),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.grey.shade400,
                                      size: 24,
                                    ),
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