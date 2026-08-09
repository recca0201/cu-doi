#!/usr/bin/env python3
"""
Azure DevOps Utilities Module

Shared utility functions for Azure DevOps operations.
"""

import html
import os
import re
from pathlib import Path
from typing import Optional
from urllib.parse import urlparse


def wiql_escape(value: str) -> str:
    """
    Escape a string for safe interpolation into a WIQL string literal.

    WIQL string literals are single-quoted; a literal single quote is escaped by
    doubling it. This both prevents WIQL injection and fixes real-world breakage
    on legitimate values that contain apostrophes (e.g. an iteration path like
    "O'Brien Team\\Sprint 1").

    Args:
        value: Raw value to place inside single quotes in a WIQL query

    Returns:
        The value with single quotes doubled. Always pass the result *between*
        quotes you write yourself, e.g. f"... = '{wiql_escape(path)}'".
    """
    return str(value).replace("'", "''")


def html_to_markdown(text: Optional[str]) -> str:
    """
    Convert the simple HTML that Azure DevOps stores in rich-text fields
    (Description, Acceptance Criteria, etc.) into readable Markdown.

    ADO returns rich-text fields as HTML fragments. Dumping that HTML straight
    into a Markdown file leaves `<div>`, `<ul><li>`, `&nbsp;`, and inline styles
    in the output, which renders poorly and is hard for downstream tools to
    parse. This does a dependency-free best-effort conversion of the common
    tags; it is intentionally lightweight, not a full HTML parser.

    Args:
        text: Raw field value (may be None or already plain text)

    Returns:
        Markdown-ish plain text. Returns "" for falsy input.
    """
    if not text:
        return ""
    if not isinstance(text, str):
        text = str(text)

    s = text

    # Normalize line breaks and block boundaries to newlines.
    s = re.sub(r"<\s*br\s*/?\s*>", "\n", s, flags=re.IGNORECASE)
    s = re.sub(r"</\s*(p|div|tr|h[1-6])\s*>", "\n", s, flags=re.IGNORECASE)
    s = re.sub(r"<\s*(p|div|h[1-6])[^>]*>", "\n", s, flags=re.IGNORECASE)

    # Images -> ![alt](src). Done before generic tag stripping so the src is
    # preserved (these may point at locally downloaded attachment files).
    s = re.sub(
        r"<\s*img\b[^>]*?\bsrc\s*=\s*[\"']([^\"']+)[\"'][^>]*>",
        lambda m: f"![]({m.group(1)})",
        s,
        flags=re.IGNORECASE,
    )

    # Links -> [text](href)
    s = re.sub(
        r"<\s*a\b[^>]*?\bhref\s*=\s*[\"']([^\"']+)[\"'][^>]*>(.*?)</\s*a\s*>",
        lambda m: f"[{m.group(2).strip()}]({m.group(1)})",
        s,
        flags=re.IGNORECASE | re.DOTALL,
    )

    # Bullet list items -> "- item"
    s = re.sub(r"<\s*li[^>]*>", "\n- ", s, flags=re.IGNORECASE)
    s = re.sub(r"</\s*li\s*>", "", s, flags=re.IGNORECASE)

    # Bold / italic markers
    s = re.sub(r"<\s*(strong|b)\s*>", "**", s, flags=re.IGNORECASE)
    s = re.sub(r"</\s*(strong|b)\s*>", "**", s, flags=re.IGNORECASE)
    s = re.sub(r"<\s*(em|i)\s*>", "_", s, flags=re.IGNORECASE)
    s = re.sub(r"</\s*(em|i)\s*>", "_", s, flags=re.IGNORECASE)

    # Drop every remaining tag, then decode entities (&nbsp;, &amp;, ...).
    s = re.sub(r"<[^>]+>", "", s)
    s = html.unescape(s)
    s = s.replace("\xa0", " ")

    # Collapse excess whitespace/newlines.
    s = re.sub(r"[ \t]+\n", "\n", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s.strip()


def load_env_file(env_file: Path) -> None:
    """
    Load environment variables from .env file

    Args:
        env_file: Path to .env file
    """
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            # Allow shell-style "export KEY=val" lines.
            if line.startswith("export "):
                line = line[len("export "):].lstrip()
            key, value = line.split("=", 1)
            key = key.strip()
            if not key:
                continue
            value = value.strip()
            quoted = len(value) >= 2 and (
                (value.startswith('"') and value.endswith('"'))
                or (value.startswith("'") and value.endswith("'"))
            )
            if quoted:
                # Quoted values are taken verbatim (an inline "#" is part of the value).
                value = value[1:-1]
            elif "#" in value:
                # Strip inline comments from unquoted values: KEY=val  # note
                value = value.split("#", 1)[0].strip()
            # Real environment variables take precedence over the .env file.
            os.environ.setdefault(key, value)


def build_organization_url(organization: str) -> str:
    """
    Build organization URL from name or URL

    Args:
        organization: Organization name or full URL

    Returns:
        Full organization URL
    """
    organization = organization.strip()
    if not organization:
        raise ValueError("Azure DevOps organization cannot be empty")

    if not organization.startswith(("http://", "https://")):
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,49}", organization):
            raise ValueError("Azure DevOps organization name is invalid")
        return f"https://dev.azure.com/{organization}"

    parsed = urlparse(organization)
    if parsed.scheme != "https" or parsed.username or parsed.password or parsed.port:
        raise ValueError("Azure DevOps organization URL must be an HTTPS URL without credentials or a custom port")

    host = (parsed.hostname or "").lower()
    path_parts = [part for part in parsed.path.split("/") if part]
    if host == "dev.azure.com":
        if len(path_parts) != 1 or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]{0,49}", path_parts[0]):
            raise ValueError("dev.azure.com organization URLs must be https://dev.azure.com/<organization>")
        return f"https://dev.azure.com/{path_parts[0]}"

    if host.endswith(".visualstudio.com") and not path_parts:
        return f"https://{host}"

    raise ValueError("Azure DevOps organization URL must use dev.azure.com or *.visualstudio.com")


def get_env_config(
    organization: Optional[str] = None,
    pat: Optional[str] = None,
    project: Optional[str] = None,
    team: Optional[str] = None,
    area_path: Optional[str] = None,
    env_file: Optional[Path] = None,
) -> tuple[str, str, Optional[str], Optional[str], Optional[str]]:
    """
    Get configuration from environment variables and parameters

    Args:
        organization: Organization name or URL
        pat: Personal Access Token
        project: Default project name
        team: Default team name
        area_path: Default area path
        env_file: Path to .env file (optional)

    Returns:
        Tuple of (organization, pat, project, team, area_path)

    Raises:
        ValueError: If required config is missing
    """
    # Load from .env file if provided
    if env_file and env_file.exists():
        load_env_file(env_file)

    organization = organization or os.getenv("AZURE_DEVOPS_ORG")
    pat = pat or os.getenv("AZURE_DEVOPS_PAT")
    project = project or os.getenv("AZURE_DEVOPS_PROJECT")
    team = team or os.getenv("AZURE_DEVOPS_TEAM")
    area_path = area_path or os.getenv("AZURE_DEVOPS_AREA_PATH")

    if not organization or not pat:
        raise ValueError("AZURE_DEVOPS_ORG and AZURE_DEVOPS_PAT must be set")

    return organization, pat, project, team, area_path
