"""Tests for export_test_cases."""

from export_test_cases import AidlcMarkdownParser


def test_parse_legacy_gherkin_table_format_with_traceability_matrix():
    content = """
## Traceability matrix

| Source ID | Source summary | Test case IDs | Coverage notes |
| --- | --- | --- | --- |
| AC-1 | User can submit an order | TC-001 | happy path |

## Test cases

| Test case ID | Scenario | Given | When | Then | Source ID | Coverage type | Automation target | Priority | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-001 | Submit valid order | A shopper has a valid cart | The shopper submits the order | The order is created | AC-1 | functional | manual | High |  |
"""
    rows = AidlcMarkdownParser(content).parse()
    assert len(rows) == 1
    assert rows[0].title == "Submit valid order"
    assert rows[0].preconditions == "A shopper has a valid cart"
    assert rows[0].source_summary == "User can submit an order"


def test_parse_gherkin_table_format_without_traceability_matrix():
    content = """
## Test cases

| Test case ID | Scenario | Given | When | Then | Source ID | Coverage type | Automation target | Priority | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-001 | Submit valid order | A shopper has a valid cart | The shopper submits the order | The order is created | AC-1 | happy | manual | High |  |

## Coverage summary

| Coverage type | Count | Test case IDs | Notes |
| --- | ---: | --- | --- |
| happy | 1 | TC-001 |  |
"""
    rows = AidlcMarkdownParser(content).parse()
    assert len(rows) == 1
    assert rows[0].title == "Submit valid order"
    assert rows[0].coverage_type == "happy"
    assert rows[0].source_id == "AC-1"
    assert rows[0].source_summary == ""


def test_parse_standard_table_format():
    content = """
## Test cases

| Test case ID | Title | Preconditions | Steps | Expected result | Source ID | Coverage type | Automation target | Priority | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-001 | Reject invalid order | Invalid payment is selected | Submit the order | The order is rejected with a visible reason | FR-1 | negative | manual | High |  |

## Coverage summary

| Coverage type | Count | Test case IDs | Notes |
| --- | ---: | --- | --- |
| negative | 1 | TC-001 |  |
"""
    rows = AidlcMarkdownParser(content).parse()
    assert len(rows) == 1
    assert rows[0].title == "Reject invalid order"
    assert rows[0].test_steps == "Submit the order"
    assert rows[0].expected_result.startswith("The order is rejected")
    assert rows[0].coverage_type == "negative"


def test_parse_gherkin_blocks_format():
    content = """
## Scenario inventory

| Test case ID | Title | Source ID | Coverage type | Automation target | Priority |
| --- | --- | --- | --- | --- | --- |
| TC-001 | Submit valid order | AC-1 | happy | manual | High |

## Gherkin scenarios

```gherkin
Scenario: Submit valid order
  Given a shopper has a valid cart
  When the shopper submits the order
  Then the order is created
```

## Coverage summary

| Coverage type | Count | Test case IDs | Notes |
| --- | ---: | --- | --- |
| happy | 1 | TC-001 |  |
"""
    rows = AidlcMarkdownParser(content).parse()
    assert len(rows) == 1
    assert rows[0].title == "Submit valid order"
    assert rows[0].preconditions == "a shopper has a valid cart"
    assert rows[0].test_steps == "the shopper submits the order"
    assert rows[0].expected_result == "the order is created"
    assert rows[0].coverage_type == "happy"
