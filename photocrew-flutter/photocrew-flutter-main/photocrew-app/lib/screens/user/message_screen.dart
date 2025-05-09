// lib/screens/user/message_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _filteredChats = [];
  List<QueryDocumentSnapshot> _allChats = [];
  bool _isLoading = true;

  void _filterChats(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChats = _allChats;
      } else {
        _filteredChats = _allChats.where((chat) {
          final chatData = chat.data() as Map<String, dynamic>;
          final lastMessage =
              chatData['lastMessage']?.toString().toLowerCase() ?? '';
          return lastMessage.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 24,
                fontFamily: 'Effective Way',
              ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser?.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              _isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              ),
            );
          }

          if (snapshot.hasData) {
            _allChats = snapshot.data!.docs;
            if (_filteredChats.isEmpty && _searchController.text.isEmpty) {
              _filteredChats = _allChats;
            }
            _isLoading = false;
          }

          if (_allChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'Effective Way',
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting with photographers',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'Space Mono',
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'Space Mono',
                      ),
                  onChanged: _filterChats,
                ),
              ),
              Expanded(
                child: _filteredChats.isEmpty &&
                        _searchController.text.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No chats found',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontFamily: 'Effective Way',
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try different search terms',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontFamily: 'Space Mono',
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = _filteredChats[index].data()
                              as Map<String, dynamic>;
                          final otherUserId = (chat['participants'] as List)
                              .firstWhere((id) => id != currentUser?.uid);

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('photographers')
                                .doc(otherUserId)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData) {
                                return const SizedBox();
                              }

                              final userData = userSnapshot.data?.data()
                                  as Map<String, dynamic>?;
                              if (userData == null) return const SizedBox();

                              return _ChatTile(
                                name: userData['name'] ?? 'Unknown',
                                lastMessage:
                                    chat['lastMessage'] ?? 'No messages yet',
                                time: chat['lastMessageTime'] != null
                                    ? (chat['lastMessageTime'] as Timestamp)
                                        .toDate()
                                    : null,
                                imageUrl:
                                    userData['portfolioImages']?.isNotEmpty ==
                                            true
                                        ? userData['portfolioImages'][0]
                                        : null,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/chat',
                                  arguments: _filteredChats[index].id,
                                ),
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
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final DateTime? time;
  final String? imageUrl;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.lastMessage,
    required this.onTap,
    this.time,
    this.imageUrl,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[300]
            : Colors.grey[800],
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? Text(
                name[0].toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Effective Way',
                    ),
              )
            : null,
      ),
      title: Text(
        name,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontFamily: 'Effective Way',
            ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            lastMessage,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: 'Space Mono',
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(time),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black54
                      : Colors.white54,
                  fontFamily: 'Space Mono',
                ),
          ),
        ],
      ),
    );
  }
}
