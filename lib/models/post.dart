class Post {
  Post({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.userId,
    required this.likes,
    required this.dislikes,
  });

  final int id;
  final String title;
  final String body;
  final List<String> tags;
  final int userId;
  final int likes;
  final int dislikes;

  factory Post.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List
        ? rawTags.whereType<String>().toList()
        : <String>[];

    final reactions = json['reactions'];
    int likes = 0;
    int dislikes = 0;

    if (reactions is int) {
      likes = reactions;
    } else if (reactions is Map) {
      final rawLikes = reactions['likes'];
      final rawDislikes = reactions['dislikes'];
      likes = rawLikes is int ? rawLikes : 0;
      dislikes = rawDislikes is int ? rawDislikes : 0;
    }

    return Post(
      id: json['id'] is int ? json['id'] as int : 0,
      title: json['title'] is String ? json['title'] as String : '',
      body: json['body'] is String ? json['body'] as String : '',
      tags: tags,
      userId: json['userId'] is int ? json['userId'] as int : 0,
      likes: likes,
      dislikes: dislikes,
    );
  }
}
