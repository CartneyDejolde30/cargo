import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Load logged user ID from SharedPreferences
  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString("user_id") ?? "";

    print("DEBUG → Logged in User: $currentUserId");

    if (currentUserId.isEmpty) return;

    listenChats();
    setState(() {});
  }

  /// Listen to all chats where current user is part of the "members" list
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

  /// Search filtering
  void searchChats(String text) {
    setState(() {
      filteredChats = text.isEmpty
          ? chats
          : chats.where((chat) {
              // Fetch peer name dynamically from Firestore so search works
              final List members = chat["members"];
              final peerId = members.first == currentUserId ? members.last : members.first;
              return peerId.toLowerCase().contains(text.toLowerCase());
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _searchBar(),
            _title(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _action(Icons.arrow_back, () => Navigator.pop(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Text("Chats",
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          _action(Icons.more_vert, () {}),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: searchChats,
        decoration: InputDecoration(
          hintText: "Search chats...",
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text("Recent",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildList() {
    if (filteredChats.isEmpty) {
      return Center(
        child: Text("No chats found",
            style: GoogleFonts.poppins(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredChats.length,
      itemBuilder: (_, i) => _chatTile(filteredChats[i]),
    );
  }

  /// Chat UI Tile
  Widget _chatTile(QueryDocumentSnapshot chat) {
    // Determine the other user in the chat
    List members = chat["members"];
    String peerId = members.first == currentUserId ? members.last : members.first;

    bool isUnread = chat["lastSender"] != currentUserId && chat["seen"] == false;
    bool isTyping = chat["${peerId}_typing"] == true;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(peerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 50);

        final user = snapshot.data!;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  peerId: peerId,
                  peerName: user["fullname"] ?? "Unknown",
                  peerAvatar: user["profile_image"] ?? "",
                  chatId: chat.id,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    user["profile_image"] ?? "",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user["fullname"] ?? "Unknown",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        isTyping ? "Typing..." : chat["lastMessage"],
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: isUnread ? Colors.black : Colors.grey,
                        ),
                      )
                    ],
                  ),
                ),
                Text(
                  chat["lastTimestamp"] != null
                      ? chat["lastTimestamp"].toDate().toString().substring(11, 16)
                      : "",
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _action(IconData icon, VoidCallback action) => GestureDetector(
        onTap: action,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20),
        ),
      );
}
