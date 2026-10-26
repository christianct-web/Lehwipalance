import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';
// lib/core/models/chat_models.dart
import 'package:equatable/equatable.dart';

// Chat Group - represents a conversation between a customer and a team
class ChatGroup extends Equatable implements Identifiable, Timestamped {
  @override
  final String id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  // Customer who initiated/participates in this chat
  final String customerId;
  final String customerName;
  final String customerImageUrl;

  // Team/Group information (what customer sees)
  final String teamId;
  final String teamName; // Display name for customer
  final String? teamImageUrl;

  // Members in this team (what members see)
  final List<String> memberIds;
  final List<String> memberNames;

  // Chat metadata
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final ChatStatus status;

  const ChatGroup({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.customerId,
    required this.customerName,
    required this.customerImageUrl,
    required this.teamId,
    required this.teamName,
    this.teamImageUrl,
    required this.memberIds,
    required this.memberNames,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.status = ChatStatus.active,
  });

  ChatGroup copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerId,
    String? customerName,
    String? customerImageUrl,
    String? teamId,
    String? teamName,
    String? teamImageUrl,
    List<String>? memberIds,
    List<String>? memberNames,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    ChatStatus? status,
  }) {
    return ChatGroup(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerImageUrl: customerImageUrl ?? this.customerImageUrl,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamImageUrl: teamImageUrl ?? this.teamImageUrl,
      memberIds: memberIds ?? this.memberIds,
      memberNames: memberNames ?? this.memberNames,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    updatedAt,
    customerId,
    customerName,
    teamId,
    teamName,
    lastMessage,
    lastMessageTime,
    unreadCount,
    status,
  ];
}

// Chat Message
class ChatMessage extends Equatable implements Identifiable, Timestamped {
  @override
  final String id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  final String chatGroupId;
  final String senderId;
  final String senderName;
  final String senderImageUrl;
  final MessageSenderType senderType; // customer or member
  final String content;
  final MessageType messageType;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.chatGroupId,
    required this.senderId,
    required this.senderName,
    required this.senderImageUrl,
    required this.senderType,
    required this.content,
    this.messageType = MessageType.text,
    this.isRead = false,
    this.readAt,
    this.metadata,
  });

  ChatMessage copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? chatGroupId,
    String? senderId,
    String? senderName,
    String? senderImageUrl,
    MessageSenderType? senderType,
    String? content,
    MessageType? messageType,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chatGroupId: chatGroupId ?? this.chatGroupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    updatedAt,
    chatGroupId,
    senderId,
    senderName,
    content,
    messageType,
    isRead,
  ];
}

// Enums
enum ChatStatus { active, archived, blocked }

enum MessageSenderType { customer, member }

enum MessageType { text, image, file, system }

// DTO for creating a new chat
class CreateChatRequest {
  final String customerId;
  final String teamId;
  final String initialMessage;

  const CreateChatRequest({
    required this.customerId,
    required this.teamId,
    required this.initialMessage,
  });
}

// lib/core/base/mock_chat_api_service.dart
// lib/core/providers/chat_provider.dart
