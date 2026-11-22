#!/usr/bin/env python3
"""rime-wanxiang-gram-update.py —— 自动跟踪万象 LTS 语法模型（.gram）的滚动发布。

为什么需要它
------------
上游 `amzxyz/rime-wanxiang-data` 用固定 tag `LTS` 覆盖式更新资产
（tag 常年不变，asset 里换文件），而 Nix 的 fetchurl 必须钉死 sha256。
所以要么手改 hash，要么用这个脚本自动改。

怎么省流量
----------
GitHub Releases API 会直接给出资产的 sha256（`digest` 字段），和文件内容一致，
所以默认只发 1 个 API 请求（几百字节）判断是否需要更新，不下载那 390 MB。
真要核对再 `--verify`（下载后本地算 hash 比对）。

用法
----
    # 只查询：有新版本则退出码 1（可直接做 CI / 定时检查）
    python3 configuration/pkgs/data/rime-wanxiang-gram/rime-wanxiang-gram-update.py --check

    # 直接改 nix 文件（version 日期 + sha256）
    python3 rime-wanxiang-gram-update.py --apply

    # 下载核对（慢，390MB）
    python3 configuration/pkgs/data/rime-wanxiang-gram/rime-wanxiang-gram-update.py --check --verify
"""

import argparse
import datetime
import hashlib
import json
import os
import re
import sys
import urllib.error
import urllib.request

DEFAULT_FILE = "/etc/nixos/configuration/pkgs/data/rime-wanxiang-gram/rime-wanxiang-gram.nix"
DEFAULT_REPO = "amzxyz/rime-wanxiang-data"
DEFAULT_TAG = "LTS"
DEFAULT_ASSET = "wanxiang-lts-zh-hans.gram"

VERSION_RE = re.compile(r'(version\s*=\s*")unstable-\d{4}-\d{2}-\d{2}(")')
SHA_RE = re.compile(r'(sha256\s*=\s*")[0-9a-fA-F]{64}(")')

# systemd 服务里不一定有 SSL_CERT_FILE；缺了就指向 NixOS 的 CA bundle
if not os.environ.get("SSL_CERT_FILE"):
    for _ca in ("/etc/ssl/certs/ca-bundle.crt", "/etc/ssl/certs/ca-certificates.crt"):
        if os.path.exists(_ca):
            os.environ["SSL_CERT_FILE"] = _ca
            break


def log(msg):
    print(msg, file=sys.stderr)


def api_asset(repo, tag, asset):
    url = "https://api.github.com/repos/%s/releases/tags/%s" % (repo, tag)
    req = urllib.request.Request(url, headers={
        "User-Agent": "rime-wanxiang-gram-update",
        "Accept": "application/vnd.github+json",
    })
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.load(resp)
    except urllib.error.HTTPError as e:
        log("GitHub API 失败: HTTP %s（未认证限流 60 次/小时，可设 GITHUB_TOKEN）" % e.code)
        raise SystemExit(2)
    except Exception as e:  # noqa: BLE001
        log("GitHub API 失败: %s" % e)
        raise SystemExit(2)

    for a in data.get("assets", []):
        if a.get("name") == asset:
            return a
    log("资产 %s 不存在；现有: %s"
        % (asset, ", ".join(a.get("name", "?") for a in data.get("assets", []))))
    raise SystemExit(2)


def download_sha256(url):
    h = hashlib.sha256()
    req = urllib.request.Request(url, headers={"User-Agent": "rime-wanxiang-gram-update"})
    with urllib.request.urlopen(req, timeout=300) as resp:
        while True:
            chunk = resp.read(1 << 20)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser(description="跟踪万象 LTS .gram 的滚动更新")
    ap.add_argument("--file", default=DEFAULT_FILE, help="要改的 nix 文件")
    ap.add_argument("--repo", default=DEFAULT_REPO)
    ap.add_argument("--tag", default=DEFAULT_TAG)
    ap.add_argument("--asset", default=DEFAULT_ASSET)
    ap.add_argument("--apply", action="store_true", help="写回 nix 文件（默认只查询）")
    ap.add_argument("--check", action="store_true", help="有新版本则退出码 1")
    ap.add_argument("--verify", action="store_true", help="下载资产本地核对 sha256（390MB）")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    if not os.path.isfile(args.file):
        log("nix 文件不存在: %s" % args.file)
        return 2
    text = open(args.file, encoding="utf-8").read()

    m_sha = SHA_RE.search(text)
    m_ver = VERSION_RE.search(text)
    if not (m_sha and m_ver):
        log("在 %s 里没找到 version/sha256，文件结构变了？" % args.file)
        return 2
    cur_sha = m_sha.group(0).split('"')[1]
    cur_ver = m_ver.group(0).split('"')[1]

    asset = api_asset(args.repo, args.tag, args.asset)
    digest = (asset.get("digest") or "").split(":")[-1].lower()
    if not digest:
        log("API 没给 digest，改用下载核对")
        digest = download_sha256(asset["browser_download_url"])
    if args.verify:
        log("下载核对 %s（%.0f MB）…" % (args.asset, asset.get("size", 0) / 1048576))
        got = download_sha256(asset["browser_download_url"])
        if got != digest:
            log("⚠ API digest(%s) 与文件实际 hash(%s) 不一致，以实际为准" % (digest, got))
            digest = got

    updated = asset.get("updated_at") or ""
    new_ver = "unstable-" + (updated[:10] or datetime.date.today().isoformat())

    if digest == cur_sha:
        if not args.quiet:
            log("已是最新：%s  %s" % (cur_ver, cur_sha))
        return 0

    log("发现新版本：%s → %s" % (cur_ver, new_ver))
    log("  sha256 %s → %s" % (cur_sha, digest))

    if not args.apply:
        if not args.quiet:
            log("（未改动文件；加 --apply 写回）")
        return 1 if args.check else 0

    text = SHA_RE.sub(lambda mm: mm.group(1) + digest + mm.group(2), text, count=1)
    text = VERSION_RE.sub(lambda mm: mm.group(1) + new_ver + mm.group(2), text, count=1)
    with open(args.file, "w", encoding="utf-8") as fh:
        fh.write(text)
    log("已写入 %s；下次 rebuild 生效（可先 nix build 验证）" % args.file)
    return 0


if __name__ == "__main__":
    sys.exit(main())
