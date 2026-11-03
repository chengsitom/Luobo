#!/usr/bin/env bash
# 道理鱼「有声书进度」接口探测（只读优先）
#
# 目的：确认 `GET /api/library/audiobooks/progress` 的真实响应结构，以及
#       「写进度」到底有没有独立端点（PATCH/PUT/POST）。结果用来收紧
#       `AudiobookProgress.fromServerJson`（现在是按字段名猜测）。
#
# 用法（在家里/能访问服务器时跑）：
#   export DL_BASE="http://192.168.31.142:4000"     # 或 https://你的域名:10010
#   export DL_USER="chengsitom"
#   export DL_PASS="你的密码"
#   ./tool/probe_audiobook_progress.sh
#
# 默认**只做 GET**。要探测写方法是否存在，加 --probe-write：
#   ./tool/probe_audiobook_progress.sh --probe-write
# （探测方式是发空 body，服务端返回 400=路由存在但参数不全，404=不存在，405=方法不允许；
#   不会写入真实进度，但确实会往你的服务器发请求，自己判断是否接受。）
#
# 依赖：curl + python3（macOS 自带），不需要 jq。

set -uo pipefail

BASE="${DL_BASE:-http://192.168.31.142:4000}"
USER_NAME="${DL_USER:-}"
PASS="${DL_PASS:-}"
TOKEN="${DL_TOKEN:-}"
PROBE_WRITE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    --user) USER_NAME="$2"; shift 2 ;;
    --pass) PASS="$2"; shift 2 ;;
    --token) TOKEN="$2"; shift 2 ;;
    --probe-write) PROBE_WRITE=1; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "未知参数：$1"; exit 2 ;;
  esac
done

BASE="${BASE%/}"
say() { printf '\n\033[1m%s\033[0m\n' "$*"; }
pretty() { python3 -m json.tool 2>/dev/null || cat; }
code() { printf '  → HTTP %s\n' "$1"; }

# ── 1. 登录拿 JWT ────────────────────────────────────────────────────────────
if [ -z "$TOKEN" ]; then
  if [ -z "$USER_NAME" ] || [ -z "$PASS" ]; then
    echo "缺少凭据：export DL_USER / DL_PASS（或用 --token 直接给 JWT）"
    exit 2
  fi
  say "1) POST /api/auth/login"
  LOGIN=$(curl -s -m 15 -w '\n%{http_code}' \
    -X POST "$BASE/api/auth/login" \
    -H 'Content-Type: application/json' \
    --data "{\"username\":\"$USER_NAME\",\"password\":\"$PASS\"}")
  LOGIN_CODE=$(printf '%s' "$LOGIN" | tail -n1)
  LOGIN_BODY=$(printf '%s' "$LOGIN" | sed '$d')
  code "$LOGIN_CODE"
  TOKEN=$(printf '%s' "$LOGIN_BODY" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("token",""))' 2>/dev/null)
  if [ -z "$TOKEN" ]; then
    echo "$LOGIN_BODY" | pretty
    echo "登录失败，退出。"
    exit 1
  fi
  echo "  token: ${TOKEN:0:24}…"
fi

AUTH="Authorization: Bearer $TOKEN"

# ── 2. 读进度（本次调研的核心）────────────────────────────────────────────────
say "2) GET /api/library/audiobooks/progress  ← 关键"
RESP=$(curl -s -m 20 -w '\n%{http_code}' -H "$AUTH" "$BASE/api/library/audiobooks/progress")
RC=$(printf '%s' "$RESP" | tail -n1)
BODY=$(printf '%s' "$RESP" | sed '$d')
code "$RC"
echo "  顶层类型：$(printf '%s' "$BODY" | python3 -c 'import sys,json;d=json.load(sys.stdin);print(type(d).__name__, (list(d.keys())[:10] if isinstance(d,dict) else "len=%d"%len(d)))' 2>/dev/null || echo '非 JSON')"
echo "  --- 原始响应（完整贴给我即可）---"
printf '%s' "$BODY" | pretty

# ── 3. 拿两本书 id（给写探测用）──────────────────────────────────────────────
say "3) GET /api/library/audiobooks（取 abk_ id）"
BOOKS=$(curl -s -m 20 -H "$AUTH" "$BASE/api/library/audiobooks?limit=2")
printf '%s' "$BOOKS" | python3 -c '
import sys,json
d=json.load(sys.stdin)
items=d.get("items") or d.get("data") or []
for b in items[:2]:
    print("  ", b.get("id"), "|", b.get("title"), "| episodeCount=", b.get("episodeCount"))
' 2>/dev/null || echo "  （解析失败，见下方原文）$BOOKS"
BOOK_ID=$(printf '%s' "$BOOKS" | python3 -c '
import sys,json
d=json.load(sys.stdin); items=d.get("items") or d.get("data") or []
print(items[0]["id"] if items else "")
' 2>/dev/null)

# ── 4. 写端点探测（可选，只发空 body）────────────────────────────────────────
if [ "$PROBE_WRITE" -eq 1 ] && [ -n "${BOOK_ID:-}" ]; then
  say "4) 写端点探测（空 body，看路由是否存在）"
  for METHOD in PATCH PUT POST; do
    for PATH_ in "/api/library/audiobooks/$BOOK_ID/progress" \
                 "/api/library/audiobooks/progress" \
                 "/api/library/audiobooks/$BOOK_ID/progress/$BOOK_ID"; do
      C=$(curl -s -m 10 -o /tmp/_dl_probe_body -w '%{http_code}' \
        -X "$METHOD" "$BASE$PATH_" -H "$AUTH" \
        -H 'Content-Type: application/json' --data '{}')
      printf '  %-6s %-58s → %s\n' "$METHOD" "$PATH_" "$C"
    done
  done
  echo "  读法：400/422=路由存在但参数不全（有戏）｜404=不存在｜405=方法不允许｜2xx=真的写进去了"
else
  say "4) 跳过写端点探测（加 --probe-write 开启）"
fi

say "完成。把上面第 2 步的完整响应贴给我。"
