import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/posts'),
                child: const Text('Go to posts'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
