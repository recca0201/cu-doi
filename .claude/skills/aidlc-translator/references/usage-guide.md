# AIDLC Translator - Usage Guide

Detailed usage examples and patterns for the AIDLC Translator skill.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Workflow Integration](#workflow-integration)
- [Common Use Cases](#common-use-cases)
- [Best Practices](#best-practices)

## Basic Usage

### Initialize Translation Log

```bash
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --init \
  --context "AIDLC Inception - Project Name" \
  --log-file tmp/log/aidlc-translation-log.md
```

### Append Translation Entries

```bash
# Japanese to Vietnamese
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --original "要件を確認してください" \
  --translation "Vui lòng xác nhận yêu cầu" \
  --direction "JP→VN"

# Vietnamese to Japanese
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --original "Tôi đã hiểu yêu cầu" \
  --translation "要件を理解しました" \
  --direction "VN→JP"

# English to Vietnamese
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --original "Please confirm the requirements" \
  --translation "Vui lòng xác nhận yêu cầu" \
  --direction "EN→VN"
```

### Real-time Monitoring

```bash
# Team members can monitor translations in real-time
tail -f tmp/log/aidlc-translation-log.md
```

## Workflow Integration

### AIDLC Inception Phase Integration

```bash
# 1. Start AIDLC Inception session
claude "Start AIDLC Inception for [project name]"

# 2. Enable translation monitoring
claude "Enable translation monitoring"

# 3. Load Japanese materials
claude "Analyze this Japanese PRD: [file path]"

# 4. Session continues with automatic translation
# - Requirements discussions translated
# - User stories translated
# - Decisions logged bilingually

# 5. Review translation log after session
cat tmp/log/aidlc-translation-log.md
```

### Python Integration

```python
from datetime import datetime
import subprocess

# Initialize log file
log_file = f"tmp/log/aidlc-translation-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"

# Start monitoring with custom log
subprocess.run([
    'python3',
    '.claude/skills/aidlc-translator/scripts/append_translation.py',
    '--init',
    '--context', 'AIDLC Inception Session',
    '--log-file', log_file
])

# Add translation during session
subprocess.run([
    'python3',
    '.claude/skills/aidlc-translator/scripts/append_translation.py',
    '--original', 'システム要件',
    '--translation', 'Yêu cầu hệ thống',
    '--direction', 'JP→VN',
    '--log-file', log_file
])

# Read translations later
with open(log_file, 'r') as f:
    translations = f.read()
    print(translations)
```

## Common Use Cases

### Use Case 1: JP Product Owner Explains Requirements

**Scenario:** Japanese Product Owner explains feature requirements in Japanese

**Flow:**
1. PO presents requirements in Japanese
2. AI Translator detects requirements
3. Translates to Vietnamese in real-time
4. Logs translation with timestamp
5. VN team reads Vietnamese in log file

**Benefits:** VN team follows discussion without interrupting

### Use Case 2: VN Team Asks Clarifying Questions

**Scenario:** Vietnamese engineers ask technical questions

**Flow:**
1. VN engineer asks question in Vietnamese
2. AI Translator translates to Japanese
3. JP PO reads Japanese translation
4. PO responds in Japanese
5. Response translated back to Vietnamese

**Benefits:** Both sides understand discussion fully

### Use Case 3: Creating Bilingual Documentation

**Scenario:** AIDLC artifacts need both JP and VN versions

**Flow:**
1. Generate user stories in English
2. Translate to both JP and VN
3. Log all versions
4. Both teams reference same documentation

**Benefits:** Single source of truth in multiple languages

### Use Case 4: Meeting Minutes

**Scenario:** Need bilingual record of inception meeting

**Flow:**
1. Meeting discussion translated in real-time
2. Important decisions logged bilingually
3. Action items recorded in both languages
4. Log file serves as meeting minutes

**Benefits:** Clear record of what was decided

## Best Practices

### For Translation Quality

1. **Maintain Context**: Always consider full conversation history
2. **Preserve Terms**: Keep AIDLC methodology terms in English
3. **Cultural Nuance**: Translate meaning, not just words
4. **Technical Accuracy**: Verify technical terminology

### For Log Management

1. **Session-Based Files**: One log file per AIDLC session
2. **Clear Naming**: Use date/time in filename (e.g., `aidlc-translation-2026-03-12-14-30.md`)
3. **Regular Review**: Check log during session for accuracy
4. **Archive After Session**: Move completed logs to project folder

### For Team Collaboration

1. **Share Log Location**: Tell team where translations are logged
2. **Real-time Access**: Team can `tail -f` the log file to follow along
3. **Post-Session Review**: Use log for meeting minutes and documentation
4. **Archive Management**: Keep logs organized by project/sprint

### Workflow Example

**Complete session workflow:**

```bash
# Pre-session setup
LOG_FILE="tmp/log/project-alpha-inception-2026-03-12.md"
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --init \
  --context "Project Alpha - AIDLC Inception" \
  --log-file "$LOG_FILE"

# During session - team monitors
tail -f "$LOG_FILE" &

# Session continues with automatic translation...

# Post-session review
cat "$LOG_FILE"

# Archive
mkdir -p projects/project-alpha/inception/translations/
mv "$LOG_FILE" projects/project-alpha/inception/translations/
```

## Advanced Patterns

### Multi-session Tracking

For projects spanning multiple sessions:

```bash
# Create session-specific logs
SESSION_DATE=$(date +%Y-%m-%d)
LOG_DIR="tmp/log/project-alpha/"
mkdir -p "$LOG_DIR"

python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --init \
  --context "Project Alpha - Session $SESSION_DATE" \
  --log-file "$LOG_DIR/session-$SESSION_DATE.md"
```

### Translation Quality Checks

Review translations periodically:

```bash
# Extract all translations for review
grep -A 2 "^\[.*\] \[.*→.*\]" tmp/log/aidlc-translation-log.md > translations-review.txt
```

### Custom Direction Codes

While the standard directions are JP→VN, VN→JP, EN→JP, EN→VN, you can track context in the Session Context field:

```bash
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --init \
  --context "Multi-lingual session: JP/VN/EN stakeholders" \
  --log-file tmp/log/multilingual-session.md
```
