import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/post.dart';
import 'screens/about_screen.dart';
import 'screens/post_by_id_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/posts_screen.dart';
import 'screens/route_error_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/posts',
  errorBuilder: (BuildContext context, GoRouterState state) {
    return RouteErrorScreen(
      message: state.error?.toString() ?? 'Page not found.',
    );
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      redirect: (BuildContext context, GoRouterState state) => '/posts',
    ),
    GoRoute(
      path: '/posts',
      name: 'posts',
      builder: (BuildContext context, GoRouterState state) {
        return const PostsScreen();
      },
    ),
    GoRoute(
      path: '/about',
      name: 'about',
      builder: (BuildContext context, GoRouterState state) {
        return const AboutScreen();
      },
    ),
    GoRoute(
      path: '/posts/:postId',
      name: 'post-details',
      builder: (BuildContext context, GoRouterState state) {
        final rawId = state.pathParameters['postId'];
        final postId = int.tryParse(rawId ?? '');
        if (postId == null) {
          return const RouteErrorScreen(message: 'Invalid post ID.');
        }

        final extra = state.extra;
        if (extra is Post && extra.id == postId) {
          return PostDetailScreen(post: extra);
        }

        return PostByIdScreen(postId: postId);
      },
    ),
  ],
);
