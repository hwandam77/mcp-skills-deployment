# MCP + Skills 완전 배포 가이드

> **목적**: hwandam.kr의 최적화된 MCP + Skills 구성을 다른 환경에 배포하는 완전 가이드
>
> **대상**: Linux/macOS 환경, Claude Code 사용자
>
> **난이도**: 중급 (터미널 기본 명령어 숙지 필요)

---

## 📋 목차

1. [시스템 요구사항](#1-시스템-요구사항)
2. [사전 준비](#2-사전-준비)
3. [Lazy MCP 설치](#3-lazy-mcp-설치)
4. [MCP 서버 설치](#4-mcp-서버-설치)
5. [Skills 배포](#5-skills-배포)
6. [통합 테스트](#6-통합-테스트)
7. [문제 해결](#7-문제-해결)
8. [고급 설정](#8-고급-설정)

---

## 1. 시스템 요구사항

### 필수 요구사항

#### 운영체제
- ✅ Linux (Ubuntu 20.04+, Debian 11+)
- ✅ macOS (11.0+)
- ⚠️ Windows WSL2 (Ubuntu 22.04+)

#### 소프트웨어
```bash
# 필수
- Claude Code (최신 버전)
- Node.js 20+ (MCP 서버용)
- Git 2.30+
- Go 1.24+ (Lazy MCP 빌드용)

# 선택 (AI 기능 사용 시)
- Ollama (BGE-M3, Gemma3 모델)
- PostgreSQL 14+ (선택, PostgreSQL MCP 사용시)
```

#### 디스크 공간
- 최소: 500MB
- 권장: 2GB (AI 모델 포함)

#### 메모리
- 최소: 4GB RAM
- 권장: 8GB RAM (Ollama 사용 시)

---

## 2. 사전 준비

### 2.1 환경 변수 설정

배포할 환경의 사용자 정보를 확인합니다:

```bash
# 현재 사용자 확인
echo $USER

# 홈 디렉토리 확인
echo $HOME

# 환경 변수 설정 (배포 스크립트에서 사용)
export DEPLOY_USER=$USER
export DEPLOY_HOME=$HOME
export DEPLOY_DIR="$HOME/mcp-deployment"
```

### 2.2 필수 도구 설치

```bash
# Node.js 20+ 설치 (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Python 3.11+ 설치 (Ubuntu/Debian)
sudo apt-get install -y python3.11 python3.11-venv python3-pip

# Go 1.24+ 설치
wget https://go.dev/dl/go1.25.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.25.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# Git 설치
sudo apt-get install -y git

# 설치 확인
node --version   # v20.x.x 이상
python3 --version # 3.11.x 이상
go version       # go1.25.4 이상
git --version    # 2.30.x 이상
```

### 2.3 Claude Code 설정 확인

```bash
# Claude Code 설정 디렉토리 확인
ls -la ~/.claude/

# 없으면 생성
mkdir -p ~/.claude/skills
```

---

## 3. Lazy MCP 설치

Lazy MCP는 MCP 서버를 자동으로 로드하여 토큰을 96% 절감합니다.

### 3.1 Lazy MCP 다운로드 및 빌드

```bash
# 설치 디렉토리 생성
mkdir -p ~/lazy-mcp
cd ~/lazy-mcp

# 소스 클론
git clone https://github.com/chrishayuk/lazy-mcp.git .

# 빌드
go build -o build/mcp-proxy ./cmd/mcp-proxy
go build -o build/structure_generator ./cmd/structure_generator

# 빌드 확인
ls -lh build/
# -rwxr-xr-x mcp-proxy
# -rwxr-xr-x structure_generator
```

### 3.2 Lazy MCP 설정 파일 생성

```bash
# config.json 생성
cat > ~/lazy-mcp/config.json << 'EOF'
{
  "mcpProxy": {
    "hierarchyPath": "DEPLOY_HOME/lazy-mcp/testdata/mcp_hierarchy",
    "options": {
      "lazyLoad": true
    }
  },
  "mcpServers": {
      "transportType": "stdio",
      "command": "node",
      "options": {
        "lazyLoad": false,
        "preload": true
      }
    },
      "transportType": "stdio",
      "command": "node",
      "options": {
        "lazyLoad": false,
        "preload": true
      }
    },
    "context7": {
      "transportType": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "options": {
        "lazyLoad": false,
        "preload": true
      }
    },
    "ssh": {
      "transportType": "stdio",
      "command": "DEPLOY_HOME/mcp-servers/mcp-ssh/mcp-ssh",
      "args": ["--allowed-hosts", "*"],
      "options": {
        "lazyLoad": false,
        "preload": true
      }
    },
    "github": {
      "transportType": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_TOKEN"
      },
      "options": {
        "lazyLoad": true,
        "preload": false
      }
    }
  }
}
EOF

# DEPLOY_HOME을 실제 경로로 치환
sed -i "s|DEPLOY_HOME|$HOME|g" ~/lazy-mcp/config.json
```

### 3.3 도구 계층 구조 생성

```bash
# 계층 구조 디렉토리 생성
mkdir -p ~/lazy-mcp/testdata/mcp_hierarchy

# 나중에 MCP 서버 설치 후 생성
# (각 MCP 서버의 도구 목록을 자동 생성)
```

---

## 4. MCP 서버 설치

### 4.1 MCP 서버 디렉토리 구조

```bash
# MCP 서버 설치 디렉토리 생성
mkdir -p ~/mcp-servers
cd ~/mcp-servers
```


```bash
cd ~/mcp-servers

# 소스 다운로드

# 의존성 설치
npm install

# .env 설정
cat > .env << 'EOF'
PORT=39210
CODEX_CLI_PATH=codex
QWEN_CLI_PATH=qwen
GEMINI_CLI_PATH=gemini
CLI_TIMEOUT_MS=300000
LOG_LEVEL=INFO
EOF

# 테스트
node src/server-stdio.js
# Ctrl+C로 종료
```

**주의**: Codex, Qwen, Gemini CLI가 설치되어 있어야 합니다.

```bash
# CLI 설치 확인
codex --version
qwen --version
gemini --version

# 설치 안 되어 있으면:
# npm install -g @anthropic/codex-cli
# npm install -g @qwen/cli
# npm install -g @google/gemini-cli

# 인증
codex auth login
qwen auth login
gemini auth login
```


```bash
cd ~/mcp-servers

# 소스 다운로드

# Python 가상환경 생성
python3.11 -m venv .venv
source .venv/bin/activate

# 의존성 설치
pip install -r requirements.txt

# .env 설정
cat > config/.env << 'EOF'
DB_HOST=localhost
DB_PORT=5432
DB_NAME=knowledge_base_db
DB_USER=your_db_user
DB_PASSWORD=${DB_PASSWORD}

KNOWLEDGE_MCP_HOST=127.0.0.1
KNOWLEDGE_MCP_PORT=8711

USE_SSH_TUNNEL=false
EOF

# Node.js 래퍼 생성 (stdio 지원)
cat > local_mcp/kb-mcp-wrapper.js << 'EOF'
#!/usr/bin/env node
const { spawn } = require('child_process');
const path = require('path');

const venvPython = path.join(__dirname, '..', '.venv', 'bin', 'python3');
const mcpScript = path.join(__dirname, 'kb_mcp_stdio.py');

const child = spawn(venvPython, [mcpScript], {
  stdio: 'inherit',
  env: process.env
});

child.on('exit', (code) => {
  process.exit(code || 0);
});
EOF

chmod +x local_mcp/kb-mcp-wrapper.js

# 테스트 (PostgreSQL 연결 필요)
node local_mcp/kb-mcp-wrapper.js
# Ctrl+C로 종료
```

**주의**: PostgreSQL + pgvector가 설치되어 있어야 합니다.

```bash
# PostgreSQL 설치 (Ubuntu/Debian)
sudo apt-get install -y postgresql-14 postgresql-contrib-14

# pgvector 설치
sudo apt-get install -y postgresql-14-pgvector

# 데이터베이스 생성
sudo -u postgres psql << 'EOF'
CREATE DATABASE knowledge_base_db;
CREATE USER your_db_user WITH PASSWORD 'your_db_password';
GRANT ALL PRIVILEGES ON DATABASE knowledge_base_db TO your_db_user;
\c knowledge_base_db
CREATE EXTENSION vector;
EOF
```

### 4.4 SSH MCP 설치

```bash
cd ~/mcp-servers

# 소스 다운로드
git clone https://github.com/zueai/mcp-ssh.git
cd mcp-ssh

# Go 빌드
go build -o mcp-ssh

# 실행 권한
chmod +x mcp-ssh

# 테스트
./mcp-ssh --allowed-hosts "*"
# Ctrl+C로 종료
```

### 4.5 도구 계층 구조 생성

```bash
cd ~/lazy-mcp

# 각 MCP 서버의 도구 계층 생성
  echo "Generating hierarchy for $server..."
  timeout 30s ./build/structure_generator \
    --server "$server" \
    --config ./config.json \
    --output ./testdata/mcp_hierarchy || true
done

# 생성된 파일 확인
ls -lh testdata/mcp_hierarchy/
# root.json
# ssh/
```

---

## 5. Skills 배포

### 5.1 Skills 디렉토리 생성

```bash
# Skills 디렉토리 생성
mkdir -p ~/.claude/skills
cd ~/.claude/skills
```

### 5.2 Skills 다운로드

**방법 1: Git에서 다운로드**

```bash
# Skills 저장소 클론
git clone https://github.com/YOUR_REPO/claude-skills.git temp-skills

# Skills 복사
cp -r temp-skills/skills/* ~/.claude/skills/

# 임시 디렉토리 삭제
rm -rf temp-skills
```

**방법 2: 수동 복사 (원본 시스템에서)**

```bash
# 원본 시스템에서 압축
cd /home/trading/workspace/.claude/skills
tar czf ~/claude-skills.tar.gz \
  kb-system/ \
  kb-knowledge-graph/ \
  kb-ai-assistant/ \
  ssh-operator/ \
  github-manager/ \
  context7-docs/ \
  codex-architect/ \
  qwen-code-engineer/ \
  gemini-content-creator/ \
  sequential-thinker/

# 새 시스템으로 전송
scp ~/claude-skills.tar.gz user@new-system:~/

# 새 시스템에서 압축 해제
cd ~/.claude/skills
tar xzf ~/claude-skills.tar.gz
```

### 5.3 Skills 목록 확인

```bash
ls -la ~/.claude/skills/

# 예상 출력:
# drwxr-xr-x codex-architect/
# drwxr-xr-x context7-docs/
# drwxr-xr-x gemini-content-creator/
# drwxr-xr-x github-manager/
# drwxr-xr-x kb-ai-assistant/
# drwxr-xr-x kb-knowledge-graph/
# drwxr-xr-x kb-system/
# drwxr-xr-x qwen-code-engineer/
# drwxr-xr-x sequential-thinker/
# drwxr-xr-x ssh-operator/
```

---

## 6. 통합 테스트

### 6.1 Claude Code 설정 업데이트

```bash
# .claude.json 백업
cp ~/.claude.json ~/.claude.json.backup

# Lazy MCP 설정
cat > ~/.claude.json << EOF
{
  "mcpServers": {
    "lazy-mcp-proxy": {
      "type": "stdio",
      "command": "$HOME/lazy-mcp/build/mcp-proxy",
      "args": [
        "--config",
        "$HOME/lazy-mcp/config.json"
      ],
      "env": {}
    }
  }
}
EOF
```

### 6.2 Claude Code 재시작

```bash
# Claude Code 프로세스 종료
pkill -f "claude-code"

# 또는 GUI에서 재시작

# 재시작 후 터미널에서 확인
# Claude Code 실행
```

### 6.3 MCP 연결 확인

Claude Code에서:

```
/mcp
```

**예상 출력**:
```
Connected MCP Servers:
✅ lazy-mcp-proxy
   - context7 (preloaded)
   - ssh (preloaded)
   - github (lazy-load)
```

### 6.4 Skills 확인

Claude Code에서:

```
/skills
```

**예상 출력**:
```
Available Skills:
- codex-architect
- context7-docs
- gemini-content-creator
- github-manager
- kb-ai-assistant
- kb-knowledge-graph
- kb-system
- qwen-code-engineer
- sequential-thinker
- ssh-operator
```

### 6.5 토큰 사용량 확인

Claude Code에서:

```
/context
```

**예상 출력**:
```
Token Usage: 158k/200k (79%)
- MCP Tools: ~2.7k (Lazy MCP 덕분에 매우 낮음)
- Skills: ~155k
```

### 6.6 기능 테스트

#### 테스트 1: KB 검색
```
"KB에서 MCP 검색해줘"
→ kb-system의 kb_search 사용
```

#### 테스트 2: 시맨틱 검색 (AI 기능)
```
"WebSocket과 유사한 문서 찾아줘"
→ kb-ai-assistant의 kb_search_semantic 사용
```

#### 테스트 3: 지식 그래프
```
"FastAPI 엔티티 생성해줘"
→ kb-knowledge-graph의 kg_create_entities 사용
```

#### 테스트 4: SSH 연결
```
"localhost에 SSH 연결해줘"
→ ssh-operator의 ssh_connect 사용
```

---

## 7. 문제 해결

### 7.1 MCP 서버 연결 실패

**증상**:
```
/mcp
❌ lazy-mcp-proxy: Connection failed
```

**해결**:

1. Lazy MCP 프로세스 확인
```bash
ps aux | grep mcp-proxy
```

2. 설정 파일 확인
```bash
cat ~/.claude.json
cat ~/lazy-mcp/config.json
```

3. 경로 확인
```bash
ls -lh ~/lazy-mcp/build/mcp-proxy
ls -lh ~/mcp-servers/
```

4. 수동 실행 테스트
```bash
~/lazy-mcp/build/mcp-proxy --config ~/lazy-mcp/config.json
```


**증상**:
```
```

**해결**:

1. PostgreSQL 실행 확인
```bash
sudo systemctl status postgresql
```

2. 데이터베이스 연결 테스트
```bash
psql -h localhost -U your_db_user -d knowledge_base_db
```

3. Python 환경 확인
```bash
source .venv/bin/activate
python3 -c "import asyncpg; print('OK')"
```

4. 래퍼 스크립트 확인
```bash
node local_mcp/kb-mcp-wrapper.js
```

### 7.3 Skills 인식 안 됨

**증상**:
```
/skills
No skills found
```

**해결**:

1. Skills 디렉토리 확인
```bash
ls -la ~/.claude/skills/
```

2. SKILL.md 파일 확인
```bash
for skill in ~/.claude/skills/*/; do
  echo "=== $skill ==="
  ls -lh "$skill/SKILL.md"
done
```

3. 권한 확인
```bash
chmod -R 755 ~/.claude/skills/
```

4. Claude Code 재시작

### 7.4 토큰 여전히 높음

**증상**:
```
/context
Token Usage: 234k/200k (117%)
MCP Tools: 77k
```

**해결**:

1. Lazy MCP가 제대로 작동하는지 확인
```bash
cat ~/.claude.json
# lazy-mcp-proxy만 있어야 함
```

2. 불필요한 MCP 서버 제거
```bash
# config.json에서 사용하지 않는 서버 제거
vim ~/lazy-mcp/config.json
```

3. 도구 계층 구조 재생성
```bash
cd ~/lazy-mcp
rm -rf testdata/mcp_hierarchy/*
```

---

## 8. 고급 설정

### 8.1 Ollama + AI 모델 설치 (선택)

KB AI Assistant 기능을 사용하려면 Ollama가 필요합니다.

```bash
# Ollama 설치
curl -fsSL https://ollama.com/install.sh | sh

# 서비스 시작
sudo systemctl start ollama
sudo systemctl enable ollama

# BGE-M3 모델 다운로드 (임베딩용)
ollama pull bge-m3

# Gemma3 모델 다운로드 (생성용)
ollama pull gemma3

# 확인
ollama list
```

### 8.2 GitHub MCP 설정

```bash
# GitHub Personal Access Token 생성
# https://github.com/settings/tokens

# config.json에 토큰 추가
vim ~/lazy-mcp/config.json

# "github" 섹션에 env 추가:
"github": {
  ...
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_YOUR_TOKEN_HERE"
  }
}
```

### 8.3 원격 PostgreSQL 연결

```bash
# SSH 터널 사용
ssh -L 5432:localhost:5432 user@remote-db-server

# config/.env 수정

# 설정:
DB_HOST=localhost
DB_PORT=5432
USE_SSH_TUNNEL=false
```

### 8.4 사용자 정의 Skills 추가

```bash
# 새 Skill 생성
mkdir -p ~/.claude/skills/my-custom-skill

# SKILL.md 작성
cat > ~/.claude/skills/my-custom-skill/SKILL.md << 'EOF'
---
name: my-custom-skill
description: My custom skill description
allowed-tools: tool1, tool2
---

# My Custom Skill

## Purpose
...
EOF

# Claude Code 재시작
```

---

## 📦 빠른 배포 스크립트

전체 프로세스를 자동화하는 스크립트를 제공합니다.

**사용법**:
```bash
# 스크립트 다운로드
curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/mcp-deployment/main/deploy.sh -o deploy.sh
chmod +x deploy.sh

# 실행
./deploy.sh --full

# 또는 단계별 실행
./deploy.sh --lazy-mcp      # Lazy MCP만 설치
./deploy.sh --mcp-servers   # MCP 서버만 설치
./deploy.sh --skills        # Skills만 설치
```

**스크립트 위치**: `scripts/deploy.sh` (다음 섹션 참조)

---

## 🎯 체크리스트

배포 완료 전 확인:

- [ ] Node.js 20+ 설치됨
- [ ] Python 3.11+ 설치됨
- [ ] Go 1.24+ 설치됨
- [ ] Lazy MCP 빌드 완료
- [ ] config.json 경로 수정됨
- [ ] MCP 서버 설치 완료
- [ ] Skills 배포 완료
- [ ] .claude.json 업데이트됨
- [ ] Claude Code 재시작됨
- [ ] `/mcp` 명령 성공
- [ ] `/skills` 명령 성공
- [ ] 토큰 사용량 79% 이하
- [ ] 기능 테스트 통과

---

## 📚 추가 리소스

- **상세 분석**: `skills-optimization-detailed-analysis.md`
- **구현 요약**: `skills-complete-implementation-summary.md`
- **Lazy MCP 가이드**: `lazy-mcp-setup-guide.md`
- **트러블슈팅**: `TROUBLESHOOTING.md`
- **자동 배포**: `scripts/deploy.sh`

---

## 📞 지원

문제 발생 시:

1. **트러블슈팅 가이드** 확인
2. **로그 확인**: `~/lazy-mcp/logs/`, `~/.claude/logs/`
3. **GitHub Issues**: https://github.com/YOUR_REPO/issues
4. **이메일**: support@hwandam.kr

---

**최종 업데이트**: 2025-11-15
**버전**: 1.0.0
**테스트 환경**: Ubuntu 22.04, macOS 14.0
