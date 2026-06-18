import 'package:flutter/material.dart';

const appBackButtonLeadingWidth = 84.0;

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1976B9),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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

class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions = const [],
    this.centerTitle = false,
    this.onBack,
  });

  final String title;
  final bool showBack;
  final List<Widget> actions;
  final bool centerTitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: const BoxDecoration(color: Color(0xFF101416)),
        child: Row(
          children: [
            if (showBack)
              SizedBox(
                width: appBackButtonLeadingWidth,
                child: AppBackButton(onPressed: onBack),
              )
            else
              const SizedBox(width: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  color: Color(0xFFE2E8EA),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (actions.isEmpty)
              const SizedBox.shrink()
            else
              Row(mainAxisSize: MainAxisSize.min, children: actions),
          ],
        ),
      ),
    );
  }
}
