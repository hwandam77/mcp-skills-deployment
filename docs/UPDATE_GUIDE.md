# 업데이트 가이드

> MCP + Skills 패키지 업데이트 절차

---

## 📋 목차

- [Lazy MCP 업데이트](#lazy-mcp-업데이트)
- [Skills 업데이트](#skills-업데이트)
- [MCP 서버 업데이트](#mcp-서버-업데이트)
- [배포 스크립트 업데이트](#배포-스크립트-업데이트)

---

## 🔄 Lazy MCP 업데이트

### 방법 1: Git Pull (권장)

```bash
# 1. 백업
./scripts/backup.sh ~/mcp-backup-before-update

# 2. Lazy MCP 업데이트
cd ~/lazy-mcp
git pull origin main

# 3. 재빌드
make clean
make build

# 4. 검증
./scripts/verify.sh --connectivity

# 5. Claude Code 재시작
pkill -f "claude-code"
```

---

### 방법 2: 재설치

```bash
# 1. 백업
./scripts/backup.sh ~/mcp-backup-before-reinstall

# 2. 기존 제거
rm -rf ~/lazy-mcp

# 3. 재설치
./scripts/deploy.sh --lazy-mcp

# 4. 설정 복원
cp ~/mcp-backup-before-reinstall/lazy-mcp/config.json ~/lazy-mcp/config.json

# 5. 검증
./scripts/verify.sh
```

---

## 🎯 Skills 업데이트

### 신규 Skills 추가

```bash
# 1. 최신 코드 가져오기
cd mcp-deployment
git pull origin main

# 2. Skills 업데이트 (기존 보존)
./scripts/deploy.sh --skills-only

# 3. 확인
/skills  # Claude Code에서
```

---

### 기존 Skills 업그레이드

```bash
# 1. 백업
./scripts/package-skills.sh ~/skills-backup-before-update.tar.gz

# 2. 특정 Skill 업데이트
rm -rf ~/.claude/skills/kb-system
cp -r skills/kb-system ~/.claude/skills/

# 3. Claude Code 재시작
pkill -f "claude-code"
```

---

## 🔧 MCP 서버 업데이트

### NPM 기반 MCP 서버

```bash
# 전역 업데이트
npm update -g @modelcontextprotocol/server-filesystem

# 특정 버전 설치
npm install -g @modelcontextprotocol/server-filesystem@1.0.0
```

---

### MCP 서버

```bash
cd ~/service/MCP/Knowledge_Base-MCP

# 1. 백업
make backup

# 2. 업데이트
git pull origin main

# 3. 의존성 업데이트
source .venv-311/bin/activate
pip install -r requirements.txt --upgrade

# 4. 재시작
make restart

# 5. 검증
make test
```

---


```bash

# 1. 업데이트
git pull origin main

# 2. 의존성 업데이트
npm install

# 3. 재배포
./scripts/deploy_to_service_dir.sh

# 4. 테스트
./scripts/mcp_smoke_test.sh http
```

---

## 📦 배포 스크립트 업데이트

```bash
# 1. 최신 스크립트 가져오기
cd mcp-deployment
git pull origin main

# 2. 권한 확인
chmod +x scripts/*.sh

# 3. 테스트 (dry-run)
./scripts/deploy.sh --verify
```

---

## ✅ 업데이트 후 검증

```bash
# 전체 검증
./scripts/verify.sh

# 부분 검증
./scripts/verify.sh --requirements     # 시스템 요구사항
./scripts/verify.sh --installation     # 설치 상태
./scripts/verify.sh --connectivity     # MCP 연결
```

---

## 🔔 업데이트 알림

### GitHub Releases 구독

1. https://github.com/YOUR_REPO/releases
2. "Watch" → "Custom" → "Releases" 체크

### 수동 버전 확인

```bash
# Lazy MCP 버전
cd ~/lazy-mcp && git log -1 --oneline

# Skills 버전
cat ~/.claude/skills/kb-system/SKILL.md | grep "version:"

# 스크립트 버전
head -n 20 scripts/deploy.sh | grep "v[0-9]"
```

---

## 🚨 롤백

업데이트 후 문제 발생 시:

```bash
# 백업으로 복원
./scripts/restore.sh ~/mcp-backup-before-update

# Claude Code 재시작
pkill -f "claude-code"

# 검증
./scripts/verify.sh
```

---

**마지막 업데이트**: 2025-11-15
**다음 권장 업데이트 확인**: 2025-12-15
