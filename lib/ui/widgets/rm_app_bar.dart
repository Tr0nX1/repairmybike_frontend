import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class RMAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const RMAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final platform = defaultTargetPlatform;
    final leadingIcon = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
        ? CupertinoIcons.back
        : Icons.arrow_back;
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).appBarTheme.backgroundColor ?? cs.surface;
    final fg = Theme.of(context).appBarTheme.foregroundColor ?? cs.onSurface;
    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      leading: canPop
          ? Semantics(
              label: 'Go back',
              button: true,
              child: IconButton(
                icon: Icon(leadingIcon, color: fg),
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
              ),
            )
          : null,
      title: Text(title, style: TextStyle(color: fg)),
      actions: actions,
    );
  }
}
