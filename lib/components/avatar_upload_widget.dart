import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class AvatarUploadWidget extends StatefulWidget {
  final double radius;
  final Function(Uint8List?)? onAvatarChanged;
  final Uint8List? initialAvatar;

  const AvatarUploadWidget({
    super.key,
    this.radius = 60,
    this.onAvatarChanged,
    this.initialAvatar,
  });

  @override
  State<AvatarUploadWidget> createState() => _AvatarUploadWidgetState();
}

class _AvatarUploadWidgetState extends State<AvatarUploadWidget> {
  Uint8List? _avatarBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndCropImage() async {
    try {
      // 1️⃣ 选择图片
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
      );
      if (picked == null) return;

      Uint8List bytes = await picked.readAsBytes();

      // 2️⃣ 如果在移动端，则裁剪
      if (!kIsWeb) {
        final cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 90,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Cropping',
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              hideBottomControls: true,
            ),
            IOSUiSettings(title: 'Cropping'),
          ],
        );
        if (cropped != null) {
          bytes = await cropped.readAsBytes();
        }
      }

      setState(() {
        _avatarBytes = bytes;
      });
      widget.onAvatarChanged?.call(bytes);
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _pickAndCropImage,
      borderRadius: BorderRadius.circular(widget.radius),
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: theme.colorScheme.secondaryContainer,
        backgroundImage: _avatarBytes != null
            ? MemoryImage(_avatarBytes!)
            : widget.initialAvatar != null
            ? MemoryImage(widget.initialAvatar!)
            : null,
        child: _avatarBytes == null && widget.initialAvatar == null
            ? Icon(
                Icons.add_a_photo,
                size: widget.radius,
                color: theme.colorScheme.primary,
              )
            : null,
      ),
    );
  }
}
