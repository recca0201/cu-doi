import json
import subprocess
import sys

import pytest

from conftest import SCRIPTS_DIR, load_script_module


figma_client = load_script_module("figma_client")
extract_spec = load_script_module("extract_spec")

FIGMA_URLS = [
    (
        "https://www.figma.com/design/whWQS3CJg5Yal1gKWS4wTi/-DDM2-DES--BOARD-%7C-DDM2?node-id=1356-546806&t=T1IDgI1ZfFaMQD8m-0",
        "whWQS3CJg5Yal1gKWS4wTi",
        "1356:546806",
    ),
    (
        "https://www.figma.com/design/wjxRCZwqAjTsqSuflZHEQQ/Unicorn--Global--About-us---Media-room?node-id=4812-38472&t=0W6PMad25fULqDHu-0",
        "wjxRCZwqAjTsqSuflZHEQQ",
        "4812:38472",
    ),
]


def require_figma_token() -> None:
    try:
        figma_client.resolve_token()
    except SystemExit:
        pytest.skip("Figma token is not configured for live E2E tests")


def find_single_generated_file(tmp_path, pattern: str):
    matches = sorted(tmp_path.glob(pattern))
    assert len(matches) == 1, f"Expected one generated file for {pattern}, found {len(matches)}"
    return matches[0]


@pytest.mark.parametrize("url,file_key,node_id", FIGMA_URLS)
def test_read_spec_from_live_figma_url(tmp_path, url: str, file_key: str, node_id: str):
    require_figma_token()

    client_command = [
        sys.executable,
        str(SCRIPTS_DIR / "figma_client.py"),
        "--url",
        url,
        "--node-only",
    ]
    try:
        client_run = subprocess.run(
            client_command,
            cwd=tmp_path,
            capture_output=True,
            text=True,
            check=True,
            timeout=45,
        )
    except subprocess.TimeoutExpired:
        pytest.skip(f"Timed out fetching live Figma URL: {url}")

    parsed_file_key, parsed_node_id = figma_client.parse_figma_url(url)
    assert client_run.returncode == 0
    assert parsed_file_key == file_key
    assert parsed_node_id == node_id
    output_json = find_single_generated_file(tmp_path, "temp/figma_*/figma-spec.json")
    assert output_json.exists()

    payload = json.loads(output_json.read_text(encoding="utf-8"))
    assert payload["file_key"] == file_key
    assert payload["node_id"] == node_id
    assert payload["target_node"] is not None
    assert payload["target_node_image"] is not None

    spec_command = [
        sys.executable,
        str(SCRIPTS_DIR / "extract_spec.py"),
        "--input",
        str(output_json),
    ]
    try:
        spec_run = subprocess.run(
            spec_command,
            cwd=tmp_path,
            capture_output=True,
            text=True,
            check=True,
            timeout=20,
        )
    except subprocess.TimeoutExpired:
        pytest.skip(f"Timed out rendering Markdown spec for live Figma URL: {url}")

    assert spec_run.returncode == 0
    output_md = find_single_generated_file(tmp_path, "temp/figma_*/figma-spec.md")
    assert output_md.exists()

    markdown = output_md.read_text(encoding="utf-8")
    assert "# Design Spec:" in markdown
    assert f"File key: `{file_key}`" in markdown
    assert "## Target Node" in markdown
    assert payload["target_node"]["name"] in markdown