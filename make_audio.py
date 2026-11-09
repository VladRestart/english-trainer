"""Records every phrase from index.html with natural American voices (edge-tts).

"say" phrases (what you say) use a male voice, "hear" phrases (what people tell you) a female voice.
Each phrase gets a normal file and a slow one: audio/<id>.mp3 and audio/<id>-slow.mp3.
Run again after adding phrases: existing files are skipped.
"""
import asyncio
import re
from pathlib import Path

import edge_tts

ROOT = Path(__file__).parent
VOICES = {"say": "en-US-AndrewNeural", "hear": "en-US-AvaNeural"}
SLOW_RATE = "-30%"


def phrases():
    html = (ROOT / "index.html").read_text(encoding="utf-8")
    for m in re.finditer(r"(?:^|`)(say|hear)\|([^|\n]+)\|", html, re.M):
        kind, en = m.group(1), m.group(2)
        # Same id as in the page: lowercase, non-alphanumerics to "-", trimmed.
        pid = re.sub(r"[^a-z0-9]+", "-", en.lower()).strip("-")
        yield kind, en, pid


async def record(text, voice, rate, path):
    if path.exists() and path.stat().st_size > 0:
        return False
    await edge_tts.Communicate(text, voice, rate=rate).save(str(path))
    return True


async def main():
    out = ROOT / "audio"
    out.mkdir(exist_ok=True)
    items = list(phrases())
    ids = [pid for _, _, pid in items]
    dupes = {i for i in ids if ids.count(i) > 1}
    if dupes:
        raise SystemExit(f"Duplicate phrase ids: {dupes}")
    made = 0
    for kind, en, pid in items:
        made += await record(en, VOICES[kind], "+0%", out / f"{pid}.mp3")
        made += await record(en, VOICES[kind], SLOW_RATE, out / f"{pid}-slow.mp3")
    print(f"{len(items)} phrases, {made} new files")


asyncio.run(main())
