#!/usr/bin/env python3
"""Fixture and sample checker for this repository.

Validates every JSON fixture under tests/ against the schema its file name selects,
and every sample script under Samples/v1.2/ against the v1.2 schemas plus the subset
of validator rules listed in docs/validator/validator-rules-v1.2.md section "Fixture
checker". It uses the Iranux runner's block regular expressions and JSON strictness (including
the runner's refusal of decimal numbers in integer fields), so a script that passes
here is parsed by the Iranux applications; the checker does not reproduce the runner's
per-value validation at run time.

This is a test aid for the repository. It is not the Iranux Validator and issues no
certification.

Usage:
    python3 tools/check_fixtures.py [--mdi NAMES_FILE] [--profile catalog] [paths...]

Requires: jsonschema (python3 -m pip install jsonschema). Uses bash and shellcheck
when present on PATH.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

try:
    import jsonschema
    from jsonschema import Draft202012Validator
except ImportError:  # pragma: no cover
    print("jsonschema is required: python3 -m pip install jsonschema", file=sys.stderr)
    sys.exit(2)

ROOT = Path(__file__).resolve().parent.parent
SCHEMAS = ROOT / "schemas"

# The runner's regular expressions (IranuxScriptParser), translated to Python.
BLOCK_RE = {
    "metadata": re.compile(r"^\s*:\s*<<'IRANUX_METADATA'\s*\r?\n([\s\S]*?)\r?\nIRANUX_METADATA\s*$", re.M),
    "param": re.compile(r"^\s*:\s*<<'IRANUX_PARAM'\s*\r?\n([\s\S]*?)\r?\nIRANUX_PARAM\s*$", re.M),
    "certification": re.compile(r"^\s*:\s*<<'IRANUX_CERTIFICATION'\s*\r?\n([\s\S]*?)\r?\nIRANUX_CERTIFICATION\s*$", re.M),
}
MARKER = "__IRANUX_REACHED_END_V1__"
MARKER_ECHO_RE = re.compile(r"""echo\s+['"]?__IRANUX_REACHED_END_V1__['"]?""", re.I)
BIDI_RE = re.compile("[‪-‮⁦-⁩]")
ARABIC_YEH_KAF_RE = re.compile("[يك]")
SENSITIVE_TYPES = {"password", "secret", "private_key"}


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.infos: list[str] = []
        self.passed = 0

    def error(self, where: str, code: str, message: str) -> None:
        self.errors.append(f"{code} ERROR {where}: {message}")

    def warn(self, where: str, code: str, message: str) -> None:
        self.warnings.append(f"{code} WARN  {where}: {message}")

    def info(self, where: str, code: str, message: str) -> None:
        line = f"{code} INFO  {where}: {message}"
        if line not in self.infos:
            self.infos.append(line)


def load_schema(name: str) -> Draft202012Validator:
    with (SCHEMAS / name).open(encoding="utf-8") as handle:
        schema = json.load(handle)
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema)


def schema_for_fixture(path: Path) -> str | None:
    name = path.name
    if name.startswith("v1.1-") or name.startswith("metadata-v1.1"):
        return "iranux-metadata-v1.1.schema.json"
    if name.startswith("metadata-"):
        return "iranux-metadata-v1.2.schema.json"
    if name.startswith("param-v1.0"):
        return "iranux-param-v1.0.schema.json"
    if name.startswith("param-"):
        return "iranux-param-v1.2.schema.json"
    if name.startswith("result-"):
        return "iranux-result-v1.2.schema.json"
    if name.startswith("certification-"):
        return "iranux-certification-v1.0.schema.json"
    return None


class DecimalNumber(float):
    """A JSON number written with a fraction or exponent. The runner refuses it for
    `estimated_minutes` (the whole metadata block then fails to parse) and ignores a
    `min_length`/`max_length` constraint written that way."""


INTEGER_FIELDS = {"estimated_minutes", "min_length", "max_length"}


def decimal_integer_fields(node, path: str = "") -> list[str]:
    found: list[str] = []
    if isinstance(node, dict):
        for key, value in node.items():
            child = f"{path}.{key}" if path else key
            if key in INTEGER_FIELDS and isinstance(value, DecimalNumber):
                found.append(child)
            found.extend(decimal_integer_fields(value, child))
    elif isinstance(node, list):
        for index, value in enumerate(node):
            found.extend(decimal_integer_fields(value, f"{path}[{index}]"))
    return found


def strict_json(text: str):
    """Strict JSON: no NaN/Infinity, duplicate keys raise ValueError, decimal numbers marked."""

    def pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                raise ValueError(f"duplicate key '{key}'")
            result[key] = value
        return result

    def constant(name):
        raise ValueError(f"non-standard constant {name}")

    return json.loads(text, object_pairs_hook=pairs, parse_constant=constant, parse_float=DecimalNumber)


def schema_errors(validator: Draft202012Validator, instance) -> list[str]:
    return [
        f"{'/'.join(str(p) for p in error.absolute_path) or '<root>'}: {error.message}"
        for error in sorted(validator.iter_errors(instance), key=lambda e: list(e.absolute_path))
    ]


def check_fixture(path: Path, validators: dict[str, Draft202012Validator], report: Report) -> None:
    where = display(path)
    schema_name = schema_for_fixture(path)
    if schema_name is None:
        report.error(where, "FIXTURE", "file name does not select a schema (metadata-, param-, result-, certification-)")
        return
    try:
        instance = strict_json(path.read_text(encoding="utf-8"))
    except ValueError as exc:
        if path.parent.name == "invalid":
            report.passed += 1
            return
        report.error(where, "IRX1014", f"not strict JSON: {exc}")
        return
    errors = schema_errors(validators[schema_name], instance)
    errors += [f"{field}: decimal number in an integer field (the runner cannot parse it)" for field in decimal_integer_fields(instance)]
    expect_invalid = path.parent.name == "invalid"
    if expect_invalid and not errors:
        report.error(where, "FIXTURE", f"expected to fail {schema_name} but validated")
    elif not expect_invalid and errors:
        for message in errors:
            report.error(where, "SCHEMA", f"{schema_name}: {message}")
    else:
        report.passed += 1


def display(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def line_of(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def strip_comments(line: str) -> str:
    # Good enough for the checks below: drop a trailing comment that starts a word.
    return re.sub(r"(^|\s)#.*$", "", line)


def is_inside_double_quotes(line: str, position: int) -> bool:
    """Whether the character at position is inside double quotes, following Bash
    nesting: a $( ... ) inside double quotes starts a new quoting context."""
    saved: list[bool] = []
    in_double = False
    in_single = False
    index = 0
    while index < position:
        char = line[index]
        if in_single:
            if char == "'":
                in_single = False
        elif char == "\\":
            index += 2
            continue
        elif char == "'" and not in_double:
            in_single = True
        elif char == '"':
            in_double = not in_double
        elif line.startswith("$(", index):
            saved.append(in_double)
            in_double = False
            index += 2
            continue
        elif char == ")" and saved and not in_double:
            in_double = saved.pop()
        index += 1
    return in_double


def heredoc_lines(lines: list[str]) -> set[int]:
    """1-based numbers of lines inside a heredoc body (terminator excluded)."""
    inside: set[int] = set()
    terminator: str | None = None
    for number, line in enumerate(lines, start=1):
        if terminator is not None:
            if line.strip() == terminator:
                terminator = None
            else:
                inside.add(number)
            continue
        match = re.search(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1", line)
        if match and "<<<" not in line:
            terminator = match.group(2)
    return inside


def strip_quoted(code: str) -> str:
    """Remove single- and double-quoted segments so operators inside strings are ignored."""
    return re.sub(r"'[^']*'|\"(?:\\.|[^\"\\])*\"", "''", code)


def check_result_line(where: str, number: int, code: str, validators: dict[str, Draft202012Validator],
                      profile: str | None, report: Report) -> None:
    """Validates an echo of IRANUX_RESULT whose JSON is literal apart from shell expansions.
    Expansions are replaced by placeholder strings before parsing."""
    match = re.search(r'echo\s+(-e\s+)?"IRANUX_RESULT\s+(.*)"\s*$', code)
    if not match:
        report.warn(where, "IRX1802", f"line {number}: IRANUX_RESULT is not printed by a single echo with a double-quoted argument; not checked")
        return
    text = match.group(2)
    # Expansions become a placeholder that satisfies both the text and the url patterns.
    text = re.sub(r"\$\((?:[^()]|\([^()]*\))*\)", '"https://x"', text)   # $(...) in value position
    text = re.sub(r"\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*", "https://x", text)
    text = text.replace('\\"', '"')
    try:
        result = strict_json(text)
    except ValueError as exc:
        report.warn(where, "IRX1802", f"line {number}: IRANUX_RESULT JSON could not be checked statically ({exc})")
        return
    for message in schema_errors(validators["iranux-result-v1.2.schema.json"], result):
        report.error(where, "RESULT", f"line {number}: IRANUX_RESULT {message}")
    if profile == "catalog":
        for output in result.get("outputs") or []:
            if not (((output.get("i18n") or {}).get("fa")) or {}).get("label"):
                report.error(where, "IRX1904", f"line {number}: result output '{output.get('key')}' has no Persian label")


def check_sample(path: Path, validators: dict[str, Draft202012Validator], mdi_names: set[str] | None,
                 profile: str | None, report: Report) -> None:
    where = display(path)
    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        report.error(where, "IRX1301", "file starts with a byte-order mark")
    text = raw.decode("utf-8")
    if "\r\n" in text:
        report.warn(where, "IRX1302", "CRLF line endings")
    first_line = text.split("\n", 1)[0].rstrip("\r")
    if first_line not in ("#!/usr/bin/env bash", "#!/bin/bash"):
        report.error(where, "IRX1303", f"first line is not a Bash shebang: {first_line!r}")
    for match in BIDI_RE.finditer(text):
        report.error(where, "IRX1305", f"bidirectional control U+{ord(match.group()):04X} at line {line_of(text, match.start())}")

    # Blocks
    metadata_matches = list(BLOCK_RE["metadata"].finditer(text))
    param_matches = list(BLOCK_RE["param"].finditer(text))
    cert_matches = list(BLOCK_RE["certification"].finditer(text))
    if not metadata_matches:
        report.error(where, "PLAIN", "no IRANUX_METADATA block found; the runner treats the script as Plain")
        return
    if len(metadata_matches) > 1:
        report.error(where, "IRX1012", "more than one IRANUX_METADATA block")
    if len(cert_matches) > 1:
        report.error(where, "IRX1013", "more than one IRANUX_CERTIFICATION block")
    for match in metadata_matches + param_matches + cert_matches:
        opening = text[text.rfind("\n", 0, match.start()) + 1: match.start() + len(match.group(0))].split("\n", 1)[0]
        if opening[:1] in (" ", "\t"):
            report.warn(where, "IRX1011", f"indented Iranux block at line {line_of(text, match.start())}")

    try:
        metadata = strict_json(metadata_matches[0].group(1).strip())
    except ValueError as exc:
        report.error(where, "IRX1014", f"metadata is not strict JSON: {exc}")
        return
    version = (metadata.get("standard") or {}).get("schema_version")
    if version == "1.2":
        metadata_schema, param_schema = "iranux-metadata-v1.2.schema.json", "iranux-param-v1.2.schema.json"
    elif version == "1.1":
        metadata_schema, param_schema = "iranux-metadata-v1.1.schema.json", "iranux-param-v1.0.schema.json"
    else:
        report.error(where, "IRX1001", f"schema version {version!r} is not checked by this tool (1.1 and 1.2 only)")
        return
    for message in schema_errors(validators[metadata_schema], metadata):
        report.error(where, "SCHEMA", f"metadata: {message}")
    for field in decimal_integer_fields(metadata):
        report.error(where, "IRX1014", f"metadata {field} is a decimal number; the runner cannot parse the block")
    minutes = (metadata.get("script") or {}).get("estimated_minutes")
    if isinstance(minutes, int) and minutes > 10:
        report.warn(where, "IRX1234", f"estimated_minutes {minutes} exceeds the runners' 10-minute run limit")

    icon = ((metadata.get("ui") or {}).get("icon") or {}).get("name")
    if mdi_names is None:
        report.info(where, "IRX1107", "skipped: no --mdi name list given")
    elif icon and icon not in mdi_names:
        report.error(where, "IRX1107", f"icon '{icon}' is not in the supplied MDI name list")

    params: list[dict] = []
    names: set[str] = set()
    for match in param_matches:
        line = line_of(text, match.start())
        try:
            param = strict_json(match.group(1).strip())
        except ValueError as exc:
            report.error(where, "IRX1014", f"parameter block at line {line} is not strict JSON: {exc}")
            continue
        for message in schema_errors(validators[param_schema], param):
            report.error(where, "SCHEMA", f"param '{param.get('name', '?')}' (line {line}): {message}")
        for field in decimal_integer_fields(param):
            report.warn(where, "IRX1014", f"param '{param.get('name', '?')}' {field} is a decimal number; the runner ignores that constraint")
        pattern = (param.get("validation") or {}).get("pattern")
        if isinstance(pattern, str) and not (pattern.startswith("^") and pattern.endswith("$")):
            report.warn(where, "IRX1235", f"param '{param.get('name', '?')}' validation.pattern is not anchored with ^ and $")
        name = param.get("name")
        if isinstance(name, str):
            if name in names:
                report.error(where, "DUPLICATE", f"duplicate parameter name '{name}'")
            names.add(name)
        params.append(param)

    # Persian text quality (IRX1403) over every "fa" value in metadata and params.
    def walk_fa(node, path: str) -> None:
        if isinstance(node, dict):
            for key, value in node.items():
                child = f"{path}.{key}" if path else key
                if key == "fa" or key.startswith("fa-"):
                    for inner_key, inner in (value or {}).items():
                        if isinstance(inner, str) and ARABIC_YEH_KAF_RE.search(inner):
                            report.warn(where, "IRX1403", f"{child}.{inner_key} uses Arabic ي/ك")
                else:
                    walk_fa(value, child)

    walk_fa(metadata, "metadata")
    for param in params:
        walk_fa(param, f"param:{param.get('name', '?')}")

    # Bash-text rules
    body = text[metadata_matches[0].end():]
    lines = text.split("\n")
    sensitive_vars = {
        p["name"].upper()
        for p in params
        if isinstance(p.get("name"), str) and (p.get("type") in SENSITIVE_TYPES or p.get("sensitive") is True)
    }
    heredoc_body = heredoc_lines(lines)
    for param in params:
        name = param.get("name")
        if not isinstance(name, str):
            continue
        upper = name.upper()
        if not re.search(rf"\$\{{?{upper}\b", body):
            report.error(where, "IRX1211", f"parameter '{name}' is declared but ${upper} is never read")
        expansion_re = re.compile(rf"\$\{{?{upper}\b")
        for number, line in enumerate(lines, start=1):
            if number in heredoc_body:
                continue  # a heredoc body is not word-split
            code = strip_comments(line)
            for match in expansion_re.finditer(code):
                stripped = code.strip()
                if stripped.startswith("[[") or stripped.startswith("((") or re.match(r"^\s*[A-Za-z_][A-Za-z0-9_]*=", code):
                    continue
                if not is_inside_double_quotes(code, match.start()):
                    report.error(where, "IRX1602", f"line {number}: ${upper} is expanded without quotes")

    for number, line in enumerate(lines, start=1):
        code = strip_comments(line)
        if re.match(r"^\s*(echo|printf)\b", code):
            # Output piped into another program or redirected to a file is not printed
            # (IRX1604/IRX1605 cover those cases as warnings in the full Validator).
            consumed = re.search(r"(?<![|<>])[|>](?![|&])", strip_quoted(code)) is not None
            for var in sensitive_vars:
                if not consumed and re.search(rf"\$\{{?{var}\b", code):
                    report.error(where, "IRX1601", f"line {number}: prints sensitive value ${var}")
            if MARKER in code:
                inner = re.sub(r"""^\s*echo\s+(-e\s+|-n\s+)?""", "", code).strip()
                if inner.strip("\"'") != MARKER:
                    report.error(where, "IRX1231", f"line {number}: the final marker must be alone on its line")
            if "IRANUX_RESULT" in code:
                for var in sensitive_vars:
                    if re.search(rf"\$\{{?{var}\b", code):
                        report.error(where, "IRX1803", f"line {number}: sensitive value ${var} inside IRANUX_RESULT")
                check_result_line(where, number, code, validators, profile, report)
            if re.search(r"command not found|syntax error|bad interpreter", code, re.I):
                report.warn(where, "IRX1236", f"line {number}: output text matches a phrase the runner treats as a critical error")
        elif MARKER in code:
            report.error(where, "IRX1233", f"line {number}: the final marker appears outside an echo")
        if re.search(r"\bset\s+-[a-zA-Z]*x|\bset\s+-o\s+xtrace", code):
            report.error(where, "IRX1603", f"line {number}: xtrace enabled")
        if re.search(r"--no-check-certificate|\s-k\s|--insecure|\bhttp://[^ '\"]+\.(tar|gz|zip|sh|deb|rpm)\b", code):
            report.error(where, "IRX1611", f"line {number}: TLS verification disabled or plain-HTTP download")

    if not MARKER_ECHO_RE.search(text):
        report.error(where, "MARKER", "no echo of the final marker was found")

    if profile == "catalog":
        script = metadata.get("script") or {}
        fa = (script.get("i18n") or {}).get("fa") or {}
        if version != "1.2":
            report.error(where, "IRX1901", "catalog scripts declare schema 1.2")
        if not fa.get("name") or not fa.get("description"):
            report.error(where, "IRX1902", "script.i18n.fa.name and .description are required")
        for param in params:
            pfa = ((param.get("i18n") or {}).get("fa")) or {}
            advanced = param.get("level") == "advanced"
            if not pfa.get("label") or (not advanced and not pfa.get("description")):
                report.error(where, "IRX1903", f"parameter '{param.get('name')}' needs Persian label{'' if advanced else ' and description'}")
        if "estimated_minutes" not in script:
            report.error(where, "IRX1905", "estimated_minutes is required")
        if not (metadata.get("requirements") or {}).get("supported_os"):
            report.error(where, "IRX1906", "supported_os must not be empty")

    # External tools
    bash = shutil.which("bash")
    if bash:
        result = subprocess.run([bash, "-n", str(path)], capture_output=True, text=True)
        if result.returncode != 0:
            report.error(where, "IRX1304", f"bash -n failed: {result.stderr.strip()}")
    shellcheck = shutil.which("shellcheck")
    if shellcheck:
        result = subprocess.run([shellcheck, "-S", "error", "-f", "gcc", str(path)], capture_output=True, text=True)
        if result.returncode != 0:
            report.error(where, "IRX1306", f"shellcheck errors:\n{result.stdout.strip()}")
        warnings = subprocess.run([shellcheck, "-S", "warning", "-f", "gcc", str(path)], capture_output=True, text=True)
        for line in warnings.stdout.strip().splitlines():
            report.warn(where, "SHELLCHECK", line)

    if not any(e.startswith(("IRX", "SCHEMA", "DUPLICATE", "MARKER", "PLAIN")) and f" {where}:" in e for e in report.errors):
        report.passed += 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("paths", nargs="*", help="fixtures (.json) or scripts (.sh); default: tests/ and Samples/v1.2/")
    parser.add_argument("--mdi", type=Path, help="text file with one MDI icon name per line, for IRX1107")
    parser.add_argument("--profile", choices=["catalog"], help="also apply the Catalog profile rules to scripts")
    args = parser.parse_args()

    validators = {
        name: load_schema(name)
        for name in (
            "iranux-metadata-v1.1.schema.json",
            "iranux-metadata-v1.2.schema.json",
            "iranux-param-v1.0.schema.json",
            "iranux-param-v1.2.schema.json",
            "iranux-result-v1.2.schema.json",
            "iranux-certification-v1.0.schema.json",
        )
    }
    mdi_names = set(args.mdi.read_text(encoding="utf-8").split()) if args.mdi else None

    paths = [Path(p).resolve() for p in args.paths] or [ROOT / "tests", ROOT / "Samples" / "v1.2"]
    files: list[Path] = []
    for path in paths:
        if path.is_dir():
            files.extend(sorted(p for p in path.rglob("*") if p.suffix in (".json", ".sh")))
        else:
            files.append(path)

    report = Report()
    for path in files:
        if path.suffix == ".json":
            check_fixture(path, validators, report)
        else:
            check_sample(path, validators, mdi_names, args.profile, report)

    for line in report.infos:
        print(line)
    for line in report.warnings:
        print(line)
    for line in report.errors:
        print(line)
    print(f"\n{report.passed} of {len(files)} files passed, {len(report.errors)} errors, {len(report.warnings)} warnings")
    return 1 if report.errors else 0


if __name__ == "__main__":
    sys.exit(main())
