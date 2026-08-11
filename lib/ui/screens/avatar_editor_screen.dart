// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/avatar_repository.dart';
import '../../domain/player_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets/player_avatar.dart';

class AvatarEditorScreen extends ConsumerStatefulWidget {
  const AvatarEditorScreen({
    super.key,
    this.pickImagePath,
    this.repository = const AvatarRepository(),
  });
  final Future<String?> Function()? pickImagePath;
  final AvatarRepository repository;
  @override
  ConsumerState<AvatarEditorScreen> createState() => _State();
}

class _State extends ConsumerState<AvatarEditorScreen> {
  PlayerAvatarRef? selected;
  bool processing = false;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final current = ref.watch(profileProvider).profile.avatar;
    final choice = selected ?? current;
    return Scaffold(
      appBar: AppBar(title: Text(t.changeAvatarCta)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                key: const Key('avatar-square-preview'),
                width: 140,
                height: 140,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber, width: 3),
                ),
                child: choice.kind == AvatarKind.custom
                    ? Image.file(File(choice.value), fit: BoxFit.cover)
                    : Image.asset(
                        PlayerAvatar.presetAssets[choice.value] ??
                            PlayerAvatar.presetAssets[kDefaultAvatarPreset]!,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.avatarPresetsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              children: PlayerAvatar.presetAssets.keys.map((id) {
                final active =
                    choice.kind == AvatarKind.preset && choice.value == id;
                return Semantics(
                  selected: active,
                  label: id,
                  button: true,
                  child: InkWell(
                    onTap: () =>
                        setState(() => selected = PlayerAvatarRef.preset(id)),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PlayerAvatar(avatar: PlayerAvatarRef.preset(id)),
                        if (active)
                          const Positioned(
                            right: 8,
                            bottom: 8,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.amber,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            OutlinedButton.icon(
              onPressed: processing ? null : _pick,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(t.devicePhotoCta),
            ),
            Text(t.avatarPrivacyCopy, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: processing
                  ? null
                  : () async {
                      if (selected != null &&
                          await ref
                              .read(profileProvider.notifier)
                              .saveAvatar(selected!) &&
                          mounted) {
                        Navigator.pop(context);
                      }
                    },
              child: processing
                  ? const CircularProgressIndicator()
                  : Text(t.saveCta),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick() async {
    final pickedPath = widget.pickImagePath != null
        ? await widget.pickImagePath!()
        : (await ImagePicker().pickImage(source: ImageSource.gallery))?.path;
    if (pickedPath == null || !mounted) return;
    setState(() => processing = true);
    try {
      final root = await getApplicationSupportDirectory();
      final file = await widget.repository.process(
        inputPath: pickedPath,
        outputPath: '${root.path}/avatars/guest/avatar.jpg',
      );
      if (mounted) setState(() => selected = PlayerAvatarRef.custom(file.path));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).avatarInvalidError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }
}
