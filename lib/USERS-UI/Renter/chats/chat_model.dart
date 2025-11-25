class ChatModel {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;
  final bool isOnline;

  ChatModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  // Dummy data
  static List<ChatModel> getDummyChats() {
    return [
      ChatModel(
        id: '1',
        name: 'Helda Quardo',
        avatarUrl: 'https://ui-avatars.com/api/?name=Helda+Quardo&background=ff6b35&color=fff',
        lastMessage: 'Your car is in the way it will arrriv...',
        timestamp: '09:20 pm',
        unreadCount: 0,
        isOnline: false,
      ),
      ChatModel(
        id: '2',
        name: 'Cameron',
        avatarUrl: 'https://ui-avatars.com/api/?name=Cameron&background=4a90e2&color=fff',
        lastMessage: 'Ok, thanks!',
        timestamp: '08:35 pm',
        unreadCount: 1,
        isOnline: true,
      ),
      ChatModel(
        id: '3',
        name: 'Mr. David',
        avatarUrl: 'https://ui-avatars.com/api/?name=Mr+David&background=7b68ee&color=fff',
        lastMessage: 'Hi, I am looking with um...',
        timestamp: '08:20 pm',
        unreadCount: 0,
        isOnline: false,
      ),
      ChatModel(
        id: '4',
        name: 'Richard',
        avatarUrl: 'https://ui-avatars.com/api/?name=Richard&background=50c878&color=fff',
        lastMessage: 'Typing message',
        timestamp: '07:25 pm',
        unreadCount: 0,
        isOnline: true,
      ),
      ChatModel(
        id: '5',
        name: 'Machel',
        avatarUrl: 'https://ui-avatars.com/api/?name=Machel&background=ff69b4&color=fff',
        lastMessage: 'Yes, It is amazing and smooth.',
        timestamp: 'Yesterday',
        unreadCount: 0,
        isOnline: false,
      ),
      ChatModel(
        id: '6',
        name: 'Anna',
        avatarUrl: 'https://ui-avatars.com/api/?name=Anna&background=ffa500&color=fff',
        lastMessage: 'Thank you',
        timestamp: 'Yesterday',
        unreadCount: 0,
        isOnline: false,
      ),
    ];
  }
}