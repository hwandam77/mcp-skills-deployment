# 빠른 참조 (Quick Reference)

> MCP + Skills 패키지 치트 시트 - 자주 사용하는 명령어와 워크플로우

---

## 📋 목차

- [설치 및 배포](#설치-및-배포)
- [검증 및 확인](#검증-및-확인)
- [MCP 서버 관리](#mcp-서버-관리)
- [Skills 사용](#skills-사용)
- [백업 및 복원](#백업-및-복원)
- [문제 해결 빠른 참조](#문제-해결-빠른-참조)
- [중요 경로](#중요-경로)
- [환경 변수](#환경-변수)

---

## 🚀 설치 및 배포

### 전체 자동 설치

```bash
./scripts/deploy.sh --full
```

**포함 내용**: Lazy MCP + MCP 서버 + Skills + 설정

---

### 부분 설치

```bash
# Lazy MCP만
./scripts/deploy.sh --lazy-mcp

# Skills만
./scripts/deploy.sh --skills-only

# 검증만
./scripts/deploy.sh --verify
```

---

### MCP 서버 추가

```bash
# 기본 사용법
./scripts/add-mcp.sh <server-name> <npm-package> [preload|lazy]

# Filesystem (Preload - 자주 사용)
./scripts/add-mcp.sh filesystem \
  @modelcontextprotocol/server-filesystem \
  preload \
  --allowed-directories /home/user/documents

# Slack (Lazy Load - 가끔 사용)
./scripts/add-mcp.sh slack \
  @modelcontextprotocol/server-slack \
  lazy

# Postgres (Lazy Load - 높은 토큰 비용)
./scripts/add-mcp.sh postgres \
  @modelcontextprotocol/server-postgres \
  lazy
```

**참고**: [ADD_MCP_GUIDE.md](ADD_MCP_GUIDE.md)

---

## ✅ 검증 및 확인

### 전체 검증

```bash
./scripts/verify.sh
```

**검증 항목**: 요구사항 + 설치 + 연결 + 권한

---

### 부분 검증

```bash
# 시스템 요구사항만
./scripts/verify.sh --requirements

# 설치 상태만
./scripts/verify.sh --installation

# MCP 연결만
./scripts/verify.sh --connectivity

# 파일 권한만
./scripts/verify.sh --permissions
```

---

### Claude Code에서 확인

```bash
# MCP 서버 목록
/mcp

# Skills 목록
/skills

# 토큰 사용량
/context

# 도구 목록
/tools
```

---

## 🔧 MCP 서버 관리

### Lazy MCP 상태 확인

```bash
# 프로세스 확인
ps aux | grep mcp-proxy

# 수동 실행
~/lazy-mcp/build/mcp-proxy --config ~/lazy-mcp/config.json

# 설정 파일 확인
cat ~/lazy-mcp/config.json | jq '.mcpServers'
```

---

### MCP 서버 재시작

```bash
# 1. Lazy MCP 프로세스 종료
pkill -f mcp-proxy

# 2. Claude Code 재시작
pkill -f "claude-code"

# 또는 Claude Code에서
Cmd+Shift+P → "Reload Window"
```

---

### 도구 계층 구조 재생성

```bash
cd ~/lazy-mcp

# 특정 서버
./build/structure_generator \
  --server "knowledge-base" \
  --config ./config.json \
  --output ./testdata/mcp_hierarchy

# 모든 서버
for server in codex-qwen-gemini knowledge-base ssh context7; do
  ./build/structure_generator \
    --server "$server" \
    --config ./config.json \
    --output ./testdata/mcp_hierarchy
done
```

---

## 🎯 Skills 사용

### Skills 목록 확인

```bash
# Claude Code에서
/skills

# 파일 시스템에서
ls -la ~/.claude/skills/

# 특정 Skill 내용
cat ~/.claude/skills/kb-system/SKILL.md
```

---

### Skills 호출

Claude Code에서 다음과 같이 사용:

```
# KB 시스템 (문서 관리)
"knowledge base에서 'API 설계'에 대한 문서를 검색해줘"

# KB 지식 그래프 (엔티티 및 관계)
"FastAPI와 PostgreSQL 간의 관계를 knowledge graph에 추가해줘"

# KB AI 어시스턴트 (시맨틱 검색, RAG)
"knowledge base에서 인증 관련 내용을 시맨틱 검색으로 찾아줘"

# SSH 운영
"hwandam 서버에 연결해서 디스크 사용량 확인해줘"

# GitHub 관리
"PR #123의 상태를 확인하고 리뷰를 요약해줘"

# Context7 (라이브러리 문서)
"FastAPI의 dependency injection 문서를 찾아줘"
```

---

### 새 Skill 생성

```bash
# 1. 디렉토리 생성
mkdir -p ~/.claude/skills/my-skill

# 2. SKILL.md 작성
cat > ~/.claude/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: My custom skill description
allowed-tools: tool1, tool2, tool3
---

# My Skill

Detailed instructions for Claude...
EOF

# 3. Claude Code 재시작
pkill -f "claude-code"
```

---

## 💾 백업 및 복원

### 백업

```bash
# 전체 백업
./scripts/backup.sh ~/mcp-backup

# Skills만 백업
./scripts/package-skills.sh ~/skills-backup.tar.gz

# 설정 파일만 백업
cp ~/.claude.json ~/.claude.json.backup
cp ~/lazy-mcp/config.json ~/lazy-mcp/config.json.backup
```

---

### 복원

```bash
# 전체 복원
./scripts/restore.sh ~/mcp-backup

# Skills만 복원
tar xzf ~/skills-backup.tar.gz -C ~/.claude/skills/

# 설정 파일만 복원
cp ~/.claude.json.backup ~/.claude.json
cp ~/lazy-mcp/config.json.backup ~/lazy-mcp/config.json
```

---

## 🐛 문제 해결 빠른 참조

### MCP 연결 실패

```bash
# 1. 프로세스 확인
ps aux | grep mcp-proxy

# 2. 수동 실행 테스트
~/lazy-mcp/build/mcp-proxy --config ~/lazy-mcp/config.json

# 3. 설정 파일 검증
cat ~/lazy-mcp/config.json | python3 -m json.tool

# 4. 재설치
./scripts/deploy.sh --lazy-mcp
```

---

### Skills 인식 안 됨

```bash
# 1. 디렉토리 확인
ls -la ~/.claude/skills/

# 2. 권한 확인
./scripts/verify.sh --permissions

# 3. SKILL.md 형식 확인
cat ~/.claude/skills/kb-system/SKILL.md | head -10

# 4. 재배포
./scripts/deploy.sh --skills-only
```

---

### 토큰 여전히 높음

```bash
# 1. Lazy MCP 사용 확인
cat ~/.claude.json | jq '.mcpServers'
# → "lazy-mcp-proxy"만 있어야 함

# 2. Lazy Load 설정 확인
cat ~/lazy-mcp/config.json | jq '.mcpProxy.options.lazyLoad'
# → true 여야 함

# 3. Claude Code 재시작
pkill -f "claude-code"

# 4. 토큰 재확인
# Claude Code에서: /context
```

---

### Knowledge Base 연결 오류

```bash
# 1. PostgreSQL 연결 확인
psql -h your-db-host -U your-db-user -d your-db-name -c "SELECT 1;"

# 2. MCP 서버 로그 확인
tail -f ~/lazy-mcp/logs/knowledge-base.log

# 3. 환경 변수 확인
cat ~/lazy-mcp/config.json | jq '.mcpServers."knowledge-base".env'

# 4. 재시작
pkill -f "knowledge_mcp.py"
./scripts/verify.sh --connectivity
```

---

### Claude Code 응답 없음

```bash
# 1. 프로세스 확인
ps aux | grep claude

# 2. 로그 확인
tail -f ~/.claude/logs/main.log

# 3. 강제 종료 및 재시작
pkill -9 -f "claude-code"
# VSCode에서 Claude Code 재실행

# 4. 캐시 정리 (마지막 수단)
rm -rf ~/.claude/cache/
rm -rf ~/.claude/temp/
```

---

## 📁 중요 경로

### 설정 파일

| 파일 | 경로 | 설명 |
|------|------|------|
| **Claude 설정** | `~/.claude.json` | Claude Code 메인 설정 |
| **Lazy MCP 설정** | `~/lazy-mcp/config.json` | Lazy MCP 서버 설정 |
| **KB MCP 환경 변수** | `~/service/MCP/Knowledge_Base-MCP/config/.env` | KB MCP 환경 변수 |

---

### 디렉토리

| 디렉토리 | 경로 | 설명 |
|----------|------|------|
| **Skills** | `~/.claude/skills/` | Skills 저장소 |
| **Lazy MCP** | `~/lazy-mcp/` | Lazy MCP 설치 디렉토리 |
| **도구 계층 구조** | `~/lazy-mcp/testdata/mcp_hierarchy/` | MCP 도구 계층 구조 |
| **KB MCP** | `~/service/MCP/Knowledge_Base-MCP/` | Knowledge Base MCP 서버 |
| **Codex-Qwen-Gemini** | `~/service/MCP/codex-qwen-gemini-mcp/` | Codex-Qwen-Gemini MCP 서버 |

---

### 로그 파일

| 로그 | 경로 | 설명 |
|------|------|------|
| **Claude 메인 로그** | `~/.claude/logs/main.log` | Claude Code 로그 |
| **Lazy MCP 로그** | `~/lazy-mcp/logs/mcp-proxy.log` | Lazy MCP 프록시 로그 |
| **KB MCP 로그** | `~/service/MCP/Knowledge_Base-MCP/logs/` | KB MCP 서버 로그 |

---

## 🔐 환경 변수

### Lazy MCP (config.json)

```json
{
  "mcpServers": {
    "knowledge-base": {
      "env": {
        "DB_HOST": "your-db-host",
        "DB_PORT": "5432",
        "DB_NAME": "your-db-name",
        "DB_USER": "your-db-user",
        "DB_PASSWORD": "${DB_PASSWORD}"
      }
    },
    "slack": {
      "env": {
        "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}",
        "SLACK_TEAM_ID": "T..."
      }
    }
  }
}
```

---

### Knowledge Base MCP (.env)

```bash
# 데이터베이스
DB_HOST=your-db-host
DB_PORT=5432
DB_NAME=your-db-name
DB_USER=your-db-user
DB_PASSWORD=your-password

# MCP 서버
KNOWLEDGE_MCP_HOST=127.0.0.1
KNOWLEDGE_MCP_PORT=8711

# AI 모델 (선택)
OLLAMA_HOST=http://localhost:11434
EMBEDDING_MODEL=bge-m3
LLM_MODEL=gemma3
```

---

## 📊 토큰 최적화 팁

### 1. Preload vs Lazy Load 선택

**Preload (항상 로드)**:
- 매일 사용하는 MCP
- 토큰 비용 낮음 (<1k)
- 예: filesystem, ssh, context7

**Lazy Load (필요시 로드)**:
- 가끔 사용하는 MCP
- 토큰 비용 높음 (>2k)
- 예: slack, github, postgres

---

### 2. 불필요한 MCP 제거

```bash
# config.json에서 제거
vim ~/lazy-mcp/config.json

# 해당 서버 블록 삭제
# "unused-server": { ... }  ← 삭제

# Claude Code 재시작
pkill -f "claude-code"
```

---

### 3. 도구 계층 구조 최적화

```bash
# 도구 계층 구조가 크면 재생성
cd ~/lazy-mcp
./build/structure_generator \
  --server "server-name" \
  --config ./config.json \
  --output ./testdata/mcp_hierarchy \
  --max-depth 2  # 깊이 제한
```

---

## 🔄 업데이트 빠른 참조

### Lazy MCP 업데이트

```bash
cd ~/lazy-mcp
git pull origin main
make build
./scripts/verify.sh
```

---

### Skills 업데이트

```bash
cd mcp-deployment
git pull origin main
./scripts/deploy.sh --skills-only
```

---

### MCP 서버 업데이트

```bash
# npm 패키지 업데이트
npm update -g @modelcontextprotocol/server-filesystem

# Knowledge Base MCP 업데이트
cd ~/service/MCP/Knowledge_Base-MCP
git pull origin main
source .venv-311/bin/activate
pip install -r requirements.txt
make restart
```

---

## 📝 자주 사용하는 명령어 조합

### 완전 재설치

```bash
# 1. 백업
./scripts/backup.sh ~/mcp-backup-$(date +%Y%m%d)

# 2. 제거
./scripts/uninstall.sh --full

# 3. 재설치
./scripts/deploy.sh --full

# 4. 검증
./scripts/verify.sh
```

---

### 설정 검증 및 재시작

```bash
# 1. 설정 파일 검증
cat ~/.claude.json | python3 -m json.tool
cat ~/lazy-mcp/config.json | python3 -m json.tool

# 2. 모든 프로세스 종료
pkill -f mcp-proxy
pkill -f "claude-code"

# 3. 검증
./scripts/verify.sh

# 4. Claude Code 재시작
# (VSCode에서 수동으로)
```

---

### 문제 진단 전체 흐름

```bash
# 1. 시스템 요구사항
./scripts/verify.sh --requirements

# 2. 설치 상태
./scripts/verify.sh --installation

# 3. MCP 연결
./scripts/verify.sh --connectivity

# 4. 로그 확인
tail -f ~/.claude/logs/main.log
tail -f ~/lazy-mcp/logs/mcp-proxy.log

# 5. 프로세스 확인
ps aux | grep -E "claude|mcp"

# 6. 권한 확인
./scripts/verify.sh --permissions
```

---

## 🎯 시나리오별 빠른 가이드

### 새 서버에 배포

```bash
# 1. 저장소 클론
git clone https://github.com/YOUR_REPO/mcp-deployment.git
cd mcp-deployment

# 2. 자동 설치
./scripts/deploy.sh --full

# 3. 환경 변수 설정
vim ~/lazy-mcp/config.json  # env 섹션 편집

# 4. 검증
./scripts/verify.sh

# 5. Claude Code 설정
# .claude.json이 자동으로 업데이트됨

# 6. Claude Code 재시작
```

---

### 기존 설정과 병합

```bash
# 1. 현재 설정 백업
./scripts/backup.sh ~/backup-before-merge

# 2. Skills만 배포
./scripts/deploy.sh --skills-only

# 3. Lazy MCP 설정 수동 병합
vim ~/.claude.json  # lazy-mcp-proxy 추가
vim ~/lazy-mcp/config.json  # 기존 서버 추가

# 4. 검증
./scripts/verify.sh
```

---

### Skills만 업데이트

```bash
# 1. Skills 백업
./scripts/package-skills.sh ~/skills-backup.tar.gz

# 2. 새 Skills 배포
./scripts/deploy.sh --skills-only

# 3. Claude Code 재시작
pkill -f "claude-code"

# 4. 확인
# Claude Code에서: /skills
```

---

## 🔗 관련 문서

- **[README.md](README.md)** - 프로젝트 개요
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - 완전 배포 가이드
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - 문제 해결
- **[ADD_MCP_GUIDE.md](ADD_MCP_GUIDE.md)** - MCP 서버 추가
- **[FAQ.md](FAQ.md)** - 자주 묻는 질문

---

**마지막 업데이트**: 2025-11-15
**버전**: 1.0.0
