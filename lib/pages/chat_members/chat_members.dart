import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import '../../widgets/matrix.dart';
import 'chat_members_view.dart';

class ChatMembersPage extends StatefulWidget {
  final String roomId;
  const ChatMembersPage({required this.roomId, super.key});

  @override
  State<ChatMembersPage> createState() => ChatMembersController();
}

class ChatMembersController extends State<ChatMembersPage> {
  List<User>? members;
  List<User>? filteredMembers;
  Object? error;

  bool hideMembersList = false; // New property to track hide_members_list.

  final TextEditingController filterController = TextEditingController();

  void setFilter([_]) async {
    final filter = filterController.text.toLowerCase().trim();

    if (filter.isEmpty) {
      setState(() {
        filteredMembers = members
          ?..sort((b, a) => a.powerLevel.compareTo(b.powerLevel));
      });
      return;
    }
    setState(() {
      filteredMembers = members
          ?.where(
            (user) =>
        user.displayName?.toLowerCase().contains(filter) ??
            user.id.toLowerCase().contains(filter),
      )
          .toList()
        ?..sort((b, a) => a.powerLevel.compareTo(b.powerLevel));
    });
  }

  void refreshMembers() async {
    try {
      setState(() {
        error = null;
      });

      final room = Matrix.of(context).client.getRoomById(widget.roomId);
      if (room == null) {
        setState(() {
          error = 'Room not found.';
        });
        return;
      }

      // Retrieve custom events from the room's states
      final customEvent = room.states['m.room.custom_hide_members']?.values.firstWhereOrNull(
            (event) => event.content != null && event.content['hide_members_list'] == true,
      );

      // Set the hideMembersList flag based on the custom event
      hideMembersList = customEvent != null;

      // Fetch participants
      final participants = await room.requestParticipants();
      if (!mounted) return;

      // Get the current user's power level
      final currentUserPowerLevel = room.ownPowerLevel;

      if (!hideMembersList || currentUserPowerLevel >= 50) {
        // If the list is not hidden or the current user is an admin/moderator, show all members
        setState(() {
          members = participants;
        });
      } else {
        // Otherwise, show only admins
        final adminMembers = participants.where((user) => user.powerLevel >= 50).toList();
        setState(() {
          members = adminMembers; // Show only admins
        });
      }

      setFilter();
    } catch (e, s) {
      Logs().d('Unable to request participants. Try again in 3 seconds...', e, s);
      setState(() {
        error = e;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    refreshMembers();
  }

  @override
  Widget build(BuildContext context) => ChatMembersView(this);
}