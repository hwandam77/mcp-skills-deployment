# MCP + Skills 트러블슈팅 가이드

> 배포 중 발생할 수 있는 문제와 해결 방법을 정리한 가이드입니다.

---

## 📋 목차

1. [설치 문제](#1-설치-문제)
2. [MCP 연결 문제](#2-mcp-연결-문제)
3. [Skills 인식 문제](#3-skills-인식-문제)
4. [토큰 문제](#4-토큰-문제)
5. [성능 문제](#5-성능-문제)
6. [데이터베이스 문제](#6-데이터베이스-문제)
7. [권한 문제](#7-권한-문제)
8. [로그 확인](#8-로그-확인)

---

## 1. 설치 문제

### 1.1 Node.js 버전 낮음

**증상**:
```bash
$ node --version
v18.x.x
```

**해결**:
```bash
# NVM 사용 (권장)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
nvm alias default 20

# 또는 공식 저장소
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 1.2 Python 버전 낮음

**증상**:
```bash
$ python3 --version
Python 3.9.x
```

**해결**:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install -y python3.11 python3.11-venv python3.11-dev

# 기본 python3를 3.11로 설정
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
```

### 1.3 Go 설치 실패

**증상**:
```bash
$ go version
command not found: go
```

**해결**:
```bash
# 최신 Go 다운로드
cd /tmp
wget https://go.dev/dl/go1.25.4.linux-amd64.tar.gz

# 설치
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.25.4.linux-amd64.tar.gz

# PATH 설정
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
source ~/.bashrc

# 확인
go version
```

### 1.4 Lazy MCP 빌드 실패

**증상**:
```bash
$ go build -o build/mcp-proxy ./cmd/mcp-proxy
go: module requires Go 1.24
```

**해결**:
```bash
# go.mod 파일 수정
cd ~/lazy-mcp
vim go.mod

# 첫 줄을 다음으로 수정:
go 1.25  # 또는 설치된 Go 버전

# 다시 빌드
go build -o build/mcp-proxy ./cmd/mcp-proxy
```

---

## 2. MCP 연결 문제

### 2.1 lazy-mcp-proxy 연결 실패

**증상**:
```
/mcp
❌ lazy-mcp-proxy: Connection failed
```

**진단**:
```bash
# 1. 설정 파일 확인
cat ~/.claude.json

# 2. mcp-proxy 존재 확인
ls -lh ~/lazy-mcp/build/mcp-proxy

# 3. 수동 실행 테스트
~/lazy-mcp/build/mcp-proxy --config ~/lazy-mcp/config.json
```

**해결**:

**원인 1: 경로 오류**
```bash
# .claude.json에서 절대 경로 확인
{
  "mcpServers": {
    "lazy-mcp-proxy": {
      "command": "/home/USERNAME/lazy-mcp/build/mcp-proxy",
      "args": ["--config", "/home/USERNAME/lazy-mcp/config.json"]
    }
  }
}

# USERNAME을 실제 사용자명으로 변경
```

**원인 2: 실행 권한 없음**
```bash
chmod +x ~/lazy-mcp/build/mcp-proxy
chmod +x ~/lazy-mcp/build/structure_generator
```

**원인 3: config.json 오류**
```bash
# JSON 유효성 검사
cat ~/lazy-mcp/config.json | python3 -m json.tool

# 오류 있으면 수정
vim ~/lazy-mcp/config.json
```

### 2.2 MCP 서버 연결 타임아웃

**증상**:
```
knowledge-base: Connection timeout (30s)
```

**진단**:
```bash
# 1. PostgreSQL 실행 확인
sudo systemctl status postgresql

# 2. 데이터베이스 연결 테스트
psql -h localhost -U your_db_user -d knowledge_base_db

# 3. Python 환경 확인
source .venv/bin/activate
python3 -c "import asyncpg; print('OK')"

# 4. 래퍼 스크립트 테스트
node local_mcp/kb-mcp-wrapper.js
```

**해결**:

**원인 1: PostgreSQL 미실행**
```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**원인 2: 데이터베이스 없음**
```bash
sudo -u postgres psql << 'EOF'
CREATE DATABASE knowledge_base_db;
CREATE USER your_db_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE knowledge_base_db TO your_db_user;
\c knowledge_base_db
CREATE EXTENSION vector;
EOF
```

**원인 3: Python 의존성 없음**
```bash
source .venv/bin/activate
pip install -r requirements.txt
```

**원인 4: .env 설정 오류**
```bash
# config/.env 확인
cat config/.env

# 수정
vim config/.env

# 필수 항목:
DB_HOST=localhost
DB_PORT=5432
DB_NAME=knowledge_base_db
DB_USER=your_db_user
DB_PASSWORD=your_password
```

### 2.3 SSH MCP 연결 실패

**증상**:
```
ssh: Permission denied
```

**해결**:
```bash
# mcp-ssh 실행 권한
chmod +x ~/mcp-servers/mcp-ssh/mcp-ssh

# 테스트
~/mcp-servers/mcp-ssh/mcp-ssh --allowed-hosts "*"
```

---

## 3. Skills 인식 문제

### 3.1 Skills 목록 비어있음

**증상**:
```
/skills
No skills found
```

**진단**:
```bash
# 1. Skills 디렉토리 확인
ls -la ~/.claude/skills/

# 2. SKILL.md 파일 확인
find ~/.claude/skills/ -name "SKILL.md"

# 3. 파일 내용 확인
head -20 ~/.claude/skills/kb-system/SKILL.md
```

**해결**:

**원인 1: Skills 디렉토리 없음**
```bash
mkdir -p ~/.claude/skills
# Skills 복사 (deploy.sh 재실행)
```

**원인 2: SKILL.md 누락**
```bash
# 각 Skill 디렉토리에 SKILL.md 있는지 확인
for skill_dir in ~/.claude/skills/*/; do
  if [ ! -f "${skill_dir}SKILL.md" ]; then
    echo "Missing: ${skill_dir}SKILL.md"
  fi
done
```

**원인 3: 잘못된 frontmatter**
```bash
# SKILL.md 첫 부분 확인
head -5 ~/.claude/skills/kb-system/SKILL.md

# 예상 출력:
# ---
# name: kb-system
# description: ...
# allowed-tools: ...
# ---

# --- 없으면 추가
```

**원인 4: 권한 문제**
```bash
chmod -R 755 ~/.claude/skills/
```

### 3.2 특정 Skill만 인식 안 됨

**증상**:
```
/skills
- kb-system ✓
- kb-knowledge-graph ✗
```

**해결**:
```bash
# 해당 Skill 디렉토리 확인
ls -la ~/.claude/skills/kb-knowledge-graph/

# SKILL.md 유효성 검사
cat ~/.claude/skills/kb-knowledge-graph/SKILL.md | head -10

# frontmatter 형식 확인:
# - 시작과 끝에 "---" 있는지
# - name, description 필드 있는지
# - allowed-tools 형식 올바른지
```

---

## 4. 토큰 문제

### 4.1 토큰 여전히 높음 (Lazy MCP 효과 없음)

**증상**:
```
/context
Token Usage: 234k/200k (117%)
MCP Tools: 77k
```

**진단**:
```bash
# .claude.json 확인
cat ~/.claude.json
```

**해결**:

**원인: Lazy MCP 미적용**
```bash
# .claude.json에 lazy-mcp-proxy만 있어야 함
cat > ~/.claude.json << EOF
{
  "mcpServers": {
    "lazy-mcp-proxy": {
      "type": "stdio",
      "command": "$HOME/lazy-mcp/build/mcp-proxy",
      "args": ["--config", "$HOME/lazy-mcp/config.json"]
    }
  }
}
EOF

# Claude Code 재시작
pkill -f "claude-code"
```

### 4.2 토큰 초과 (Skills 너무 많음)

**증상**:
```
Token Usage: 220k/200k (110%)
MCP Tools: 2.7k
Skills: 217k
```

**해결**:

불필요한 Skills 제거:
```bash
cd ~/.claude/skills

# 사용하지 않는 Skills 백업
mkdir -p ~/skills-backup
mv sequential-thinker ~/skills-backup/  # 예시

# Claude Code 재시작
```

---

## 5. 성능 문제

### 5.1 MCP 서버 응답 느림

**증상**:
도구 호출 시 30초 이상 소요

**진단**:
```bash
# 1. 시스템 리소스 확인
top
htop

# 2. PostgreSQL 성능 확인
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"

# 3. 네트워크 확인 (원격 DB인 경우)
ping your-db-server
```

**해결**:

**원인 1: 데이터베이스 연결 풀 부족**
```python
# knowledge_mcp.py 수정
self.db_pool = await asyncpg.create_pool(
    **self.db_config,
    min_size=5,
    max_size=20,  # 10 → 20으로 증가
    command_timeout=60
)
```

**원인 2: 인덱스 누락**
```sql
-- PostgreSQL에서 인덱스 추가
CREATE INDEX idx_documents_title ON kb.documents(title);
CREATE INDEX idx_documents_content_tsv ON kb.documents USING gin(content_tsv);
```

### 5.2 Ollama 느림 (AI 기능)

**증상**:
임베딩 생성 또는 RAG Q&A 매우 느림

**해결**:

**원인 1: GPU 미사용**
```bash
# Ollama GPU 사용 확인
nvidia-smi  # NVIDIA GPU

# Ollama 재시작 (GPU 활성화)
sudo systemctl restart ollama
```

**원인 2: 모델 크기 큼**
```bash
# 경량 모델로 변경
ollama pull gemma3:2b  # 8b 대신 2b 사용
```

---

## 6. 데이터베이스 문제

### 6.1 pgvector 확장 없음

**증상**:
```sql
ERROR: type "vector" does not exist
```

**해결**:
```bash
# pgvector 설치 (Ubuntu/Debian)
sudo apt-get install -y postgresql-14-pgvector

# PostgreSQL에서 확장 활성화
sudo -u postgres psql knowledge_base_db << 'EOF'
CREATE EXTENSION vector;
EOF

# 확인
sudo -u postgres psql knowledge_base_db -c "\dx"
```

### 6.2 스키마 없음

**증상**:
```
ERROR: schema "kb" does not exist
```

**해결**:
```bash
# 스키마 생성 스크립트 실행
source .venv/bin/activate
python3 scripts/init_db.py

# 또는 수동 생성
sudo -u postgres psql knowledge_base_db << 'EOF'
CREATE SCHEMA IF NOT EXISTS kb;
GRANT ALL ON SCHEMA kb TO your_db_user;
EOF
```

---

## 7. 권한 문제

### 7.1 MCP 서버 파일 접근 거부

**증상**:
```
Permission denied: /home/other_user/mcp-servers/...
```

**해결**:

**방법 1: 파일 권한 변경**
```bash
# 상위 디렉토리 권한
chmod 755 /home/other_user

# MCP 서버 권한
chmod -R 755 ~/mcp-servers/
```

**방법 2: 그룹 추가**
```bash
# 현재 사용자를 소유자 그룹에 추가
sudo usermod -aG owner_group $USER

# 로그아웃 후 재로그인 필요
```

### 7.2 Skills 디렉토리 접근 거부

**증상**:
```
Permission denied: ~/.claude/skills/
```

**해결**:
```bash
# 소유자 변경
sudo chown -R $USER:$USER ~/.claude

# 권한 설정
chmod -R 755 ~/.claude/skills/
```

---

## 8. 로그 확인

### 8.1 Lazy MCP 로그

```bash
# stdout/stderr 리다이렉트
~/lazy-mcp/build/mcp-proxy --config ~/lazy-mcp/config.json 2>&1 | tee ~/lazy-mcp-debug.log
```

### 8.2 Claude Code 로그

```bash
# Claude Code 로그 위치 (OS별)
# macOS
~/Library/Logs/Claude Code/

# Linux
~/.config/claude-code/logs/

# 최근 로그 확인
tail -f ~/.config/claude-code/logs/main.log
```

### 8.3 MCP 서버 로그

```bash
# Python 로그 활성화
source .venv/bin/activate

# DEBUG 모드로 실행
LOGLEVEL=DEBUG python3 local_mcp/kb_mcp_stdio.py 2>&1 | tee kb-mcp-debug.log
```

### 8.4 PostgreSQL 로그

```bash
# PostgreSQL 로그 위치
sudo tail -f /var/log/postgresql/postgresql-14-main.log

# 또는
sudo journalctl -u postgresql -f
```

---

## 🔍 일반적인 진단 절차

### 단계 1: 환경 확인

```bash
#!/bin/bash
echo "=== 환경 정보 ==="
echo "OS: $(uname -a)"
echo "User: $USER"
echo "Home: $HOME"
echo ""
echo "=== 소프트웨어 버전 ==="
echo "Node: $(node --version 2>&1)"
echo "Python: $(python3 --version 2>&1)"
echo "Go: $(go version 2>&1)"
echo "Git: $(git --version 2>&1)"
echo ""
echo "=== 디렉토리 존재 확인 ==="
ls -ld ~/lazy-mcp 2>&1
ls -ld ~/mcp-servers 2>&1
ls -ld ~/.claude/skills 2>&1
echo ""
echo "=== 설정 파일 확인 ==="
ls -l ~/.claude.json 2>&1
ls -l ~/lazy-mcp/config.json 2>&1
```

### 단계 2: MCP 연결 테스트

```bash
# Lazy MCP 수동 실행
timeout 10s ~/lazy-mcp/build/mcp-proxy \
  --config ~/lazy-mcp/config.json 2>&1 | head -50
```

### 단계 3: Skills 검증

```bash
# Skills 개수 확인
find ~/.claude/skills -name "SKILL.md" | wc -l

# Skills frontmatter 확인
for skill in ~/.claude/skills/*/SKILL.md; do
  echo "=== $skill ==="
  head -10 "$skill"
  echo ""
done
```

---

## 📞 추가 지원

위 해결 방법으로 문제가 해결되지 않으면:

1. **GitHub Issues**: https://github.com/YOUR_REPO/issues
2. **이메일**: support@hwandam.kr
3. **Discord**: hwandam-dev 채널

**문제 보고 시 포함할 정보**:
- OS 및 버전
- Node.js, Python, Go 버전
- 에러 메시지 전문
- 관련 로그 파일
- 실행한 명령어

---

**최종 업데이트**: 2025-11-15
**버전**: 1.0.0
