import '../domain/chapters.dart';
import '../domain/character.dart';
import '../l10n/app_localizations.dart';

String characterName(AppLocalizations t) => t.characterName;

String chapterTitle(Chapter? chapter, AppLocalizations t) =>
    switch (chapter?.number) {
      1 => t.chapter1Title,
      2 => t.chapter2Title,
      3 => t.chapter3Title,
      4 => t.chapter4Title,
      _ => t.chapterOtherTitle,
    };

String dialogueText(DialogueId id, AppLocalizations t) => switch (id) {
  DialogueId.intro => t.dialogueIntro,
  DialogueId.levelWin => t.dialogueWin,
  DialogueId.levelLose => t.dialogueLose,
  DialogueId.levelLoseShort => t.dialogueLoseShort,
  DialogueId.finalVictory => t.dialogueFinalVictory,
};
