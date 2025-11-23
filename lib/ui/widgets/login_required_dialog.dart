import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../auth_page.dart';

Future<void> showLoginRequiredDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Login Required'),
        content: const Text('To complete this action, please log in or create an account'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Continue as Guest'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AuthPage(
                    onFinished: () async {
                      // After login, attempt to perform pending action from storage
                      final action = await AppState.takePendingAction();
                      if (action == null) return;
                      // Let originating pages re-dispatch based on pending action presence
                      // No-op here; pages will check and perform on next build.
                    },
                  ),
                ),
              );
            },
            child: const Text('Log In'),
          ),
        ],
      );
    },
  );
}
