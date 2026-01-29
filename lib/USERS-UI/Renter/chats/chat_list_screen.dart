import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../widgets/bottom_nav_bar.dart';
import 'package:flutter_application_1/USERS-UI/Renter/chats/chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentNavIndex = 3;

  String currentUserId = "";
  List<QueryDocumentSnapshot> chats = [];
  List<QueryDocumentSnapshot> filteredChats = [];

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString("user_id") ?? "";

    if (currentUserId.isEmpty) return;

    listenChats();
    setState(() {});
  }

  void listenChats() {
    FirebaseFirestore.instance
        .collection("chats")
        .where("members", arrayContains: currentUserId)
        .orderBy("lastTimestamp", descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        chats = snapshot.docs;
        filteredChats = chats;
      });
    });
  }

  void searchChats(String text) async {
    if (text.isEmpty) {
      setState(() => filteredChats = chats);
      return;
    }

    List<QueryDocumentSnapshot> filtered = [];

    for (var chat in chats) {
      final List members = chat["members"];
      final peerId = members.first == currentUserId ? members.last : members.first;

      try {
        final userDoc = await FirebaseFirestore.instance.collection("users").doc(peerId).get();
        if (userDoc.exists) {
          final name = userDoc.data()?.containsKey("name") == true ? userDoc["name"] : "";
          if (name.toLowerCase().contains(text.toLowerCase())) {
            filtered.add(chat);
          }
        }
      } catch (e) {
        // Handle error silently
      }
    }

    setState(() => filteredChats = filtered);
  }

  bool isValidUrl(String url) {
    return url.startsWith("http");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _appBar(),
            _searchBar(),
            _activeChatsList(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // ---------------- UI ----------------

  Widget _appBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Messages",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).iconTheme.color,



              ),
            ),
          ),
          Image.asset("assets/cargo.png", width: 36),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: FadeInDown(
        duration: const Duration(milliseconds: 400),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: searchChats,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: "Search conversations...",
              hintStyle: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.outline,                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.outline,                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _activeChatsList() {
    if (chats.isEmpty) return const SizedBox();

    return Container(
      color: Theme.of(context).colorScheme.surface,      padding: const EdgeInsets.only(bottom: 12),
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
                color: Theme.of(context).colorScheme.outline,                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: chats.length > 8 ? 8 : chats.length,
              itemBuilder: (_, index) => _activeUserItem(chats[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeUserItem(QueryDocumentSnapshot chat, int index) {
    List members = chat["members"];
    String peerId = members.first == currentUserId ? members.last : members.first;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(peerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final user = snapshot.data!;
        final name = user.data().toString().contains("name") ? user["name"] : "User";
        final img = user.data().toString().contains("avatar") ? user["avatar"] : "";

        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FadeInUp(
            duration: Duration(milliseconds: 300 + (index * 50)),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      chatId: chat.id,
                      peerId: peerId,
                      peerName: name,
                      peerAvatar: img,
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
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(2.5),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,                          backgroundImage: isValidUrl(img)
                              ? CachedNetworkImageProvider(img)
                              : null,
                          child: !isValidUrl(img)
                              ? Icon(Icons.person, size: 26, color: Colors.grey.shade600)
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
                            color: Theme.of(context).colorScheme.primary,                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,                              width: 2,
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
                        color: Theme.of(context).colorScheme.onSurface,
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
  }

  Widget _buildList() {
    if (filteredChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.outlineVariant,            ),
            const SizedBox(height: 16),
            Text(
              "No messages yet",
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.outline,                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start a conversation to see it here",
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.outline,                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: filteredChats.length,
      itemBuilder: (_, i) => _chatTile(filteredChats[i], i),
    );
  }

  Widget _chatTile(QueryDocumentSnapshot chat, int index) {
    List members = chat["members"];
    String peerId = members.first == currentUserId ? members.last : members.first;

    bool isTyping = chat.data().toString().contains("${peerId}_typing")
        ? chat["${peerId}_typing"]
        : false;

    bool isUnread = chat["lastSender"] != currentUserId && chat["seen"] == false;
    final timestamp = chat["lastTimestamp"];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(peerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 65);

        final user = snapshot.data!;
        final name = user.data().toString().contains("name") ? user["name"] : "User";
        final img = user.data().toString().contains("avatar") ? user["avatar"] : "";
        final lastMessage = chat["lastMessage"] ?? "";

        return SlideInUp(
          duration: Duration(milliseconds: 350 + index * 60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,                    backgroundImage: isValidUrl(img)
                        ? CachedNetworkImageProvider(img)
                        : null,
                    child: !isValidUrl(img)
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
                        color: Theme.of(context).colorScheme.primary,                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,width: 2,
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
                        color: Theme.of(context).colorScheme.onSurface,
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
                        color: Theme.of(context).colorScheme.outline,                      ),
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,

                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        isTyping ? "Typing..." : lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: isTyping
                          ? Theme.of(context).colorScheme.primary
                          : isUnread
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.outline,

                          fontSize: 14,
                          fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                          fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.outline,

                size: 24,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      chatId: chat.id,
                      peerId: peerId,
                      peerName: name,
                      peerAvatar: img,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}