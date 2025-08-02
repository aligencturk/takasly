import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/chat.dart';
import '../../core/app_theme.dart';
import '../../utils/logger.dart';
import 'chat_detail_view.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında hemen loading başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChats();
    });
  }





  void _loadChats() {
    final authViewModel = context.read<AuthViewModel>();
    final chatViewModel = context.read<ChatViewModel>();
    
    if (authViewModel.currentUser != null) {
      Logger.info('ChatListView: Loading chats for user ${authViewModel.currentUser!.id}');
      chatViewModel.loadChats(authViewModel.currentUser!.id);
      chatViewModel.loadUnreadCount(authViewModel.currentUser!.id);
    } else {
      Logger.warning('ChatListView: No current user found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<ChatViewModel, AuthViewModel>(
        builder: (context, chatViewModel, authViewModel, child) {
          // Sadece loading true olduğunda loading göster
          if (chatViewModel.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Mesajlar yükleniyor...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (chatViewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bir hata oluştu',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chatViewModel.error!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      chatViewModel.clearError();
                      _loadChats();
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (chatViewModel.chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz mesajınız yok',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Takas teklifleri gönderdiğinizde\nburada görünecek',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadChats();
            },
            child: ListView.builder(
              itemCount: chatViewModel.chats.length,
              itemBuilder: (context, index) {
                // Pinli sohbetler üstte gözüksün diye sıralama
                final sortedChats = [
                  ...chatViewModel.chats.where((c) => c.isPinned == true),
                  ...chatViewModel.chats.where((c) => c.isPinned != true),
                ];
                final chat = sortedChats[index];
                return Slidable(
                  key: Key(chat.id),
                  startActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.25,
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          chatViewModel.togglePinChat(chat.id);
                        },
                        backgroundColor: chat.isPinned == true ? Colors.orange : AppTheme.primary,
                        foregroundColor: Colors.white,
                        icon: chat.isPinned == true ? FontAwesomeIcons.thumbtackSlash : FontAwesomeIcons.thumbtack,
                        label: chat.isPinned == true ? 'Kaldır' : 'Sabitle',
                      ),
                    ],
                  ),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.25,
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Sohbeti Sil'),
                              content: const Text('Bu sohbeti silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Vazgeç'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Sil'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true && context.mounted) {
                            try {
                              // Loading göster
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Sohbet siliniyor...'),
                                    ],
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              
                              await chatViewModel.deleteChat(chat.id);
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sohbet başarıyla silindi'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              Logger.error('Chat silme hatası: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Sohbet silinirken hata oluştu: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Sil',
                      ),
                    ],
                  ),
                  child: _ChatListItem(
                    chat: chat,
                    currentUserId: authViewModel.currentUser?.id ?? '',
                    unreadCount: chatViewModel.chatUnreadCounts[chat.id] ?? 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailView(chat: chat),
                        ),
                      );
                    },
                    onPinToggle: () {
                      chatViewModel.togglePinChat(chat.id);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final Chat chat;
  final String currentUserId;
  final int unreadCount;
  final VoidCallback onTap;
  final VoidCallback onPinToggle;

  const _ChatListItem({
    required this.chat,
    required this.currentUserId,
    required this.unreadCount,
    required this.onTap,
    required this.onPinToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Diğer katılımcıyı bul
    final otherParticipant = chat.participants
        .where((user) => user.id != currentUserId)
        .firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primary,
              child: otherParticipant?.avatar != null
                  ? ClipOval(
                      child: Image.network(
                        otherParticipant!.avatar!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            otherParticipant.name.isNotEmpty
                                ? otherParticipant.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      otherParticipant?.name.isNotEmpty == true
                          ? otherParticipant!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            // Sabitlenmiş sohbet için "Sabit" yazısı
            if (chat.isPinned == true)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.thumbtack,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherParticipant?.name ?? 'Bilinmeyen Kullanıcı',
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                  color: unreadCount > 0 ? Colors.black87 : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),  
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(chat.lastMessage?.createdAt ?? chat.updatedAt),
              style: TextStyle(
                color: unreadCount > 0 ? AppTheme.primary : Colors.grey[500],
                fontSize: 10,
                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                // Mesaj tipi ikonu
                if (chat.lastMessage != null) ...[
                  if (chat.lastMessage!.type == MessageType.product)
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 15,
                      color: unreadCount > 0 ? AppTheme.primary : Colors.grey[500],
                    )
                  else if (chat.lastMessage!.type == MessageType.image)
                    Icon(
                      Icons.image_outlined,
                      size: 15,
                      color: unreadCount > 0 ? AppTheme.primary : Colors.grey[500],
                    )
                  else
                    Icon(
                      Icons.message_outlined,
                      size: 15,
                      color: unreadCount > 0 ? AppTheme.primary : Colors.grey[500],
                    ),
                  const SizedBox(width: 4),
                ],
                // Son mesaj içeriği
                Expanded(
                  child: Text(
                    _getLastMessageText(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                // Okunmamış sayısı
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _getLastMessageText() {
    if (chat.lastMessage == null) {
      Logger.debug('ChatListItem: lastMessage is null for chat ${chat.id}');
      return 'Henüz mesaj yok';
    }

    final message = chat.lastMessage!;
    Logger.debug('ChatListItem: lastMessage type: ${message.type}, content: ${message.content}');
    
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Fotoğraf';
      case MessageType.product:
        return '📦 ${message.product?.title ?? 'Ürün'}';
      default:
        return message.content;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    final difference = now.difference(date);

    if (messageDate == today) {
      // Bugün
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Dün
      return 'Dün';
    } else if (difference.inDays < 7) {
      // Bu hafta
      final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return days[date.weekday - 1];
    } else {
      // Daha eski
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
    }
  }
} 