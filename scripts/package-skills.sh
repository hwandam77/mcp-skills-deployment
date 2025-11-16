#!/usr/bin/env bash
#
# Skills 패키징 스크립트
# 원본 시스템에서 Skills를 압축하여 배포 가능한 아카이브 생성
#
# 사용법:
#   ./package-skills.sh [출력_디렉토리]
#

set -e

# 색상
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 변수
SKILLS_SOURCE="/home/trading/workspace/.claude/skills"
OUTPUT_DIR="${1:-$(pwd)}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/claude-skills-$TIMESTAMP.tar.gz"

log_info "Skills 패키징 시작..."
echo ""

# Skills 소스 확인
if [ ! -d "$SKILLS_SOURCE" ]; then
    echo "오류: Skills 소스 디렉토리를 찾을 수 없습니다: $SKILLS_SOURCE"
    exit 1
fi

# Skills 목록
log_info "패키징할 Skills:"
for skill_dir in "$SKILLS_SOURCE"/*/; do
    skill_name=$(basename "$skill_dir")
    echo "  - $skill_name"
done
echo ""

# 압축
log_info "압축 중..."
cd "$SKILLS_SOURCE"
tar czf "$OUTPUT_FILE" \
    kb-system/ \
    kb-knowledge-graph/ \
    kb-ai-assistant/ \
    ssh-operator/ \
    github-manager/ \
    context7-docs/ \
    codex-architect/ \
    qwen-code-engineer/ \
    gemini-content-creator/ \
    sequential-thinker/ \
    2>/dev/null || true

# 결과
if [ -f "$OUTPUT_FILE" ]; then
    file_size=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    log_success "패키징 완료!"
    echo ""
    echo "  파일: $OUTPUT_FILE"
    echo "  크기: $file_size"
    echo ""
    echo "배포 방법:"
    echo "  1. 새 시스템으로 전송:"
    echo "     scp $OUTPUT_FILE user@new-system:~/"
    echo ""
    echo "  2. 새 시스템에서 압축 해제:"
    echo "     mkdir -p ~/.claude/skills"
    echo "     tar xzf ~/$(basename $OUTPUT_FILE) -C ~/.claude/skills/"
    echo ""
else
    echo "오류: 패키징 실패"
    exit 1
fi
