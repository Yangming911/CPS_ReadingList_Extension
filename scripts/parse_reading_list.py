#!/usr/bin/env python3
"""
Parse a LaTeX reading list document and extract paper titles.

Usage:
    python3 parse_reading_list.py --input raw_text.txt --output papers.json
    echo "latex content" | python3 parse_reading_list.py --output papers.json

The parser expects LaTeX with \\begin{enumerate} ... \\end{enumerate}
containing \\item entries, where each item is a paper title.
New papers are at the top of the list.
"""

import argparse
import json
import re
import sys
from pathlib import Path


def extract_items_from_latex(text: str) -> list[str]:
    """Extract paper titles from LaTeX enumerate environment."""

    # Try to find the enumerate block
    # The text might come from Overleaf's page text extraction, which may not
    # have clean LaTeX formatting, so we handle both cases.

    # Strategy 1: Find content between \begin{enumerate} and \end{enumerate}
    enum_match = re.search(
        r'\\begin\{enumerate\}(.*?)\\end\{enumerate\}',
        text,
        re.DOTALL
    )

    if enum_match:
        content = enum_match.group(1)
    else:
        # Strategy 2: Just look for \item patterns in the whole text
        content = text

    # Split on \item and extract titles
    # Each \item is followed by the paper title (possibly multi-line)
    items = re.split(r'\\item\s*', content)

    papers = []
    for item in items:
        item = item.strip()
        if not item:
            continue

        # Clean up the title:
        # 1. Remove LaTeX commands that might appear
        title = re.sub(r'\\[a-zA-Z]+\{[^}]*\}', '', item)
        title = re.sub(r'\\[a-zA-Z]+', '', title)

        # 2. Handle multi-line: collapse whitespace
        title = re.sub(r'\s+', ' ', title)

        # 3. If there's commentary after the title (like "??? anyone wants to..."),
        #    try to extract just the paper title. Heuristic: if there's a pattern
        #    like "reference:" or a long run of "?" that looks like commentary,
        #    truncate there. But be careful — some titles legitimately have "?"
        #    (e.g., "Can LLMs Perform Synthesis?")

        # Look for obvious commentary markers
        commentary_markers = [
            r'\?\?\?',           # Multiple question marks = commentary
            r'reference:',       # Explicit reference note
            r'anyone wants to',  # Discussion note
        ]
        for marker in commentary_markers:
            match = re.search(marker, title, re.IGNORECASE)
            if match:
                title = title[:match.start()].strip()
                break

        # 4. Remove trailing punctuation artifacts but keep "?" if it ends a title
        title = title.strip()

        if title and len(title) > 5:  # Filter out very short fragments
            papers.append(title)

    return papers


def compare_with_state(current_papers: list[str], state_path: str) -> dict:
    """Compare current papers with saved state. Return new papers and updated state."""

    state_file = Path(state_path)

    if state_file.exists():
        with open(state_file) as f:
            state = json.load(f)
        known = set(state.get("known_papers", []))
    else:
        # First run — establish baseline
        known = set()

    # Find papers not in the known set
    # Normalize for comparison (lowercase, strip)
    known_normalized = {p.lower().strip() for p in known}

    new_papers = []
    for paper in current_papers:
        if paper.lower().strip() not in known_normalized:
            new_papers.append(paper)

    return {
        "new_papers": new_papers,
        "all_papers": current_papers,
        "previously_known_count": len(known),
        "is_first_run": not state_file.exists()
    }


def main():
    parser = argparse.ArgumentParser(description="Parse LaTeX reading list")
    parser.add_argument("--input", "-i", help="Input file with raw text (stdin if omitted)")
    parser.add_argument("--output", "-o", required=True, help="Output JSON file")
    parser.add_argument("--state", "-s", default="/Users/wangshuqi/helloworld/Reading_List/reading-list-state.json",
                       help="State file path (default: /Users/wangshuqi/helloworld/Reading_List/reading-list-state.json)")
    parser.add_argument("--compare", action="store_true",
                       help="Compare with state and report new papers")

    args = parser.parse_args()

    # Read input
    if args.input:
        with open(args.input) as f:
            text = f.read()
    else:
        text = sys.stdin.read()

    # Parse papers
    papers = extract_items_from_latex(text)

    if args.compare:
        state_path = str(Path(args.state).expanduser())
        result = compare_with_state(papers, state_path)
        output = {
            "papers": papers,
            "new_papers": result["new_papers"],
            "total_count": len(papers),
            "new_count": len(result["new_papers"]),
            "is_first_run": result["is_first_run"]
        }
    else:
        output = {
            "papers": papers,
            "total_count": len(papers)
        }

    # Write output
    with open(args.output, "w") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    # Also print summary to stdout
    print(f"Found {len(papers)} papers total")
    if args.compare:
        print(f"New papers: {len(result['new_papers'])}")
        for p in result["new_papers"]:
            print(f"  - {p}")


if __name__ == "__main__":
    main()
