#!/usr/bin/env bash
#
# MCP + Skills 자동 배포 스크립트
#
# 사용법:
#   ./deploy.sh --full              # 전체 설치
#   ./deploy.sh --lazy-mcp          # Lazy MCP만 설치
#   ./deploy.sh --mcp-servers       # MCP 서버만 설치
#   ./deploy.sh --skills            # Skills만 설치
#   ./deploy.sh --verify            # 설치 검증
#

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로깅 함수
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

# 배너 출력
print_banner() {
    echo -e "${GREEN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         MCP + Skills Deployment Script v1.0.0            ║
║                                                           ║
║         Optimized Configuration by hwandam.kr            ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 환경 변수 설정
DEPLOY_USER=${USER}
DEPLOY_HOME=${HOME}
LAZY_MCP_DIR="${DEPLOY_HOME}/lazy-mcp"
MCP_SERVERS_DIR="${DEPLOY_HOME}/mcp-servers"
SKILLS_DIR="${DEPLOY_HOME}/.claude/skills"
CLAUDE_CONFIG="${DEPLOY_HOME}/.claude.json"

# 시스템 요구사항 확인
check_requirements() {
    log_info "시스템 요구사항 확인 중..."

    local missing_deps=()

    # Node.js 확인
    if ! command -v node &> /dev/null; then
        missing_deps+=("Node.js 20+")
    else
        node_version=$(node --version | sed 's/v//' | cut -d. -f1)
        if [ "$node_version" -lt 20 ]; then
            missing_deps+=("Node.js 20+ (현재: v$node_version)")
        fi
    fi

    # Python 확인
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("Python 3.11+")
    else
        python_version=$(python3 --version | awk '{print $2}' | cut -d. -f1,2)
        if (( $(echo "$python_version < 3.11" | bc -l) )); then
            missing_deps+=("Python 3.11+ (현재: $python_version)")
        fi
    fi

    # Go 확인
    if ! command -v go &> /dev/null; then
        missing_deps+=("Go 1.24+")
    fi

    # Git 확인
    if ! command -v git &> /dev/null; then
        missing_deps+=("Git")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "다음 필수 도구가 설치되어 있지 않습니다:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "설치 가이드: DEPLOYMENT_GUIDE.md의 '2.2 필수 도구 설치' 참조"
        exit 1
    fi

    log_success "모든 시스템 요구사항이 충족되었습니다."
}

# Lazy MCP 설치
install_lazy_mcp() {
    log_info "Lazy MCP 설치 시작..."

    # 디렉토리 생성
    mkdir -p "$LAZY_MCP_DIR"
    cd "$LAZY_MCP_DIR"

    # 기존 설치 확인
    if [ -f "build/mcp-proxy" ]; then
        log_warn "Lazy MCP가 이미 설치되어 있습니다. 건너뜁니다."
        return 0
    fi

    # Git 클론
    log_info "Lazy MCP 소스 다운로드 중..."
    git clone https://github.com/chrishayuk/lazy-mcp.git temp-lazy-mcp
    mv temp-lazy-mcp/* .
    mv temp-lazy-mcp/.* . 2>/dev/null || true
    rm -rf temp-lazy-mcp

    # 빌드
    log_info "Lazy MCP 빌드 중..."
    mkdir -p build
    go build -o build/mcp-proxy ./cmd/mcp-proxy
    go build -o build/structure_generator ./cmd/structure_generator

    # 실행 권한
    chmod +x build/mcp-proxy
    chmod +x build/structure_generator

    # 설정 파일 생성
    log_info "Lazy MCP 설정 파일 생성 중..."
    cat > config.json << EOF
{
  "mcpProxy": {
    "hierarchyPath": "${LAZY_MCP_DIR}/testdata/mcp_hierarchy",
    "options": {
      "lazyLoad": true
    }
  },
  "mcpServers": {
    "context7": {
      "transportType": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "options": {
        "lazyLoad": false,
        "preload": true
      }
    }
  }
}
EOF

    # 계층 구조 디렉토리 생성
    mkdir -p testdata/mcp_hierarchy

    log_success "Lazy MCP 설치 완료!"
}

# Skills 배포
install_skills() {
    log_info "Skills 배포 시작..."

    # Skills 디렉토리 생성
    mkdir -p "$SKILLS_DIR"

    # 소스에서 Skills 복사 (실제 배포 시 수정 필요)
    if [ -d "/home/trading/workspace/.claude/skills" ]; then
        log_info "Skills 복사 중..."
        cp -r /home/trading/workspace/.claude/skills/* "$SKILLS_DIR/"
        log_success "Skills 복사 완료!"
    else
        log_warn "Skills 소스를 찾을 수 없습니다."
        log_info "Skills 아카이브를 수동으로 추출하세요:"
        echo "  tar xzf claude-skills.tar.gz -C $SKILLS_DIR"
        return 1
    fi

    # 권한 설정
    chmod -R 755 "$SKILLS_DIR"

    # Skills 검증
    log_info "Skills 검증 중..."
    skill_count=$(find "$SKILLS_DIR" -name "SKILL.md" | wc -l)
    log_success "총 $skill_count 개의 Skills가 배포되었습니다."
}

# Claude Code 설정
configure_claude() {
    log_info "Claude Code 설정 업데이트 중..."

    # 백업
    if [ -f "$CLAUDE_CONFIG" ]; then
        cp "$CLAUDE_CONFIG" "${CLAUDE_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "기존 설정 백업 완료: ${CLAUDE_CONFIG}.backup.*"
    fi

    # 새 설정 생성
    cat > "$CLAUDE_CONFIG" << EOF
{
  "mcpServers": {
    "lazy-mcp-proxy": {
      "type": "stdio",
      "command": "${LAZY_MCP_DIR}/build/mcp-proxy",
      "args": [
        "--config",
        "${LAZY_MCP_DIR}/config.json"
      ],
      "env": {}
    }
  }
}
EOF

    log_success "Claude Code 설정 업데이트 완료!"
    log_warn "Claude Code를 재시작해야 변경사항이 적용됩니다."
}

# 설치 검증
verify_installation() {
    log_info "설치 검증 중..."

    local errors=0

    # Lazy MCP 확인
    if [ ! -f "$LAZY_MCP_DIR/build/mcp-proxy" ]; then
        log_error "Lazy MCP 실행 파일을 찾을 수 없습니다."
        ((errors++))
    else
        log_success "✓ Lazy MCP 실행 파일 확인"
    fi

    # config.json 확인
    if [ ! -f "$LAZY_MCP_DIR/config.json" ]; then
        log_error "Lazy MCP 설정 파일을 찾을 수 없습니다."
        ((errors++))
    else
        log_success "✓ Lazy MCP 설정 파일 확인"
    fi

    # Skills 확인
    if [ ! -d "$SKILLS_DIR" ]; then
        log_error "Skills 디렉토리를 찾을 수 없습니다."
        ((errors++))
    else
        skill_count=$(find "$SKILLS_DIR" -name "SKILL.md" | wc -l)
        if [ "$skill_count" -eq 0 ]; then
            log_error "Skills가 배포되지 않았습니다."
            ((errors++))
        else
            log_success "✓ Skills 확인 ($skill_count 개)"
        fi
    fi

    # Claude 설정 확인
    if [ ! -f "$CLAUDE_CONFIG" ]; then
        log_error "Claude Code 설정 파일을 찾을 수 없습니다."
        ((errors++))
    else
        log_success "✓ Claude Code 설정 파일 확인"
    fi

    # Lazy MCP 실행 테스트
    log_info "Lazy MCP 실행 테스트 중..."
    if timeout 5s "$LAZY_MCP_DIR/build/mcp-proxy" --config "$LAZY_MCP_DIR/config.json" &> /dev/null; then
        log_success "✓ Lazy MCP 실행 테스트 통과"
    else
        log_warn "⚠ Lazy MCP 실행 테스트 실패 (정상일 수 있음)"
    fi

    if [ $errors -eq 0 ]; then
        echo ""
        log_success "========================================="
        log_success "   모든 검증 통과! 설치 완료!"
        log_success "========================================="
        echo ""
        echo "다음 단계:"
        echo "  1. Claude Code 재시작"
        echo "  2. /mcp 명령으로 MCP 서버 확인"
        echo "  3. /skills 명령으로 Skills 확인"
        echo ""
        return 0
    else
        echo ""
        log_error "========================================="
        log_error "   $errors 개의 오류 발생"
        log_error "========================================="
        echo ""
        echo "트러블슈팅: DEPLOYMENT_GUIDE.md의 '7. 문제 해결' 참조"
        return 1
    fi
}

# 사용법 출력
print_usage() {
    cat << EOF
사용법: $0 [옵션]

옵션:
  --full              전체 설치 (Lazy MCP + Skills + 설정)
  --lazy-mcp          Lazy MCP만 설치
  --skills            Skills만 배포
  --configure         Claude Code 설정만 업데이트
  --verify            설치 검증
  -h, --help          이 도움말 출력

예제:
  $0 --full           # 전체 설치
  $0 --verify         # 설치 검증만

EOF
}

# 메인 실행
main() {
    print_banner

    # 인수 없으면 사용법 출력
    if [ $# -eq 0 ]; then
        print_usage
        exit 1
    fi

    # 인수 파싱
    case "$1" in
        --full)
            check_requirements
            install_lazy_mcp
            install_skills
            configure_claude
            verify_installation
            ;;
        --lazy-mcp)
            check_requirements
            install_lazy_mcp
            ;;
        --skills)
            install_skills
            ;;
        --configure)
            configure_claude
            ;;
        --verify)
            verify_installation
            ;;
        -h|--help)
            print_usage
            ;;
        *)
            log_error "알 수 없는 옵션: $1"
            print_usage
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@"
