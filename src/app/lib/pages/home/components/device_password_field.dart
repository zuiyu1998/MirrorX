import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DevicePasswordField extends StatefulWidget {
  const DevicePasswordField({Key? key}) : super(key: key);

  @override
  _DevicePasswordFieldState createState() => _DevicePasswordFieldState();
}

class _DevicePasswordFieldState extends State<DevicePasswordField> {
  bool _passwordVisable = false;
  final String _password = "45678213";

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(children: [
        Expanded(
          child: Center(
            child: Text(
              _passwordVisable ? _password : "＊＊＊＊＊＊",
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: _passwordVisable
              ? tr("connect_to_remote.device_password_hide")
              : tr("connect_to_remote.device_password_show"),
          onPressed: () => setState(() {
            _passwordVisable = !_passwordVisable;
          }),
          splashRadius: 14,
          splashColor: Colors.transparent,
          hoverColor: const Color.fromARGB(240, 220, 220, 220),
          icon: Icon(
            _passwordVisable ? Icons.visibility_off : Icons.visibility,
            size: 16,
          ),
        ),
        IconButton(
          tooltip: tr("connect_to_remote.device_password_edit"),
          onPressed: () {},
          splashRadius: 14,
          splashColor: Colors.transparent,
          hoverColor: const Color.fromARGB(240, 220, 220, 220),
          icon: const Icon(
            Icons.edit,
            size: 16,
          ),
        ),
      ]),
    );
  }
}
