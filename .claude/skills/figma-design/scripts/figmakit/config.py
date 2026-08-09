"""Token, file-key, .env, and Figma URL resolution (standalone; imports SKILL_DIR)."""

import os
import sys
import urllib.parse
from pathlib import Path
from typing import Optional

from figmakit import SKILL_DIR


def load_dotenv(path: Path) -> dict:
    """Parse a .env file into a dict. Ignores comments and blank lines."""
    env = {}
    try:
        for line in path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            env[key.strip()] = val.strip().strip('"').strip("'")
    except FileNotFoundError:
        pass
    return env


def resolve_token() -> str:
    """
    Return PAT from env var → .env file, in that order.
    Token is never accepted as a CLI arg to prevent exposure in logs/shell history.
    Run setup_token.py once to save securely.
    """
    if os.environ.get("FIGMA_TOKEN"):
        return os.environ["FIGMA_TOKEN"]

    for env_path in [SKILL_DIR / ".env", Path.cwd() / ".env"]:
        env = load_dotenv(env_path)
        if env.get("FIGMA_TOKEN"):
            return env["FIGMA_TOKEN"]

    print(
        "Error: No Figma token found.\n"
        "  Option 1 (recommended): run setup once →\n"
        f"    python3 {SKILL_DIR / 'scripts/setup_token.py'}\n"
        "  Option 2: export FIGMA_TOKEN=your_token  (current shell session only)\n"
        f"  Option 3: manually add FIGMA_TOKEN=... to {SKILL_DIR / '.env'}",
        file=sys.stderr,
    )
    sys.exit(1)


def parse_figma_url(url: str) -> tuple[str, Optional[str]]:
    """
    Parse a Figma URL and return (file_key, node_id).
    node_id is None if not present. node_id is returned with ':' separator (API format).

    Handles both URL formats:
      figma.com/design/FILE_KEY/name?node-id=4812-38472
      figma.com/file/FILE_KEY/name?node-id=4812-38472
    """
    parsed = urllib.parse.urlparse(url)
    parts = [p for p in parsed.path.split("/") if p]

    # Path is like: ['design', 'FILE_KEY', 'name'] or ['file', 'FILE_KEY', 'name']
    try:
        type_idx = next(i for i, p in enumerate(parts) if p in ("design", "file", "proto"))
        file_key = parts[type_idx + 1]
    except (StopIteration, IndexError):
        print(f"Error: Could not parse file key from URL: {url}", file=sys.stderr)
        sys.exit(1)

    params = urllib.parse.parse_qs(parsed.query)
    node_id = None
    if "node-id" in params:
        # Convert URL format "4812-38472" → API format "4812:38472"
        node_id = params["node-id"][0].replace("-", ":")

    return file_key, node_id


def resolve_file_key(cli_key: Optional[str]) -> str:
    """Return file key from CLI arg → env var → .env file."""
    if cli_key:
        return cli_key

    if os.environ.get("FIGMA_FILE_KEY"):
        return os.environ["FIGMA_FILE_KEY"]

    for env_path in [SKILL_DIR / ".env", Path.cwd() / ".env"]:
        env = load_dotenv(env_path)
        if env.get("FIGMA_FILE_KEY"):
            return env["FIGMA_FILE_KEY"]

    print("Error: No file key provided. Pass --file FILE_KEY, --url FIGMA_URL, or set FIGMA_FILE_KEY in .env", file=sys.stderr)
    sys.exit(1)
