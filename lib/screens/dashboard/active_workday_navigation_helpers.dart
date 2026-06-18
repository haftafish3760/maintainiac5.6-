part of 'active_workday_screen.dart';

void _openFlow(
  BuildContext context, {
  required String title,
  required IconData icon,
  required String summary,
  required bool requiresOdometer,
}) {
  Navigator.of(context).push(
    appNativeRoute<void>(
      context,
      FlowPlaceholderScreen(
        title: title,
        icon: icon,
        summary: summary,
        requiresOdometer: requiresOdometer,
      ),
    ),
  );
}
