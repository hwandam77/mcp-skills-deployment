#!/usr/bin/env bash
#
# MCP + Skills 제거 스크립트
#
# 사용법:
#   ./uninstall.sh [--full|--lazy-mcp|--skills|--config]
#
# 예시:
#   ./uninstall.sh --full      # 전체 제거
#   ./uninstall.sh --skills    # Skills만 제거
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
    echo -e "${RED}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║          MCP + Skills Uninstall Script v1.0.0            ║
║                  ⚠️  DESTRUCTIVE OPERATION ⚠️              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 사용법
print_usage() {
    cat << EOF
사용법: $0 [option]

옵션:
  --full        전체 제거 (Lazy MCP + Skills + 설정)
  --lazy-mcp    Lazy MCP만 제거
  --skills      Skills만 제거
  --config      설정 파일만 제거
  -h, --help    도움말 표시

주의사항:
  - 제거 전 자동 백업이 수행됩니다
  - 복원은 백업 파일로 가능합니다

예시:
  $0 --full        # 모든 것 제거
  $0 --skills      # Skills만 제거
  $0 --lazy-mcp    # Lazy MCP만 제거

EOF
}

# 인수 처리
MODE="${1:---full}"

if [ "$MODE" = "-h" ] || [ "$MODE" = "--help" ]; then
    print_usage
    exit 0
fi

print_banner

log_warn "========================================="
log_warn "   제거 작업을 시작합니다"
log_warn "========================================="
echo ""
echo "  모드: $MODE"
echo ""

# 확인
log_error "이 작업은 되돌릴 수 없습니다!"
echo "계속하시겠습니까? (yes/NO)"
read -r response

if [ "$response" != "yes" ]; then
    log_info "제거 취소"
    exit 0
fi

# 백업
log_info "제거 전 백업 중..."
BACKUP_DIR="$HOME/.mcp-uninstall-backup-$(date +%Y%m%d_%H%M%S)"

if [ -f ~/.claude.json ] || [ -d ~/lazy-mcp ] || [ -d ~/.claude/skills ]; then
    mkdir -p "$BACKUP_DIR"

    [ -f ~/.claude.json ] && cp ~/.claude.json "$BACKUP_DIR/"
    [ -f ~/lazy-mcp/config.json ] && mkdir -p "$BACKUP_DIR/lazy-mcp" && cp ~/lazy-mcp/config.json "$BACKUP_DIR/lazy-mcp/"
    [ -d ~/.claude/skills ] && cp -r ~/.claude/skills "$BACKUP_DIR/"

    log_success "  ✓ 백업 완료: $BACKUP_DIR"
else
    log_warn "  ⊗ 백업할 파일이 없습니다"
fi

# 제거 카운터
REMOVED_COUNT=0

# Lazy MCP 제거
if [ "$MODE" = "--full" ] || [ "$MODE" = "--lazy-mcp" ]; then
    log_info "Lazy MCP 제거 중..."

    # 프로세스 종료
    pkill -f mcp-proxy 2>/dev/null || true

    # 디렉토리 제거
    if [ -d ~/lazy-mcp ]; then
        rm -rf ~/lazy-mcp
        log_success "  ✓ ~/lazy-mcp 제거"
        ((REMOVED_COUNT++))
    else
        log_warn "  ⊗ ~/lazy-mcp 디렉토리가 없습니다"
    fi
fi

# Skills 제거
if [ "$MODE" = "--full" ] || [ "$MODE" = "--skills" ]; then
    log_info "Skills 제거 중..."

    if [ -d ~/.claude/skills ]; then
        rm -rf ~/.claude/skills
        log_success "  ✓ ~/.claude/skills 제거"
        ((REMOVED_COUNT++))
    else
        log_warn "  ⊗ ~/.claude/skills 디렉토리가 없습니다"
    fi
fi

# 설정 파일 제거
if [ "$MODE" = "--full" ] || [ "$MODE" = "--config" ]; then
    log_info "설정 파일 제거 중..."

    if [ -f ~/.claude.json ]; then
        rm ~/.claude.json
        log_success "  ✓ ~/.claude.json 제거"
        ((REMOVED_COUNT++))
    else
        log_warn "  ⊗ ~/.claude.json 파일이 없습니다"
    fi
fi

# Claude Code 재시작 권장
log_warn "Claude Code를 재시작하세요:"
echo "  pkill -f \"claude-code\""

# 완료 메시지
echo ""
log_success "========================================="
log_success "   제거 완료!"
log_success "========================================="
echo ""
echo "제거된 항목: $REMOVED_COUNT"
echo "백업 위치: $BACKUP_DIR"
echo ""
echo "복원 방법:"
echo "  ./scripts/restore.sh $BACKUP_DIR"
echo ""
