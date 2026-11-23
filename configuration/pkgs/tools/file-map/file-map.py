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
    相关         证据推导，分两档：
                 ① 结构化（硬）：同一个挂载点、同一个 systemd 单元、同一条完整
                    option 路径（fileSystems.*.neededForBoot，引号段归一成 *）；
                 ② 使用关系（硬，定向）：本文件用了仓库里定义的包，或把包 X 装进
                    包清单而仓库里正好有 X/ 或 X.nix（包在此安装、配置在彼）。
                 ③ 名字（中）：本仓库自己定义的名字（包名/文件名主干/目录名/mkOption
                    声明的 option）才算数——来自 nixpkgs 的通用名字（alsa-lib、dbus）
                    不参与分数，只用于批注兜底，因为「都依赖同一个库」不等于相关。
                    名字要出现在代码或短字面量里（extraGroups = ["libvirtd"]），
                    只在描述文案里出现的不算（description = "mango compositor session"
                    里的 session）。
                 同一对关系，两个文件各拿一份措辞：装包的一侧「使用 X」，
                 提供方那侧「X 的定义 / X 的配置」。
                 特征出现在太多文件里视为通用词丢弃（df 上限随文件数放宽，封顶 12）。
                 人工写的条目一律保留，把「自动：」前缀删掉即接管。

行为约定
    幂等：条目顺序、人工批注、自动条目的呈现都稳定；无变化不写文件。
    只改写已存在的文件（不新建），所以以 root 运行也不会产生属主变化。
    只改注释块，从不改代码；头部之前的内容（shebang、版权注释）原样保留。
    删掉某个 .nix 后，别的文件头部里指向它的行会被清掉（上游/下游每次重算，
    相关做路径存在性检查），但代码里的 import 不动，只在报告里给出
    「指向不存在文件的引用」，配合 --strict 可让 --check 失败。
    只读开关（--check/--dry-run/--json/--stale-files/--explain-related/--graph/
    --strict）一律不写盘；--graph 可以单独安全使用。
    符号链接不替换（跳过并报告）；单个文件读/写失败只记录，不阻断其它文件。
    pathExists 这种允许目标不存在的探测不算断链。
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
PATH_EXISTS_RE = re.compile(r"\bpathExists\s*\(?\s*$")
IMPORT_RE = re.compile(r"\b(?:import|callPackage)\s*\(?\s*$")
FIELD_RE = re.compile(r"^#   (\S+?)：(.*)$")
ITEM_RE = re.compile(r"^#     - (.*)$")
NOTE_RE = re.compile(r"^(.*?)（(.*)）$")

def write_atomic(path, text):
    """同目录临时文件 + os.replace，避免写到一半被中断把文件截断。

    顺手保住属主与权限：root 跑（activation）时若直接 replace，新文件会变成
    root 所有，所以先把 uid/gid/mode 复制到临时文件上。
    拒绝写入符号链接：os.replace 会替换链接本身，而不是它指向的文件。
    """
    if os.path.islink(path):
        raise OSError("拒绝改写符号链接: %s" % path)
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
# 特征分成两档，这是「更智能」的关键：
#   结构化证据（同一个挂载点 / 同一个 systemd 单元 / 同一条完整 option 路径 /
#               引用了本仓库自己定义的包）——两个文件撞上它就基本真的相关；
#   词面证据（标识符）——只有本仓库自己定义的名字（包名、文件名、option 名）才给分，
#               来自 nixpkgs 的通用名字（alsa-lib、dbus、mesa…）几乎不给分：
#               "两个文件都依赖同一个库"不等于它们相关。
UNIT_RE = re.compile(r"^[A-Za-z0-9@._-]+\.(service|target|socket|timer|mount|path|slice)$")
IDENT_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_.+-]*")
ABS_RE = re.compile(r'"(\/[A-Za-z0-9._+\/-]+)"')
DIR_RE = re.compile(r'"([A-Za-z0-9._+-]+)\/[A-Za-z0-9._+-]')
# 完整 option 路径：foo.bar."带引号的段".baz = …（引号段归一成 *）
OPT_RE = re.compile(
    r"^\s*([A-Za-z][\w-]*(?:\s*\.\s*(?:[A-Za-z_][\w-]*|\"[^\"]*\"))+)\s*=", re.M)
CALLPKG_RE = re.compile(r"([A-Za-z0-9._'-]+)\s*=\s*pkgs\.callPackage\s+(\S+)")
# option 路径的头部：只排除真正的「表达式前缀」。
# `nixpkgs.*`、`home.*`、`system.*` 是模块命名空间，必须保留 —— 它们在 STOP 表里
# 只是为了过滤「裸标识符」，不能拿来砍 option 路径（否则 nixpkgs.config.* 会被当成
# 普通标识符，权重从 2.0 掉到 0.2，nix 侧与 home 侧的配置分工就永远发现不了）。
OPT_HEAD_STOP = {"lib", "builtins", "pkgs", "inputs", "config", "self", "super",
                 "final", "prev", "args", "stdenv", "meta", "src"}
LITERAL_RE = re.compile(r'"([^"\\\n]+)"')
# 出现在点号后面时不算特征的名字（文件扩展名 / 模块后缀）
EXT_STOP = {"nix", "py", "sh", "bash", "fish", "json", "jsonc", "yaml", "yml", "toml",
            "conf", "ini", "css", "lua", "desktop", "lock", "md", "txt", "svg", "png", "jpg"}
MKOPT_RE = re.compile(r"([A-Za-z][\w-]*(?:\.[\w-]+)*)\s*=\s*(?:lib\.)?mkOption\b")

SEM_W = {"path": 3.0, "unit": 3.0, "opt": 2.0, "dir": 1.5, "id_l": 2.0, "id_x": 0.2}
SEM_USES = 3.0                              # 「用了本仓库里的包」这条边
# df>2 时的折扣：结构化证据不打折，通用 option 前缀、标识符打折。
SEM_PENALTY = {"path": 1.0, "unit": 1.0, "uses": 1.0, "id_l": 0.6,
               "opt": 0.8, "dir": 0.6, "id_x": 0.6}
SEM_STRONG = {"path", "unit", "opt", "uses", "id_l"}  # 单条证据就能成立
SEM_MAX_DF = 3          # df 上限的下界（实际随文件数放宽，见 df_cutoff）
SEM_MIN_SCORE = 2.0     # 低于该分值不认为相关
SEM_MAX_ITEMS = 3       # 每个文件最多自动补几条
# 证据在批注里的说法（越靠前越"硬"）
SEM_PHRASE = {"uses": "使用", "path": "同用", "unit": "同关",
              "opt": "同设", "dir": "同配目录", "id_l": "同名"}

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
            i += 1
        elif c == "}":
            depth -= 1
            i += 1
        elif c == '"':
            i += 1
            while i < n and src[i] != '"':
                if src[i] == "\\" and i + 1 < n:
                    i += 2
                else:
                    i += 1
            if i < n:
                i += 1
        elif src[i:i + 3] == "''\\":
            i += 4 if i + 3 < n else 3
        elif src[i:i + 3] == "'''":
            i += 3
        elif src[i:i + 3] == "''$":
            i += 3
        elif src[i:i + 2] == "''":
            i += 2
            while i < n:
                if src[i:i + 3] == "'''":
                    i += 3
                elif src[i:i + 3] == "''\\":
                    i += 4 if i + 3 < n else 3
                elif src[i:i + 3] == "''$":
                    i += 3
                elif src[i:i + 2] == "''":
                    i += 2
                    break
                elif src[i:i + 2] == "${":
                    i = _interp_end(src, i + 2)
                else:
                    i += 1
        elif src[i:i + 2] == "/*":
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
        elif c == "#":
            j = src.find("\n", i + 1)
            i = n if j < 0 else j
        else:
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
                elif src[i:i + 2] == "${":
                    j = _interp_end(src, i + 2)
                    if mask_strings and j > i + 2 and src[j - 1] == "}":
                        # 插值里是代码，保留；其中的字符串仍要屏蔽，避免把文案路径当 import
                        out.append("${" + sanitize(src[i + 2:j - 1], True) + "}")
                    else:
                        out.append(src[i:j])
                    i = j
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
                elif src[i:i + 3] == "''\\":
                    take = 4 if i + 3 < n else 3
                    out.append(" " * take)
                    i += take
                elif src[i:i + 3] == "''$":
                    # ''$ 是缩进字符串里对 $ 的转义（例如 ''${ 是字面量 ${）
                    out.append("   ")
                    i += 3
                elif src[i:i + 2] == "''":
                    out.append("''")
                    i += 2
                    break
                elif src[i:i + 2] == "${":
                    j = _interp_end(src, i + 2)
                    if mask_strings and j > i + 2 and src[j - 1] == "}":
                        out.append("${" + sanitize(src[i + 2:j - 1], True) + "}")
                    else:
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
    """路径字面量 → 真实文件：支持 ../、无扩展名、目录→default.nix。

    目录优先按 Nix 语义处理：./foo 指向目录时只看 foo/default.nix，
    不会为了「猜」目标而落到同级的 foo.nix。
    """
    base = os.path.dirname(src_path)
    p = os.path.normpath(os.path.join(base, ref))
    if os.path.isdir(p):
        cand = os.path.join(p, "default.nix")
        return cand if os.path.isfile(cand) else None
    cands = [p]
    if not p.endswith(".nix"):
        cands.append(p + ".nix")
    for c in cands:
        if os.path.isfile(c):
            return c
    return None


def within_root(path, root):
    """realpath 后判断 path 是否仍在 root 内（root 本身也算）。"""
    real_root = os.path.realpath(root)
    real = os.path.realpath(path)
    if real_root == os.sep:
        return real.startswith(os.sep)
    return real == real_root or real.startswith(real_root + os.sep)


def in_imports_list(code, pos):
    """path 是否位于 imports = [ … ] 的括号里（支持跨行、嵌套列表）。"""
    depth = 0
    for j in range(pos - 1, -1, -1):
        c = code[j]
        if c == "]":
            depth += 1
        elif c == "[":
            if depth:
                depth -= 1
            else:
                head = code[max(0, j - 40):j]
                return bool(re.search(r"\bimports\s*=\s*$", head))
    return False


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
    for i, line in enumerate(lines):
        if line.rstrip() == MARK:
            idx = i
            break
    if idx is None:
        return None, {}

    label_to_key = {v: k for k, v in FIELDS}
    start = idx - 1 if idx and lines[idx - 1].rstrip() == SEP else idx
    end = None
    for j in range(idx + 1, len(lines)):
        if lines[j].rstrip() == SEP:
            end = j
            break
    if end is None:
        # 头部破损：只吞头部认得的内容，遇到普通注释就停，避免把正文注释删掉
        end = idx
        while end + 1 < len(lines):
            nxt = lines[end + 1]
            if not nxt.strip():
                break
            m = FIELD_RE.match(nxt)
            if m and m.group(1) in label_to_key:
                end += 1
                continue
            if ITEM_RE.match(nxt):
                end += 1
                continue
            break

    fields = {k: [] for k, _ in FIELDS}
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
        if p and p != EMPTY and not os.path.exists(os.path.join(root, p)):
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
    for score, other, note in auto:
        if used >= max_items:
            break
        if other in have:
            continue
        items.append(join_note(other, AUTO_TAG + note))
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
    """用新头部替换旧头部；头部与正文之间恰好一个空行。

    头部之前的内容（shebang、版权注释等）必须原样保留：不能把新头部
    直接拼到全文最前面。无头部时也把 shebang 留在第一行。
    """
    lines = text.split("\n")
    prefix = lines[:span[0]] if span else []
    rest = lines[span[1] + 1:] if span else lines
    if span is None:
        while rest and rest[0].startswith("#!"):
            prefix.append(rest.pop(0))
    while rest and not rest[0].strip():
        rest.pop(0)
    new = prefix + block + [""] + rest
    if text.endswith("\n") and new[-1] != "":
        new.append("")
    return "\n".join(new)


# ── 语义特征 ─────────────────────────────────────────────────────
def df_cutoff(n_files):
    """df 上限：仓库越大，越允许一个特征多出现几处，但设上界。

    下界：写死 3 的话，加十几个文件之后，原本 df=4 的真关联会被判成"通用词"而消失。
    上界：不设的话仓库长到 500 个文件时上限会到 40，"稀有"就失去意义了。
    上界 12 的含义是"出现在十几个以上文件里的词，无论仓库多大都算通用词"。
    """
    return max(SEM_MAX_DF, min(12, -(-n_files // 12)))


def package_defs(texts, root):
    """本仓库自定义包：{包名: 定义文件 realpath}，以及 {包名: 在哪定义的}。

    texts 必须已剥掉注释（sem），否则注释掉的 callPackage 会被当成定义。
    只认「名字和定义文件对得上」的绑定（等于文件名主干、目录名或该包的 pname），
    否则 `let package = pkgs.callPackage …;` 这种局部变量会被当成一个叫 package 的包。
    """
    real_root = os.path.realpath(root)
    self_names = {}
    for p, raw in texts.items():
        real = os.path.realpath(p)
        if p.endswith(".nix"):
            stem = os.path.basename(p)[:-4]
            names = {stem}
            if stem == "default":
                names.add(os.path.basename(os.path.dirname(p)))
        else:
            names = {os.path.basename(p)}
        for m in re.finditer(r'^\s*pname\s*=\s*"([A-Za-z0-9._+-]+)"', raw, re.M):
            names.add(m.group(1))
        self_names[real] = names

    defs, definer = {}, {}
    for p, raw in texts.items():
        for m in CALLPKG_RE.finditer(raw):
            attr, ref = m.group(1), m.group(2)
            tgt = os.path.normpath(os.path.join(os.path.dirname(p), ref))
            if not tgt.endswith(".nix"):
                tgt = os.path.join(tgt, "default.nix")
            if not os.path.isfile(tgt):
                continue
            real = os.path.realpath(tgt)
            if not within_root(real, real_root):
                continue
            if attr not in self_names.get(real, ()):
                continue
            defs[attr] = real
            definer.setdefault(attr, set()).add(p)
    return defs, definer


def self_names(path):
    """这个文件"代表"的名字：文件名主干；default.nix 则用所在目录名。

    `waybar/default.nix` 里不会出现 "waybar" 这个词，但别处装包/写配置时会出现，
    所以要把「我是谁」也算成一条特征，否则「包在此安装、配置在彼」这类关系永远发现不了。
    """
    stem = os.path.basename(path)[:-4] if path.endswith(".nix") else os.path.basename(path)
    if stem == "default":
        return {os.path.basename(os.path.dirname(path))}
    return {stem} if len(stem) >= 4 else set()


def local_vocabulary(defs, texts):
    """本仓库"定义"过的名字：包名、文件名主干、pname、mkOption 声明的 option。

    texts 用剥掉注释的 sem，避免注释里的 pname/mkOption 进入词表。
    """
    names = set(defs)
    for p, raw in texts.items():
        names |= self_names(p)
        for m in re.finditer(r'\b(?:pname|name)\s*=\s*"([A-Za-z0-9._+-]+)"', raw):
            names.add(m.group(1))
        for m in MKOPT_RE.finditer(raw):
            names.add(m.group(1))
            names.add(m.group(1).split(".")[-1])
    return names


def package_refs(text, defs):
    """文本里引用到的本仓库自定义包（`pkgs.X` 或裸名 X），排除路径片段和 .nix 文件名。"""
    out = set()
    for attr in defs:
        pat = r"(?<![A-Za-z0-9_/@-])%s(?![A-Za-z0-9_/-])" % re.escape(attr)
        for m in re.finditer(pat, text):
            if text[m.end():m.end() + 4] == ".nix":
                continue
            out.add(attr)
            break
    return out


# 包清单上下文：home.packages / systemPackages / `packages = with pkgs; [ … ]`
LIST_HEAD = re.compile(
    r"(?:home\.packages|systemPackages|packages\s*=|with\s+pkgs\s*;)"
    r"\s*(?:=\s*)?(?:with\s+pkgs\s*;)?\s*\[")


def package_list_refs(text):
    """包清单里出现的包名（裸标识符 / pkgs.X）。

    「这个文件装了这个包」——如果仓库里正好有 `X/default.nix` 或 `X.nix`，
    那多半就是那个包的配置，属于典型的「包在此安装、配置在彼」。
    """
    out = set()
    for m in LIST_HEAD.finditer(text):
        i, depth = m.end(), 1
        while i < len(text) and depth:
            if text[i] == "[":
                depth += 1
            elif text[i] == "]":
                depth -= 1
            i += 1
        for t in IDENT_RE.findall(text[m.end():i - 1]):
            if t.startswith("inputs.") or t.startswith("lib.") or t.startswith("builtins."):
                continue
            name = t[5:].split(".")[0] if t.startswith("pkgs.") else t
            if len(name) >= 3 and name not in STOP and not name.isdigit():
                out.add(name)
    return out


def option_paths(text):
    """完整 option 路径（引号段归一成 *），比 `services.xserver` 这种两段前缀精确得多。"""
    out = set()
    for m in OPT_RE.finditer(text):
        raw = re.sub(r"\s+", "", m.group(1))
        raw = re.sub(r'"[^"]*"', "*", raw)
        head = raw.split(".")[0]
        if head in OPT_HEAD_STOP or len(head) < 3:
            continue
        out.add(raw)
    return out


def features(text, local=frozenset(), own=frozenset(), code=None):
    f = set()
    ids_in_code = None
    if code is not None:
        # 代码里的标识符 + 短的无空格字面量（"libvirtd"、"waybar/config" 是引用；
        # "mango compositor session" 这种长句是文案，不算证据）
        ids_in_code = set(IDENT_RE.findall(code))
        for lit in LITERAL_RE.findall(text):
            if " " not in lit:
                ids_in_code.update(IDENT_RE.findall(lit))
    for n in own:  # 「我是谁」：文件名/目录名本身也是一条特征
        f.add(("id_l", n))
    for m in ABS_RE.finditer(text):
        parts = [p for p in m.group(1).split("/") if p]
        if parts:
            f.add(("path", "/" + "/".join(parts[:2])))
    for m in DIR_RE.finditer(text):
        f.add(("dir", m.group(1)))
    opts = option_paths(text)
    for o in opts:
        f.add(("opt", o))
    for m in IDENT_RE.finditer(text):
        t = m.group(0).strip(".")
        if (m.start() and text[m.start() - 1] == "/") or text[m.end():m.end() + 1] == "/":
            continue  # 路径碎片（/var/lib 里的 var）
        if m.start() and text[m.start() - 1] == "." and t.lower() in EXT_STOP:
            continue  # 文件扩展名（"各 .nix 文件" 里的 nix）
        if any(o == t or o.endswith("." + t) or t.endswith("." + o) for o in opts):
            continue  # 已经作为完整 option 路径记过，别重复计分
        if UNIT_RE.match(t):
            f.add(("unit", t))
            continue
        if t.startswith("pkgs.") and len(t) > 5:
            name = t[5:].split(".")[0]
            if name not in STOP and len(name) >= 2:
                f.add(("id_l" if name in local else "id_x", name))
            continue
        if len(t) < 3 or t in STOP or t.isdigit():
            continue
        if t.startswith(("lib.", "builtins.", "config.", "inputs.")):
            continue
        if ids_in_code is not None and t not in ids_in_code:
            continue  # 只在字符串文案里出现过（description = "… session"），不算证据
        f.add(("id_l" if t in local else "id_x", t))
    return f


def render_evidence(items, side=None, deps=()):
    """把证据渲染成人话，最多两组。

    deps 是定向的「用了对方的包」：(包名, def|cfg, 谁在用)。同一对关系两个文件
    各拿一份措辞——装包的一侧说「使用 X」，提供方那侧说「X 的定义 / X 的配置」。
    """
    parts = []
    for name, kind, src in deps:
        if len(parts) == 2:
            break
        if src == side:
            parts.append("使用 " + name)
        else:
            parts.append(name + (" 的定义" if kind == "def" else " 的配置"))
    by = {}
    for _, kind, tok in items:
        if kind in ("id_x", "uses"):
            continue
        by.setdefault(kind, []).append(tok)
    for kind in ("path", "unit", "opt", "dir", "id_l"):
        if len(parts) == 2:
            break
        toks = by.get(kind)
        if not toks:
            continue
        parts.append("%s %s" % (SEM_PHRASE[kind], "、".join(sorted(set(toks))[:2])))
    if not parts:  # 只剩通用词，也给个交代
        weak = sorted({t for _, k, t in items if k == "id_x"})[:2]
        if weak:
            parts.append("同提 " + "、".join(weak))
    return "；".join(parts)


def self_index(raws):
    """名字 → 文件，只保留唯一匹配（`default`、重名文件不参与）。"""
    idx = {}
    for p in raws:
        for n in self_names(p):
            idx.setdefault(n, []).append(p)
    return {n: v[0] for n, v in idx.items() if len(v) == 1}


def reference_edges(sem, defs, definer, index, codes=None):
    """文件 → 它用到的「本仓库里有定义或配置文件」的包 → 那些文件。

    两条来源：① 直接引用本仓库自定义的包（`pkgs.X`/裸名 X）；
    ② 把 X 装进包清单，而仓库里正好有 `X/` 或 `X.nix`（包在此安装，配置在彼）。
    在 mask 过字符串的代码上匹配，避免 description 里的包名被当成真实依赖。
    """
    out = {}
    for p, text in sem.items():
        code = (codes or {}).get(p, text)
        targets = {}
        for attr in package_refs(code, defs):
            if p in definer.get(attr, ()):
                continue  # 定义处不算使用
            t = defs[attr]
            if t != p:
                targets.setdefault(t, {}).setdefault(attr, "def")
        for name in package_list_refs(code):
            t = index.get(name)
            if t and t != p:
                targets.setdefault(t, {}).setdefault(name, "cfg")
        out[p] = targets
    return out


def semantic_map(texts, min_score, local, uses, codes=None):
    """texts: {abs_path: 语义文本}，返回 {abs_path: [(score, other, 批注), ...]}。

    uses: {abs_path: {对方路径: {包名}}}，即「这个文件用了对方定义的包」，
    按定向关系加满权重，并且在词面证据里不重复计分。
    """
    per = {p: features(t, local, self_names(p), (codes or {}).get(p))
           for p, t in texts.items()}
    df = {}
    for feats in per.values():
        for ft in feats:
            df[ft] = df.get(ft, 0) + 1
    cut = df_cutoff(len(per))

    paths = sorted(per)
    scored = {}
    for i, p in enumerate(paths):
        for q in paths[i + 1:]:
            items, deps, uses_hit = [], [], set()
            for src, dst in ((p, q), (q, p)):
                for name, dep_kind in sorted(uses.get(src, {}).get(dst, {}).items()):
                    deps.append((name, dep_kind, src))
                    items.append((SEM_USES, "uses", name))
                    uses_hit.add(name)
            for kind, tok in per[p] & per[q]:
                if kind == "id_l" and tok in uses_hit:
                    continue  # 已被「引用包」这条边计过分
                d = df[(kind, tok)]
                if d > cut:
                    continue
                w = SEM_W[kind] * (SEM_PENALTY.get(kind, 0.6) if d > 2 else 1.0)
                items.append((w, kind, tok))
            if not items:
                continue
            # 通用库名（id_x）只用于批注渲染，不参与分数：
            # 否则「都依赖同一批库」会靠数量堆过阈值（典型：两个 Electron deb 包）。
            score = sum(w for w, kind, _ in items if kind != "id_x")
            if score < min_score:
                continue
            # 单条弱证据（一条孤零零的 option 路径之外的东西）不算相关
            if len(items) < 2 and not any(k in SEM_STRONG for _, k, _ in items):
                continue
            items.sort(key=lambda x: (-x[0], x[2]))
            scored[(p, q)] = (score, items, deps)

    out = {p: [] for p in paths}
    for (p, q), (score, items, deps) in scored.items():
        out[p].append((score, q, render_evidence(items, p, deps)))
        out[q].append((score, p, render_evidence(items, q, deps)))
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
    downstream, broken, resources, seq, sem, raws, codes = {}, [], {}, {}, {}, {}, {}
    for src in files:
        with open(src, encoding="utf-8") as fh:
            raw = fh.read()
        code = sanitize(raw, mask_strings=True)
        hits, res, order = set(), set(), []
        for m in REF_RE.finditer(code):
            ref = m.group(1).rstrip(".")
            tgt = resolve(ref, src)
            if tgt is None:
                p = os.path.normpath(os.path.join(os.path.dirname(src), ref))
                pre = code[max(0, m.start() - 40):m.start()]
                # pathExists 是「允许不存在」的探测，不算断链。
                if PATH_EXISTS_RE.search(pre):
                    continue
                # 无扩展名的路径也可能是资源/目录，只在确实不存在，
                # 或 import/callPackage 指向一个没有 default.nix 的目录时报断链。
                missing = not os.path.exists(p)
                dir_without_default = (os.path.isdir(p) and
                                       (IMPORT_RE.search(pre) or in_imports_list(code, m.start())))
                if ref.endswith(".nix") or missing or dir_without_default:
                    broken.append((display(src, root), ref))
                continue
            real = os.path.realpath(tgt)
            if not within_root(real, real_root):
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
        codes[key] = code
        raws[key] = raw
    return downstream, broken, resources, seq, sem, raws, codes


# 目录被"整体搬进 store"的用法：src = ./.; source = ./dir; PYTHONPATH=${./dir}
SRC_LIKE_RE = re.compile(r"\b(?:src|source|PYTHONPATH)\s*=\s*[^;]*$")
# 构建残留：目录被整体引用时看不出"没人用"，但这些东西基本可以删
JUNK_RE = re.compile(
    r"(^|/)(__pycache__|\.direnv|\.venv|\.pytest_cache|result|result-[^/]+|build|dist|node_modules)(/|$)"
    r"|[^/]+\.egg-info(/|$)"
    r"|\.(pyc|pyo|orig|rej|bak|swp)$|~$"
)


def scan_references(root, files):
    """返回 (被直接引用的文件, 被整体引用的目录)。"""
    real_root = os.path.realpath(root)
    refd_files, refd_dirs = set(), set()
    for src in files:
        with open(src, encoding="utf-8") as fh:
            code = sanitize(fh.read(), mask_strings=True)
        for m in REF_RE.finditer(code):
            ref = m.group(1).rstrip(".")
            p = os.path.normpath(os.path.join(os.path.dirname(src), ref))
            if os.path.isdir(p):
                if not within_root(p, real_root):
                    continue
                # import ./dir 只会拿 default.nix；src = ./dir 才是整棵树
                pre = code[max(0, m.start() - 40):m.start()]
                if SRC_LIKE_RE.search(pre) or not os.path.isfile(os.path.join(p, "default.nix")):
                    refd_dirs.add(os.path.realpath(p))
                else:
                    default = os.path.realpath(os.path.join(p, "default.nix"))
                    if within_root(default, real_root):
                        refd_files.add(default)
            else:
                t = resolve(ref, src)
                if t and within_root(t, real_root):
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
            if not within_root(p, real_root):
                continue
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
                    help="断链/失效相关条目/符号链接也算失败（只读，配合 --check 做 pre-commit）")
    ap.add_argument("--dry-run", action="store_true", help="打印 diff，不写文件")
    ap.add_argument("--json", action="store_true", help="以 JSON 输出结果")
    ap.add_argument("--graph", action="store_true", help="从 flake.nix 打印引用树")
    ap.add_argument("--stale-files", action="store_true",
                    help="列出 configuration/ 下没被任何 .nix 引用的资源文件（只读）")
    ap.add_argument("--related", choices=("merge", "auto", "off"), default="merge",
                    help="相关：merge=保留人工+自动补充(默认) / auto=完全重算 / off=不动")
    ap.add_argument("--related-min", type=float, default=SEM_MIN_SCORE,
                    help="语义相关的最低分值（默认 %.1f）" % SEM_MIN_SCORE)
    ap.add_argument("--explain-related", action="store_true",
                    help="打印「相关」候选与证据分值（只读，用于调 --related-min）")
    ap.add_argument("--related-max", type=int, default=SEM_MAX_ITEMS,
                    help="每个文件最多自动补几条（默认 %d）" % SEM_MAX_ITEMS)
    ap.add_argument("-v", "--verbose", action="store_true", help="输出孤立文件与外部资源")
    args = ap.parse_args()

    # 只读模式：任何"看一眼"的开关都不写盘（--strict 也只是校验，不隐式写入）
    readonly = (args.check or args.dry_run or args.json or args.stale_files
                or args.explain_related or args.graph or args.strict)

    root = os.path.abspath(args.root)
    if not os.path.isdir(root):
        sys.exit("根目录不存在: %s" % root)

    files = collect(root)
    downstream, broken, resources, seq, sem, raws, codes = build(root, files)

    upstream = {p: [] for p in downstream}
    for src, tgts in downstream.items():
        for t in tgts:
            upstream[t].append(src)

    # 语义相关：结构化证据 + 本仓库里「包 ↔ 配置文件」的使用关系
    defs, definer = package_defs(sem, root)
    local = local_vocabulary(defs, sem)
    uses = reference_edges(sem, defs, definer, self_index(raws), codes)
    auto_rel = (semantic_map(sem, args.related_min, local, uses, codes)
                if args.related != "off" else {})

    # 文件名 → 路径，用于"相关"条目跟随改名（只认唯一匹配）
    by_name = {}
    for f in files:
        by_name.setdefault(os.path.basename(f), []).append(display(f, root))

    targets = [p for p in files if display(p, root) not in EXCLUDE_FILES]

    changed, stale, renamed, errors, skipped_links = [], [], [], [], []
    for path in sorted(targets):
        rel = display(path, root)
        rp = os.path.realpath(path)
        if os.path.islink(path):
            skipped_links.append(rel)
            continue
        try:
            with open(path, encoding="utf-8") as fh:
                text = fh.read()
            span, old = parse_header(text)

            up = sorted({display(s, root) for s in upstream.get(rp, [])})
            down = sorted({display(t, root) for t in downstream.get(rp, [])})
            neighbours = set(up) | set(down)

            cands = []
            for score, other, note in auto_rel.get(rp, []):
                d = display(other, root)
                if d in neighbours or d == rel or d in EXCLUDE_FILES:
                    continue
                cands.append((score, d, note))

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

            if args.dry_run:
                if not args.json:
                    sys.stdout.writelines(difflib.unified_diff(
                        text.splitlines(True), new_text.splitlines(True),
                        fromfile="a/" + rel, tofile="b/" + rel, n=2))
                changed.append(rel)
            elif not readonly and not args.json:
                try:
                    write_atomic(path, new_text)
                except OSError as exc:
                    errors.append((rel, str(exc)))
                    continue
                changed.append(rel)
            else:
                changed.append(rel)
        except (OSError, UnicodeError) as exc:
            # 单个文件读不了/编码坏了，不拖垮其它文件；最后统一报错并非零退出
            errors.append((rel, str(exc)))

    orphans = sorted(
        display(p, root) for p in targets if not upstream.get(os.path.realpath(p), [])
    )

    if args.stale_files or args.json:
        unused_files, junk_files = unreferenced(root, files)
    else:
        unused_files, junk_files = [], []

    graph_lines = []
    if args.graph:
        flake = os.path.realpath(os.path.join(root, "flake.nix"))
        seen = set()

        def walk(p, depth):
            graph_lines.append("  " * depth + ("└─ " if depth else "") +
                               ("flake.nix" if p == flake else display(p, root)))
            if p in seen or depth > 12:
                return
            seen.add(p)
            for k in downstream.get(p, []):
                if display(k, root) not in EXCLUDE_FILES:
                    walk(k, depth + 1)

        walk(flake, 0)

    if args.json:
        payload = {
            "scanned": len(targets),
            "changed": changed,
            "broken": broken,
            "orphans": orphans,
            "stale": stale,
            "renamed": [{"file": f, "from": a, "to": b} for f, a, b in renamed],
            "skipped_symlinks": skipped_links,
            "errors": [{"file": f, "error": e} for f, e in errors],
            "stale_files": {
                "unused": [{"path": p, "size": sz} for sz, p in unused_files],
                "junk": [{"path": p, "size": sz} for sz, p in junk_files],
            },
        }
        if args.graph:
            payload["graph"] = graph_lines
        print(json.dumps(payload, ensure_ascii=False, indent=2))
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
        if errors:
            print("⚠ 处理失败 %d 个:" % len(errors))
            for f, e in errors[:20]:
                print("  - %s: %s" % (f, e))
        if skipped_links:
            print("⚠ 跳过符号链接 %d 个（拒绝替换链接）:" % len(skipped_links))
            for f in skipped_links[:20]:
                print("  - " + f)
        if args.stale_files:
            unused, junk = unused_files, junk_files
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

        if args.explain_related:
            rows, seen = [], {}
            for p, lst in auto_rel.items():
                for score, other, note in lst:
                    key = tuple(sorted((p, other)))
                    pair = seen.setdefault(key, {})
                    pair[p] = note
                    if len(pair) == 2:
                        rows.append((score, key[0], key[1], pair))
            rows.sort(key=lambda r: -r[0])
            print("「相关」候选 %d 对（阈值 %.1f；两文件措辞不同时用 ／ 分隔）:"
                  % (len(rows), args.related_min))
            for score, a, b, notes in rows:
                na, nb = notes.get(a, ""), notes.get(b, "")
                ev = na if na == nb else "%s ／ %s" % (na, nb)
                print("  %5.1f  %-44s ↔ %-44s %s" % (
                    score, display(a, root), display(b, root), ev))

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
            print("\n".join(graph_lines))

    failed = ((args.check and changed)
              or (args.strict and (broken or stale or skipped_links))
              or bool(errors))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
