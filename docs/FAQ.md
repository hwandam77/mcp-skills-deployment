# 자주 묻는 질문 (FAQ)

> MCP + Skills 배포 패키지에 대해 자주 묻는 질문과 답변

---

## 📋 목차

- [일반 질문](#일반-질문)
- [설치 관련](#설치-관련)
- [토큰 최적화](#토큰-최적화)
- [MCP 서버](#mcp-서버)
- [Skills](#skills)
- [문제 해결](#문제-해결)
- [성능 및 최적화](#성능-및-최적화)
- [고급 사용](#고급-사용)

---

## 🤔 일반 질문

### Q1: MCP란 무엇인가요?

**A**: MCP (Model Context Protocol)는 Claude와 같은 AI 모델이 외부 도구 및 API에 연결할 수 있도록 하는 프로토콜입니다.

**주요 특징**:
- 표준화된 인터페이스
- 다양한 도구 연결 (파일 시스템, 데이터베이스, API 등)
- Claude Code와 완벽 통합

**참고**: https://modelcontextprotocol.io/

---

### Q2: Skills란 무엇인가요?

**A**: Skills는 Claude Code에서 사용할 수 있는 **마크다운 기반 기능 정의**입니다.

**특징**:
- `SKILL.md` 파일로 정의
- MCP 도구를 호출할 수 있음 (`allowed-tools`)
- 가이드라인 제공 (프롬프트 엔지니어링)
- 도메인별 전문화 가능

**예시**:
```yaml
---
name: kb-system
description: Knowledge Base 시스템 관리자
allowed-tools: kb_search, kb_document_create, kb_upload
---

# KB System Skill

이 Skill은 Knowledge Base를 관리합니다...
```

---

### Q3: Lazy MCP란 무엇이고 왜 필요한가요?

**A**: Lazy MCP는 MCP 서버를 **필요할 때만 로드**하는 프록시 서버입니다.

**문제**:
- 기본 MCP 설정: 모든 도구를 항상 로드 → 77.1k 토큰 소비
- Claude Code 토큰 제한: 200k

**해결**:
- Lazy MCP: 필요할 때만 로드 → 2.7k 토큰 (96.5% 절감)
- 토큰 버퍼 확보: 34k → 42k (+24%p)

**참고**: [lazy-mcp-setup-guide.md](lazy-mcp-setup-guide.md)

---

### Q4: 이 패키지를 사용하면 어떤 이점이 있나요?

**A**: 3가지 핵심 이점이 있습니다.

1. **토큰 최적화** (96.5% 절감)
   - Before: 234k/200k (초과!)
   - After: 158k/200k (79%)

2. **완전 자동화** (95% 시간 절감)
   - Before: 2-3시간 수동 설정
   - After: 10-15분 자동 설치

3. **도구 활용도 향상** (71%p 향상)
   - Before: KB 도구 29% 활용 (7/24)
   - After: KB 도구 100% 활용 (24/24)

---

### Q5: 누가 이 패키지를 사용해야 하나요?

**A**: 다음과 같은 사용자에게 권장합니다.

**강력 권장**:
- Claude Code를 프로덕션 환경에서 사용
- 토큰 제한에 자주 걸림
- 여러 MCP 서버 사용
- Knowledge Base 또는 데이터베이스 연동 필요

**권장**:
- Claude Code를 처음 시작
- 최적화된 설정 원함
- 다른 환경에 재배포 필요

**선택**:
- MCP 서버를 1-2개만 사용
- 토큰 여유 충분
- 수동 설정 선호

---

## 🚀 설치 관련

### Q6: 설치에 얼마나 걸리나요?

**A**: 환경에 따라 다릅니다.

**자동 설치** (`./scripts/deploy.sh --full`):
- 준비된 시스템: **10-15분**
- 의존성 설치 필요: **20-30분**

**수동 설치** (DEPLOYMENT_GUIDE.md 참조):
- 단계별 이해하며 설치: **30-45분**

**검증 포함**:
- 자동 설치 + 검증: **15-20분**

---

### Q7: 시스템 요구사항이 무엇인가요?

**A**: 다음 소프트웨어가 필요합니다.

**필수**:
- **Node.js**: 20.0.0 이상
- **Python**: 3.11.0 이상
- **Go**: 1.24.0 이상
- **OS**: Linux, macOS, WSL2

**선택** (기능에 따라):
- **PostgreSQL**: 14.0+ (Knowledge Base 사용 시)
- **Ollama**: (AI 기능 사용 시)
  - BGE-M3 모델 (임베딩)
  - Gemma3 모델 (텍스트 생성)

**확인 방법**:
```bash
./scripts/verify.sh --requirements
```

---

### Q8: 기존 Claude Code 설정을 덮어쓰나요?

**A**: 아니오, **백업 후 안전하게 업데이트**합니다.

**자동 백업**:
```bash
# deploy.sh 실행 시 자동으로
~/.claude.json → ~/.claude.json.backup.YYYYMMDD_HHMMSS
~/lazy-mcp/config.json → ~/lazy-mcp/config.json.backup.YYYYMMDD_HHMMSS
```

**수동 백업**:
```bash
./scripts/backup.sh ~/mcp-backup
```

**복원**:
```bash
./scripts/restore.sh ~/mcp-backup
```

**참고**: [BACKUP_RESTORE.md](BACKUP_RESTORE.md)

---

### Q9: 설치 후 바로 사용할 수 있나요?

**A**: 네, **Claude Code 재시작 후 즉시 사용** 가능합니다.

**설치 후 단계**:
```bash
# 1. 자동 설치
./scripts/deploy.sh --full

# 2. 검증 (선택)
./scripts/verify.sh

# 3. Claude Code 재시작
pkill -f "claude-code"
# → VSCode에서 Claude Code 재실행

# 4. 확인
/mcp       # MCP 서버 목록
/skills    # Skills 목록
/context   # 토큰 사용량
```

**예상 토큰**: 158k/200k (79%)

---

### Q10: 윈도우에서 사용할 수 있나요?

**A**: **WSL2 (Windows Subsystem for Linux)**에서 사용 가능합니다.

**WSL2 설치**:
1. PowerShell에서 실행:
   ```powershell
   wsl --install
   ```
2. Ubuntu 설치 선택
3. WSL2에서 배포 스크립트 실행

**네이티브 Windows**: 현재 미지원
- Lazy MCP가 Go로 작성되어 Linux/macOS 환경 필요
- WSL2 사용 권장

---

## 🎯 토큰 최적화

### Q11: 토큰이 왜 중요한가요?

**A**: Claude Code는 **200k 토큰 제한**이 있습니다.

**토큰 구성**:
- 시스템 프롬프트: ~155k
- MCP 도구 정의: 기본 77.1k (Lazy MCP: 2.7k)
- 대화 컨텍스트: 나머지

**문제**:
- 기본 설정: 234k 필요 → **34k 초과!**
- 초과 시: 오래된 대화 자동 삭제

**해결**:
- Lazy MCP 사용: 158k (79%) → **42k 여유**

---

### Q12: Lazy MCP를 사용하면 성능이 느려지나요?

**A**: **첫 사용 시 1-2초 지연**, 이후 빠름.

**성능 비교**:
| 상황 | 기본 MCP | Lazy MCP | 차이 |
|------|----------|----------|------|
| **초기 로드** | 즉시 | 즉시 | 동일 |
| **첫 도구 사용** | 즉시 | 1-2초 | -1-2초 |
| **이후 사용** | 즉시 | 즉시 | 동일 |

**캐싱**:
- 한 번 로드된 도구는 캐시에 유지
- 재사용 시 즉시 응답

**권장**:
- 자주 사용: Preload (즉시 로드)
- 가끔 사용: Lazy Load (필요시 로드)

---

### Q13: Preload와 Lazy Load 중 어떤 걸 선택해야 하나요?

**A**: **사용 빈도와 토큰 비용**으로 결정합니다.

**Preload 선택** (항상 로드):
- ✅ 매일 사용하는 MCP
- ✅ 토큰 비용 낮음 (<1k)
- ✅ 즉시 응답 필요
- 예: filesystem, ssh, context7

**Lazy Load 선택** (필요시 로드):
- ✅ 가끔 사용하는 MCP
- ✅ 토큰 비용 높음 (>2k)
- ✅ 1-2초 지연 허용
- 예: slack, github, postgres

**설정 예시**:
```json
{
  "mcpServers": {
    "filesystem": {
      "options": {"lazyLoad": false, "preload": true}
    },
    "slack": {
      "options": {"lazyLoad": true, "preload": false}
    }
  }
}
```

**참고**: [ADD_MCP_GUIDE.md - Preload vs Lazy Load](ADD_MCP_GUIDE.md#preload-vs-lazy-load-가이드)

---

### Q14: 토큰을 더 절감할 수 있나요?

**A**: 네, **추가 최적화 방법**이 있습니다.

**1. 불필요한 MCP 서버 제거**:
```bash
vim ~/lazy-mcp/config.json
# 사용하지 않는 서버 블록 삭제
```

**2. Lazy Load로 전환**:
```bash
# Preload → Lazy Load
"options": {"lazyLoad": true, "preload": false}
```

**3. 도구 계층 구조 간소화**:
```bash
# 깊이 제한
./build/structure_generator \
  --server "server-name" \
  --max-depth 2
```

**4. Skills 최적화**:
- `allowed-tools`를 필수 도구로만 제한
- 불필요한 Skills 제거

**예상 추가 절감**: 5-10k 토큰

---

## 🔧 MCP 서버

### Q15: 어떤 MCP 서버가 포함되어 있나요?

**A**: 기본으로 **3개 MCP 서버**가 포함됩니다.

1. **Codex-Qwen-Gemini MCP**
   - 3개 AI CLI 통합 (Codex, Qwen, Gemini)
   - 50+ 도구
   - 세션 관리

2. **Knowledge Base MCP**
   - PostgreSQL + pgvector 기반
   - 24개 도구 (문서, KG, AI)
   - BGE-M3, Gemma3 AI 지원

3. **SSH MCP**
   - 원격 서버 관리
   - 4개 도구 (연결, 실행, 종료, 목록)

**추가 가능**: [ADD_MCP_GUIDE.md](ADD_MCP_GUIDE.md) 참조

---

### Q16: 새 MCP 서버를 어떻게 추가하나요?

**A**: **자동 스크립트** 또는 **수동 설정**으로 추가합니다.

**자동 추가** (권장):
```bash
./scripts/add-mcp.sh <server-name> <npm-package> [preload|lazy]

# 예시: Filesystem
./scripts/add-mcp.sh filesystem \
  @modelcontextprotocol/server-filesystem \
  preload \
  --allowed-directories /home/user/documents
```

**수동 추가**:
1. `~/lazy-mcp/config.json` 편집
2. `mcpServers` 섹션에 추가
3. 도구 계층 구조 생성
4. Claude Code 재시작

**참고**: [ADD_MCP_GUIDE.md](ADD_MCP_GUIDE.md)

---

### Q17: MCP 서버를 어떻게 제거하나요?

**A**: `config.json`에서 **서버 블록 삭제** 후 재시작합니다.

**단계**:
```bash
# 1. config.json 편집
vim ~/lazy-mcp/config.json

# 2. 서버 블록 삭제
# "unwanted-server": { ... }  ← 전체 삭제

# 3. 도구 계층 구조 정리 (선택)
rm ~/lazy-mcp/testdata/mcp_hierarchy/unwanted-server/

# 4. Claude Code 재시작
pkill -f "claude-code"
```

**참고**: [ADD_MCP_GUIDE.md - MCP 서버 제거](ADD_MCP_GUIDE.md#mcp-서버-제거)

---

### Q18: MCP 서버가 연결되지 않아요. 어떻게 하나요?

**A**: **4단계 진단**을 수행합니다.

**1. 프로세스 확인**:
```bash
ps aux | grep mcp-proxy
# → mcp-proxy 실행 중이어야 함
```

**2. 설정 파일 검증**:
```bash
cat ~/lazy-mcp/config.json | python3 -m json.tool
# → JSON 형식 오류 확인
```

**3. 수동 실행 테스트**:
```bash
~/lazy-mcp/build/mcp-proxy --config ~/lazy-mcp/config.json
# → 오류 메시지 확인
```

**4. 로그 확인**:
```bash
tail -f ~/lazy-mcp/logs/mcp-proxy.log
```

**참고**: [TROUBLESHOOTING.md - MCP 연결 문제](TROUBLESHOOTING.md#2-mcp-연결-문제)

---

### Q19: Knowledge Base MCP는 어떻게 설정하나요?

**A**: **PostgreSQL 연결 정보** 설정이 필요합니다.

**설정 위치**:
```bash
vim ~/lazy-mcp/config.json
```

**환경 변수 추가**:
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
    }
  }
}
```

**테스트**:
```bash
psql -h your-db-host -U your-db-user -d your-db-name -c "SELECT 1;"
```

**참고**: [DEPLOYMENT_GUIDE.md - Knowledge Base MCP](DEPLOYMENT_GUIDE.md#43-knowledge-base-mcp-설치)

---

## 🎓 Skills

### Q20: Skills와 MCP의 차이는 무엇인가요?

**A**: **역할과 구현 방식**이 다릅니다.

| 항목 | MCP | Skills |
|------|-----|--------|
| **역할** | 도구 실행 | 가이드라인 + 도구 호출 |
| **구현** | Python/Node.js 코드 | 마크다운 문서 |
| **배포** | 서버 프로세스 | 파일 복사 |
| **설정** | config.json | SKILL.md frontmatter |

**사용 예시**:
- **MCP**: `kb_search("API")` → 실제 검색 실행
- **Skill**: "KB에서 API 검색해줘" → MCP 도구 호출 + 가이드라인 적용

**통합**:
```yaml
---
name: kb-system
allowed-tools: kb_search, kb_document_create  ← MCP 도구 호출
---

# KB System Skill
이 Skill은 Knowledge Base를 관리합니다...  ← 가이드라인
```

---

### Q21: 새 Skill을 어떻게 만드나요?

**A**: **3단계로 간단히 생성**할 수 있습니다.

**1단계: 디렉토리 생성**:
```bash
mkdir -p ~/.claude/skills/my-skill
```

**2단계: SKILL.md 작성**:
```bash
cat > ~/.claude/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: My custom skill for specific tasks
allowed-tools: tool1, tool2, tool3
---

# My Skill

## 목적
이 Skill은 특정 작업을 수행합니다.

## 사용 방법
"my-skill을 사용해서 XXX를 해줘"

## 주요 기능
1. 기능 1
2. 기능 2
3. 기능 3
EOF
```

**3단계: Claude Code 재시작**:
```bash
pkill -f "claude-code"
```

**확인**:
```
/skills
→ my-skill 표시되어야 함
```

---

### Q22: Skill이 인식되지 않아요. 왜 그런가요?

**A**: **4가지 주요 원인**이 있습니다.

**1. 경로 오류**:
```bash
# 올바른 경로
~/.claude/skills/<skill-name>/SKILL.md

# 확인
ls -la ~/.claude/skills/
```

**2. 파일명 오류**:
- 반드시 `SKILL.md` (대문자)
- `skill.md`, `Skill.md` → 인식 안 됨

**3. Frontmatter 형식 오류**:
```yaml
# 올바른 형식
---
name: skill-name
description: Description here
---

# 틀린 형식 (공백 누락)
---
name:skill-name  ← 공백 필요!
---
```

**4. 권한 문제**:
```bash
chmod 644 ~/.claude/skills/*/SKILL.md
```

**참고**: [TROUBLESHOOTING.md - Skills 인식 문제](TROUBLESHOOTING.md#3-skills-인식-문제)

---

### Q23: Skills에서 MCP 도구를 호출하려면?

**A**: **`allowed-tools` frontmatter**를 사용합니다.

**설정**:
```yaml
---
name: my-skill
description: My skill
allowed-tools: kb_search, kb_document_create, ssh_execute
---
```

**사용**:
Claude Code에서:
```
"my-skill을 사용해서 KB에서 'API'를 검색해줘"
```

Claude가 자동으로:
1. my-skill 가이드라인 적용
2. kb_search MCP 도구 호출
3. 결과 반환

**주의**:
- `allowed-tools`에 명시된 도구만 호출 가능
- 도구 이름은 정확히 입력 (대소문자 구분)

---

### Q24: 하나의 Skill에서 여러 MCP 서버의 도구를 사용할 수 있나요?

**A**: 네, **여러 MCP 서버의 도구를 혼합** 가능합니다.

**예시**:
```yaml
---
name: integrated-workflow
description: Knowledge Base + SSH 통합 워크플로우
allowed-tools: kb_search, kb_document_create, ssh_connect, ssh_execute
---

# Integrated Workflow Skill

이 Skill은 KB와 SSH를 통합하여 사용합니다.

## 사용 시나리오
1. KB에서 배포 스크립트 검색
2. SSH로 서버 연결
3. 스크립트 실행
4. 결과를 KB에 문서화
```

**사용**:
```
"integrated-workflow를 사용해서 배포 스크립트를 찾고 실행해줘"
```

---

### Q25: 기존 Skill을 수정하려면?

**A**: **SKILL.md 파일을 직접 편집**합니다.

**단계**:
```bash
# 1. 파일 편집
vim ~/.claude/skills/kb-system/SKILL.md

# 2. 변경사항 저장

# 3. Claude Code 재시작
pkill -f "claude-code"
```

**Hot Reload**: 현재 미지원
- 변경 후 반드시 Claude Code 재시작 필요

**백업 권장**:
```bash
cp ~/.claude/skills/kb-system/SKILL.md \
   ~/.claude/skills/kb-system/SKILL.md.backup
```

---

## 🐛 문제 해결

### Q26: 검증 스크립트가 실패하면 어떻게 하나요?

**A**: **실패 항목별로 해결**합니다.

**시스템 요구사항 실패**:
```bash
./scripts/verify.sh --requirements
# → Node.js, Python, Go 버전 확인 및 업그레이드
```

**설치 상태 실패**:
```bash
./scripts/verify.sh --installation
# → 누락된 컴포넌트 재설치
./scripts/deploy.sh --lazy-mcp  # Lazy MCP
./scripts/deploy.sh --skills     # Skills
```

**MCP 연결 실패**:
```bash
./scripts/verify.sh --connectivity
# → 프로세스 확인 및 재시작
ps aux | grep mcp-proxy
```

**권한 실패**:
```bash
./scripts/verify.sh --permissions
# → 권한 수정
chmod 644 ~/.claude/skills/*/SKILL.md
chmod 644 ~/.claude.json
```

---

### Q27: 로그는 어디서 확인하나요?

**A**: **3가지 주요 로그 위치**가 있습니다.

**1. Claude Code 로그**:
```bash
tail -f ~/.claude/logs/main.log
```

**2. Lazy MCP 프록시 로그**:
```bash
tail -f ~/lazy-mcp/logs/mcp-proxy.log
```

**3. Knowledge Base MCP 로그**:
```bash
tail -f ~/service/MCP/Knowledge_Base-MCP/logs/*.log
```

**실시간 모니터링**:
```bash
# 모든 로그 동시 모니터링
tail -f ~/.claude/logs/main.log \
        ~/lazy-mcp/logs/mcp-proxy.log \
        ~/service/MCP/Knowledge_Base-MCP/logs/*.log
```

---

### Q28: "Unknown tool" 오류가 발생해요.

**A**: **도구 이름 확인 및 계층 구조 재생성**이 필요합니다.

**원인**:
- 도구 이름 오타
- MCP 서버 미연결
- 도구 계층 구조 누락

**해결**:
```bash
# 1. 사용 가능한 도구 목록 확인
# Claude Code에서: /tools

# 2. 도구 이름 확인 (정확한 이름 사용)
"allowed-tools": "kb_search"  # 올바름
"allowed-tools": "kbSearch"   # 틀림

# 3. 도구 계층 구조 재생성
cd ~/lazy-mcp
./build/structure_generator \
  --server "knowledge-base" \
  --config ./config.json \
  --output ./testdata/mcp_hierarchy

# 4. Claude Code 재시작
pkill -f "claude-code"
```

---

### Q29: 백업을 어떻게 하나요?

**A**: **자동 스크립트** 또는 **수동 백업**을 사용합니다.

**자동 백업** (전체):
```bash
./scripts/backup.sh ~/mcp-backup-$(date +%Y%m%d)
```

**백업 내용**:
- `~/.claude.json`
- `~/lazy-mcp/config.json`
- `~/.claude/skills/` (전체)

**Skills만 백업**:
```bash
./scripts/package-skills.sh ~/skills-backup.tar.gz
```

**수동 백업**:
```bash
# 설정 파일
cp ~/.claude.json ~/.claude.json.backup
cp ~/lazy-mcp/config.json ~/lazy-mcp/config.json.backup

# Skills
tar czf ~/skills-backup.tar.gz -C ~/.claude/skills/ .
```

**참고**: [BACKUP_RESTORE.md](BACKUP_RESTORE.md)

---

### Q30: 복원은 어떻게 하나요?

**A**: **백업 파일로 복원**합니다.

**자동 복원** (전체):
```bash
./scripts/restore.sh ~/mcp-backup-20251115
```

**수동 복원**:
```bash
# 설정 파일
cp ~/.claude.json.backup ~/.claude.json
cp ~/lazy-mcp/config.json.backup ~/lazy-mcp/config.json

# Skills
rm -rf ~/.claude/skills/*
tar xzf ~/skills-backup.tar.gz -C ~/.claude/skills/

# Claude Code 재시작
pkill -f "claude-code"
```

**참고**: [BACKUP_RESTORE.md](BACKUP_RESTORE.md)

---

## 🚀 성능 및 최적화

### Q31: 성능을 더 향상시킬 수 있나요?

**A**: 네, **5가지 최적화 방법**이 있습니다.

**1. Preload/Lazy Load 최적화**:
- 자주 사용: Preload
- 가끔 사용: Lazy Load

**2. 불필요한 MCP 제거**:
```bash
vim ~/lazy-mcp/config.json
# 사용하지 않는 서버 삭제
```

**3. 도구 계층 구조 간소화**:
```bash
./build/structure_generator --max-depth 2
```

**4. Skills 최적화**:
- 필수 도구로만 `allowed-tools` 제한
- 불필요한 Skills 제거

**5. PostgreSQL 튜닝** (KB 사용 시):
- 인덱스 최적화
- 커넥션 풀 조정

---

### Q32: AI 기능 (시맨틱 검색, RAG)을 사용하려면?

**A**: **Ollama + AI 모델 설치**가 필요합니다.

**설치**:
```bash
# 1. Ollama 설치
curl -fsSL https://ollama.com/install.sh | sh

# 2. 모델 다운로드
ollama pull bge-m3       # 임베딩 모델
ollama pull gemma3       # LLM 모델

# 3. Ollama 실행
ollama serve

# 4. 환경 변수 설정
vim ~/lazy-mcp/config.json
{
  "env": {
    "OLLAMA_HOST": "http://localhost:11434",
    "EMBEDDING_MODEL": "bge-m3",
    "LLM_MODEL": "gemma3"
  }
}

# 5. Claude Code 재시작
```

**사용**:
```
"KB에서 '인증'을 시맨틱 검색으로 찾아줘"
"이 문서를 요약해줘 (kb_summarize)"
"KB에 저장된 내용으로 API 설계 방법을 알려줘 (kb_ask)"
```

**참고**: [DEPLOYMENT_GUIDE.md - Ollama 설치](DEPLOYMENT_GUIDE.md#81-ollama--ai-모델-설치)

---

### Q33: Knowledge Graph는 언제 사용하나요?

**A**: **복잡한 관계 및 지식 구조**를 관리할 때 사용합니다.

**사용 시나리오**:
1. **프로젝트 관계**: "FastAPI → depends_on → PostgreSQL"
2. **개념 연결**: "API → part_of → Backend System"
3. **인물 관계**: "John → leads → Backend Team"
4. **관찰 추가**: "FastAPI의 버전은 0.115.0"

**예시**:
```
"knowledge graph에 FastAPI와 PostgreSQL의 의존 관계를 추가해줘"
"FastAPI에 대한 관찰을 추가해줘: 비동기 지원, 자동 문서 생성"
"Backend System과 관련된 모든 엔티티를 검색해줘"
```

**vs 일반 문서**:
- 문서: 텍스트 기반, 전체 내용
- KG: 구조화된 지식, 관계 중심

---

## 🔐 고급 사용

### Q34: 여러 환경 (개발/스테이징/프로덕션)에서 사용하려면?

**A**: **환경별 설정 파일**을 사용합니다.

**설정**:
```bash
# 개발 환경
~/lazy-mcp/config.dev.json

# 스테이징 환경
~/lazy-mcp/config.staging.json

# 프로덕션 환경
~/lazy-mcp/config.prod.json
```

**전환**:
```bash
# 심볼릭 링크 사용
ln -sf ~/lazy-mcp/config.prod.json ~/lazy-mcp/config.json

# 또는 환경 변수
export MCP_CONFIG=~/lazy-mcp/config.prod.json
~/lazy-mcp/build/mcp-proxy --config $MCP_CONFIG
```

**환경별 차이**:
- 개발: Preload 위주 (빠른 응답)
- 스테이징: Lazy Load 테스트
- 프로덕션: 최적화된 Lazy Load

---

### Q35: Docker 컨테이너에서 사용할 수 있나요?

**A**: 가능하지만 **복잡도가 증가**합니다.

**고려사항**:
1. **Lazy MCP 빌드**: Go 1.24+ 필요
2. **MCP 서버**: Node.js, Python 환경 필요
3. **PostgreSQL**: 별도 컨테이너 또는 외부 DB
4. **Ollama**: GPU 지원 필요 (AI 기능 사용 시)

**기본 Dockerfile** (예시):
```dockerfile
FROM ubuntu:22.04

# 의존성 설치
RUN apt-get update && apt-get install -y \
    nodejs npm python3 python3-pip golang-1.24

# Lazy MCP 빌드
WORKDIR /lazy-mcp
COPY lazy-mcp/ .
RUN make build

# Skills 복사
COPY skills/ /root/.claude/skills/

# 설정 파일
COPY config.json /lazy-mcp/

CMD ["/lazy-mcp/build/mcp-proxy", "--config", "/lazy-mcp/config.json"]
```

**권장**: 네이티브 설치 (복잡도 낮음)

---

### Q36: CI/CD 파이프라인에 통합하려면?

**A**: **배포 스크립트를 CI/CD에 추가**합니다.

**GitHub Actions 예시**:
```yaml
name: Deploy MCP + Skills

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y nodejs python3 golang-1.24

      - name: Deploy
        run: |
          ./scripts/deploy.sh --full

      - name: Verify
        run: |
          ./scripts/verify.sh

      - name: Package Skills
        run: |
          ./scripts/package-skills.sh skills-${{ github.sha }}.tar.gz

      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: skills-package
          path: skills-*.tar.gz
```

---

### Q37: 커스텀 MCP 서버를 개발하려면?

**A**: **MCP SDK 사용**하여 개발합니다.

**Node.js 예시**:
```javascript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const server = new Server({
  name: "my-custom-mcp",
  version: "1.0.0"
}, {
  capabilities: {
    tools: {}
  }
});

server.setRequestHandler("tools/list", async () => ({
  tools: [{
    name: "my_custom_tool",
    description: "My custom tool",
    inputSchema: {
      type: "object",
      properties: { ... }
    }
  }]
}));

server.setRequestHandler("tools/call", async (request) => {
  // 도구 실행 로직
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

**참고**:
- https://modelcontextprotocol.io/docs
- https://github.com/modelcontextprotocol

---

### Q38: Skills를 팀과 공유하려면?

**A**: **Git 저장소 또는 압축 파일**로 공유합니다.

**Git 저장소**:
```bash
# 1. Skills 저장소 생성
cd ~/.claude/skills
git init
git add .
git commit -m "Initial Skills"
git remote add origin https://github.com/team/claude-skills.git
git push -u origin main

# 2. 팀원이 클론
git clone https://github.com/team/claude-skills.git ~/.claude/skills
```

**압축 파일**:
```bash
# 1. 패키징
./scripts/package-skills.sh ~/skills-share.tar.gz

# 2. 공유 (이메일, Slack 등)
# ...

# 3. 팀원이 압축 해제
tar xzf ~/skills-share.tar.gz -C ~/.claude/skills/
```

**버전 관리 권장**: Git 사용 시 변경 이력 추적 가능

---

## 📞 지원

### Q39: 문서를 읽어도 해결되지 않으면?

**A**: **3가지 지원 채널**이 있습니다.

**1. GitHub Issues**:
- https://github.com/YOUR_REPO/issues
- 버그 리포트 및 기능 요청

**2. 이메일**:
- support@hwandam.kr
- 기술 지원 및 문의

**3. Discord**:
- hwandam-dev
- 커뮤니티 지원 및 토론

**요청 시 포함할 정보**:
- OS 및 버전
- Node.js, Python, Go 버전
- 오류 메시지 (로그 포함)
- `./scripts/verify.sh` 결과

---

### Q40: 기여하고 싶어요. 어떻게 하나요?

**A**: **Pull Request**로 기여합니다.

**절차**:
```bash
# 1. Fork the repository
# GitHub에서 Fork 버튼 클릭

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/mcp-deployment.git
cd mcp-deployment

# 3. Create feature branch
git checkout -b feature/amazing-feature

# 4. Make changes
vim scripts/my-script.sh

# 5. Commit
git add .
git commit -m "Add amazing feature"

# 6. Push
git push origin feature/amazing-feature

# 7. Open Pull Request
# GitHub에서 PR 생성
```

**기여 아이디어**:
- 새 Skills 추가
- MCP 서버 예시 추가
- 문서 개선
- 버그 수정
- 스크립트 최적화

**감사합니다!** 🎉

---

**마지막 업데이트**: 2025-11-15
**버전**: 1.0.0

**[⬆ 맨 위로](#자주-묻는-질문-faq)**
