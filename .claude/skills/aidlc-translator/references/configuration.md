# AIDLC Translator - Configuration Guide

Configuration options and customization for the AIDLC Translator skill.

## Default Settings

**Log file location**: `tmp/log/aidlc-translation-log.md`
**Translation directions**: JP↔VN, EN→JP, EN→VN
**Format**: Markdown with timestamps
**Detection sensitivity**: High (captures most important info)

## Custom Configuration

Create `~/.aidlc-translator-config.json` to customize behavior:

```json
{
  "log_directory": "tmp/log",
  "default_direction": "JP→VN",
  "include_metadata": true,
  "detection_sensitivity": "high",
  "skip_patterns": ["ok", "thanks", "done"],
  "preserve_terms": ["User Story", "Unit", "Bolt", "Inception"]
}
```

### Configuration Options

#### `log_directory`
- **Type**: String
- **Default**: `"tmp/log"`
- **Description**: Directory where translation logs are stored
- **Example**: `"projects/translations"` or `"/Users/dinhnc/aidlc-translations"`

#### `default_direction`
- **Type**: String
- **Default**: `"JP→VN"`
- **Options**: `"JP→VN"`, `"VN→JP"`, `"EN→JP"`, `"EN→VN"`
- **Description**: Default translation direction when not specified

#### `include_metadata`
- **Type**: Boolean
- **Default**: `true`
- **Description**: Include session metadata (start time, context) in log files

#### `detection_sensitivity`
- **Type**: String
- **Default**: `"high"`
- **Options**: `"low"`, `"medium"`, `"high"`
- **Description**: How aggressively to detect important information
  - **Low**: Only explicit requirements and decisions
  - **Medium**: Requirements, decisions, and key discussions
  - **High**: All important business information

#### `skip_patterns`
- **Type**: Array of strings
- **Default**: `["ok", "thanks", "done"]`
- **Description**: Phrases to skip when detecting important information
- **Example**: `["ok", "thanks", "done", "roger", "understood"]`

#### `preserve_terms`
- **Type**: Array of strings
- **Default**: `["User Story", "Unit", "Bolt", "Inception"]`
- **Description**: AIDLC methodology terms to preserve in English
- **Example**: Add project-specific terms like `["Sprint", "Backlog", "Epic"]`

## Detection Rules Configuration

### What Gets Translated (High Sensitivity)

By default, these are detected and translated:

- ✅ Requirements and specifications
- ✅ Business rules and constraints
- ✅ Decisions and agreements
- ✅ Action items and next steps
- ✅ Questions and clarifications
- ✅ Technical discussions with business impact
- ✅ User stories and acceptance criteria
- ✅ Risk and assumption statements

### What Gets Skipped

By default, these are NOT translated:

- ❌ Code snippets and syntax
- ❌ File paths and commands
- ❌ Timestamps and metadata
- ❌ Simple acknowledgments (configurable via `skip_patterns`)
- ❌ Tool invocation details
- ❌ System messages

### Customizing Detection

To adjust what gets translated, modify `detection_sensitivity`:

```json
{
  "detection_sensitivity": "medium",
  "skip_patterns": ["ok", "thanks", "done", "understood", "roger", "ack"]
}
```

## Translation Format Configuration

### Log File Structure

Standard format (cannot be customized):

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

### Direction Codes

Supported directions:

- `JP→VN`: Japanese to Vietnamese
- `VN→JP`: Vietnamese to Japanese
- `EN→JP`: English to Japanese
- `EN→VN`: English to Vietnamese

## File Organization

### Recommended Structure

For multi-project usage:

```
tmp/log/
├── project-alpha/
│   ├── inception/
│   │   ├── session-2026-03-12.md
│   │   └── session-2026-03-15.md
│   └── refinement/
│       └── session-2026-03-20.md
└── project-beta/
    └── inception/
        └── session-2026-03-18.md
```

Create this structure manually or via script:

```bash
# Create project-specific log directory
PROJECT="project-alpha"
PHASE="inception"
mkdir -p "tmp/log/$PROJECT/$PHASE"

# Use in script
LOG_FILE="tmp/log/$PROJECT/$PHASE/session-$(date +%Y-%m-%d).md"
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --init \
  --context "$PROJECT - $PHASE" \
  --log-file "$LOG_FILE"
```

## Environment Variables

Set environment variables to override defaults:

```bash
# Set default log directory
export AIDLC_TRANSLATOR_LOG_DIR="tmp/log"

# Set default translation direction
export AIDLC_TRANSLATOR_DEFAULT_DIRECTION="JP→VN"

# Example usage
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --original "Hello" \
  --translation "こんにちは" \
  --direction "EN→JP"
```

## Performance Tuning

### For Large Sessions

When sessions generate many translations:

1. **Use session-specific files**: Don't append to same file indefinitely
2. **Archive regularly**: Move old logs to archive directory
3. **Monitor file size**: Split logs if they exceed 1000 lines

```bash
# Check log file size
wc -l tmp/log/aidlc-translation-log.md

# Split if needed
tail -500 tmp/log/aidlc-translation-log.md > tmp/log/aidlc-translation-log-part2.md
```

### For Real-time Monitoring

When team members use `tail -f`:

```bash
# Optimize for real-time viewing
tail -f -n 50 tmp/log/aidlc-translation-log.md
```

## Integration with AIDLC Tools

### With AI Translator Agent

The ai-translator agent automatically uses these settings:

```bash
# Agent reads config from ~/.aidlc-translator-config.json
claude "Enable ai-translator for this AIDLC session"
```

### With AIDLC Core Skill

Translation logs can reference AIDLC artifacts:

```json
{
  "preserve_terms": [
    "User Story",
    "Unit",
    "Bolt",
    "Inception",
    "Construction",
    "Foundation",
    "Epic"
  ]
}
```

## Security Considerations

### Log File Permissions

Translation logs may contain sensitive information:

```bash
# Set restrictive permissions
chmod 600 tmp/log/aidlc-translation-log.md

# Verify
ls -la tmp/log/
```

### Gitignore Configuration

Already configured in repository `.gitignore`:

```
tmp/log/
!tmp/log/.gitkeep
```

Logs are excluded from version control by default.

### Archiving Sensitive Logs

For completed projects with sensitive data:

```bash
# Archive and encrypt
tar -czf project-alpha-translations.tar.gz tmp/log/project-alpha/
openssl enc -aes-256-cbc -salt -in project-alpha-translations.tar.gz \
  -out project-alpha-translations.tar.gz.enc

# Delete original
rm -rf tmp/log/project-alpha/
rm project-alpha-translations.tar.gz
```
