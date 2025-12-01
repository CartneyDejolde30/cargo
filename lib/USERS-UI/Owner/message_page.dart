import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Renter/chats/chat_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// ======= TOP BAR =======
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Messages",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Image.asset("assets/cargo.png", width: 34),
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
              children: [

                /// 🔍 SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search messages...",
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: const Icon(Icons.search, color: Colors.black87),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: StreamBuilder(
                    stream: getChats(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Colors.black));
                      }

                      final chats = snapshot.data!.docs;
                      if (chats.isEmpty) {
                        return Center(
                          child: Text(
                            "No messages yet",
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          
                          /// ====== STORY BUBBLES ======
                          SizedBox(
                            height: 95,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: chats.length,
                              itemBuilder: (_, index) {
                                final chatDoc = chats[index];
                                final userId = extractOtherUser(chatDoc["members"]);

                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection("users").doc(userId).get(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) return const SizedBox();

                                    final user = snapshot.data!;
                                    final avatar = user["profile_image"] ?? "";
                                    final name = user["fullname"] ?? "User";

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 14),
                                      child: FadeInUp(
                                        duration: Duration(milliseconds: 300 + (index * 60)),
                                        child: Column(
                                          children: [
                                            Stack(
                                              children: [
                                                CircleAvatar(
                                                  radius: 30,
                                                  backgroundColor: Colors.grey.shade300,
                                                  backgroundImage: avatar.isNotEmpty
                                                      ? CachedNetworkImageProvider(avatar)
                                                      : null,
                                                  child: avatar.isEmpty
                                                      ? const Icon(Icons.person, color: Colors.black, size: 28)
                                                      : null,
                                                ),
                                                if (user["online"] == true)
                                                  const Positioned(
                                                    right: 0,
                                                    bottom: 0,
                                                    child: CircleAvatar(
                                                      radius: 7,
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              name.split(" ").first,
                                              style: const TextStyle(color: Colors.black, fontSize: 12),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          /// ====== MESSAGE LIST ======
                          Expanded(
                            child: ListView.builder(
                              itemCount: chats.length,
                              padding: const EdgeInsets.only(top: 6),
                              itemBuilder: (_, index) {
                                final chatDoc = chats[index];
                                final userId = extractOtherUser(chatDoc["members"]);

                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection("users").doc(userId).get(),
                                  builder: (context, snap) {
                                    if (!snap.hasData) return const SizedBox();

                                    final user = snap.data!;
                                    final avatar = user["profile_image"] ?? "";
                                    final name = user["fullname"] ?? "Unknown";
                                    final lastMessage = chatDoc["lastMessage"] ?? "";

                                    if (searchQuery.isNotEmpty &&
                                        !name.toLowerCase().contains(searchQuery.toLowerCase())) {
                                      return const SizedBox();
                                    }

                                    return StreamBuilder(
                                      stream: chatDoc.reference
                                          .collection("messages")
                                          .where("receiverId", isEqualTo: currentUserId)
                                          .where("seen", isEqualTo: false)
                                          .snapshots(),
                                      builder: (context, unreadSnap) {
                                        final unread = unreadSnap.data?.docs.length ?? 0;

                                        return SlideInUp(
                                          duration: Duration(milliseconds: 350 + index * 80),
                                          child: Slidable(
                                            endActionPane: ActionPane(
                                              motion: const DrawerMotion(),
                                              children: [
                                                SlidableAction(
                                                  onPressed: (_) {},
                                                  backgroundColor: Colors.blue,
                                                  icon: Icons.archive,
                                                ),
                                                SlidableAction(
                                                  onPressed: (_) {},
                                                  backgroundColor: Colors.red,
                                                  icon: Icons.delete,
                                                ),
                                              ],
                                            ),

                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                              ),

                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  radius: 26,
                                                  backgroundColor: Colors.grey.shade300,
                                                  backgroundImage: avatar.isNotEmpty
                                                      ? CachedNetworkImageProvider(avatar)
                                                      : null,
                                                  child: avatar.isEmpty
                                                      ? const Icon(Icons.person, color: Colors.black54)
                                                      : null,
                                                ),

                                                title: Text(
                                                  name,
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w500,
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                  ),
                                                ),

                                                subtitle: Text(
                                                  lastMessage == "typing..." ? "Typing..." : lastMessage,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                                                    color: unread > 0 ? Colors.black : Colors.grey.shade600,
                                                  ),
                                                ),

                                                trailing: unread > 0
                                                    ? CircleAvatar(
                                                        radius: 13,
                                                        backgroundColor: Colors.blueAccent,
                                                        child: Text(
                                                          unread.toString(),
                                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                                        ),
                                                      )
                                                    : Icon(Icons.check, size: 16, color: Colors.grey.shade600),

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
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
