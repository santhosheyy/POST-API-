import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/post.dart';

class PostApi {
  static const _baseUrl = 'https://dummyjson.com/posts';

  static Future<PostPage> fetchPosts({
    int limit = 20,
    int skip = 0,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'limit': limit.toString(),
        'skip': skip.toString(),
      },
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load posts (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response shape');
    }

    final posts = decoded['posts'];
    if (posts is! List) {
      return PostPage(
        posts: const [],
        total: decoded['total'] is int ? decoded['total'] as int : 0,
        limit: limit,
        skip: skip,
      );
    }

    final parsedPosts = posts
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();

    return PostPage(
      posts: parsedPosts,
      total: decoded['total'] is int ? decoded['total'] as int : parsedPosts.length,
      limit: decoded['limit'] is int ? decoded['limit'] as int : limit,
      skip: decoded['skip'] is int ? decoded['skip'] as int : skip,
    );
  }
}

class PostPage {
  PostPage({
    required this.posts,
    required this.total,
    required this.limit,
    required this.skip,
  });

  final List<Post> posts;
  final int total;
  final int limit;
  final int skip;
}
