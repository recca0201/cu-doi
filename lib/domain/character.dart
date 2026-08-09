enum DialogueId { intro, levelWin, levelLose, levelLoseShort, finalVictory }

class DialogueSpec {
  const DialogueSpec(this.id, {required this.onceOnly});

  final DialogueId id;
  final bool onceOnly;
}

const List<DialogueSpec> kDialogues = <DialogueSpec>[
  DialogueSpec(DialogueId.intro, onceOnly: true),
  DialogueSpec(DialogueId.levelWin, onceOnly: false),
  DialogueSpec(DialogueId.levelLose, onceOnly: false),
  DialogueSpec(DialogueId.levelLoseShort, onceOnly: false),
  DialogueSpec(DialogueId.finalVictory, onceOnly: true),
];

DialogueSpec dialogueSpec(DialogueId id) =>
    kDialogues.firstWhere((DialogueSpec spec) => spec.id == id);
