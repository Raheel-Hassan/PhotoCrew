// lib/screens/shared/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:photocrew/widgets/audio_message.dart';
import 'package:photocrew/widgets/audio_recorder.dart';
import 'package:photocrew/widgets/custom_back_button.dart';
import 'dart:io';

class SharedChatScreen extends StatefulWidget {
  final String chatId;

  const SharedChatScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<SharedChatScreen> createState() => _SharedChatScreenState();
}

class _SharedChatScreenState extends State<SharedChatScreen> {
  final _messageController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  final _player = AudioPlayer();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _showAttachments = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder.init();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source);
    if (image == null) return;

    setState(() => _showAttachments = false);
    await _uploadAndSendFile(File(image.path), 'image');
  }

  Future<void> _playAudio(String url) async {
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
      );
    }
  }

  Future<void> _uploadAndSendFile(File file, String type) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_files/${widget.chatId}/$fileName');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'type': type,
        'url': url,
        'senderId': _currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': type == 'image' ? '📷 Image' : '🎵 Voice message',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'type': 'text',
        'text': message,
        'senderId': _currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Widget _buildChatHeader(Map<String, dynamic> chatData) {
    final otherUserId = (chatData['participants'] as List)
        .firstWhere((id) => id != _currentUser?.uid);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('photographers')
          .doc(otherUserId)
          .get(),
      builder: (context, photographerSnapshot) {
        if (photographerSnapshot.hasData && photographerSnapshot.data!.exists) {
          // Other user is a photographer
          final photographerData =
              photographerSnapshot.data!.data() as Map<String, dynamic>;
          return Row(
            children: [
              const CustomBackButton(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photographerData['name'],
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontFamily: 'Effective Way',
                          ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/booking/create',
                  arguments: {
                    'photographerId': otherUserId,
                    'photographerName': photographerData['name'],
                  },
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Book Now',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'Space Mono',
                      ),
                ),
              ),
            ],
          );
        } else {
          // Other user is a regular user
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) return const CustomBackButton();

              final userData =
                  userSnapshot.data?.data() as Map<String, dynamic>?;
              if (userData == null) return const CustomBackButton();

              return Row(
                children: [
                  const CustomBackButton(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['name'],
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 18,
                                    fontFamily: 'Effective Way',
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }

  Future<void> _startRecording() async {
    await _audioRecorder.startRecording();
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    setState(() => _isRecording = false);
    final path = await _audioRecorder.stopRecording();
    if (path != null) {
      await _uploadAndSendFile(File(path), 'audio');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CustomBackButton();

            final chatData = snapshot.data!.data() as Map<String, dynamic>?;
            if (chatData == null) return const CustomBackButton();

            return _buildChatHeader(chatData);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                  ));
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_outlined,
                            size: 64,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.black
                                    : Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start the conversation',
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Send a message to discuss your photography needs',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final isCurrentUser =
                        message['senderId'] == _currentUser?.uid;

                    return _MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      onPlayAudio: _playAudio,
                    );
                  },
                );
              },
            ),
          ),
          if (_showAttachments)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[300]!
                        : Colors.grey[800]!,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachmentButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _AttachmentButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[300]!
                      : Colors.grey[800]!,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() => _showAttachments = !_showAttachments);
                  },
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isRecording
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: _isRecording
                          ? Colors.white
                          : Theme.of(context).brightness == Brightness.light
                              ? Colors.white
                              : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _messageController.dispose();
    _player.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isCurrentUser;
  final Function(String) onPlayAudio;

  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.onPlayAudio,
  });

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final time = timestamp.toDate();
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.7;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white
                : Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[200]
                    : Colors.grey[800],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message['type'] == 'text')
                Text(
                  message['text'],
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isCurrentUser
                            ? Theme.of(context).brightness == Brightness.light
                                ? Colors.white
                                : Colors.black
                            : null,
                      ),
                )
              else if (message['type'] == 'image')
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message['url'],
                    width: maxWidth,
                    fit: BoxFit.cover,
                  ),
                )
              else if (message['type'] == 'audio')
                AudioMessageWidget(
                  audioUrl: message['url'],
                  isCurrentUser: isCurrentUser,
                ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message['timestamp']),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isCurrentUser
                          ? Theme.of(context).brightness == Brightness.light
                              ? Colors.white70
                              : Colors.black54
                          : Theme.of(context).brightness == Brightness.light
                              ? Colors.black54
                              : Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
