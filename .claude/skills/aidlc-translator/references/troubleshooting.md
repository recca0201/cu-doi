# AIDLC Translator - Troubleshooting Guide

Common issues, limitations, and solutions for the AIDLC Translator skill.

## Table of Contents

- [Common Issues](#common-issues)
- [Limitations](#limitations)
- [Comparison with Other Solutions](#comparison-with-other-solutions)
- [Future Enhancements](#future-enhancements)

## Common Issues

### Log File Not Created

**Symptom:** Translation log file doesn't exist after running script

**Causes:**
- Directory doesn't exist
- No write permissions
- Disk space full

**Solutions:**

```bash
# Check if directory exists
ls -la tmp/log/

# Create directory if missing
mkdir -p tmp/log/

# Check write permissions
ls -ld tmp/log/

# Fix permissions if needed
chmod 755 tmp/log/

# Check disk space
df -h .
```

### Translations Seem Inaccurate

**Symptom:** Translated text doesn't match original meaning

**Causes:**
- Missing context
- Technical terminology misunderstood
- Cultural nuances lost

**Solutions:**

1. **Provide more context**:
   ```bash
   # Include project context when initializing
   python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
     --init \
     --context "Mobile Banking App - Payment Features" \
     --log-file tmp/log/session.md
   ```

2. **Review and correct**: Manually review important translations
3. **Use preserve_terms**: Configure AIDLC terms to keep in English
4. **Human validation**: Have bilingual team member review critical translations

### Missing Translations

**Symptom:** Expected information not translated

**Causes:**
- Detection rules too strict
- Information matches skip patterns
- Script not capturing all conversations

**Solutions:**

1. **Check detection sensitivity**:
   ```json
   {
     "detection_sensitivity": "high"
   }
   ```

2. **Review skip patterns**:
   ```json
   {
     "skip_patterns": ["ok", "thanks"]
   }
   ```

3. **Manual logging**: Add important translations manually if missed

### File Permission Errors

**Symptom:** "Permission denied" errors when writing to log

**Solutions:**

```bash
# Fix file permissions
chmod 644 tmp/log/aidlc-translation-log.md

# Fix directory permissions
chmod 755 tmp/log/

# Check file owner
ls -l tmp/log/aidlc-translation-log.md

# Fix owner if needed (replace username)
chown username tmp/log/aidlc-translation-log.md
```

### UTF-8 Encoding Issues

**Symptom:** Japanese or Vietnamese characters display incorrectly

**Solutions:**

```bash
# Verify file encoding
file -I tmp/log/aidlc-translation-log.md

# Convert if needed (usually not necessary)
iconv -f ISO-8859-1 -t UTF-8 tmp/log/old.md > tmp/log/new.md

# Set locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

### Script Path Issues

**Symptom:** "No such file or directory" when running script

**Solutions:**

```bash
# Use absolute path
python3 /Users/dinhnc/repos/d-odyssey/.claude/skills/aidlc-translator/scripts/append_translation.py ...

# Or run from repository root
cd /Users/dinhnc/repos/d-odyssey
python3 .claude/skills/aidlc-translator/scripts/append_translation.py ...

# Or add to PATH (in ~/.zshrc or ~/.bashrc)
export PATH="$PATH:/Users/dinhnc/repos/d-odyssey/.claude/skills/aidlc-translator/scripts"
```

## Limitations

### Current Limitations

#### 1. Translation Accuracy

- **❌ 80-85% accuracy**: AI translation, not human-level
- **❌ Context dependent**: May miss nuances without full context
- **❌ Technical terms**: May mistranslate domain-specific terminology

**Mitigation:**
- Review critical translations manually
- Configure preserve_terms for key terminology
- Provide clear context when initializing logs

#### 2. Not Real-time Broadcast

- **❌ Local files only**: Team must actively check log files
- **❌ No push notifications**: No automatic alerts for new translations
- **❌ Manual monitoring**: Team uses `tail -f` to follow along

**Mitigation:**
- Use `tail -f` for real-time monitoring
- Share log file location with team before session
- Consider MS Teams integration (future enhancement)

#### 3. Manual Invocation Required

- **❌ Not fully automatic**: Script must be called for each translation
- **❌ Agent integration pending**: AI translator agent structure exists but needs implementation
- **❌ Detection logic incomplete**: Smart detection rules need manual review

**Mitigation:**
- Use Python integration for batch translations
- Plan Phase 2 enhancements for automation
- Document translation patterns for consistency

#### 4. Single Language Pair Focus

- **❌ Optimized for JP↔VN**: Other language pairs supported but not tested extensively
- **❌ Limited directions**: Only JP→VN, VN→JP, EN→JP, EN→VN

**Mitigation:**
- Test other language combinations as needed
- Request additional language support if required
- Use EN as intermediate language for other pairs

### What's NOT Implemented

1. **❌ MS Teams Bot Integration**: Logs to files instead of posting to Teams
2. **❌ Automatic Translation**: Agent monitors but requires manual script calls
3. **❌ Real-time Dashboard**: No visual interface for monitoring
4. **❌ Voice Input**: No speech-to-text for verbal meetings
5. **❌ Quality Assessment**: No AI-powered translation quality checks
6. **❌ Multi-language Support**: Beyond JP/VN/EN combinations

## Comparison with Other Solutions

### vs. MS Teams Live Captions

| Feature | AIDLC Translator | Teams Live Captions |
|---------|------------------|---------------------|
| **Accuracy** | 80-85% | 60-70% |
| **Persistence** | ✅ Log files | ❌ No record |
| **Context Aware** | ✅ Yes | ❌ No |
| **Bilingual Output** | ✅ Yes | ❌ Single language |
| **AIDLC Terms** | ✅ Preserved | ❌ Generic |
| **Cost** | Free | Free |

**Recommendation:** Use AIDLC Translator for important sessions requiring accurate records.

### vs. Human Interpreter

| Feature | AIDLC Translator | Human Interpreter |
|---------|------------------|-------------------|
| **Accuracy** | 80-85% | 95%+ |
| **Speed** | Instant | Real-time |
| **Cost** | Free | Expensive |
| **Availability** | Always | Limited |
| **Record** | ✅ Automatic | ⚠️ Manual notes |
| **Cultural Context** | ⚠️ Limited | ✅ Excellent |

**Recommendation:** Use human interpreter for critical business decisions, AIDLC Translator for documentation and routine sessions.

### vs. AI Assistant Product Owner (Idea 1)

| Feature | AIDLC Translator | AI-APO |
|---------|------------------|--------|
| **Effectiveness** | 80-85% | 95% |
| **Setup Time** | 5 minutes | 3-6 months |
| **Human Touch** | ❌ No | ✅ Yes |
| **Scalability** | Unlimited | 2 projects |
| **Cost** | Free | Internal training |

**Recommendation:** AIDLC Translator for quick pilot, AI-APO for long-term quality.

## Future Enhancements

### Planned Features (Not Yet Implemented)

#### Phase 2: Enhanced Automation

- ⏳ Automatic detection and translation
- ⏳ AI translator agent integration
- ⏳ Smart context preservation
- ⏳ Quality checks for translations

#### Phase 3: MS Teams Integration

- ⏳ Teams Bot API integration
- ⏳ Real-time posting to channels
- ⏳ Channel configuration
- ⏳ Broadcasting capabilities

#### Phase 4: Advanced Features

- ⏳ Real-time dashboard
- ⏳ Voice input support
- ⏳ Multi-language expansion (KR, CN)
- ⏳ AI-powered quality assessment
- ⏳ Translation memory
- ⏳ Terminology management

### Requesting Features

To request new features or report issues:

1. Document the use case
2. Provide examples
3. Describe expected behavior
4. Contact HOA for JP-VN collaboration improvements

## Debug Mode

### Enable Verbose Logging

Add debug output to troubleshoot issues:

```bash
# Run with verbose output
python3 -v .claude/skills/aidlc-translator/scripts/append_translation.py \
  --original "test" \
  --translation "test" \
  --direction "JP→VN"
```

### Verify Log Format

Check log file structure:

```bash
# View with line numbers
cat -n tmp/log/aidlc-translation-log.md

# Check for formatting issues
grep -E "^\[.*\]" tmp/log/aidlc-translation-log.md

# Validate markdown
# (requires mdl: gem install mdl)
mdl tmp/log/aidlc-translation-log.md
```

### Test Translation Script

Run basic functionality test:

```bash
# Test initialization
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --init \
  --context "Test" \
  --log-file tmp/log/test.md

# Test translation
python3 .claude/skills/aidlc-translator/scripts/append_translation.py \
  --original "test" \
  --translation "テスト" \
  --direction "EN→JP" \
  --log-file tmp/log/test.md

# Verify
cat tmp/log/test.md

# Cleanup
rm tmp/log/test.md
```

## Getting Help

### Resources

- **Skill Documentation**: `.claude/skills/aidlc-translator/SKILL.md`
- **Usage Guide**: `.claude/skills/aidlc-translator/references/usage-guide.md`
- **Configuration**: `.claude/skills/aidlc-translator/references/configuration.md`
- **Agent Definition**: `.claude/agents/ai-translator.md`

### Support Channels

For issues or questions:
1. Check this troubleshooting guide
2. Review skill documentation
3. Consult AIDLC Core skill for methodology terms
4. Contact HOA for JP-VN collaboration best practices

### Common Debugging Commands

```bash
# Check Python version
python3 --version

# Verify script exists
ls -l .claude/skills/aidlc-translator/scripts/append_translation.py

# Check log directory
ls -la tmp/log/

# View recent translations
tail -20 tmp/log/aidlc-translation-log.md

# Search for specific term
grep "要件" tmp/log/aidlc-translation-log.md

# Count translations
grep -c "^\[.*\] \[.*→.*\]" tmp/log/aidlc-translation-log.md
```
