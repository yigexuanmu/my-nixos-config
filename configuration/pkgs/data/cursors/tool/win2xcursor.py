#!/usr/bin/env python3
"""Convert a Windows cursor scheme (.ani/.cur) into an Xcursor theme.

The theme is written in the native Xcursor format via xcursorgen, so it is
usable by X11, Xwayland and Wayland clients (libwayland-cursor reads
Xcursor files). Multiple nominal sizes keep the cursor sharp under
fractional / integer output scaling.

Sources are auto-discovered: the Windows .inf scheme is parsed when present
(Windows role -> X11 cursor name), otherwise file names are matched against
common scheme names. Replacing source.zip is enough to switch schemes.
"""

import argparse
import io
import os
import re
import struct
import subprocess
import sys
import tempfile

from PIL import Image

JIFFY_MS = 1000.0 / 60.0
THEME_NAME = "Windows-Cursor"
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"

# Xcursor name, then aliases
CURSORS = [
    ("left_ptr", ["default", "arrow", "top_left_arrow"]),
    ("help", ["question_arrow", "whats_this"]),
    ("left_ptr_watch", ["progress", "half-busy"]),
    ("watch", ["wait"]),
    ("crosshair", ["cross", "tcross", "cross_reverse"]),
    ("xterm", ["text", "ibeam"]),
    ("pencil", ["hand1"]),
    ("hand2", ["pointer", "pointing_hand"]),
    ("not-allowed", ["forbidden", "no-drop", "circle", "crossed_circle"]),
    ("sb_v_double_arrow", ["ns-resize", "size_ver", "v_double_arrow", "row-resize"]),
    ("sb_h_double_arrow", ["ew-resize", "size_hor", "h_double_arrow", "col-resize"]),
    ("bd_double_arrow", ["size_fdiag", "nwse-resize"]),
    ("fd_double_arrow", ["size_bdiag", "nesw-resize"]),
    ("fleur", ["move", "size_all", "all-scroll"]),
    ("up_arrow", ["sb_up_arrow"]),
]

# Windows INF role -> Xcursor name
ROLE_TARGET = {
    "arrow": "left_ptr",
    "help": "help",
    "appstarting": "left_ptr_watch",
    "wait": "watch",
    "crosshair": "crosshair",
    "ibeam": "xterm",
    "hand": "hand2",
    "no": "not-allowed",
    "nwpen": "pencil",
    "sizeall": "fleur",
    "sizenesw": "fd_double_arrow",
    "sizens": "sb_v_double_arrow",
    "sizenwse": "bd_double_arrow",
    "sizewe": "sb_h_double_arrow",
    "uparrow": "up_arrow",
}

# Fallback for schemes without a usable .inf
STEM_TARGET = {
    "pointer": "left_ptr",
    "normal": "left_ptr",
    "arrow": "left_ptr",
    "left_ptr": "left_ptr",
    "help": "help",
    "question": "help",
    "work": "left_ptr_watch",
    "appstarting": "left_ptr_watch",
    "progress": "left_ptr_watch",
    "left_ptr_watch": "left_ptr_watch",
    "busy": "watch",
    "wait": "watch",
    "watch": "watch",
    "cross": "crosshair",
    "crosshair": "crosshair",
    "precision": "crosshair",
    "text": "xterm",
    "ibeam": "xterm",
    "xterm": "xterm",
    "link": "hand2",
    "hand": "hand2",
    "hand2": "hand2",
    "unavailiable": "not-allowed",
    "unavailable": "not-allowed",
    "nodrop": "not-allowed",
    "not-allowed": "not-allowed",
    "vert": "sb_v_double_arrow",
    "ns": "sb_v_double_arrow",
    "sizens": "sb_v_double_arrow",
    "horz": "sb_h_double_arrow",
    "we": "sb_h_double_arrow",
    "sizewe": "sb_h_double_arrow",
    "dgn1": "bd_double_arrow",
    "nwse": "bd_double_arrow",
    "sizenwse": "bd_double_arrow",
    "dgn2": "fd_double_arrow",
    "nesw": "fd_double_arrow",
    "sizenesw": "fd_double_arrow",
    "move": "fleur",
    "sizeall": "fleur",
    "fleur": "fleur",
    "alternate": "up_arrow",
    "uparrow": "up_arrow",
    "up": "up_arrow",
    "pencil": "pencil",
    "pen": "pencil",
    "nwpen": "pencil",
}


def iter_chunks(data):
    i = 0
    end = len(data)
    while i + 8 <= end:
        cid = data[i : i + 4]
        size = struct.unpack_from("<I", data, i + 4)[0]
        yield cid, data[i + 8 : i + 8 + size]
        i += 8 + size + (size & 1)


def parse_icon_dir(data):
    if len(data) < 6:
        raise ValueError("truncated icon directory")
    reserved, kind, count = struct.unpack_from("<HHH", data, 0)
    if reserved != 0 or kind not in (1, 2):
        raise ValueError("not a .ico/.cur file")
    entries = []
    for i in range(count):
        w, h, _colors, _res, hot_x, hot_y, size, off = struct.unpack_from(
            "<BBBBHHII", data, 6 + 16 * i
        )
        entries.append(
            {
                "w": w or 256,
                "h": h or 256,
                "hot_x": hot_x if kind == 2 else 0,
                "hot_y": hot_y if kind == 2 else 0,
                "size": size,
                "off": off,
            }
        )
    return kind, entries


def decode_image(data, width, height):
    if data[:8] == PNG_MAGIC:
        return Image.open(io.BytesIO(data)).convert("RGBA")

    if len(data) < 40:
        raise ValueError("truncated bitmap header")
    (bi_size, bw, bh, _planes, bpp, compression, _img_size,
     _xppm, _yppm, clr_used, _clr_imp) = struct.unpack_from("<IiiHHIIiiII", data, 0)
    if compression not in (0, 3):
        raise ValueError(f"unsupported bitmap compression {compression}")
    width = bw

    topdown = bh < 0
    pix_h = abs(bh) // 2
    height = pix_h

    if bpp not in (1, 4, 8, 24, 32):
        raise ValueError(f"unsupported bit depth {bpp}")

    ncolors = 0
    if bpp <= 8:
        ncolors = clr_used or (1 << bpp)
    palette = []
    palette_off = bi_size
    for i in range(ncolors):
        b, g, r, _ = data[palette_off + 4 * i : palette_off + 4 * i + 4]
        palette.append((r, g, b))

    row_stride = ((width * bpp + 31) // 32) * 4
    pix_off = bi_size + 4 * ncolors
    mask_off = pix_off + row_stride * pix_h
    mask_stride = ((width + 31) // 32) * 4

    def mask_transparent(x, y):
        # The AND mask stores rows the same way as the XOR bitmap.
        row_index = y if topdown else (pix_h - 1 - y)
        byte = data[mask_off + row_index * mask_stride + (x >> 3)]
        return (byte >> (7 - (x & 7))) & 1

    out = bytearray(width * height * 4)
    has_alpha = False
    for y in range(pix_h):
        src_y = y if topdown else pix_h - 1 - y
        row = data[pix_off + src_y * row_stride : pix_off + (src_y + 1) * row_stride]
        for x in range(width):
            if bpp == 32:
                b, g, r, a = row[4 * x : 4 * x + 4]
                has_alpha = has_alpha or a != 0
            elif bpp == 24:
                b, g, r = row[3 * x : 3 * x + 3]
                a = 255
            elif bpp == 8:
                r, g, b = palette[row[x]]
                a = 255
            elif bpp == 4:
                idx = row[x // 2]
                idx = (idx >> 4) if x % 2 == 0 else (idx & 0x0F)
                r, g, b = palette[idx]
                a = 255
            else:  # bpp == 1
                bit = (row[x // 8] >> (7 - (x % 8))) & 1
                r, g, b = palette[bit]
                a = 255
            o = (y * width + x) * 4
            out[o : o + 4] = bytes((r, g, b, a))

    img = Image.frombytes("RGBA", (width, height), bytes(out))
    if bpp == 32 and not has_alpha:
        alpha = Image.frombytes(
            "L",
            (width, height),
            bytes(
                0 if mask_transparent(x, y) else 255
                for y in range(height)
                for x in range(width)
            ),
        )
        img.putalpha(alpha)
    elif bpp != 32:
        mask = Image.frombytes(
            "L",
            (width, height),
            bytes(
                0 if mask_transparent(x, y) else 255
                for y in range(height)
                for x in range(width)
            ),
        )
        img.putalpha(mask)
    return img


def load_cursor_blob(blob):
    _kind, entries = parse_icon_dir(blob)
    entry = max(entries, key=lambda e: e["w"] * e["h"])
    raw = blob[entry["off"] : entry["off"] + entry["size"]]
    img = decode_image(raw, entry["w"], entry["h"])
    return img, entry["hot_x"], entry["hot_y"]


def parse_ani(data):
    frames = []
    rates = None
    seq = None
    anih = None

    for cid, payload in iter_chunks(data[12:]):
        if cid == b"LIST":
            if payload[:4] == b"fram":
                for sub_id, sub in iter_chunks(payload[4:]):
                    if sub_id == b"icon":
                        frames.append(sub)
        elif cid == b"anih":
            anih = struct.unpack_from("<9I", payload, 0)
        elif cid == b"rate":
            rates = struct.unpack_from("<%dI" % (len(payload) // 4), payload, 0)
        elif cid == b"seq ":
            seq = struct.unpack_from("<%dI" % (len(payload) // 4), payload, 0)

    if not frames:
        raise ValueError("no frames in .ani")
    if anih is None:
        default_rate = 6
        steps = len(frames)
    else:
        default_rate = anih[7] or 6
        steps = anih[2] or len(frames)

    if seq:
        order = [i for i in seq[:steps] if i < len(frames)] or list(range(len(frames)))
    else:
        order = list(range(min(steps, len(frames))))

    result = []
    for step, idx in enumerate(order):
        img, hot_x, hot_y = load_cursor_blob(frames[idx])
        jiffies = rates[step] if rates and step < len(rates) and rates[step] else default_rate
        delay = max(int(round(jiffies * JIFFY_MS)), 10)
        result.append((img, hot_x, hot_y, delay))
    return result


def load_cursor(path):
    with open(path, "rb") as f:
        data = f.read()
    if data[:4] == b"RIFF" and data[8:12] == b"ACON":
        return parse_ani(data)
    img, hot_x, hot_y = load_cursor_blob(data)
    return [(img, hot_x, hot_y, 0)]


def read_text(path):
    raw = open(path, "rb").read()
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff") or b"\x00" in raw[:200]:
        return raw.decode("utf-16", errors="ignore")
    return raw.decode("utf-8", errors="ignore")


def parse_inf(path, by_basename):
    """Return {x11 cursor name: source path} from a Windows cursor .inf."""
    text = read_text(path)
    section = None
    sections = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith(";"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1].strip().lower()
            sections.setdefault(section, [])
            continue
        if section is not None:
            sections[section].append(line)

    strings = {}
    for line in sections.get("strings", []):
        key, _, value = line.partition("=")
        strings[key.strip().lower()] = value.strip().strip('"')

    roles = {}
    for line in sections.get("wreg", []):
        fields = [f.strip().strip('"') for f in line.split(",")]
        if len(fields) < 5:
            continue
        role = fields[2].lower()
        target = ROLE_TARGET.get(role)
        if target is None:
            continue
        value = fields[-1]
        filename = None
        for var in reversed(re.findall(r"%([^%]+)%", value)):
            if var.isdigit():
                continue
            resolved = strings.get(var.lower())
            if resolved:
                filename = resolved
                break
        if not filename:
            continue
        source = by_basename.get(os.path.basename(filename).lower())
        if source:
            roles[target] = source
    return roles


def find_sources(root):
    by_basename = {}
    infs = []
    for dirpath, _dirs, files in os.walk(root):
        for name in files:
            lower = name.lower()
            path = os.path.join(dirpath, name)
            if lower.endswith(".inf"):
                infs.append(path)
            if os.path.splitext(lower)[1] in (".ani", ".cur"):
                by_basename.setdefault(lower, path)

    sources = {}
    for inf in sorted(infs):
        sources.update(parse_inf(inf, by_basename))

    stems = {}
    for lower, path in by_basename.items():
        stem = os.path.splitext(lower)[0]
        stems.setdefault(stem, path)

    for target, _aliases in CURSORS:
        if target in sources:
            continue
        for stem, path in stems.items():
            if STEM_TARGET.get(stem) == target:
                sources[target] = path
                break
    return sources


def build_theme(src, out, sizes, name, formats):
    sources = find_sources(src)
    if not sources:
        raise SystemExit(f"no .ani/.cur cursors found under {src}")

    want_xcursor = "xcursor" in formats
    want_hypr = "hyprcursor" in formats
    cursors_dir = os.path.join(out, "cursors")
    hypr_dir = os.path.join(out, "hyprcursors")
    if want_xcursor:
        os.makedirs(cursors_dir, exist_ok=True)
    if want_hypr:
        os.makedirs(hypr_dir, exist_ok=True)

    tmp = tempfile.mkdtemp(prefix="win2xcursor.")
    try:
        for target, aliases in CURSORS:
            path = sources.get(target)
            if path is None:
                print(f"warning: no source for {target}, skipped", file=sys.stderr)
                continue
            frames = load_cursor(path)
            lines = []
            meta = ["resize_algorithm = bilinear"]
            src_w, src_h = frames[0][0].size
            meta.append(f"hotspot_x = {frames[0][1] / src_w:.6f}")
            meta.append(f"hotspot_y = {frames[0][2] / src_h:.6f}")
            meta.extend(f"define_override = {alias}" for alias in aliases)
            target_dir = os.path.join(hypr_dir, target)
            if want_hypr:
                os.makedirs(target_dir, exist_ok=True)
            for size in sizes:
                for idx, (img, hot_x, hot_y, delay) in enumerate(frames):
                    px = min(max(int(hot_x * size / src_w + 0.5), 0), size - 1)
                    py = min(max(int(hot_y * size / src_h + 0.5), 0), size - 1)
                    scaled = img.resize((size, size), Image.LANCZOS)
                    if want_xcursor:
                        png = os.path.join(tmp, f"{target}.{size}.{idx}.png")
                        scaled.save(png)
                        lines.append(f"{size} {px} {py} {png} {delay}")
                    if want_hypr:
                        image = f"image{size}_{idx}.png"
                        scaled.save(os.path.join(target_dir, image))
                        if len(frames) > 1:
                            meta.append(f"define_size = {size}, {image}, {max(delay, 1)}")
                        else:
                            meta.append(f"define_size = {size}, {image}")

            if want_xcursor:
                config = os.path.join(tmp, target + ".conf")
                with open(config, "w") as f:
                    f.write("\n".join(lines) + "\n")
                subprocess.run(
                    ["xcursorgen", config, os.path.join(cursors_dir, target)],
                    check=True,
                )
                for alias in aliases:
                    os.symlink(target, os.path.join(cursors_dir, alias))
            if want_hypr:
                with open(os.path.join(target_dir, "meta.hl"), "w") as f:
                    f.write("\n".join(meta) + "\n")
            print(
                f"{target}: {os.path.basename(path)} "
                f"({len(frames)} frames, sizes {sizes}, formats {','.join(sorted(formats))})",
                file=sys.stderr,
            )
    finally:
        for dirpath, dirs, files in os.walk(tmp, topdown=False):
            for f in files:
                os.unlink(os.path.join(dirpath, f))
            for d in dirs:
                os.rmdir(os.path.join(dirpath, d))
        os.rmdir(tmp)

    if want_xcursor:
        with open(os.path.join(out, "index.theme"), "w") as f:
            f.write(
                "[Icon Theme]\n"
                f"Name={name}\n"
                "Comment=Windows cursor scheme converted to Xcursor\n"
                "Inherits=Adwaita\n"
            )
    if want_hypr:
        with open(os.path.join(out, "manifest.hl"), "w") as f:
            f.write(
                f"name = {name}\n"
                "description = Windows cursor scheme converted to Hyprcursor\n"
                "version = 1.0\n"
                "cursors_directory = hyprcursors\n"
            )


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--src", required=True, help="directory containing the scheme")
    parser.add_argument("--out", required=True, help="theme directory to create")
    parser.add_argument("--name", default=THEME_NAME)
    parser.add_argument("--sizes", default="24,30,32,36,42,48,60,64,72,96")
    parser.add_argument(
        "--formats",
        default="xcursor",
        help="comma separated: xcursor, hyprcursor",
    )
    args = parser.parse_args(argv)
    sizes = [int(s) for s in args.sizes.split(",") if s.strip()]
    formats = {f.strip() for f in args.formats.split(",") if f.strip()}
    unknown = formats - {"xcursor", "hyprcursor"}
    if unknown or not formats:
        raise SystemExit(f"unknown formats: {','.join(sorted(unknown))}")
    build_theme(args.src, args.out, sizes, args.name, formats)


if __name__ == "__main__":
    main()
