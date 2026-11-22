#!/usr/bin/env python3
"""file-map.py —— 自动维护 /etc/nixos 各 .nix 文件的「文件关联」头部注释。

头部格式
    # ────────────────────────────────────────────────────────────
    # 文件关联（仅 /etc/nixos 范围）
    #   上游（引用本文件）：谁 import 了我
    #   下游（本文件引用）：我 import 了谁
    #   相关（语义关联）：语义上的邻居
    # ────────────────────────────────────────────────────────────

推导规则
    上游 / 下游  从代码里的路径字面量反推（imports / import / callPackage /
                 readFile 处的 ./x、../y.nix）。注释掉的引用不算，
                 字符串里的路径不算；目录自动补 default.nix。
    相关         「证据共现」：两个文件共享稀缺特征就相关，标注证据。
                 特征 = 挂载路径 /boot、systemd 单元 x.target、pkgs.名字、
                 配置目录（xdg.configFile "waybar/…"）、选项命名空间
                 （services.pipewire.*）、罕见标识符。特征出现文件数 > 3 视为通用
                 词丢弃。人工写的条目一律保留，人工把「自动：」前缀删掉即接管。

行为约定
    幂等：条目顺序、人工批注、自动条目的呈现都稳定；无变化不写文件。
    只改写已存在的文件（不新建），所以以 root 运行也不会产生属主变化。
    只改注释块，从不改代码：删掉某个 .nix 后，别的文件头部里指向它的行会被清掉
    （上游/下游每次重算，相关做路径存在性检查），但代码里的 import 不动，
    只在报告里给出「指向不存在文件的引用」，配合 --strict 可让 --check 失败。
    写盘用临时文件 + os.replace，并复制原文件的属主/权限 —— 以 root 跑（activation）
    也不会把 /etc/nixos 里的文件变成 root 所有，中途中断也不会留下半截文件。
"""

import argparse
import difflib
import json
import os
import re
import stat
import sys
import tempfile

SEP = "# " + "\u2500" * 60
MARK = "# 文件关联（仅 /etc/nixos 范围）"
EMPTY = "无"
AUTO_TAG = "自动："

FIELDS = (
    ("upstream", "上游（引用本文件）"),
    ("downstream", "下游（本文件引用）"),
    ("related", "相关（语义关联）"),
)

# flake.nix 只作为「引用源」参与推导，本身不写头部；flake.lock 不是 nix 文件。
EXCLUDE_FILES = {"flake.nix", "flake.lock"}
# 另一套配置，不参与。
EXCLUDE_TOP_DIRS = {"guix-configuration"}
EXCLUDE_DIRS = {".git"}

REF_RE = re.compile(r"(?<![A-Za-z0-9._+/-])(\.{1,2}/[A-Za-z0-9._+/-]*)")
FIELD_RE = re.compile(r"^#   (\S+?)：(.*)$")
ITEM_RE = re.compile(r"^#     - (.*)$")
NOTE_RE = re.compile(r"^(.*?)（(.*)）$")

def write_atomic(path, text):
    """同目录临时文件 + os.replace，避免写到一半被中断把文件截断。

    顺手保住属主与权限：root 跑（activation）时若直接 replace，新文件会变成
    root 所有，所以先把 uid/gid/mode 复制到临时文件上。
    """
    st = os.stat(path)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".file-map-", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(text)
            fh.flush()
            os.fsync(fh.fileno())
        os.chmod(tmp, stat.S_IMODE(st.st_mode))
        if (st.st_uid, st.st_gid) != (os.getuid(), os.getgid()):
            os.chown(tmp, st.st_uid, st.st_gid)
        os.replace(tmp, path)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


# ── 语义特征 ─────────────────────────────────────────────────────
UNIT_RE = re.compile(r"^[A-Za-z0-9@._-]+\.(service|target|socket|timer|mount|path|slice)$")
IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_.+-]*")
ABS_RE = re.compile(r'"(\/[A-Za-z0-9._+\/-]+)"')
DIR_RE = re.compile(r'"([A-Za-z0-9._+-]+)\/[A-Za-z0-9._+-]')
OPT_RE = re.compile(r"^\s*([a-zA-Z][A-Za-z0-9_-]*\.[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)*)\s*=", re.M)

SEM_W = {"path": 3.0, "unit": 3.0, "pkg": 2.0, "dir": 2.0, "opt": 1.5, "id": 1.0}
SEM_MAX_DF = 3          # 出现在超过 3 个文件里的特征算通用词，丢掉
SEM_MIN_SCORE = 2.0     # 低于该分值不认为相关
SEM_MAX_ITEMS = 3       # 每个文件最多自动补几条

STOP = set("""
lib pkgs config inputs enable name source text type true false null path system with let in then
else inherit assert rec optional optionals mkIf mkMerge mkDefault mkForce mkBefore mkAfter mkOption
out dev version description default args super self final prev settings build root paths buildInputs
nativeBuildInputs makeWrapper postBuild postInstall preBuild old new for done case echo mkdir install
exe prefix opt bin share man doc etc package packages module modules imports outputs nixpkgs home xdg
time zone locale size executable hostPlatform stdenv optionalString concatStringsSep mapAttrs
filterAttrs attrNames attrValues foldl genAttrs listToAttrs nameValuePair mkEnableOption
callPackage override overrideAttrs fetchurl fetchFromGitHub unpackPhase installPhase stdenvNoCC
runCommand writeShellScriptBin writeTextFile mkDerivation while fi sudo env symlinkJoin mkShell
homepage license maintainers sha256 sha1 download github com pname dates weekly meta srcs
dontBuild dontConfigure dontCheck dontFixup dontStrip dontPatchElf installCheck doCheck unpackPhase
wrapProgram makeDesktopItem copyDesktopItems mkPackageOption getExe toString mapAttrs toJSON
lowPrio hiPrio optionalAttrs optionalString concatMapStringsSep stringAfter replaceStrings
Type ExecStart ExecStartPre ExecStop ExecReload Restart RestartSec WantedBy wantedBy serviceConfig
ServiceConfig ProtectSystem StateDirectory ReadWritePaths AmbientCapabilities NoNewPrivileges
PrivateTmp UserGroup TimeoutStartSec Persistent OnCalendar RandomizedDelaySec timers
after wants before requires partOf conflicts startAt postStart preStop script serviceConfig
""".split())


# ── 词法：剥注释，可选屏蔽字符串内容 ─────────────────────────────
def _interp_end(src, i):
    """从 ${ 之后开始找配对的 }，返回其后的下标（用于保留 '' 块里的 nix 插值）。"""
    depth, n = 1, len(src)
    while i < n and depth:
        c = src[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        elif c == '"':
            i += 1
            while i < n and src[i] != '"':
                if src[i] == "\\":
                    i += 1
                i += 1
        i += 1
    return i


def sanitize(src, mask_strings):
    """返回与原文等长的文本：注释变空格；mask_strings 时普通字符串内容也变空格。

    字符串内容永远不参与「路径引用」的推导（避免把文案当 import），
    但参与语义特征提取（挂载点、配置目录都写在字符串里）。
    """
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == "#":
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif src[i:i + 2] == "/*":
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append(" " * (j - i))
            i = j
        elif c == '"':
            out.append('"')
            i += 1
            while i < n:
                if src[i] == "\\" and i + 1 < n:
                    out.append("  " if mask_strings else src[i:i + 2])
                    i += 2
                elif src[i] == '"':
                    out.append('"')
                    i += 1
                    break
                else:
                    out.append(" " if mask_strings else src[i])
                    i += 1
        elif src[i:i + 2] == "''":
            # 缩进字符串多是 shell 片段，内容一律屏蔽，避免 done/echo 之类噪音
            out.append("''")
            i += 2
            while i < n:
                if src[i:i + 3] == "'''":
                    out.append("   ")
                    i += 3
                elif src[i:i + 2] == "''":
                    out.append("''")
                    i += 2
                    break
                elif src[i:i + 2] == "${":
                    j = _interp_end(src, i + 2)
                    out.append(src[i:j])
                    i = j
                else:
                    out.append(" ")
                    i += 1
        else:
            out.append(c)
            i += 1
    return "".join(out)


def resolve(ref, src_path):
    """路径字面量 → 真实文件：支持 ../、无扩展名、目录→default.nix。"""
    base = os.path.dirname(src_path)
    p = os.path.normpath(os.path.join(base, ref))
    cands = [p]
    if not p.endswith(".nix"):
        cands.append(p + ".nix")
    cands.append(os.path.join(p, "default.nix"))
    for c in cands:
        if os.path.isfile(c):
            return c
    return None


# ── 头部注释：解析 / 渲染 ─────────────────────────────────────────
def split_note(item):
    m = NOTE_RE.match(item)
    if m:
        return m.group(1).strip(), m.group(2).strip()
    return item.strip(), ""


def join_note(path, note):
    return path + ("（%s）" % note if note else "")


def parse_header(text):
    """返回 ((start, end), {key: [(path, note), ...]})，没有头部则 (None, {})。"""
    lines = text.split("\n")
    idx = None
    for i, line in enumerate(lines[:80]):
        if line.rstrip() == MARK:
            idx = i
            break
    if idx is None:
        return None, {}

    start = idx - 1 if idx and lines[idx - 1].rstrip() == SEP else idx
    end = None
    for j in range(idx + 1, len(lines)):
        if lines[j].rstrip() == SEP:
            end = j
            break
    if end is None:  # 头部破损：退到连续注释块的末尾
        end = idx
        while end + 1 < len(lines) and (lines[end + 1].startswith("#") or not lines[end + 1].strip()):
            end += 1

    fields = {k: [] for k, _ in FIELDS}
    label_to_key = {v: k for k, v in FIELDS}
    cur = None
    for line in lines[start:end + 1]:
        m = FIELD_RE.match(line)
        if m and m.group(1) in label_to_key:
            cur = label_to_key[m.group(1)]
            val = m.group(2).strip()
            if val and val != EMPTY:
                fields[cur].append(split_note(val))
            continue
        m = ITEM_RE.match(line)
        if m and cur:
            fields[cur].append(split_note(m.group(1)))
    return (start, end), fields


def merge_edges(old, new_paths, ref_order=None):
    """旧条目保留原顺序与原批注；新增项按 ref_order（代码出现顺序）插入。"""
    notes = {p: n for p, n in old}
    kept = [p for p, _ in old if p in new_paths]
    added = [p for p in new_paths if p not in notes]
    if ref_order is None:
        kept.extend(sorted(added))
    else:
        for p in added:
            if p not in ref_order:
                kept.append(p)
                continue
            idx = ref_order.index(p)
            prev = next((q for q in reversed(ref_order[:idx]) if q in kept), None)
            kept.insert(kept.index(prev) + 1 if prev else 0, p)
    return [join_note(p, notes.get(p, "")) for p in kept]


def merge_related(old, auto, mode, root, max_items, by_name=None):
    """相关 = 人工条目（保留，改名的自动跟上） + 自动证据条目（每次重算）。

    返回 (条目, 失效路径, 改名跟随列表)。
    """
    if mode == "off":
        return [join_note(p, n) for p, n in old], [], []

    hand = [(p, n) for p, n in old if not n.startswith(AUTO_TAG)]
    if mode == "auto":  # 完全重算：人工条目一并丢弃
        hand = []

    keep, missing, renamed = [], [], []
    for p, n in hand:
        if p and "/" in p and not os.path.exists(os.path.join(root, p)):
            # 文件名唯一时认为是改名/搬家，跟着改路径而不是丢掉这条关联
            alt = (by_name or {}).get(os.path.basename(p), [])
            alt = [a for a in alt if a != p]
            if len(alt) == 1:
                renamed.append((p, alt[0]))
                p = alt[0]
            else:
                missing.append(p)
                continue
        keep.append((p, n))

    items = [join_note(p, n) for p, n in keep]
    have = {p for p, _ in keep}
    used = 0
    for score, other, toks in auto:
        if used >= max_items:
            break
        if other in have:
            continue
        items.append(join_note(other, AUTO_TAG + "共享 " + "、".join(toks[:2])))
        have.add(other)
        used += 1
    return items, missing, renamed


def render(upstream, downstream, related):
    body = [SEP, MARK]
    for key, label in FIELDS:
        items = {"upstream": upstream, "downstream": downstream, "related": related}[key]
        head = "#   %s：" % label
        if not items:
            body.append(head + EMPTY)
        elif len(items) == 1:
            body.append(head + items[0])
        else:
            body.append(head)
            body.extend("#     - " + it for it in items)
    body.append(SEP)
    return body


def splice(text, span, block):
    """用新头部替换旧头部；头部与正文之间恰好一个空行。"""
    lines = text.split("\n")
    rest = lines[span[1] + 1:] if span else lines
    while rest and not rest[0].strip():
        rest.pop(0)
    new = block + [""] + rest
    if text.endswith("\n") and new[-1] != "":
        new.append("")
    return "\n".join(new)


# ── 语义特征 ─────────────────────────────────────────────────────
def features(text):
    f = set()
    for m in ABS_RE.finditer(text):
        parts = [p for p in m.group(1).split("/") if p]
        if parts:
            f.add(("path", "/" + "/".join(parts[:2])))
    for m in DIR_RE.finditer(text):
        f.add(("dir", m.group(1)))
    for m in OPT_RE.finditer(text):
        parts = m.group(1).split(".")
        if parts[0] in STOP or len(parts[0]) < 3:
            continue
        f.add(("opt", ".".join(parts[:2])))
    for m in IDENT_RE.finditer(text):
        t = m.group(0).strip(".")
        if (m.start() and text[m.start() - 1] == "/") or text[m.end():m.end() + 1] == "/":
            continue  # 路径碎片（/var/lib 里的 var）
        if UNIT_RE.match(t):
            f.add(("unit", t))
            continue
        if t.startswith("pkgs.") and len(t) > 5:
            name = t[5:].split(".")[0]
            if name not in STOP and len(name) >= 2:
                f.add(("pkg", name))
            continue
        if len(t) < 3 or t in STOP or t.isdigit():
            continue
        if t.startswith(("lib.", "builtins.", "config.", "inputs.")):
            continue
        f.add(("id", t))
    return f


def semantic_map(texts, min_score):
    """texts: {abs_path: 语义文本}，返回 {abs_path: [(score, other, tokens), ...]}。"""
    per = {p: features(t) for p, t in texts.items()}
    df = {}
    for feats in per.values():
        for ft in feats:
            df[ft] = df.get(ft, 0) + 1

    paths = sorted(per)
    scored = {}
    for i, p in enumerate(paths):
        for q in paths[i + 1:]:
            shared = per[p] & per[q]
            if not shared:
                continue
            score, toks = 0.0, []
            for kind, tok in shared:
                d = df[(kind, tok)]
                if d > SEM_MAX_DF:
                    continue
                score += SEM_W[kind] * (1.0 if d == 2 else 0.6)
                toks.append((SEM_W[kind], tok))
            if score >= min_score:
                toks.sort(key=lambda x: (-x[0], x[1]))
                scored[(p, q)] = (score, [t for _, t in toks])

    out = {p: [] for p in paths}
    for (p, q), (score, toks) in scored.items():
        out[p].append((score, q, toks))
        out[q].append((score, p, toks))
    for p in out:
        out[p].sort(key=lambda x: (-x[0], x[1]))
    return out


# ── 扫描 / 建图 ──────────────────────────────────────────────────
def collect(root):
    files = []
    for dirpath, dirnames, filenames in os.walk(root):
        reldir = os.path.relpath(dirpath, root).replace(os.sep, "/")
        dirnames[:] = sorted(
            d for d in dirnames
            if d not in EXCLUDE_DIRS and not (reldir == "." and d in EXCLUDE_TOP_DIRS)
        )
        for f in sorted(filenames):
            if f.endswith(".nix"):
                files.append(os.path.join(dirpath, f))
    return files


def display(path, root):
    return os.path.relpath(path, root).replace(os.sep, "/")


def build(root, files):
    real_root = os.path.realpath(root)
    downstream, broken, resources, seq, sem = {}, [], {}, {}, {}
    for src in files:
        with open(src, encoding="utf-8") as fh:
            raw = fh.read()
        code = sanitize(raw, mask_strings=True)
        hits, res, order = set(), set(), []
        for m in REF_RE.finditer(code):
            ref = m.group(1).rstrip(".")
            tgt = resolve(ref, src)
            if tgt is None:
                if ref.endswith(".nix"):
                    broken.append((display(src, root), ref))
                continue
            real = os.path.realpath(tgt)
            if not real.startswith(real_root + os.sep):
                continue
            if real == os.path.realpath(src):
                continue  # src = ./.; 这种自引用
            if tgt.endswith(".nix"):
                hits.add(real)
                d = display(tgt, root)
                if d not in order:
                    order.append(d)
            else:
                res.add(display(tgt, root))
        key = os.path.realpath(src)
        downstream[key] = sorted(hits)
        seq[key] = order
        resources[key] = sorted(res)
        sem[key] = sanitize(raw, mask_strings=False)
    return downstream, broken, resources, seq, sem


# 目录被"整体搬进 store"的用法：src = ./.; source = ./dir; PYTHONPATH=${./dir}
SRC_LIKE_RE = re.compile(r"(src|source|PYTHONPATH)\s*=\s*[^;]*$")
# 构建残留：目录被整体引用时看不出"没人用"，但这些东西基本可以删
JUNK_RE = re.compile(
    r"(^|/)(__pycache__|\.direnv|\.venv|\.pytest_cache|result|result-[^/]+|build|dist|node_modules)(/|$)"
    r"|[^/]+\.egg-info(/|$)"
    r"|\.(pyc|pyo|orig|rej|bak|swp)$|~$"
)


def scan_references(root, files):
    """返回 (被直接引用的文件, 被整体引用的目录)。"""
    refd_files, refd_dirs = set(), set()
    for src in files:
        with open(src, encoding="utf-8") as fh:
            code = sanitize(fh.read(), mask_strings=True)
        for m in REF_RE.finditer(code):
            ref = m.group(1).rstrip(".")
            p = os.path.normpath(os.path.join(os.path.dirname(src), ref))
            if os.path.isdir(p):
                # import ./dir 只会拿 default.nix；src = ./dir 才是整棵树
                pre = code[max(0, m.start() - 40):m.start()]
                if SRC_LIKE_RE.search(pre) or not os.path.isfile(os.path.join(p, "default.nix")):
                    refd_dirs.add(os.path.realpath(p))
                else:
                    refd_files.add(os.path.realpath(os.path.join(p, "default.nix")))
            else:
                t = resolve(ref, src)
                if t:
                    refd_files.add(os.path.realpath(t))
    return refd_files, refd_dirs


def unreferenced(root, files):
    """configuration/ 下没人用的资源文件，分两档返回 (未被引用, 疑似构建残留)。"""
    real_root = os.path.realpath(root)
    refd_files, refd_dirs = scan_references(root, files)

    def in_refd_dir(path):
        d = os.path.dirname(path)
        while len(d) > len(real_root):
            if d in refd_dirs:
                return True
            d = os.path.dirname(d)
        return False

    unused, junk = [], []
    base = os.path.join(real_root, "configuration")
    for dirpath, dirnames, filenames in os.walk(base):
        dirnames[:] = sorted(d for d in dirnames if d not in EXCLUDE_DIRS)
        for f in sorted(filenames):
            if f.endswith(".nix"):
                continue
            p = os.path.realpath(os.path.join(dirpath, f))
            rel = display(p, root)
            size = os.path.getsize(p)
            if p in refd_files:
                continue
            if in_refd_dir(p):
                if JUNK_RE.search(rel):
                    junk.append((size, rel))
                continue
            unused.append((size, rel))

    unused.sort(reverse=True)
    junk.sort(reverse=True)
    return unused, junk


def main():
    ap = argparse.ArgumentParser(
        prog="nixos-file-map",
        description="自动维护 .nix 文件的「文件关联」头部注释（默认写入）",
    )
    ap.add_argument("--root", default="/etc/nixos", help="仓库根目录（默认 /etc/nixos）")
    ap.add_argument("--check", action="store_true", help="只校验不同步，有差异则退出码 1")
    ap.add_argument("--strict", action="store_true",
                    help="断链引用或失效的相关条目也算失败（配合 --check 做 pre-commit）")
    ap.add_argument("--dry-run", action="store_true", help="打印 diff，不写文件")
    ap.add_argument("--json", action="store_true", help="以 JSON 输出结果")
    ap.add_argument("--graph", action="store_true", help="从 flake.nix 打印引用树")
    ap.add_argument("--stale-files", action="store_true",
                    help="列出 configuration/ 下没被任何 .nix 引用的资源文件（只读）")
    ap.add_argument("--related", choices=("merge", "auto", "off"), default="merge",
                    help="相关：merge=保留人工+自动补充(默认) / auto=完全重算 / off=不动")
    ap.add_argument("--related-min", type=float, default=SEM_MIN_SCORE,
                    help="语义相关的最低分值（默认 %.1f）" % SEM_MIN_SCORE)
    ap.add_argument("--related-max", type=int, default=SEM_MAX_ITEMS,
                    help="每个文件最多自动补几条（默认 %d）" % SEM_MAX_ITEMS)
    ap.add_argument("-v", "--verbose", action="store_true", help="输出孤立文件与外部资源")
    args = ap.parse_args()

    # 只读模式：任何"看一眼"的开关都不写盘
    readonly = args.check or args.dry_run or args.json or args.stale_files

    root = os.path.abspath(args.root)
    if not os.path.isdir(root):
        sys.exit("根目录不存在: %s" % root)

    files = collect(root)
    downstream, broken, resources, seq, sem = build(root, files)

    upstream = {p: [] for p in downstream}
    for src, tgts in downstream.items():
        for t in tgts:
            upstream[t].append(src)

    auto_rel = semantic_map(sem, args.related_min) if args.related != "off" else {}

    # 文件名 → 路径，用于"相关"条目跟随改名（只认唯一匹配）
    by_name = {}
    for f in files:
        by_name.setdefault(os.path.basename(f), []).append(display(f, root))

    targets = [p for p in files if display(p, root) not in EXCLUDE_FILES]

    changed, stale, renamed = [], [], []
    for path in sorted(targets):
        rel = display(path, root)
        rp = os.path.realpath(path)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        span, old = parse_header(text)

        up = sorted({display(s, root) for s in upstream.get(rp, [])})
        down = sorted({display(t, root) for t in downstream.get(rp, [])})
        neighbours = set(up) | set(down)

        cands = []
        for score, other, toks in auto_rel.get(rp, []):
            d = display(other, root)
            if d in neighbours or d == rel:
                continue
            cands.append((score, d, toks))

        related, missing, moved = merge_related(
            old.get("related", []), cands, args.related, root, args.related_max, by_name)
        for p in missing:
            stale.append((rel, p))
        for old_p, new_p in moved:
            renamed.append((rel, old_p, new_p))

        block = render(
            merge_edges(old.get("upstream", []), up),
            merge_edges(old.get("downstream", []), down, seq.get(rp, [])),
            related,
        )
        new_text = splice(text, span, block)
        if new_text == text:
            continue
        changed.append(rel)

        if args.dry_run:
            if not args.json:
                sys.stdout.writelines(difflib.unified_diff(
                    text.splitlines(True), new_text.splitlines(True),
                    fromfile="a/" + rel, tofile="b/" + rel, n=2))
        elif not readonly and not args.json:
            write_atomic(path, new_text)

    orphans = sorted(
        display(p, root) for p in targets if not upstream.get(os.path.realpath(p), [])
    )

    unused_files, junk_files = unreferenced(root, files) if (args.stale_files or args.json) else ([], [])

    if args.json:
        print(json.dumps({
            "scanned": len(targets),
            "changed": changed,
            "broken": broken,
            "orphans": orphans,
            "stale": stale,
            "renamed": [{"file": f, "from": a, "to": b} for f, a, b in renamed],
            "stale_files": {
                "unused": [{"path": p, "size": sz} for sz, p in unused_files],
                "junk": [{"path": p, "size": sz} for sz, p in junk_files],
            },
        }, ensure_ascii=False, indent=2))
    else:
        if not args.dry_run:
            print("扫描 %d 个 .nix 文件，%s %d 个"
                  % (len(targets), "待更新" if readonly else "已更新", len(changed)))
        if changed and args.check:
            print("需要更新:")
            for c in changed:
                print("  - " + c)
        if broken:
            print("⚠ 指向不存在文件的引用 %d 处:" % len(broken))
            for src, ref in broken[:20]:
                print("  - %s → %s" % (src, ref))
        if renamed:
            print("ℹ 「相关」条目跟随改名 %d 处:" % len(renamed))
            for src, old_p, new_p in renamed[:20]:
                print("  - %s: %s → %s" % (src, old_p, new_p))
        if stale:
            print("⚠ 失效的「相关」条目 %d 处（路径已不存在，已移除）:" % len(stale))
            for src, p in stale[:20]:
                print("  - %s → %s" % (src, p))
        if args.stale_files:
            unused, junk = unreferenced(root, files)
            total = sum(sz for sz, _ in unused)
            print("未被任何 .nix 引用（configuration/ 下，共 %d 个 / %.1f MB，删前确认）:"
                  % (len(unused), total / 1048576))
            for sz, p in unused:
                print("  %9.1f KB  %s" % (sz / 1024, p))
            if not unused:
                print("  （无）")
            if junk:
                print("目录被整体引用、但看着像构建残留:")
                for sz, p in junk:
                    print("  %9.1f KB  %s" % (sz / 1024, p))

        if args.verbose:
            if orphans:
                print("未被引用的文件（拓扑孤立，通常是注释停用）:")
                for o in orphans:
                    print("  - " + o)
            print("外部资源引用（非 .nix 文件）:")
            for src in sorted(resources):
                for r in resources[src]:
                    print("  - %s → %s" % (display(src, root), r))

    if args.graph:
        flake = os.path.realpath(os.path.join(root, "flake.nix"))
        seen = set()

        def walk(p, depth):
            print("  " * depth + ("└─ " if depth else "") +
                  ("flake.nix" if p == flake else display(p, root)))
            if p in seen or depth > 12:
                return
            seen.add(p)
            for k in downstream.get(p, []):
                if display(k, root) not in EXCLUDE_FILES:
                    walk(k, depth + 1)

        walk(flake, 0)

    failed = (args.check and changed) or (args.strict and (broken or stale))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
