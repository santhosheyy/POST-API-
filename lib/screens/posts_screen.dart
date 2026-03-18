import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/post.dart';
import '../services/post_api.dart';
import '../widgets/post_card.dart';
import 'package:my_simple_package/my_simple_package.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<Post> _posts = [];

  int _total = 0;
  int _skip = 0;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WelcomeDialog.show(
        context,
        title: 'Welcome!',
        message: 'Welcome to The Journal App 📖\nHere are the latest posts.',
        buttonText: 'Let\'s Go!',
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasMore => _posts.length < _total;

  List<Post> _visiblePosts() {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return _posts;

    return _posts.where((post) {
      final inTitle = post.title.toLowerCase().contains(query);
      final inBody = post.body.toLowerCase().contains(query);
      return inTitle || inBody;
    }).toList();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isInitialLoading = true;
      _hasError = false;
      _posts.clear();
      _skip = 0;
      _total = 0;
    });

    try {
      final page = await PostApi.fetchPosts(limit: _pageSize, skip: 0);
      if (!mounted) return;
      setState(() {
        _posts.addAll(page.posts);
        _total = page.total;
        _skip = page.skip + page.posts.length;
        _isInitialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final page = await PostApi.fetchPosts(limit: _pageSize, skip: _skip);
      if (!mounted) return;
      setState(() {
        _posts.addAll(page.posts);
        _total = page.total;
        _skip = page.skip + page.posts.length;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visiblePosts = _visiblePosts();

    return Scaffold(
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  loaded: _posts.length,
                  total: _total,
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (value) => setState(() => _searchQuery = value.trim()),
                  onSearchCleared: () => setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  }),
                ),
                Expanded(
                  child: _isInitialLoading
                      ? const _LoadingState()
                      : _hasError && _posts.isEmpty
                          ? _ErrorState(onRetry: _loadFirstPage)
                          : _posts.isEmpty
                              ? _EmptyState(onRetry: _loadFirstPage)
                              : visiblePosts.isEmpty
                                  ? _NoResultsState()
                                  : RefreshIndicator(
                                      color: scheme.secondary,
                                      onRefresh: _loadFirstPage,
                                      child: NotificationListener<ScrollNotification>(
                                        onNotification: (notification) {
                                          if (notification.metrics.pixels >=
                                              notification.metrics.maxScrollExtent * 0.7) {
                                            _loadMore();
                                          }
                                          return false;
                                        },
                                        child: Scrollbar(
                                          controller: _scrollController,
                                          thumbVisibility: true,
                                          interactive: true,
                                          thickness: 5,
                                          radius: const Radius.circular(12),
                                          child: ListView.builder(
                                            controller: _scrollController,
                                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                                            itemCount: visiblePosts.length + 1,
                                            itemBuilder: (context, index) {
                                              if (index < visiblePosts.length) {
                                                final post = visiblePosts[index];
                                                return PostCard(
                                                  post: post,
                                                  onTap: () {
                                                    context.push(
                                                      '/posts/${post.id}',
                                                      extra: post,
                                                    );
                                                  },
                                                );
                                              }

                                              return _LoadMoreSection(
                                                hasMore: _hasMore,
                                                isLoading: _isLoadingMore,
                                                onLoadMore: _loadMore,
                                              );
                                            },
                                          ),
                                        ),
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
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF6F1E8),
            scheme.surface,
            const Color(0xFFECE3D7),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -130,
            left: -80,
            child: _Blob(
              size: 320,
              color: scheme.primaryContainer.withValues(alpha: 0.45),
            ),
          ),
          Positioned(
            bottom: -170,
            right: -120,
            child: _Blob(
              size: 360,
              color: scheme.secondaryContainer.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.loaded,
    required this.total,
    required this.controller,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchCleared,
  });

  final int loaded;
  final int total;
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.7),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('The Journal', style: theme.textTheme.displaySmall),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  total > 0 ? '$loaded of $total posts loaded' : '$loaded posts loaded',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search title or content',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: onSearchCleared,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.85),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadMoreSection extends StatelessWidget {
  const _LoadMoreSection({
    required this.hasMore,
    required this.isLoading,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool isLoading;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            'END OF LIST',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 2.6,
                  color: Colors.black54,
                ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 18),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : FilledButton.tonalIcon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Load more'),
              ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text('Loading posts...', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 36),
            const SizedBox(height: 12),
            Text('We could not reach the feed.',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 36),
            const SizedBox(height: 12),
            Text('No posts right now.', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reload feed'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 36),
            const SizedBox(height: 12),
            Text('No posts match your search.',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
