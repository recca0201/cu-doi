---
name: aidlc-translator
description: Real-time translation monitoring for AIDLC sessions between Japanese and Vietnamese teams. Monitors Claude Code conversations, detects important information (requirements, decisions, action items), translates bidirectionally (JP↔VN, EN→JP, EN→VN), and maintains persistent bilingual log files. Use when (1) conducting AIDLC Inception sessions with JP-VN teams, (2) user explicitly requests translation monitoring, (3) Japanese materials need Vietnamese translation in real-time, (4) team collaboration requires bilingual record, or (5) requirements gathering with JP Product Owner needs translation support. Creates searchable Markdown translation logs that both JP and VN team members can reference during and after meetings.
---

# AIDLC Translator

Real-time translation monitoring for AIDLC sessions between Japanese and Vietnamese teams.

## Quick Start

### Initialize Log

```bash
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --init \
  --context "Project Name - AIDLC Inception" \
  --log-file tmp/log/aidlc-translation-log.md
```

### Add Translation

```bash
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --original "要件を確認してください" \
  --translation "Vui lòng xác nhận yêu cầu" \
  --direction "JP→VN"
```

### Monitor Real-time

```bash
tail -f tmp/log/aidlc-translation-log.md
```

## Core Features

- **Background Monitoring**: Non-intrusive conversation monitoring
- **Smart Translation**: JP↔VN, EN→JP, EN→VN with context preservation
- **Persistent Logging**: Searchable Markdown files with timestamps
- **AIDLC Integration**: Preserves methodology terms (User Story, Unit, Bolt, etc.)

## Detection Rules

### Translate These
✅ Requirements, specifications, business rules
✅ Decisions, agreements, action items
✅ Questions, clarifications, technical discussions
✅ User stories, acceptance criteria, risks

### Skip These
❌ Code snippets, file paths, timestamps
❌ Simple acknowledgments ("ok", "thanks")
❌ Tool invocation, system messages

## Log Format

```markdown
# AIDLC Session Translation Log
Session Started: YYYY-MM-DD HH:MM:SS
Session Context: [Brief description]

## Translations

[YYYY-MM-DD HH:MM:SS] [JP→VN]
Original: 要件を確認してください
Translation: Vui lòng xác nhận yêu cầu
---
```

**Direction codes**: JP→VN, VN→JP, EN→JP, EN→VN

## Bundled Resources

### Script

**scripts/append_translation.py** - Translation logging script

Initialize log:
```bash
python3 scripts/append_translation.py --init --context "Session description"
```

Add translation:
```bash
python3 scripts/append_translation.py \
  --original "text" \
  --translation "translated text" \
  --direction "JP→VN"
```

Options:
- `--log-file`: Custom log location (default: `tmp/log/aidlc-translation-log.md`)
- `--context`: Session description (used with `--init`)

### References

Load these for detailed information:

**[usage-guide.md](references/usage-guide.md)** - Detailed usage examples, workflows, common use cases, best practices

**[configuration.md](references/configuration.md)** - Configuration options, customization, detection rules, file organization

**[troubleshooting.md](references/troubleshooting.md)** - Common issues, limitations, comparisons, future enhancements

## Integration with AIDLC Workflow

### Basic Flow

1. **Pre-session**: Initialize log with project context
2. **During session**: Translate important information as detected
3. **Team monitoring**: Use `tail -f` to follow translations
4. **Post-session**: Review and archive log file

### Example Session

```bash
# Start session
LOG="tmp/log/project-alpha-$(date +%Y-%m-%d).md"
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --init --context "Project Alpha Inception" --log-file "$LOG"

# Team monitors
tail -f "$LOG" &

# During session - translations added automatically or manually

# After session
cat "$LOG"
```

## With AI Translator Agent

This skill works with the `ai-translator` agent (`.claude/agents/ai-translator.md`) for automatic translation monitoring.

Usage:
```bash
claude "Enable ai-translator for this AIDLC session"
```

The agent will:
- Monitor conversation in background
- Detect important information automatically
- Translate and log bilingually
- Preserve AIDLC terminology

## Common Patterns

### JP Product Owner → VN Team

```bash
# PO explains requirements in Japanese
# → Detected and translated to Vietnamese
# → VN team reads in log file
```

### VN Team → JP Product Owner

```bash
# VN engineer asks question in Vietnamese
# → Translated to Japanese
# → JP PO reads translation
# → Response translated back
```

### Bilingual Documentation

```bash
# Generated artifacts translated to both languages
# → Both teams reference same documentation
# → Single source of truth
```

## Quick Reference

```bash
# Initialize
python3 scripts/append_translation.py --init --context "Description"

# Add JP→VN
python3 scripts/append_translation.py --original "日本語" --translation "Tiếng Việt" --direction "JP→VN"

# Add VN→JP
python3 scripts/append_translation.py --original "Tiếng Việt" --translation "日本語" --direction "VN→JP"

# Monitor
tail -f tmp/log/aidlc-translation-log.md

# Review
cat tmp/log/aidlc-translation-log.md
```

## Detailed Documentation

- **Detailed usage patterns**: See [references/usage-guide.md](references/usage-guide.md)
- **Configuration options**: See [references/configuration.md](references/configuration.md)
- **Troubleshooting**: See [references/troubleshooting.md](references/troubleshooting.md)
- **AI Translator agent**: See `.claude/agents/ai-translator.md`
