import 'package:flutter/material.dart';

import 'conversation_page.dart';
import 'data/models/profile.dart';
import 'data/repositories/dm_repository.dart';

/// Lets any screen switch the HomePage bottom-nav tab. HomePage listens to
/// [index] and rebuilds its IndexedStack accordingly.
class HomeTab {
  HomeTab._();

  static const int talent = 0;
  static const int network = 1;
  static const int chat = 2;
  static const int home = 3;
  static const int casting = 4;
  static const int account = 5;

  static final ValueNotifier<int> index = ValueNotifier<int>(home);

  static void go(int i) => index.value = i;
}

/// Bumped whenever a conversation is closed so the Chat list can refresh its
/// threads / unread counts.
class ChatRefresh {
  ChatRefresh._();
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);
  static void bump() => tick.value++;
}

/// Opens (or creates) the DM thread with [profile] and routes so that pressing
/// back lands on the main Chat tab — not the page the chat was opened from.
Future<void> openDirectChat(BuildContext context, Profile profile) async {
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final threadId = await DmRepository().getOrCreateThread(profile.id);
    final name = profile.fullName.isNotEmpty ? profile.fullName : 'You2Art User';
    final photo = (profile.avatarUrl ?? '').isNotEmpty
        ? profile.avatarUrl!
        : 'assets/images/profile_pic.png';
    HomeTab.go(HomeTab.chat);
    // Drop any pushed pages (e.g. the user's profile) so back → Chat list.
    nav.popUntil((r) => r.isFirst);
    nav.push(MaterialPageRoute(
      builder: (_) => ConversationPage(
        threadId: threadId,
        name: name,
        photo: photo,
      ),
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not open chat: $e')));
  }
}
