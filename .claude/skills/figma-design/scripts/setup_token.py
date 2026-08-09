#!/usr/bin/env python3
"""
One-time setup: saves your Figma PAT to a gitignored .env file using masked input.
The token is not visible in the terminal, shell history, or conversation, but the
.env file stores it as plaintext on disk.

Usage:
  python3 .claude/skills/figma-design/scripts/setup_token.py
"""

import getpass
import os
import sys
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent
ENV_FILE = SKILL_DIR / ".env"
ENV_EXAMPLE = SKILL_DIR / ".env.example"


def read_env(path: Path) -> dict:
    env = {}
    if not path.exists():
        return env
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        env[key.strip()] = val.strip().strip('"').strip("'")
    return env


def write_env(path: Path, env: dict) -> None:
    lines = []
    for key, val in env.items():
        lines.append(f"{key}={val}")
    data = "\n".join(lines) + "\n"
    flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
    fd = os.open(path, flags, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(data)
    path.chmod(0o600)


def main():
    print("Figma Design Skill — Token Setup")
    print("─" * 40)
    print("Your token will be saved to:")
    print(f"  {ENV_FILE}")
    print("It is gitignored and not shown in the terminal, but it is stored as plaintext on disk.\n")

    # Load existing .env or seed from .env.example
    if ENV_FILE.exists():
        env = read_env(ENV_FILE)
        existing = env.get("FIGMA_TOKEN", "")
        if existing and not existing.startswith("figd_your"):
            masked = existing[:8] + "..." + existing[-4:]
            print(f"Current token: {masked}")
            overwrite = input("Overwrite? [y/N] ").strip().lower()
            if overwrite != "y":
                print("Keeping existing token.")
                _prompt_file_key(env)
                write_env(ENV_FILE, env)
                return
    else:
        env = read_env(ENV_EXAMPLE) if ENV_EXAMPLE.exists() else {}

    # Masked token input — getpass hides input on all platforms
    print("Get your PAT from: Figma → Account Settings → Security → Personal Access Tokens")
    print("Recommended scopes: file_content:read (add file_variables:read for Figma Variables).")
    print("The legacy 'file:read' scope still works but is no longer recommended by Figma.")
    print("Use a Dev or Full seat — a View/Collab seat allows only ~6 requests/month.")
    print("Note: Figma personal access tokens now expire after 90 days; re-run this to rotate.\n")
    token = getpass.getpass("Figma Personal Access Token: ").strip()

    if not token:
        print("Error: no token entered.", file=sys.stderr)
        sys.exit(1)

    if not token.startswith("figd_"):
        print("Warning: token doesn't start with 'figd_' — double-check it's a Figma PAT.")

    env["FIGMA_TOKEN"] = token

    _prompt_file_key(env)
    write_env(ENV_FILE, env)

    print(f"\n✓ Saved to {ENV_FILE}")
    print("You can now run figma_client.py without passing --token.")


def _prompt_file_key(env: dict) -> None:
    existing_key = env.get("FIGMA_FILE_KEY", "")
    if existing_key:
        print(f"\nCurrent default file key: {existing_key}")
        change = input("Change it? [y/N] ").strip().lower()
        if change != "y":
            return

    print("\nOptional: set a default Figma file key so you don't need --file every time.")
    print("Extract from URL: figma.com/design/<FILE_KEY>/...")
    file_key = input("Default file key (press Enter to skip): ").strip()
    if file_key:
        env["FIGMA_FILE_KEY"] = file_key
    else:
        env["FIGMA_FILE_KEY"] = ""


if __name__ == "__main__":
    main()
