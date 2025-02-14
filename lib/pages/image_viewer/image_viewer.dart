import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:skoonet/pages/image_viewer/image_viewer_view.dart';
import 'package:skoonet/utils/platform_infos.dart';
import 'package:skoonet/widgets/matrix.dart';
import '../../utils/matrix_sdk_extensions/event_extension.dart';

class ImageViewer extends StatefulWidget {
  final Event event;
  final BuildContext outerContext;

  const ImageViewer(this.event, {required this.outerContext, super.key});

  @override
  ImageViewerController createState() => ImageViewerController();
}

class ImageViewerController extends State<ImageViewer> {
  /// Forward this image to another room.
  void forwardAction() {
    Matrix.of(widget.outerContext).shareContent = widget.event.content;
    Navigator.of(context).pop();
    widget.outerContext.go('/rooms');
  }

  /// Save this file with a system call.
  void saveFileAction(BuildContext context) => widget.event.saveFile(context);

  /// Save this file with a system call.
  void shareFileAction(BuildContext context) => widget.event.shareFile(context);

  static const maxScaleFactor = 1.5;

  /// Go back if user swiped it away
  void onInteractionEnds(ScaleEndDetails endDetails) {
    if (PlatformInfos.usesTouchscreen == false) {
      if (endDetails.velocity.pixelsPerSecond.dy >
          MediaQuery.of(context).size.height * maxScaleFactor) {
        Navigator.of(context, rootNavigator: false).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) => ImageViewerView(this);
}
