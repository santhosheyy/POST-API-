import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/post.dart';
import '../services/post_api.dart';
import '../widgets/post_card.dart';

enum _SortMode { newest, oldest, mostLiked }
enum _ReadFilter { all, unread, read }

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
  final Set<int> _favoritePostIds = <int>{};
  final Set<int> _readPostIds = <int>{};
  final Set<String> _selectedTags = <String>{};

  int _total = 0;
  int _skip = 0;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _showFavoritesOnly = false;
  bool _showScrollToTop = false;
  double _scrollProgress = 0;
  _SortMode _sortMode = _SortMode.newest;
  _ReadFilter _readFilter = _ReadFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final show = position.pixels > 280;
    final max = position.maxScrollExtent;
    final progress = max <= 0 ? 0.0 : (position.pixels / max).clamp(0.0, 1.0);

    if (show != _showScrollToTop || (progress - _scrollProgress).abs() > 0.02) {
      setState(() {
        _showScrollToTop = show;
        _scrollProgress = progress;
      });
    }
  }

  bool get _hasMore => _posts.length < _total;

  List<String> get _availableTags {
    final frequencies = <String, int>{};

    for (final post in _posts) {
      for (final tag in post.tags) {
        frequencies[tag] = (frequencies[tag] ?? 0) + 1;
      }
    }

    final sorted = frequencies.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });

    return sorted.map((entry) => entry.key).take(12).toList();
  }

  List<Post> _visiblePosts() {
    final query = _searchQuery.toLowerCase();
    final filtered = _posts.where((post) {
      if (_showFavoritesOnly && !_favoritePostIds.contains(post.id)) {
        return false;
      }

      if (_readFilter == _ReadFilter.read && !_readPostIds.contains(post.id)) {
        return false;
      }

      if (_readFilter == _ReadFilter.unread && _readPostIds.contains(post.id)) {
        return false;
      }

      if (_selectedTags.isNotEmpty && !post.tags.any(_selectedTags.contains)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final inTitle = post.title.toLowerCase().contains(query);
      final inBody = post.body.toLowerCase().contains(query);
      return inTitle || inBody;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortMode) {
        case _SortMode.newest:
          return b.id.compareTo(a.id);
        case _SortMode.oldest:
          return a.id.compareTo(b.id);
        case _SortMode.mostLiked:
          return b.likes.compareTo(a.likes);
      }
    });

    return filtered;
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

  void _toggleFavorite(int postId) {
    setState(() {
      if (_favoritePostIds.contains(postId)) {
        _favoritePostIds.remove(postId);
      } else {
        _favoritePostIds.add(postId);
      }
    });
  }

  void _markAsRead(int postId) {
    if (_readPostIds.contains(postId)) return;
    setState(() {
      _readPostIds.add(postId);
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _showFavoritesOnly = false;
      _sortMode = _SortMode.newest;
      _readFilter = _ReadFilter.all;
      _searchQuery = '';
      _selectedTags.clear();
      _searchController.clear();
    });
  }

  void _openRandomPost(List<Post> visiblePosts) {
    if (visiblePosts.isEmpty) return;
    final randomPost = visiblePosts[Random().nextInt(visiblePosts.length)];
    _markAsRead(randomPost.id);
    context.push('/posts/${randomPost.id}', extra: randomPost);
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
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
                  visible: visiblePosts.length,
                  favoriteCount: _favoritePostIds.length,
                  readCount: _readPostIds.length,
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  onSearchChanged: (value) => setState(() => _searchQuery = value.trim()),
                  onSearchCleared: () => setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  }),
                  showFavoritesOnly: _showFavoritesOnly,
                  onToggleFavoritesOnly: (value) => setState(() => _showFavoritesOnly = value),
                  sortMode: _sortMode,
                  onSortChanged: (value) => setState(() => _sortMode = value),
                  readFilter: _readFilter,
                  onReadFilterChanged: (value) => setState(() => _readFilter = value),
                  availableTags: _availableTags,
                  selectedTags: _selectedTags,
                  onTagToggled: _toggleTag,
                  onClearFilters: _clearFilters,
                  scrollProgress: _scrollProgress,
                ),
                Expanded(
                  child: _isInitialLoading
                      ? const _LoadingState()
                      : _hasError && _posts.isEmpty
                          ? _ErrorState(onRetry: _loadFirstPage)
                          : _posts.isEmpty
                              ? _EmptyState(onRetry: _loadFirstPage)
                              : visiblePosts.isEmpty
                                  ? _NoResultsState(onClearFilters: _clearFilters)
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
                                            physics: const AlwaysScrollableScrollPhysics(
                                              parent: BouncingScrollPhysics(),
                                            ),
                                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                                            itemCount: visiblePosts.length + 1,
                                            itemBuilder: (context, index) {
                                              if (index < visiblePosts.length) {
                                                final post = visiblePosts[index];
                                                return PostCard(
                                                  post: post,
                                                  isFavorite: _favoritePostIds.contains(post.id),
                                                  isRead: _readPostIds.contains(post.id),
                                                  onToggleFavorite: () => _toggleFavorite(post.id),
                                                  onTap: () {
                                                    _markAsRead(post.id);
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
          if (visiblePosts.isNotEmpty)
            _QuickActions(
              showScrollToTop: _showScrollToTop,
              onRandom: () => _openRandomPost(visiblePosts),
              onScrollToTop: _scrollToTop,
            ),
          const _HomeIndicator(),
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
    required this.visible,
    required this.favoriteCount,
    required this.readCount,
    required this.controller,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.showFavoritesOnly,
    required this.onToggleFavoritesOnly,
    required this.sortMode,
    required this.onSortChanged,
    required this.readFilter,
    required this.onReadFilterChanged,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagToggled,
    required this.onClearFilters,
    required this.scrollProgress,
  });

  final int loaded;
  final int total;
  final int visible;
  final int favoriteCount;
  final int readCount;
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final bool showFavoritesOnly;
  final ValueChanged<bool> onToggleFavoritesOnly;
  final _SortMode sortMode;
  final ValueChanged<_SortMode> onSortChanged;
  final _ReadFilter readFilter;
  final ValueChanged<_ReadFilter> onReadFilterChanged;
  final List<String> availableTags;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;
  final VoidCallback onClearFilters;
  final double scrollProgress;

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
                Text('The Journal', style: theme.textTheme.displaySmall),
                const SizedBox(height: 10),
                Text(
                  total > 0 ? '$loaded of $total posts loaded' : '$loaded posts loaded',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : loaded / total,
                    minHeight: 6,
                    backgroundColor: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetricPill(label: 'Visible', value: visible),
                    const SizedBox(width: 8),
                    _MetricPill(label: 'Favorites', value: favoriteCount),
                    const SizedBox(width: 8),
                    _MetricPill(label: 'Read', value: readCount),
                    const Spacer(),
                    
                  ],
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Favorites'),
                      selected: showFavoritesOnly,
                      onSelected: onToggleFavoritesOnly,
                      avatar: Icon(
                        showFavoritesOnly
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('All'),
                      selected: readFilter == _ReadFilter.all,
                      onSelected: (_) => onReadFilterChanged(_ReadFilter.all),
                    ),
                    ChoiceChip(
                      label: const Text('Unread'),
                      selected: readFilter == _ReadFilter.unread,
                      onSelected: (_) => onReadFilterChanged(_ReadFilter.unread),
                    ),
                    ChoiceChip(
                      label: const Text('Read'),
                      selected: readFilter == _ReadFilter.read,
                      onSelected: (_) => onReadFilterChanged(_ReadFilter.read),
                    ),
                    ChoiceChip(
                      label: const Text('Newest'),
                      selected: sortMode == _SortMode.newest,
                      onSelected: (_) => onSortChanged(_SortMode.newest),
                    ),
                    ChoiceChip(
                      label: const Text('Oldest'),
                      selected: sortMode == _SortMode.oldest,
                      onSelected: (_) => onSortChanged(_SortMode.oldest),
                    ),
                    ChoiceChip(
                      label: const Text('Most Liked'),
                      selected: sortMode == _SortMode.mostLiked,
                      onSelected: (_) => onSortChanged(_SortMode.mostLiked),
                    ),
                  ],
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Text('$label: $value', style: Theme.of(context).textTheme.labelLarge),
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
  const _NoResultsState({required this.onClearFilters});

  final VoidCallback onClearFilters;

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
            Text('No posts match your filters.',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onClearFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.showScrollToTop,
    required this.onRandom,
    required this.onScrollToTop,
  });

  final bool showScrollToTop;
  final VoidCallback onRandom;
  final VoidCallback onScrollToTop;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 18,
      bottom: 86,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'random_post',
            onPressed: onRandom,
            child: const Icon(Icons.casino_rounded),
          ),
          const SizedBox(height: 10),
          AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: showScrollToTop ? 1 : 0,
            child: IgnorePointer(
              ignoring: !showScrollToTop,
              child: FloatingActionButton.small(
                heroTag: 'scroll_top',
                onPressed: onScrollToTop,
                child: const Icon(Icons.vertical_align_top_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 120,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}
