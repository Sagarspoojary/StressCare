import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

Future<void> openWebCamera(BuildContext context, Function(String) onSuccess) async {
  throw UnsupportedError("Camera not supported on this platform");
}
