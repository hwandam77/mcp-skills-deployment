#!/usr/bin/env bash
#
# MCP + Skills 설치 검증 스크립트
#
# 사용법:
#   ./verify.sh                    # 전체 검증
#   ./verify.sh --requirements     # 시스템 요구사항만
#   ./verify.sh --installation     # 설치 상태만
#   ./verify.sh --connectivity     # MCP 연결만
#

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 환경 변수
DEPLOY_HOME=${HOME}
LAZY_MCP_DIR="${DEPLOY_HOME}/lazy-mcp"
MCP_SERVERS_DIR="${DEPLOY_HOME}/mcp-servers"
SKILLS_DIR="${DEPLOY_HOME}/.claude/skills"
CLAUDE_CONFIG="${DEPLOY_HOME}/.claude.json"

# 통계 변수
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# 로깅 함수
log_check() {
    ((TOTAL_CHECKS++))
    echo -n "  [$TOTAL_CHECKS] $1 ... "
}

log_pass() {
    ((PASSED_CHECKS++))
    echo -e "${GREEN}✓ PASS${NC}"
}

log_fail() {
    ((FAILED_CHECKS++))
    echo -e "${RED}✗ FAIL${NC}"
    if [ -n "$1" ]; then
        echo -e "      ${RED}→ $1${NC}"
    fi
}

log_warn() {
    ((WARNINGS++))
    echo -e "${YELLOW}⚠ WARN${NC}"
    if [ -n "$1" ]; then
        echo -e "      ${YELLOW}→ $1${NC}"
    fi
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 배너
print_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         MCP + Skills Verification Script v1.0.0          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 시스템 요구사항 확인
check_requirements() {
    echo ""
    log_info "=== 시스템 요구사항 검증 ==="
    echo ""

    # Node.js
    log_check "Node.js 20+ 설치"
    if command -v node &> /dev/null; then
        node_version=$(node --version | sed 's/v//' | cut -d. -f1)
        if [ "$node_version" -ge 20 ]; then
            log_pass
            echo "      버전: $(node --version)"
        else
            log_fail "Node.js 버전이 낮습니다 (현재: v$node_version, 필요: v20+)"
        fi
    else
        log_fail "Node.js가 설치되어 있지 않습니다"
    fi

    # Python
    log_check "Python 3.11+ 설치"
    if command -v python3 &> /dev/null; then
        python_version=$(python3 --version | awk '{print $2}')
        python_major=$(echo "$python_version" | cut -d. -f1)
        python_minor=$(echo "$python_version" | cut -d. -f2)
        if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 11 ]; then
            log_pass
            echo "      버전: $python_version"
        else
            log_fail "Python 버전이 낮습니다 (현재: $python_version, 필요: 3.11+)"
        fi
    else
        log_fail "Python3가 설치되어 있지 않습니다"
    fi

    # Go
    log_check "Go 1.24+ 설치"
    if command -v go &> /dev/null; then
        go_version=$(go version | awk '{print $3}' | sed 's/go//')
        log_pass
        echo "      버전: $go_version"
    else
        log_warn "Go가 설치되어 있지 않습니다 (Lazy MCP 빌드에만 필요)"
    fi

    # Git
    log_check "Git 설치"
    if command -v git &> /dev/null; then
        log_pass
        echo "      버전: $(git --version)"
    else
        log_fail "Git이 설치되어 있지 않습니다"
    fi

    # PostgreSQL (선택)
    log_check "PostgreSQL 설치 (선택)"
    if command -v psql &> /dev/null; then
        log_pass
        echo "      버전: $(psql --version)"
    else
        log_warn "PostgreSQL이 설치되어 있지 않습니다 (Knowledge Base MCP 사용 시 필요)"
    fi

    # Ollama (선택)
    log_check "Ollama 설치 (선택)"
    if command -v ollama &> /dev/null; then
        log_pass
        echo "      버전: $(ollama --version 2>&1 | head -1)"
    else
        log_warn "Ollama가 설치되어 있지 않습니다 (AI 기능 사용 시 필요)"
    fi
}

# 설치 상태 확인
check_installation() {
    echo ""
    log_info "=== 설치 상태 검증 ==="
    echo ""

    # Lazy MCP 디렉토리
    log_check "Lazy MCP 디렉토리"
    if [ -d "$LAZY_MCP_DIR" ]; then
        log_pass
        echo "      위치: $LAZY_MCP_DIR"
    else
        log_fail "Lazy MCP 디렉토리가 없습니다"
    fi

    # Lazy MCP 실행 파일
    log_check "Lazy MCP 실행 파일 (mcp-proxy)"
    if [ -f "$LAZY_MCP_DIR/build/mcp-proxy" ]; then
        if [ -x "$LAZY_MCP_DIR/build/mcp-proxy" ]; then
            log_pass
            echo "      크기: $(ls -lh "$LAZY_MCP_DIR/build/mcp-proxy" | awk '{print $5}')"
        else
            log_fail "mcp-proxy에 실행 권한이 없습니다"
        fi
    else
        log_fail "mcp-proxy 파일이 없습니다"
    fi

    # Lazy MCP 설정 파일
    log_check "Lazy MCP 설정 파일 (config.json)"
    if [ -f "$LAZY_MCP_DIR/config.json" ]; then
        if python3 -m json.tool < "$LAZY_MCP_DIR/config.json" > /dev/null 2>&1; then
            log_pass
            server_count=$(python3 -c "import json; print(len(json.load(open('$LAZY_MCP_DIR/config.json'))['mcpServers']))" 2>/dev/null || echo "0")
            echo "      등록된 MCP 서버: $server_count 개"
        else
            log_fail "config.json이 유효한 JSON이 아닙니다"
        fi
    else
        log_fail "config.json 파일이 없습니다"
    fi

    # Skills 디렉토리
    log_check "Skills 디렉토리"
    if [ -d "$SKILLS_DIR" ]; then
        log_pass
        skill_count=$(find "$SKILLS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l)
        echo "      Skills 개수: $skill_count 개"
    else
        log_fail "Skills 디렉토리가 없습니다"
    fi

    # Skills 파일 검증
    log_check "Skills 파일 유효성"
    if [ -d "$SKILLS_DIR" ]; then
        invalid_skills=0
        for skill_file in "$SKILLS_DIR"/*/SKILL.md; do
            if [ -f "$skill_file" ]; then
                # frontmatter 확인
                if ! grep -q "^---$" "$skill_file"; then
                    ((invalid_skills++))
                fi
            fi
        done
        if [ $invalid_skills -eq 0 ]; then
            log_pass
        else
            log_warn "$invalid_skills 개의 Skills에 문제가 있습니다"
        fi
    else
        log_fail "Skills 디렉토리가 없어 검증할 수 없습니다"
    fi

    # Claude Code 설정
    log_check "Claude Code 설정 파일 (.claude.json)"
    if [ -f "$CLAUDE_CONFIG" ]; then
        if python3 -m json.tool < "$CLAUDE_CONFIG" > /dev/null 2>&1; then
            log_pass
            # lazy-mcp-proxy 확인
            if grep -q "lazy-mcp-proxy" "$CLAUDE_CONFIG"; then
                echo "      ✓ lazy-mcp-proxy 설정됨"
            else
                echo "      ⚠ lazy-mcp-proxy가 설정되지 않았습니다"
            fi
        else
            log_fail ".claude.json이 유효한 JSON이 아닙니다"
        fi
    else
        log_fail ".claude.json 파일이 없습니다"
    fi
}

# MCP 연결 테스트
check_connectivity() {
    echo ""
    log_info "=== MCP 연결 테스트 ==="
    echo ""

    # Lazy MCP 실행 테스트
    log_check "Lazy MCP 프록시 실행 테스트"
    if [ -f "$LAZY_MCP_DIR/build/mcp-proxy" ]; then
        if timeout 5s "$LAZY_MCP_DIR/build/mcp-proxy" --config "$LAZY_MCP_DIR/config.json" &> /tmp/mcp-test.log; then
            log_pass
        else
            exit_code=$?
            if [ $exit_code -eq 124 ]; then
                # timeout (정상)
                log_pass
                echo "      (5초 타임아웃 - 정상)"
            else
                log_fail "실행 중 오류 발생 (종료 코드: $exit_code)"
                echo "      로그: /tmp/mcp-test.log"
            fi
        fi
    else
        log_fail "mcp-proxy 파일이 없습니다"
    fi
}

# 권한 확인
check_permissions() {
    echo ""
    log_info "=== 파일 권한 검증 ==="
    echo ""

    # Lazy MCP 실행 권한
    log_check "Lazy MCP 실행 권한"
    if [ -x "$LAZY_MCP_DIR/build/mcp-proxy" ]; then
        log_pass
    else
        log_fail "mcp-proxy에 실행 권한이 없습니다"
    fi

    # Skills 읽기 권한
    log_check "Skills 디렉토리 읽기 권한"
    if [ -r "$SKILLS_DIR" ]; then
        log_pass
    else
        log_fail "Skills 디렉토리에 읽기 권한이 없습니다"
    fi

    # Claude 설정 읽기 권한
    log_check "Claude 설정 파일 읽기 권한"
    if [ -r "$CLAUDE_CONFIG" ]; then
        log_pass
    else
        log_fail ".claude.json에 읽기 권한이 없습니다"
    fi
}

# 환경 정보 출력
print_environment() {
    echo ""
    log_info "=== 환경 정보 ==="
    echo ""
    echo "  OS: $(uname -s)"
    echo "  Architecture: $(uname -m)"
    echo "  Kernel: $(uname -r)"
    echo "  User: $USER"
    echo "  Home: $HOME"
    echo "  Shell: $SHELL"
    echo ""
}

# 요약 출력
print_summary() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                     검증 요약                             ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  총 검사: ${BLUE}$TOTAL_CHECKS${NC}"
    echo -e "  통과: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "  실패: ${RED}$FAILED_CHECKS${NC}"
    echo -e "  경고: ${YELLOW}$WARNINGS${NC}"
    echo ""

    if [ $FAILED_CHECKS -eq 0 ]; then
        if [ $WARNINGS -eq 0 ]; then
            echo -e "${GREEN}✓ 모든 검증 통과! 완벽한 상태입니다.${NC}"
        else
            echo -e "${YELLOW}⚠ 경고가 있지만 사용 가능합니다.${NC}"
        fi
        echo ""
        echo "다음 단계:"
        echo "  1. Claude Code 재시작"
        echo "  2. /mcp 명령으로 MCP 서버 확인"
        echo "  3. /skills 명령으로 Skills 확인"
        echo ""
        return 0
    else
        echo -e "${RED}✗ $FAILED_CHECKS 개의 검사 실패${NC}"
        echo ""
        echo "문제 해결:"
        echo "  - TROUBLESHOOTING.md 참조"
        echo "  - 로그 확인: /tmp/mcp-test.log"
        echo "  - deploy.sh 재실행 권장"
        echo ""
        return 1
    fi
}

# 사용법
print_usage() {
    cat << EOF
사용법: $0 [옵션]

옵션:
  --requirements      시스템 요구사항만 검증
  --installation      설치 상태만 검증
  --connectivity      MCP 연결만 테스트
  --permissions       파일 권한만 확인
  --environment       환경 정보 출력
  -h, --help          이 도움말 출력

옵션 없이 실행 시 전체 검증 수행

예제:
  $0                  # 전체 검증
  $0 --requirements   # 시스템 요구사항만
  $0 --connectivity   # MCP 연결 테스트만

EOF
}

# 메인
main() {
    print_banner

    case "${1:-}" in
        --requirements)
            check_requirements
            ;;
        --installation)
            check_installation
            ;;
        --connectivity)
            check_connectivity
            ;;
        --permissions)
            check_permissions
            ;;
        --environment)
            print_environment
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        "")
            # 전체 검증
            print_environment
            check_requirements
            check_installation
            check_permissions
            check_connectivity
            print_summary
            exit $?
            ;;
        *)
            echo "알 수 없는 옵션: $1"
            print_usage
            exit 1
            ;;
    esac

    # 부분 검증 시 요약
    if [ $# -gt 0 ]; then
        echo ""
        echo "검사 완료: $PASSED_CHECKS/$TOTAL_CHECKS 통과"
        if [ $FAILED_CHECKS -gt 0 ]; then
            echo -e "${RED}실패: $FAILED_CHECKS${NC}"
            exit 1
        fi
    fi
}

main "$@"
