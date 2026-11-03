#!/usr/bin/env bash
# 提交前敏感信息自查（仓库是公开的，这里只做"防手滑"）
#
# 用法：
#   ./tool/check_secrets.sh            # 扫已跟踪文件，有 FAIL 则退出码 1
#   ./tool/check_secrets.sh --staged   # 只扫暂存区（给 pre-commit 用）
#   ./tool/check_secrets.sh --install-hook   # 装成 .git/hooks/pre-commit
#
# 分两级：FAIL = 一定不能出现；WARN = 可能是占位也可能是真的，人工看一眼。

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

MODE="${1:-}"
FAILED=0
WARNED=0

if [ "$MODE" = "--install-hook" ]; then
  HOOK=".git/hooks/pre-commit"
  cat > "$HOOK" <<'EOS'
#!/usr/bin/env bash
exec ./tool/check_secrets.sh --staged
EOS
  chmod +x "$HOOK"
  echo "已安装 .git/hooks/pre-commit（绕过：git commit --no-verify）"
  exit 0
fi

files() {
  if [ "$MODE" = "--staged" ]; then
    git diff --cached --name-only --diff-filter=ACM
  else
    git ls-files
  fi
}

# 只扫文本类，跳过二进制与生成物
TEXT_FILES=$(files | grep -vE '\.(png|jpg|jpeg|gif|webp|ico|ttf|otf|woff2?|mp4|mov|mp3|zip|apk|ipa|jar|so|dylib|a|pdf|chm|chls)$|^assets/|^build/|l10n/' || true)
[ -z "$TEXT_FILES" ] && { echo "没有需要检查的文件"; exit 0; }

# 「明文密码」只在文档/配置里查：Dart 源码里的 password: 'testpass' 是测试夹具，
# 用同一条正则扫会把几十处代码误报成泄露。
DOC_FILES=$(printf '%s\n' "$TEXT_FILES" | grep -vE '\.dart$' || true)

hit() { # hit <级别> <标题> <正则> [文件列表]
  local level="$1" title="$2" pattern="$3" list="${4:-$TEXT_FILES}" out
  [ -z "$list" ] && return 0
  out=$(printf '%s\n' "$list" | tr '\n' '\0' \
        | xargs -0 grep -nE "$pattern" 2>/dev/null \
        | sed 's/\(.\{0,160\}\).*/\1…/')
  [ -z "$out" ] && return 0
  if [ "$level" = "FAIL" ]; then
    printf '\033[31m[FAIL]\033[0m %s\n%s\n\n' "$title" "$out"
    FAILED=$((FAILED + 1))
  else
    printf '\033[33m[WARN]\033[0m %s\n%s\n\n' "$title" "$out"
    WARNED=$((WARNED + 1))
  fi
}

echo "== 敏感信息自查（$(printf '%s\n' "$TEXT_FILES" | wc -l | tr -d ' ') 个文件）=="

hit FAIL "明文密码赋值（仅文档/配置；Dart 源码里的测试夹具不查）" \
    '(password|passwd|pwd)[[:space:]]*[:=][[:space:]]*[^<*$ ][^ ]{3,}' "$DOC_FILES"
hit FAIL "手机号（11 位国内手机号，打码的 **** 不算）" \
    '(^|[^0-9])1[3-9][0-9]{9}([^0-9]|$)'
hit FAIL "JWT / Bearer token" \
    'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
hit FAIL "大模型 API Key（sk-…）" \
    'sk-[A-Za-z0-9]{16,}'
hit FAIL "本机用户目录绝对路径（暴露用户名）" \
    '/Users/[A-Za-z0-9._-]+/'

# 私有网段：192.168.1.x 是仓库里统一使用的占位段，放行；其它网段请确认是不是真机地址。
PRIVATE_IP_HITS=$(printf '%s\n' "$TEXT_FILES" | tr '\n' '\0' \
  | xargs -0 grep -nE '(^|[^0-9])(10\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])|192\.168)\.[0-9]{1,3}\.[0-9]{1,3}' 2>/dev/null \
  | grep -vE '192\.168\.1\.' || true)
if [ -n "$PRIVATE_IP_HITS" ]; then
  printf '\033[33m[WARN]\033[0m 私有网段 IP（192.168.1.x 占位段已放行）\n%s\n\n' \
    "$(printf '%s' "$PRIVATE_IP_HITS" | sed 's/\(.\{0,160\}\).*/\1…/')"
  WARNED=$((WARNED + 1))
fi

hit WARN "真实隧道/DDNS 子域（含 NAS 标识）" \
    'app-[0-9a-f]{6,}-[A-Za-z0-9]+\.cn[0-9]+\.(ugdocker|ugapp)\.link'
hit WARN "个人自建域名" \
    '[A-Za-z0-9-]+\.(fnos\.net|ug\.link)'

# 占位符放行说明：192.168.1.10 / music.example.com / xxx.fnos.net 是文档里的示例值
echo "提示：192.168.1.10、music.example.com、<nas-id> 等为占位符，可保留。"

if [ "$FAILED" -gt 0 ]; then
  printf '\033[31m共 %d 处 FAIL，%d 处 WARN —— 请先处理 FAIL 再提交。\033[0m\n' "$FAILED" "$WARNED"
  exit 1
fi
printf '\033[32m通过（%d 处 WARN 请人工确认）。\033[0m\n' "$WARNED"
