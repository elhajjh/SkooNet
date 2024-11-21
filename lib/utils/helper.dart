import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:matrix/matrix.dart';
import 'package:skoonet/widgets/matrix.dart';

class Helper {
  static bool allowLeaveRoom(Room room, BuildContext context) {
    final roomDetails = Matrix.of(context).client.getRoomById(room.id);

    // Check if the current user has sufficient power level
    final userPowerLevel =
        roomDetails!.getPowerLevelByUserId(room.client.userID!);

    // Retrieve the custom leave restriction state
    final allowLeaveEvent = roomDetails.getState('m.room.custom_allow_leave');

    // If the user is a moderator/admin and the leave is restricted, prevent leaving
    return userPowerLevel >= 50 ||
        allowLeaveEvent == null ||
        allowLeaveEvent.content['allow_leave'] == true;
  }
}
