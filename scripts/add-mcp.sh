#!/usr/bin/env bash
#
# MCP 서버 자동 추가 스크립트
#
# 사용법:
#   ./add-mcp.sh <server-name> <npm-package> [preload|lazy]
#
# 예시:
#   ./add-mcp.sh filesystem @modelcontextprotocol/server-filesystem preload
#   ./add-mcp.sh slack @modelcontextprotocol/server-slack lazy
#

set -e

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 배너
print_banner() {
    echo -e "${GREEN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║            MCP Server Addition Script v1.0.0             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 사용법
print_usage() {
    cat << EOF
사용법: $0 <server-name> <npm-package> [load-type] [args...]

파라미터:
  server-name     MCP 서버 이름 (예: filesystem, slack)
  npm-package     NPM 패키지명 (예: @modelcontextprotocol/server-filesystem)
  load-type       로딩 방식 (preload | lazy) - 기본값: lazy
  args...         추가 인수 (선택)

예시:
  # Filesystem (Preload)
  $0 filesystem @modelcontextprotocol/server-filesystem preload \\
     --allowed-directories /home/user/documents

  # Slack (Lazy Load)
  $0 slack @modelcontextprotocol/server-slack lazy

  # Postgres (Lazy Load)
  $0 postgres @modelcontextprotocol/server-postgres lazy

Load Type 가이드:
  preload - 항상 로드 (자주 사용, 토큰 비용 낮음)
  lazy    - 필요시 로드 (가끔 사용, 토큰 비용 높음)

EOF
}

# 인수 확인
SERVER_NAME="$1"
NPM_PACKAGE="$2"
LOAD_TYPE="${3:-lazy}"
shift 3 2>/dev/null || shift 2 2>/dev/null || true
EXTRA_ARGS=("$@")

if [ -z "$SERVER_NAME" ] || [ -z "$NPM_PACKAGE" ]; then
    print_usage
    exit 1
fi

# 변수
LAZY_MCP_DIR="$HOME/lazy-mcp"
CONFIG_FILE="$LAZY_MCP_DIR/config.json"
BACKUP_FILE="$LAZY_MCP_DIR/config.json.backup.$(date +%Y%m%d_%H%M%S)"

print_banner

log_info "MCP 서버 추가 시작..."
echo ""
echo "  서버 이름: $SERVER_NAME"
echo "  패키지: $NPM_PACKAGE"
echo "  로드 타입: $LOAD_TYPE"
if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then
    echo "  추가 인수: ${EXTRA_ARGS[*]}"
fi
echo ""

# Lazy MCP 디렉토리 확인
if [ ! -d "$LAZY_MCP_DIR" ]; then
    log_error "Lazy MCP 디렉토리를 찾을 수 없습니다: $LAZY_MCP_DIR"
    echo "먼저 Lazy MCP를 설치하세요: ./scripts/deploy.sh --lazy-mcp"
    exit 1
fi

# config.json 확인
if [ ! -f "$CONFIG_FILE" ]; then
    log_error "config.json을 찾을 수 없습니다: $CONFIG_FILE"
    exit 1
fi

# jq 확인
if ! command -v jq &> /dev/null; then
    log_error "jq가 설치되어 있지 않습니다"
    echo "설치: sudo apt-get install -y jq"
    exit 1
fi

# 백업
log_info "config.json 백업 중..."
cp "$CONFIG_FILE" "$BACKUP_FILE"
log_success "백업 완료: $BACKUP_FILE"

# Load Type 설정
if [ "$LOAD_TYPE" = "preload" ]; then
    LAZY_LOAD="false"
    PRELOAD="true"
elif [ "$LOAD_TYPE" = "lazy" ]; then
    LAZY_LOAD="true"
    PRELOAD="false"
else
    log_error "잘못된 load-type: $LOAD_TYPE (preload 또는 lazy 사용)"
    exit 1
fi

# args 배열 생성
ARGS_JSON="[\"-y\", \"$NPM_PACKAGE\""
if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then
    for arg in "${EXTRA_ARGS[@]}"; do
        ARGS_JSON="$ARGS_JSON, \"$arg\""
    done
fi
ARGS_JSON="$ARGS_JSON]"

# config.json에 추가
log_info "config.json에 추가 중..."

jq ".mcpServers.\"$SERVER_NAME\" = {
    \"transportType\": \"stdio\",
    \"command\": \"npx\",
    \"args\": $ARGS_JSON,
    \"env\": {},
    \"options\": {
        \"lazyLoad\": $LAZY_LOAD,
        \"preload\": $PRELOAD
    }
}" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"

if [ $? -eq 0 ]; then
    mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    log_success "config.json 업데이트 완료!"
else
    log_error "config.json 업데이트 실패"
    echo "백업 복원: cp $BACKUP_FILE $CONFIG_FILE"
    exit 1
fi

# 도구 계층 구조 생성 시도
log_info "도구 계층 구조 생성 시도 중..."
cd "$LAZY_MCP_DIR"

if timeout 30s ./build/structure_generator \
    --server "$SERVER_NAME" \
    --config ./config.json \
    --output ./testdata/mcp_hierarchy 2>/dev/null; then
    log_success "도구 계층 구조 생성 완료!"
else
    log_warn "도구 계층 구조 생성 실패 (타임아웃 또는 오류)"
    echo "  → 수동 생성 필요: cd $LAZY_MCP_DIR"
    echo "     ./build/structure_generator --server \"$SERVER_NAME\" --config ./config.json --output ./testdata/mcp_hierarchy"
fi

# 완료 메시지
echo ""
log_success "========================================="
log_success "   MCP 서버 추가 완료!"
log_success "========================================="
echo ""
echo "다음 단계:"
echo ""
echo "  1. 환경 변수 설정 (필요 시)"
echo "     vim $CONFIG_FILE"
echo "     → \"env\" 섹션에 API 키 등 추가"
echo ""
echo "  2. Claude Code 재시작"
echo "     pkill -f \"claude-code\""
echo ""
echo "  3. MCP 연결 확인"
echo "     Claude Code에서: /mcp"
echo "     예상 출력: ✅ $SERVER_NAME ($LOAD_TYPE)"
echo ""
echo "  4. Skill 생성 (선택)"
echo "     mkdir -p ~/.claude/skills/${SERVER_NAME}-manager"
echo "     vim ~/.claude/skills/${SERVER_NAME}-manager/SKILL.md"
echo ""
echo "  5. 토큰 확인"
echo "     Claude Code에서: /context"
if [ "$LOAD_TYPE" = "preload" ]; then
    echo "     예상: +0.5~2k 토큰 증가"
else
    echo "     예상: 거의 변화 없음 (~100 토큰)"
fi
echo ""
echo "백업 파일: $BACKUP_FILE"
echo ""

# 검증 스크립트 실행 제안
log_info "검증을 실행하시겠습니까? (y/N)"
read -r -n 1 response
echo ""

if [[ "$response" =~ ^[Yy]$ ]]; then
    if [ -f "$(dirname "$0")/verify.sh" ]; then
        log_info "검증 실행 중..."
        "$(dirname "$0")/verify.sh" --installation
    else
        log_warn "verify.sh를 찾을 수 없습니다"
        echo "수동 검증: ./scripts/verify.sh --installation"
    fi
fi
