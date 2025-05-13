import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // For timestamp formatting

// --- Data Models ---
class SalesPersonContact {
  final String id;
  final String name;
  final String? avatarUrl; // Optional
  final String role;
  final String lastMessagePreview; // For display on contact list
  final DateTime? lastMessageTimestamp; // For sorting/display
  bool hasUnreadMessages;

  SalesPersonContact({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.lastMessagePreview = "No messages yet.",
    this.lastMessageTimestamp,
    this.hasUnreadMessages = false,
  });
}

class ChatMessage {
  final String id;
  final String senderId; // ID of the sender (e.g., current user or contact)
  final String receiverId; // ID of the receiver
  final String text;
  final DateTime timestamp;
  bool isSentByCurrentUser; // To determine alignment and styling

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isSentByCurrentUser = false,
  });
}

// --- Mock Data ---
// Assume current user's ID
const String _currentUserId = 'user_me';

final List<SalesPersonContact> _mockSalesContacts = [
  SalesPersonContact(
    id: 'sp_001',
    name: 'Alice Smith',
    role: 'Senior Sales Rep',
    avatarUrl: 'https://placehold.co/100x100/E6E6FA/333333?text=AS',
    lastMessagePreview: "Sure, I'll send it over.",
    lastMessageTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    hasUnreadMessages: true,
  ),
  SalesPersonContact(
    id: 'sp_002',
    name: 'Bob Johnson',
    role: 'Sales Executive',
    avatarUrl: 'https://placehold.co/100x100/F0E68C/333333?text=BJ',
    lastMessagePreview: "Okay, sounds good!",
    lastMessageTimestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  SalesPersonContact(
    id: 'sp_003',
    name: 'Carol Williams',
    role: 'Sales Manager',
    avatarUrl: 'https://placehold.co/100x100/ADD8E6/333333?text=CW',
    lastMessagePreview: "Can you check on order #123?",
    lastMessageTimestamp: DateTime.now().subtract(const Duration(days: 1)),
  ),
  SalesPersonContact(
    id: 'sp_004',
    name: 'David Brown',
    role: 'Junior Sales Rep',
    lastMessagePreview: "Let's discuss this tomorrow.",
    lastMessageTimestamp: DateTime.now().subtract(const Duration(minutes: 30)),
  ),
  SalesPersonContact(
    id: 'sp_005',
    name: 'Eve Davis',
    role: 'Sales Executive',
    avatarUrl: 'https://placehold.co/100x100/90EE90/333333?text=ED',
    hasUnreadMessages: true,
    lastMessagePreview: "Meeting at 2 PM confirmed.",
    lastMessageTimestamp: DateTime.now().subtract(const Duration(hours: 3)),
  ),
];

// Mock messages for chats - keyed by a composite ID of the two users (sorted to ensure consistency)
final Map<String, List<ChatMessage>> _mockChatHistories = {
  _getChatId(_currentUserId, 'sp_001'): [
    ChatMessage(
      id: 'msg001',
      senderId: 'sp_001',
      receiverId: _currentUserId,
      text: "Hey, can you look into the Kanesan account?",
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    ChatMessage(
      id: 'msg002',
      senderId: _currentUserId,
      receiverId: 'sp_001',
      text: "Sure, what specifically?",
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      isSentByCurrentUser: true,
    ),
    ChatMessage(
      id: 'msg003',
      senderId: 'sp_001',
      receiverId: _currentUserId,
      text: "The latest order status. They called asking for an update.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
    ),
    ChatMessage(
      id: 'msg004',
      senderId: 'sp_001',
      receiverId: _currentUserId,
      text: "Sure, I'll send it over.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ],
  _getChatId(_currentUserId, 'sp_002'): [
    ChatMessage(
      id: 'msg005',
      senderId: _currentUserId,
      receiverId: 'sp_002',
      text: "Hi Bob, are you free for a quick call?",
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isSentByCurrentUser: true,
    ),
    ChatMessage(
      id: 'msg006',
      senderId: 'sp_002',
      receiverId: _currentUserId,
      text: "Yes, I am. Give me 5 mins.",
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
    ),
    ChatMessage(
      id: 'msg007',
      senderId: _currentUserId,
      receiverId: 'sp_002',
      text: "Great!",
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      isSentByCurrentUser: true,
    ),
    ChatMessage(
      id: 'msg008',
      senderId: 'sp_002',
      receiverId: _currentUserId,
      text: "Okay, sounds good!",
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ],
  _getChatId(_currentUserId, 'sp_005'): [
    ChatMessage(
      id: 'msg009',
      senderId: 'sp_005',
      receiverId: _currentUserId,
      text: "Meeting at 2 PM confirmed.",
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ],
};

String _getChatId(String userId1, String userId2) {
  List<String> ids = [userId1, userId2];
  ids.sort(); // Sort to ensure consistency (userA-userB is same as userB-userA)
  return ids.join('-');
}

// --- Messaging Landing Page (Contact List) ---
class MessagingLandingPage extends StatefulWidget {
  const MessagingLandingPage({super.key});

  @override
  State<MessagingLandingPage> createState() => _MessagingLandingPageState();
}

class _MessagingLandingPageState extends State<MessagingLandingPage> {
  List<SalesPersonContact> _contacts = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contacts = List.from(_mockSalesContacts); // Make a mutable copy
    // Sort contacts: unread first, then by last message timestamp (newest first)
    _contacts.sort((a, b) {
      if (a.hasUnreadMessages && !b.hasUnreadMessages) return -1;
      if (!a.hasUnreadMessages && b.hasUnreadMessages) return 1;
      if (a.lastMessageTimestamp == null && b.lastMessageTimestamp != null)
        return 1;
      if (a.lastMessageTimestamp != null && b.lastMessageTimestamp == null)
        return -1;
      if (a.lastMessageTimestamp != null && b.lastMessageTimestamp != null) {
        return b.lastMessageTimestamp!.compareTo(a.lastMessageTimestamp!);
      }
      return a.name.compareTo(b.name); // Fallback sort by name
    });
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _contacts = List.from(_mockSalesContacts);
      } else {
        _contacts =
            _mockSalesContacts.where((contact) {
              return contact.name.toLowerCase().contains(query) ||
                  contact.role.toLowerCase().contains(query);
            }).toList();
      }
      // Re-sort after filtering
      _contacts.sort((a, b) {
        if (a.hasUnreadMessages && !b.hasUnreadMessages) return -1;
        if (!a.hasUnreadMessages && b.hasUnreadMessages) return 1;
        if (a.lastMessageTimestamp == null && b.lastMessageTimestamp != null)
          return 1;
        if (a.lastMessageTimestamp != null && b.lastMessageTimestamp == null)
          return -1;
        if (a.lastMessageTimestamp != null && b.lastMessageTimestamp != null) {
          return b.lastMessageTimestamp!.compareTo(a.lastMessageTimestamp!);
        }
        return a.name.compareTo(b.name);
      });
    });
  }

  void _navigateToChat(SalesPersonContact contact) {
    // When navigating to chat, mark messages as read for this contact
    setState(() {
      contact.hasUnreadMessages = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ChatPage(contact: contact, currentUserId: _currentUserId),
      ),
    ).then((_) {
      // Optional: Refresh list if needed when returning from chat page
      // For example, if last message preview needs update.
      // For this mock, we'll just re-sort to reflect read status.
      _filterContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        // backgroundColor: Theme.of(context).primaryColor, // Example
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _contacts.isEmpty
                    ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'No contacts found.'
                            : 'No contacts match your search.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundImage:
                                contact.avatarUrl != null
                                    ? NetworkImage(contact.avatarUrl!)
                                    : null,
                            onBackgroundImageError:
                                contact.avatarUrl != null
                                    ? (exception, stackTrace) {}
                                    : null,
                            child:
                                contact.avatarUrl == null
                                    ? Text(
                                      contact.name.isNotEmpty
                                          ? contact.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                          ),
                          title: Text(
                            contact.name,
                            style: TextStyle(
                              fontWeight:
                                  contact.hasUnreadMessages
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            contact.lastMessagePreview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  contact.hasUnreadMessages
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade600,
                              fontSize: 13.5,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (contact.lastMessageTimestamp != null)
                                Text(
                                  DateFormat('hh:mm a').format(
                                    contact.lastMessageTimestamp!,
                                  ), // Simple time format
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              if (contact.hasUnreadMessages) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ), // Visual cue for unread
                                ),
                              ],
                            ],
                          ),
                          onTap: () => _navigateToChat(contact),
                        );
                      },
                      separatorBuilder:
                          (context, index) =>
                              const Divider(indent: 80, height: 1),
                    ),
          ),
        ],
      ),
    );
  }
}

// --- Chat Page ---
class ChatPage extends StatefulWidget {
  final SalesPersonContact contact;
  final String currentUserId;

  const ChatPage({
    super.key,
    required this.contact,
    required this.currentUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Scroll to bottom when messages load or new message arrives
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    final chatId = _getChatId(widget.currentUserId, widget.contact.id);
    setState(() {
      _messages = List.from(_mockChatHistories[chatId] ?? []);
      // Ensure isSentByCurrentUser is set correctly
      _messages =
          _messages.map((msg) {
            msg.isSentByCurrentUser = msg.senderId == widget.currentUserId;
            return msg;
          }).toList();
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}', // Unique ID
      senderId: widget.currentUserId,
      receiverId: widget.contact.id,
      text: text,
      timestamp: DateTime.now(),
      isSentByCurrentUser: true,
    );

    setState(() {
      _messages.add(newMessage);
      // Update mock history (in a real app, this would be an API call)
      final chatId = _getChatId(widget.currentUserId, widget.contact.id);
      if (_mockChatHistories.containsKey(chatId)) {
        _mockChatHistories[chatId]!.add(newMessage);
      } else {
        _mockChatHistories[chatId] = [newMessage];
      }
      // Update last message preview for the contact (mock update)
      final contactInList = _mockSalesContacts.firstWhere(
        (c) => c.id == widget.contact.id,
      );
      // contactInList.lastMessagePreview = text;
      // contactInList.lastMessageTimestamp = newMessage.timestamp;
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 30,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  widget.contact.avatarUrl != null
                      ? NetworkImage(widget.contact.avatarUrl!)
                      : null,
              onBackgroundImageError:
                  widget.contact.avatarUrl != null
                      ? (exception, stackTrace) {}
                      : null,
              child:
                  widget.contact.avatarUrl == null
                      ? Text(
                        widget.contact.name.isNotEmpty
                            ? widget.contact.name[0].toUpperCase()
                            : '?',
                      )
                      : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contact.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.contact.role,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        // backgroundColor: Theme.of(context).primaryColor, // Example
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _messages.isEmpty
                    ? Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(10.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isMe = message.isSentByCurrentUser;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor =
        isMe
            ? Theme.of(context).primaryColor.withOpacity(0.85)
            : Colors.grey.shade300;
    final textColor = isMe ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18.0),
                topRight: const Radius.circular(18.0),
                bottomLeft:
                    isMe
                        ? const Radius.circular(18.0)
                        : const Radius.circular(4.0),
                bottomRight:
                    isMe
                        ? const Radius.circular(4.0)
                        : const Radius.circular(18.0),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4.0,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          // IconButton( // Optional: Attachments button
          //   icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
          //   onPressed: () { /* TODO: Handle attachments */ },
          // ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5, // Allow multiline input
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.send_rounded,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
