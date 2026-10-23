#!/usr/bin/env python3
"""Refresh the total citation count and h-index in _data/scholar.yml from Google Scholar.

Google Scholar has no API and sometimes blocks automated requests. When the
fetch fails, the existing numbers are kept and the script exits successfully,
so the site never loses its last known values.
"""

import re
import sys
import urllib.request
from datetime import date
from pathlib import Path

DATA_FILE = Path(__file__).resolve().parent.parent / "_data" / "scholar.yml"
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"


def read_data() -> dict:
    data = {}
    for line in DATA_FILE.read_text().splitlines():
        key, sep, value = line.partition(":")
        if sep:
            data[key.strip()] = value.strip()
    return data


def write_data(data: dict) -> None:
    DATA_FILE.write_text("".join(f"{key}: {value}\n" for key, value in data.items()))


def fetch_stats(user_id: str) -> tuple[int, int]:
    url = f"https://scholar.google.com/citations?user={user_id}&hl=en"
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=30) as response:
        html = response.read().decode("utf-8", errors="replace")
    # The stats table lists: citations (all, since), h-index (all, since), i10-index (all, since).
    values = [int(v) for v in re.findall(r'class="gsc_rsb_std">(\d+)<', html)]
    if len(values) < 3:
        raise ValueError("citation table not found (request was probably blocked)")
    return values[0], values[2]


def main() -> int:
    data = read_data()
    try:
        citations, h_index = fetch_stats(data["user_id"])
    except Exception as error:
        print(f"Could not fetch Google Scholar stats, keeping existing values: {error}")
        return 0

    if (str(citations), str(h_index)) == (data.get("citations"), data.get("h_index")):
        print(f"No change: {citations} citations, h-index {h_index}")
        return 0

    print(f"Updated: {data.get('citations')} -> {citations} citations, h-index {data.get('h_index')} -> {h_index}")
    data.update(citations=citations, h_index=h_index, last_updated=date.today().isoformat())
    write_data(data)
    return 0


if __name__ == "__main__":
    sys.exit(main())
