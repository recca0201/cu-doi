"""figmakit — reusable pieces of the Figma REST client.

figma_client.py is a thin entry point that re-exports the public names defined
in this package. Shared constants live here at the package root so the submodules
(paths, nodes, api, assets, config) can import them without an import cycle.

Dependency order (acyclic): paths ← nodes ← api ← assets ; config is standalone.
"""

from pathlib import Path


BASE_URL = "https://api.figma.com/v1"
NETWORK_TIMEOUT_SECONDS = 120
CHILD_IMAGE_EXPORT_TYPES = {"FRAME", "COMPONENT", "COMPONENT_SET", "INSTANCE"}
CHILD_IMAGE_WRAPPER_TYPES = {"GROUP", "SECTION"}
CHILD_IMAGE_MIN_SIZE = 64
# Figma returns Retry-After in seconds on 429. When the quota is a per-minute burst we
# wait it out; when it is the multi-hour/day View-Collab-seat quota (Retry-After can be
# days) we abort with an actionable message instead of sleeping forever.
MAX_RETRY_AFTER_WAIT_SECONDS = 180
DEFAULT_MAX_RPM = 30  # runaway guard; Figma Tier-1 paid floor is 10-20/min, we honor 429 reactively

# figmakit/__init__.py → scripts/figmakit → scripts → skill root (dir containing SKILL.md)
SKILL_DIR = Path(__file__).resolve().parent.parent.parent
