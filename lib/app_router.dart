import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/post.dart';
import 'screens/login_screen.dart';
import 'screens/post_by_id_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/posts_screen.dart';
import 'screens/route_error_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/posts',
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (BuildContext context, GoRouterState state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isLoggingIn = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoggingIn) return '/login';
    if (isLoggedIn && isLoggingIn) return '/posts';

    return null;
  },
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
      path: '/login',
      name: 'login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/posts',
      name: 'posts',
      builder: (BuildContext context, GoRouterState state) {
        return const PostsScreen();
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
