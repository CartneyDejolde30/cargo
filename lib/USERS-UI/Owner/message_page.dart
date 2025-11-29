import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString("user_id") ?? "";

    print("DEBUG → Current user ID: $currentUserId");

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

  /// Get the second user from members list
  String extractOtherUser(List members) {
    return members.first == currentUserId ? members.last : members.first;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Messages"), backgroundColor: Colors.black),
      body: StreamBuilder(
        stream: getChats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final chats = snapshot.data!.docs;
          if (chats.isEmpty) return const Center(child: Text("No messages yet"));

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (_, index) {
              final chatDoc = chats[index];

              // Extract peer ID from members array
              final members = chatDoc["members"];
              final otherUserId = extractOtherUser(members);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection("users").doc(otherUserId).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox(height: 50);

                  final user = userSnap.data!;

                  final avatar = user["profile_image"] ?? "";
                  final name = user["fullname"] ?? "Unknown";
                  final lastMessage = chatDoc["lastMessage"] ?? "";

                  return StreamBuilder<QuerySnapshot>(
                    stream: chatDoc.reference
                        .collection("messages")
                        .where("receiverId", isEqualTo: currentUserId.toString())
                        .where("seen", isEqualTo: false)
                        .snapshots(),
                    builder: (context, msgSnap) {

                      final unreadCount = msgSnap.data?.docs.length ?? 0;

                      return ListTile(
                        leading: Stack(children: [
                          CircleAvatar(
                            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                            child: avatar.isEmpty ? const Icon(Icons.person) : null,
                          ),
                          if (user["online"] == true)
                            const Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(radius: 5, backgroundColor: Colors.green),
                            )
                        ]),
                        title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        subtitle: Text(lastMessage, maxLines: 1),
                        trailing: unreadCount > 0
                            ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white)),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              chatId: chatDoc.id,
                              peerId: otherUserId,
                              peerName: name,
                              peerAvatar: avatar,
                            ),
                          ));
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
