# 백업 및 복원 가이드

> MCP + Skills 설정 백업 및 복원 절차

---

## 📋 목차

- [백업](#백업)
- [복원](#복원)
- [자동 백업 스케줄링](#자동-백업-스케줄링)
- [재해 복구](#재해-복구)

---

## 💾 백업

### 자동 백업 (권장)

```bash
# 기본 위치에 백업
./scripts/backup.sh

# 특정 디렉토리에 백업
./scripts/backup.sh ~/mcp-backup

# 날짜 포함 백업
./scripts/backup.sh ~/mcp-backup-$(date +%Y%m%d)
```

**백업 내용**:
- `~/.claude.json` (Claude Code 설정)
- `~/lazy-mcp/config.json` (Lazy MCP 설정)
- `~/.claude/skills/` (전체 Skills)
- 메타데이터 (버전, 날짜, 시스템 정보)

**압축 옵션**: 스크립트 실행 중 선택 가능

---

### 수동 백업

```bash
# 디렉토리 생성
BACKUP_DIR=~/mcp-backup-$(date +%Y%m%d)
mkdir -p "$BACKUP_DIR"

# 설정 파일 백업
cp ~/.claude.json "$BACKUP_DIR/claude.json"
mkdir -p "$BACKUP_DIR/lazy-mcp"
cp ~/lazy-mcp/config.json "$BACKUP_DIR/lazy-mcp/config.json"

# Skills 백업
mkdir -p "$BACKUP_DIR/skills"
cp -r ~/.claude/skills/* "$BACKUP_DIR/skills/"

# 압축 (선택)
tar czf "$BACKUP_DIR.tar.gz" -C ~ "$(basename "$BACKUP_DIR")"
```

---

## 🔄 복원

### 자동 복원 (권장)

```bash
# 압축 파일인 경우 먼저 압축 해제
tar xzf ~/mcp-backup-20251115.tar.gz -C ~

# 복원 실행
./scripts/restore.sh ~/mcp-backup-20251115
```

**안전 기능**:
- 복원 전 현재 설정 자동 백업
- 복원 확인 프롬프트
- 권한 자동 설정

---

### 수동 복원

```bash
# Claude Code 설정
cp ~/mcp-backup/claude.json ~/.claude.json

# Lazy MCP 설정
cp ~/mcp-backup/lazy-mcp/config.json ~/lazy-mcp/config.json

# Skills
rm -rf ~/.claude/skills/*
cp -r ~/mcp-backup/skills/* ~/.claude/skills/

# 권한 설정
chmod 644 ~/.claude.json
chmod 644 ~/lazy-mcp/config.json
find ~/.claude/skills -type f -name "SKILL.md" -exec chmod 644 {} \;

# Claude Code 재시작
pkill -f "claude-code"
```

---

## ⏰ 자동 백업 스케줄링

### Cron 사용

```bash
# crontab 편집
crontab -e

# 매일 오전 2시 백업
0 2 * * * /path/to/mcp-deployment/scripts/backup.sh ~/mcp-backup-daily

# 매주 일요일 오전 3시 백업
0 3 * * 0 /path/to/mcp-deployment/scripts/backup.sh ~/mcp-backup-weekly
```

---

## 🚨 재해 복구

### 시나리오 1: 설정 파일 손상

```bash
# 최신 백업으로 복원
./scripts/restore.sh ~/mcp-backup-latest

# Claude Code 재시작
pkill -f "claude-code"

# 검증
./scripts/verify.sh
```

---

### 시나리오 2: Skills 삭제

```bash
# Skills만 복원
rm -rf ~/.claude/skills/*
cp -r ~/mcp-backup/skills/* ~/.claude/skills/

# 권한 설정
find ~/.claude/skills -type f -name "SKILL.md" -exec chmod 644 {} \;

# Claude Code 재시작
pkill -f "claude-code"
```

---

**마지막 업데이트**: 2025-11-15
