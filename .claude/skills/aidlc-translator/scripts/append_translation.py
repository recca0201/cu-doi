#!/usr/bin/env python3
"""
Append translation entries to AIDLC translation log file
"""

import os
import argparse
from datetime import datetime


def append_translation(original, translation, direction, log_file='tmp/log/aidlc-translation-log.md'):
    """
    Append a translation entry to the log file

    Args:
        original: Original text
        translation: Translated text
        direction: JP→VN, VN→JP, EN→JP, EN→VN
        log_file: Path to log file
    """
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    entry = f"""
[{timestamp}] [{direction}]
Original: {original}
Translation: {translation}
---
"""

    # Create file if doesn't exist
    if not os.path.exists(log_file):
        init_log(log_file)

    # Append translation
    with open(log_file, 'a', encoding='utf-8') as f:
        f.write(entry)

    print(f"✓ Translation logged to {log_file}")
    return True


def init_log(log_file, context=""):
    """Initialize a new translation log file"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    content = f"""# AIDLC Session Translation Log
Session Started: {timestamp}
Session Context: {context}

## Translations

"""

    # Create directory if doesn't exist
    log_dir = os.path.dirname(log_file)
    if log_dir and not os.path.exists(log_dir):
        os.makedirs(log_dir)

    with open(log_file, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"✓ Translation log initialized: {log_file}")


def main():
    parser = argparse.ArgumentParser(
        description='Append translation to AIDLC translation log'
    )
    parser.add_argument('--original', help='Original text')
    parser.add_argument('--translation', help='Translated text')
    parser.add_argument('--direction',
                       choices=['JP→VN', 'VN→JP', 'EN→JP', 'EN→VN'],
                       help='Translation direction')
    parser.add_argument('--log-file', default='tmp/log/aidlc-translation-log.md',
                       help='Path to log file (default: tmp/log/aidlc-translation-log.md)')
    parser.add_argument('--init', action='store_true',
                       help='Initialize a new log file')
    parser.add_argument('--context', default='',
                       help='Session context (used with --init)')

    args = parser.parse_args()

    if args.init:
        init_log(args.log_file, args.context)
    else:
        # Validate required arguments for translation
        if not args.original or not args.translation or not args.direction:
            parser.error('--original, --translation, and --direction are required when not using --init')
        append_translation(args.original, args.translation, args.direction, args.log_file)


if __name__ == '__main__':
    main()
