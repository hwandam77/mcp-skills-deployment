#!/usr/bin/env bash
#
# MCP + Skills 복원 스크립트
#
# 사용법:
#   ./restore.sh <backup-directory>
#
# 예시:
#   ./restore.sh ~/mcp-backup-20251115
#   ./restore.sh ~/mcp-backup
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
║           MCP + Skills Restore Script v1.0.0             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 사용법
print_usage() {
    cat << EOF
사용법: $0 <backup-directory>

파라미터:
  backup-directory    백업 파일이 있는 디렉토리

복원 내용:
  - ~/.claude.json (Claude Code 설정)
  - ~/lazy-mcp/config.json (Lazy MCP 설정)
  - ~/.claude/skills/ (전체 Skills)

주의사항:
  - 복원 전에 현재 설정이 자동으로 백업됩니다
  - 기존 설정이 덮어쓰기됩니다

예시:
  $0 ~/mcp-backup-20251115
  $0 ~/mcp-backup

EOF
}

# 인수 확인
if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
    exit 1
fi

BACKUP_DIR="$1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

print_banner

log_info "MCP + Skills 복원 시작..."
echo ""
echo "  백업 디렉토리: $BACKUP_DIR"
echo "  복원 타임스탬프: $TIMESTAMP"
echo ""

# 백업 디렉토리 확인
if [ ! -d "$BACKUP_DIR" ]; then
    log_error "백업 디렉토리를 찾을 수 없습니다: $BACKUP_DIR"
    exit 1
fi

# 백업 메타데이터 확인
if [ -f "$BACKUP_DIR/backup-metadata.txt" ]; then
    log_info "백업 메타데이터 확인:"
    echo ""
    grep -E "^(백업 날짜|백업 타임스탬프|호스트|사용자)" "$BACKUP_DIR/backup-metadata.txt" | sed 's/^/  /'
    echo ""
else
    log_warn "백업 메타데이터가 없습니다 (backup-metadata.txt)"
fi

# 복원 확인
log_warn "복원하면 현재 설정이 덮어쓰기됩니다!"
echo "계속하시겠습니까? (y/N)"
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log_info "복원 취소"
    exit 0
fi

# 복원 카운터
SUCCESS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0

# 현재 설정 백업
log_info "[0/3] 현재 설정 백업 중..."
CURRENT_BACKUP_DIR="$HOME/.mcp-restore-backup-$TIMESTAMP"
mkdir -p "$CURRENT_BACKUP_DIR"

if [ -f ~/.claude.json ]; then
    cp ~/.claude.json "$CURRENT_BACKUP_DIR/claude.json"
    log_success "  ✓ 현재 Claude 설정 백업: $CURRENT_BACKUP_DIR/claude.json"
fi

if [ -f ~/lazy-mcp/config.json ]; then
    mkdir -p "$CURRENT_BACKUP_DIR/lazy-mcp"
    cp ~/lazy-mcp/config.json "$CURRENT_BACKUP_DIR/lazy-mcp/config.json"
    log_success "  ✓ 현재 Lazy MCP 설정 백업: $CURRENT_BACKUP_DIR/lazy-mcp/config.json"
fi

if [ -d ~/.claude/skills ]; then
    mkdir -p "$CURRENT_BACKUP_DIR/skills"
    cp -r ~/.claude/skills/* "$CURRENT_BACKUP_DIR/skills/" 2>/dev/null || true
    log_success "  ✓ 현재 Skills 백업: $CURRENT_BACKUP_DIR/skills/"
fi

log_info "  → 현재 설정 백업 완료: $CURRENT_BACKUP_DIR"
echo ""

# 1. Claude Code 설정 복원
log_info "[1/3] Claude Code 설정 복원 중..."
if [ -f "$BACKUP_DIR/claude.json" ]; then
    cp "$BACKUP_DIR/claude.json" ~/.claude.json
    log_success "  ✓ $BACKUP_DIR/claude.json → ~/.claude.json"
    ((SUCCESS_COUNT++))
else
    log_warn "  ⊗ claude.json이 백업에 없습니다"
    ((SKIP_COUNT++))
fi

# 2. Lazy MCP 설정 복원
log_info "[2/3] Lazy MCP 설정 복원 중..."
if [ -f "$BACKUP_DIR/lazy-mcp/config.json" ]; then
    mkdir -p ~/lazy-mcp
    cp "$BACKUP_DIR/lazy-mcp/config.json" ~/lazy-mcp/config.json
    log_success "  ✓ $BACKUP_DIR/lazy-mcp/config.json → ~/lazy-mcp/config.json"
    ((SUCCESS_COUNT++))
else
    log_warn "  ⊗ lazy-mcp/config.json이 백업에 없습니다"
    ((SKIP_COUNT++))
fi

# 3. Skills 복원
log_info "[3/3] Skills 복원 중..."
if [ -d "$BACKUP_DIR/skills" ]; then
    SKILL_COUNT=$(find "$BACKUP_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)
    if [ "$SKILL_COUNT" -gt 0 ]; then
        mkdir -p ~/.claude/skills
        rm -rf ~/.claude/skills/*
        cp -r "$BACKUP_DIR/skills/"* ~/.claude/skills/
        log_success "  ✓ Skills 복원 완료 ($SKILL_COUNT개)"
        ((SUCCESS_COUNT++))
    else
        log_warn "  ⊗ 백업에 Skills가 없습니다"
        ((SKIP_COUNT++))
    fi
else
    log_warn "  ⊗ skills 디렉토리가 백업에 없습니다"
    ((SKIP_COUNT++))
fi

# 권한 설정
log_info "파일 권한 설정 중..."
if [ -f ~/.claude.json ]; then
    chmod 644 ~/.claude.json
fi

if [ -f ~/lazy-mcp/config.json ]; then
    chmod 644 ~/lazy-mcp/config.json
fi

if [ -d ~/.claude/skills ]; then
    find ~/.claude/skills -type f -name "SKILL.md" -exec chmod 644 {} \;
fi

log_success "  ✓ 권한 설정 완료"

# 완료 메시지
echo ""
log_success "========================================="
log_success "   복원 완료!"
log_success "========================================="
echo ""
echo "복원 정보:"
echo "  백업 디렉토리: $BACKUP_DIR"
echo "  성공: $SUCCESS_COUNT"
echo "  건너뜀: $SKIP_COUNT"
echo "  실패: $FAIL_COUNT"
echo ""
echo "현재 설정 백업:"
echo "  위치: $CURRENT_BACKUP_DIR"
echo "  (문제 발생 시 이 디렉토리로 롤백 가능)"
echo ""

# 복원 내용 요약
echo "복원된 내용:"
if [ -f ~/.claude.json ]; then
    echo "  ✓ Claude Code 설정 (~/.claude.json)"
fi

if [ -f ~/lazy-mcp/config.json ]; then
    echo "  ✓ Lazy MCP 설정 (~/lazy-mcp/config.json)"

    # MCP 서버 목록
    if command -v jq &> /dev/null; then
        echo ""
        echo "  MCP 서버:"
        jq -r '.mcpServers | keys[]' ~/lazy-mcp/config.json 2>/dev/null | sed 's/^/    - /' || echo "    (jq 파싱 실패)"
    fi
fi

if [ -d ~/.claude/skills ]; then
    RESTORED_SKILLS=$(find ~/.claude/skills -mindepth 1 -maxdepth 1 -type d | wc -l)
    echo "  ✓ Skills ($RESTORED_SKILLS개)"

    echo ""
    echo "  Skills 목록:"
    find ~/.claude/skills -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sed 's/^/    - /'
fi

echo ""
echo "다음 단계:"
echo ""
echo "  1. Claude Code 재시작"
echo "     pkill -f \"claude-code\""
echo ""
echo "  2. MCP 연결 확인"
echo "     Claude Code에서: /mcp"
echo ""
echo "  3. Skills 확인"
echo "     Claude Code에서: /skills"
echo ""
echo "  4. 토큰 사용량 확인"
echo "     Claude Code에서: /context"
echo ""
echo "  5. 검증 (선택)"
echo "     ./scripts/verify.sh"
echo ""

# 롤백 정보
log_info "문제가 발생하면 롤백 가능:"
echo "  ./scripts/restore.sh $CURRENT_BACKUP_DIR"
echo ""
