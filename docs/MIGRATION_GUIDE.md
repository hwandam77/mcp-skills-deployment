# 마이그레이션 가이드

> 기존 Claude Code 설정에서 MCP + Skills 패키지로 마이그레이션

---

## 📋 마이그레이션 시나리오

### 시나리오 1: 기존 MCP 서버가 없는 경우

**가장 간단함** - 전체 자동 설치 사용

```bash
./scripts/deploy.sh --full
```

---

### 시나리오 2: 기존 MCP 서버가 있는 경우

**단계별 마이그레이션**:

```bash
# 1. 현재 설정 백업
./scripts/backup.sh ~/mcp-before-migration

# 2. 기존 MCP 서버 목록 저장
cat ~/.claude.json | jq '.mcpServers | keys' > ~/existing-mcp-servers.json

# 3. Lazy MCP 설치
./scripts/deploy.sh --lazy-mcp

# 4. 기존 MCP 서버를 Lazy MCP config.json에 추가
vim ~/lazy-mcp/config.json
# (기존 서버 블록 복사)

# 5. Skills 배포
./scripts/deploy.sh --skills-only

# 6. 검증
./scripts/verify.sh
```

---

### 시나리오 3: 기존 Skills가 있는 경우

**병합 마이그레이션**:

```bash
# 1. 기존 Skills 백업
./scripts/package-skills.sh ~/existing-skills-backup.tar.gz

# 2. 새 Skills 배포
./scripts/deploy.sh --skills-only

# 3. 기존 Skills 복원 (선택적)
tar xzf ~/existing-skills-backup.tar.gz -C ~/.claude/skills/

# 4. 중복 확인 및 병합
ls ~/.claude/skills/
```

---

## 🔄 호환성 체크리스트

- [ ] Node.js 20+
- [ ] Python 3.11+
- [ ] Go 1.24+
- [ ] 기존 MCP 서버 백업
- [ ] Lazy MCP 설치
- [ ] Skills 배포
- [ ] 검증 성공

---

**마지막 업데이트**: 2025-11-15
