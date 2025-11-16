#!/usr/bin/env bash
#
# MCP + Skills 백업 스크립트
#
# 사용법:
#   ./backup.sh [output-directory]
#
# 예시:
#   ./backup.sh ~/mcp-backup
#   ./backup.sh ~/mcp-backup-20251115
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
║            MCP + Skills Backup Script v1.0.0             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 사용법
print_usage() {
    cat << EOF
사용법: $0 [output-directory]

파라미터:
  output-directory    백업 파일을 저장할 디렉토리 (기본값: ~/mcp-backup-YYYYMMDD_HHMMSS)

백업 내용:
  - ~/.claude.json (Claude Code 설정)
  - ~/lazy-mcp/config.json (Lazy MCP 설정)
  - ~/.claude/skills/ (전체 Skills)
  - 메타데이터 (버전, 날짜 등)

예시:
  $0                              # 기본 위치에 백업
  $0 ~/mcp-backup                 # 특정 디렉토리에 백업
  $0 ~/mcp-backup-20251115        # 날짜 포함 백업

EOF
}

# 인수 처리
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
    exit 0
fi

# 백업 디렉토리
BACKUP_DIR="${1:-$HOME/mcp-backup-$(date +%Y%m%d_%H%M%S)}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

print_banner

log_info "MCP + Skills 백업 시작..."
echo ""
echo "  백업 디렉토리: $BACKUP_DIR"
echo "  타임스탬프: $TIMESTAMP"
echo ""

# 백업 디렉토리 생성
if [ -d "$BACKUP_DIR" ]; then
    log_warn "백업 디렉토리가 이미 존재합니다: $BACKUP_DIR"
    echo "덮어쓰시겠습니까? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "백업 취소"
        exit 0
    fi
    rm -rf "$BACKUP_DIR"
fi

mkdir -p "$BACKUP_DIR"
log_success "백업 디렉토리 생성: $BACKUP_DIR"

# 백업 카운터
SUCCESS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0

# 1. Claude Code 설정 백업
log_info "[1/4] Claude Code 설정 백업 중..."
if [ -f ~/.claude.json ]; then
    cp ~/.claude.json "$BACKUP_DIR/claude.json"
    log_success "  ✓ ~/.claude.json → $BACKUP_DIR/claude.json"
    ((SUCCESS_COUNT++))
else
    log_warn "  ⊗ ~/.claude.json 파일이 없습니다"
    ((SKIP_COUNT++))
fi

# 2. Lazy MCP 설정 백업
log_info "[2/4] Lazy MCP 설정 백업 중..."
if [ -f ~/lazy-mcp/config.json ]; then
    mkdir -p "$BACKUP_DIR/lazy-mcp"
    cp ~/lazy-mcp/config.json "$BACKUP_DIR/lazy-mcp/config.json"
    log_success "  ✓ ~/lazy-mcp/config.json → $BACKUP_DIR/lazy-mcp/config.json"
    ((SUCCESS_COUNT++))
else
    log_warn "  ⊗ ~/lazy-mcp/config.json 파일이 없습니다"
    ((SKIP_COUNT++))
fi

# 3. Skills 백업
log_info "[3/4] Skills 백업 중..."
if [ -d ~/.claude/skills ]; then
    SKILL_COUNT=$(find ~/.claude/skills -mindepth 1 -maxdepth 1 -type d | wc -l)
    if [ "$SKILL_COUNT" -gt 0 ]; then
        mkdir -p "$BACKUP_DIR/skills"
        cp -r ~/.claude/skills/* "$BACKUP_DIR/skills/" 2>/dev/null || true
        log_success "  ✓ Skills 백업 완료 ($SKILL_COUNT개)"
        ((SUCCESS_COUNT++))
    else
        log_warn "  ⊗ Skills 디렉토리가 비어 있습니다"
        ((SKIP_COUNT++))
    fi
else
    log_warn "  ⊗ ~/.claude/skills 디렉토리가 없습니다"
    ((SKIP_COUNT++))
fi

# 4. 메타데이터 생성
log_info "[4/4] 메타데이터 생성 중..."
cat > "$BACKUP_DIR/backup-metadata.txt" << EOF
MCP + Skills 백업 메타데이터
=============================

백업 정보
---------
백업 날짜: $(date +"%Y-%m-%d %H:%M:%S")
백업 타임스탬프: $TIMESTAMP
백업 디렉토리: $BACKUP_DIR
호스트: $(hostname)
사용자: $(whoami)

시스템 정보
-----------
OS: $(uname -s)
커널: $(uname -r)
아키텍처: $(uname -m)

소프트웨어 버전
--------------
Node.js: $(node --version 2>/dev/null || echo "Not installed")
Python: $(python3 --version 2>/dev/null || echo "Not installed")
Go: $(go version 2>/dev/null || echo "Not installed")

백업 내용
---------
EOF

if [ -f "$BACKUP_DIR/claude.json" ]; then
    echo "✓ Claude Code 설정 (~/.claude.json)" >> "$BACKUP_DIR/backup-metadata.txt"
fi

if [ -f "$BACKUP_DIR/lazy-mcp/config.json" ]; then
    echo "✓ Lazy MCP 설정 (~/lazy-mcp/config.json)" >> "$BACKUP_DIR/backup-metadata.txt"

    # MCP 서버 목록 추가
    echo "" >> "$BACKUP_DIR/backup-metadata.txt"
    echo "MCP 서버:" >> "$BACKUP_DIR/backup-metadata.txt"
    if command -v jq &> /dev/null; then
        jq -r '.mcpServers | keys[]' "$BACKUP_DIR/lazy-mcp/config.json" 2>/dev/null | sed 's/^/  - /' >> "$BACKUP_DIR/backup-metadata.txt" || echo "  (jq 파싱 실패)" >> "$BACKUP_DIR/backup-metadata.txt"
    else
        echo "  (jq 미설치)" >> "$BACKUP_DIR/backup-metadata.txt"
    fi
fi

if [ -d "$BACKUP_DIR/skills" ]; then
    BACKED_UP_SKILLS=$(find "$BACKUP_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)
    echo "✓ Skills ($BACKED_UP_SKILLS개)" >> "$BACKUP_DIR/backup-metadata.txt"

    # Skills 목록 추가
    echo "" >> "$BACKUP_DIR/backup-metadata.txt"
    echo "Skills 목록:" >> "$BACKUP_DIR/backup-metadata.txt"
    find "$BACKUP_DIR/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sed 's/^/  - /' >> "$BACKUP_DIR/backup-metadata.txt"
fi

echo "" >> "$BACKUP_DIR/backup-metadata.txt"
echo "통계" >> "$BACKUP_DIR/backup-metadata.txt"
echo "----" >> "$BACKUP_DIR/backup-metadata.txt"
echo "성공: $SUCCESS_COUNT" >> "$BACKUP_DIR/backup-metadata.txt"
echo "건너뜀: $SKIP_COUNT" >> "$BACKUP_DIR/backup-metadata.txt"
echo "실패: $FAIL_COUNT" >> "$BACKUP_DIR/backup-metadata.txt"

log_success "  ✓ 메타데이터 생성: $BACKUP_DIR/backup-metadata.txt"
((SUCCESS_COUNT++))

# 5. 압축 옵션
echo ""
log_info "백업을 압축하시겠습니까? (y/N)"
read -r -n 1 response
echo ""

if [[ "$response" =~ ^[Yy]$ ]]; then
    ARCHIVE_FILE="$BACKUP_DIR.tar.gz"
    log_info "백업 압축 중: $ARCHIVE_FILE"

    tar czf "$ARCHIVE_FILE" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"

    if [ $? -eq 0 ]; then
        ARCHIVE_SIZE=$(du -h "$ARCHIVE_FILE" | cut -f1)
        log_success "  ✓ 압축 완료: $ARCHIVE_FILE ($ARCHIVE_SIZE)"

        log_info "원본 디렉토리를 삭제하시겠습니까? (y/N)"
        read -r -n 1 response2
        echo ""

        if [[ "$response2" =~ ^[Yy]$ ]]; then
            rm -rf "$BACKUP_DIR"
            log_success "  ✓ 원본 디렉토리 삭제: $BACKUP_DIR"
        fi
    else
        log_error "  ✗ 압축 실패"
        ((FAIL_COUNT++))
    fi
fi

# 백업 크기 계산
if [ -d "$BACKUP_DIR" ]; then
    BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
else
    BACKUP_SIZE="N/A (압축됨)"
fi

# 완료 메시지
echo ""
log_success "========================================="
log_success "   백업 완료!"
log_success "========================================="
echo ""
echo "백업 정보:"
echo "  위치: $BACKUP_DIR"
if [ -f "$ARCHIVE_FILE" ]; then
    echo "  압축 파일: $ARCHIVE_FILE"
    echo "  압축 크기: $(du -h "$ARCHIVE_FILE" | cut -f1)"
else
    echo "  크기: $BACKUP_SIZE"
fi
echo "  성공: $SUCCESS_COUNT"
echo "  건너뜀: $SKIP_COUNT"
echo "  실패: $FAIL_COUNT"
echo ""

# 메타데이터 출력
if [ -f "$BACKUP_DIR/backup-metadata.txt" ]; then
    echo "백업 내용:"
    grep "^✓" "$BACKUP_DIR/backup-metadata.txt" | sed 's/^/  /'
fi

echo ""
echo "복원 방법:"
if [ -f "$ARCHIVE_FILE" ]; then
    echo "  tar xzf $ARCHIVE_FILE"
    echo "  ./scripts/restore.sh $(basename "$BACKUP_DIR")"
else
    echo "  ./scripts/restore.sh $BACKUP_DIR"
fi
echo ""

log_info "메타데이터 확인: cat $BACKUP_DIR/backup-metadata.txt"
echo ""
