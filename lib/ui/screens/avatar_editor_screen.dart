// ignore_for_file: use_build_context_synchronously
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../data/avatar_repository.dart';
import '../../domain/player_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets/bb_backdrop.dart';
import '../widgets/bb_widgets.dart';
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
      backgroundColor: BbTokens.karstDeep,
      body: Stack(
        children: [
          const Positioned.fill(
            child: BbCanyonBackdrop(scrim: .68, bottomShade: .84),
          ),
          SafeArea(
            child: Column(
              children: [
                BbKarstHeader(
                  titleAsset:
                      'assets/images/ui/karst/avatar_profile_title_v3.png',
                  titleLabel: t.profileTitle,
                  titleKey: const Key('avatar-title'),
                  backLabel: t.backCta,
                  backKey: const Key('avatar-back'),
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AvatarPanel(
                                padding: const EdgeInsets.all(14),
                                child: Center(
                                  child: Container(
                                    key: const Key('avatar-square-preview'),
                                    width: 132,
                                    height: 132,
                                    padding: const EdgeInsets.all(6),
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: BbTokens.karstDeep,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: BbTokens.primaryGold,
                                        width: 3,
                                      ),
                                      boxShadow: BbTokens.sticker(
                                        5,
                                        BbTokens.karstShadow,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: choice.kind == AvatarKind.custom
                                          ? Image.file(
                                              File(choice.value),
                                              fit: BoxFit.cover,
                                            )
                                          : Image.asset(
                                              PlayerAvatar.presetAssets[choice
                                                      .value] ??
                                                  PlayerAvatar.presetAssets[
                                                      kDefaultAvatarPreset]!,
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _AvatarPanel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.mood_rounded,
                                          color: BbTokens.primaryGold,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          t.avatarPresetsTitle,
                                          style: BbText.h3(BbTokens.cream),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    GridView.count(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.3,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      children: PlayerAvatar.presetAssets.keys
                                          .map((id) {
                                            final active =
                                                choice.kind ==
                                                    AvatarKind.preset &&
                                                choice.value == id;
                                            return Semantics(
                                              selected: active,
                                              label: id,
                                              button: true,
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  onTap: () => setState(
                                                    () => selected =
                                                        PlayerAvatarRef.preset(
                                                          id,
                                                        ),
                                                  ),
                                                  child: AnimatedContainer(
                                                    duration:
                                                        BbTokens.durFast,
                                                    decoration: BoxDecoration(
                                                      color: BbTokens.karstDeep
                                                          .withValues(
                                                            alpha: .82,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            18,
                                                          ),
                                                      border: Border.all(
                                                        color: active
                                                            ? BbTokens
                                                                  .primaryGold
                                                            : BbTokens
                                                                  .karstBronze,
                                                        width: active ? 3 : 1.5,
                                                      ),
                                                    ),
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        PlayerAvatar(
                                                          avatar:
                                                              PlayerAvatarRef
                                                                  .preset(id),
                                                          size: 82,
                                                        ),
                                                        if (active)
                                                          const Positioned(
                                                            right: 8,
                                                            bottom: 8,
                                                            child: Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color: BbTokens
                                                                  .primaryGold,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              BbButton.karst(
                                label: t.devicePhotoCta,
                                icon: Icons.photo_library_outlined,
                                expand: true,
                                onPressed: processing ? null : _pick,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                t.avatarPrivacyCopy,
                                textAlign: TextAlign.center,
                                style: BbText.small(
                                  BbTokens.cream.withValues(alpha: .86),
                                ),
                              ),
                              const SizedBox(height: 14),
                              processing
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: BbTokens.primaryGold,
                                      ),
                                    )
                                  : BbButton.primary(
                                      label: t.saveCta,
                                      expand: true,
                                      onPressed: _save,
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (selected != null &&
        await ref.read(profileProvider.notifier).saveAvatar(selected!) &&
        mounted) {
      Navigator.pop(context);
    }
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

class _AvatarPanel extends StatelessWidget {
  const _AvatarPanel({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF20B675B), Color(0xF207504A)],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: BbTokens.karstBronze, width: 2),
      boxShadow: BbTokens.sticker(5, BbTokens.karstShadow),
    ),
    child: child,
  );
}
