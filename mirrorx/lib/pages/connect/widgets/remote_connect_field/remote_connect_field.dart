import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mirrorx/env/sdk/mirrorx_core.dart';
import 'package:mirrorx/env/sdk/mirrorx_core_sdk.dart';
import 'package:mirrorx/env/utility/dialog.dart';
import 'package:mirrorx/model/desktop.dart';
import 'package:mirrorx/pages/connect/widgets/connect_progress_dialog/connect_progress_dialog.dart';
import 'package:mirrorx/pages/connect/widgets/remote_connect_field/digit_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mirrorx/pages/desktop/desktop_page.dart';
import 'package:mirrorx/state/desktop_manager/desktop_manager_cubit.dart';
import 'package:mirrorx/state/navigator_key.dart';
import 'package:mirrorx/state/page_manager/page_manager_cubit.dart';
import 'package:mirrorx/state/profile/profile_state_cubit.dart';
import 'package:texture_render/texture_render.dart';

class RemoteConnectField extends StatefulWidget {
  const RemoteConnectField({Key? key}) : super(key: key);

  @override
  _RemoteConnectFieldState createState() => _RemoteConnectFieldState();
}

class _RemoteConnectFieldState extends State<RemoteConnectField> {
  final List<TextEditingController> _textControllers = [];
  late FocusScopeNode _focusScopeNode;
  bool _connectButtonDisabled = true;
  bool _connectHandshake = false;

  @override
  void initState() {
    super.initState();

    _focusScopeNode = FocusScopeNode(
      onKeyEvent: ((node, event) {
        if (event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.backspace) {
          final scopeNode = node as FocusScopeNode;
          if (scopeNode.focusedChild != null) {
            final index =
                scopeNode.children.toList().indexOf(scopeNode.focusedChild!);

            if (_textControllers[index].text.isEmpty) {
              if (index > 0) {
                scopeNode.previousFocus();
              }
            } else {
              _textControllers[index].clear();
            }
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      }),
    );

    for (var i = 0; i < 10; i++) {
      final controller = TextEditingController();
      controller.addListener(() {
        if (mounted) {
          setState(() {
            _connectButtonDisabled =
                _textControllers.any((element) => element.text.isEmpty);
          });
        }
      });
      _textControllers.add(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      width: 498,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.yellow, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.connectPageConnectRemoteTitle,
                  style: const TextStyle(fontSize: 27),
                ),
                _connectHandshake
                    ? const CircularProgressIndicator()
                    : IconButton(
                        onPressed: _connectButtonDisabled ? null : _connect,
                        icon: const Icon(Icons.login),
                        splashRadius: 20,
                        hoverColor: Colors.yellow,
                        disabledColor: Colors.grey,
                        tooltip: AppLocalizations.of(context)!
                            .connectPageConnectRemoteButtonConnectTooltip,
                      ),
              ],
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FocusScope(
                    node: _focusScopeNode,
                    child: Row(
                      children: [
                        _createField(0, 3, _textControllers[0]),
                        _createField(3, 6, _textControllers[1]),
                        const Text("-", style: TextStyle(fontSize: 36)),
                        _createField(6, 3, _textControllers[2]),
                        _createField(3, 3, _textControllers[3]),
                        _createField(3, 3, _textControllers[4]),
                        _createField(3, 6, _textControllers[5]),
                        const Text("-", style: TextStyle(fontSize: 36)),
                        _createField(6, 3, _textControllers[6]),
                        _createField(3, 3, _textControllers[7]),
                        _createField(3, 3, _textControllers[8]),
                        _createField(3, 0, _textControllers[9]),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _createField(double leftPadding, double rightPadding,
      TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.fromLTRB(leftPadding, 0, rightPadding, 0),
      child: SizedBox(
        width: 38,
        child: DigitInput(
          textEditingController: controller,
          focusNode: _focusScopeNode,
        ),
      ),
    );
  }

  void _connect() async {
    _updateHandshakeState(true);

    final remoteDeviceId = _textControllers.map((e) => e.text).join();
    log(remoteDeviceId);
    try {
      final success = await MirrorXCoreSDK.instance
          .signalingConnect(remoteDeviceId: remoteDeviceId);

      if (!success) {
        _updateHandshakeState(false);
        await popupDialog(
          contentBuilder: (_) =>
              Text(AppLocalizations.of(context)!.dialogConnectRemoteOffline),
          actionBuilder: (navigatorState) => [
            TextButton(
              onPressed: navigatorState.pop,
              child: Text(AppLocalizations.of(context)!.dialogOK),
            )
          ],
        );
        return;
      }
    } catch (e) {
      _updateHandshakeState(false);
      await popupDialog(
        contentBuilder: (_) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.dialogConnectRemoteError),
            Text(e.toString()),
          ],
        ),
        actionBuilder: (navigatorState) => [
          TextButton(
            onPressed: navigatorState.pop,
            child: Text(AppLocalizations.of(context)!.dialogOK),
          )
        ],
      );
      return;
    }

    _updateHandshakeState(false);

    await showGeneralDialog(
      context: context,
      pageBuilder: (context, animationValue1, animationValue2) {
        return StatefulBuilder(builder: (context, setter) {
          return ConnectProgressStateDialog(remoteDeviceId: remoteDeviceId);
        });
      },
      barrierDismissible: false,
      transitionBuilder: (context, animationValue1, animationValue2, child) {
        return Transform.scale(
          scale: animationValue1.value,
          child: Opacity(
            opacity: animationValue1.value,
            child: child,
          ),
        );
      },
      transitionDuration: kThemeAnimationDuration * 2,
    );
  }

  void _updateHandshakeState(bool isHandshaking) {
    setState(() {
      _connectHandshake = isHandshaking;
    });
  }

  @override
  void dispose() {
    _focusScopeNode.dispose();

    for (var controller in _textControllers) {
      controller.dispose();
    }

    super.dispose();
  }
}
