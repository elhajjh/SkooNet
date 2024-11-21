import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:skoonet/pages/new_private_chat/new_private_chat_view.dart';
import 'package:skoonet/pages/new_private_chat/qr_scanner_modal.dart';
import 'package:skoonet/pages/user_bottom_sheet/user_bottom_sheet.dart';
import 'package:skoonet/utils/adaptive_bottom_sheet.dart';
import 'package:skoonet/utils/fluffy_share.dart';
import 'package:skoonet/utils/platform_infos.dart';
import 'package:skoonet/utils/url_launcher.dart';
import 'package:skoonet/widgets/matrix.dart';

import '../../config/app_config.dart';

class NewPrivateChat extends StatefulWidget {
  const NewPrivateChat({super.key});

  @override
  NewPrivateChatController createState() => NewPrivateChatController();
}

class NewPrivateChatController extends State<NewPrivateChat> {
  final TextEditingController controller = TextEditingController();
  final FocusNode textFieldFocus = FocusNode();

  Future<List<Profile>>? searchResponse;

  Timer? _searchCoolDown;

  static const Duration _coolDown = Duration(milliseconds: 500);

  void searchUsers([String? input]) async {
    final searchTerm = input ?? controller.text;
    if (searchTerm.isEmpty) {
      _searchCoolDown?.cancel();
      setState(() {
        searchResponse = _searchCoolDown = null;
      });
      return;
    }

    _searchCoolDown?.cancel();
    _searchCoolDown = Timer(_coolDown, () {
      setState(() {
        searchResponse = _searchUser(searchTerm);
      });
    });
  }

  Future<List<Profile>> _searchUser(String searchTerm) async {
    // Check if username already includes the home server
    final userWithHomeServer = searchTerm.contains(':')
        ? searchTerm
        : '@$searchTerm:${AppConfig.defaultHomeserver}'; // Append home server if not present

    final result =
        await Matrix.of(context).client.searchUserDirectory(userWithHomeServer);
    final profiles = result.results;

    if (userWithHomeServer.isValidMatrixId &&
        userWithHomeServer.sigil == '@' &&
        !profiles.any((profile) => profile.userId == userWithHomeServer)) {
      profiles.add(Profile(userId: userWithHomeServer));
    }

    return profiles;
  }

  void inviteAction() => FluffyShare.shareInviteLink(context);

  void openScannerAction() async {
    if (PlatformInfos.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt < 21) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.of(context).unsupportedAndroidVersionLong,
            ),
          ),
        );
        return;
      }
    }
    await showAdaptiveBottomSheet(
      context: context,
      builder: (_) => QrScannerModal(
        onScan: (link) => UrlLauncher(context, link).openMatrixToUrl(),
      ),
    );
  }

  void copyUserId() async {
    await Clipboard.setData(
      ClipboardData(text: Matrix.of(context).client.userID!),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L10n.of(context).copiedToClipboard)),
    );
  }

  void openUserModal(Profile profile) => showAdaptiveBottomSheet(
        context: context,
        builder: (c) => UserBottomSheet(
          profile: profile,
          outerContext: context,
        ),
      );

  @override
  Widget build(BuildContext context) => NewPrivateChatView(this);
}
