import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/bb_theme.dart';
import '../core/bb_tokens.dart';
import '../domain/character.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'localized_text.dart';
import 'widgets/bb_widgets.dart';

enum CharacterDialoguePresentation { modal, embedded }

class CharacterDialogue extends ConsumerWidget {
  const CharacterDialogue({
    required this.id,
    required this.onDismiss,
    this.presentation = CharacterDialoguePresentation.embedded,
    super.key,
  });

  final DialogueId id;
  final VoidCallback onDismiss;
  final CharacterDialoguePresentation presentation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DialogueSpec spec = dialogueSpec(id);
    final Set<DialogueId> seen = ref.watch(dialogueSeenProvider);
    if (spec.onceOnly && seen.contains(id)) return const SizedBox.shrink();

    final AppLocalizations t = AppLocalizations.of(context);
    final String name = characterName(t);
    final String line = dialogueText(id, t);
    final bool modal = presentation == CharacterDialoguePresentation.modal;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Widget panel = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        key: Key('character-dialogue-${id.name}'),
        padding: const EdgeInsets.all(BbTokens.sp4),
        decoration: BoxDecoration(
          color: BbTokens.panelNavy,
          borderRadius: BorderRadius.circular(BbTokens.rLg),
          border: Border.all(color: BbTokens.textMuted, width: BbTokens.bd2),
          boxShadow: modal
              ? BbTokens.sticker(BbTokens.stickerMd, BbTokens.outlineDark)
              : const <BoxShadow>[],
        ),
        // Keep this one explicit semantics node. Without explicitChildNodes,
        // combining a labelled container and its interactive close control can
        // trigger a framework semantics assertion and a red error screen.
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: '$name. $line',
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Image.asset(
                      'assets/images/mascot/cu_doi_mascot_galaxy_v3.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: BbTokens.sp3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(name, style: BbText.h3(BbTokens.primaryGold)),
                          const SizedBox(height: BbTokens.sp1),
                          Text(line, style: BbText.body(BbTokens.textPrimary)),
                        ],
                      ),
                    ),
                    if (!modal)
                      BbIconButton(
                        key: const Key('dialogue-close'),
                        icon: Icons.close_rounded,
                        variant: BbVariant.danger,
                        diameter: BbTokens.tapMin,
                        semanticLabel: t.backCta,
                        onPressed: () => _dismiss(ref),
                      ),
                  ],
                ),
                if (modal) ...<Widget>[
                  const SizedBox(height: BbTokens.sp4),
                  BbButton.primary(
                    key: const Key('dialogue-dismiss'),
                    label: t.gotItCta,
                    expand: true,
                    onPressed: () => _dismiss(ref),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    final Widget animated = AnimatedOpacity(
      opacity: 1,
      duration: reduceMotion ? Duration.zero : BbTokens.durBase,
      child: panel,
    );
    if (!modal) return animated;
    return ColoredBox(
      color: BbTokens.outlineDark.withValues(alpha: 0.76),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BbTokens.sp5),
          child: animated,
        ),
      ),
    );
  }

  Future<void> _dismiss(WidgetRef ref) async {
    if (dialogueSpec(id).onceOnly) {
      await ref.read(dialogueSeenProvider.notifier).markSeen(id);
    }
    onDismiss();
  }
}
