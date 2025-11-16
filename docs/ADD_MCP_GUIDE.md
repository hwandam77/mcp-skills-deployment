# MCP 서버 추가 가이드

> 기존 배포 패키지에 새로운 MCP 서버를 추가하는 완전 가이드입니다.

---

## 📋 목차

1. [MCP 서버 추가 개요](#1-mcp-서버-추가-개요)
2. [사전 준비](#2-사전-준비)
3. [Lazy MCP에 추가](#3-lazy-mcp에-추가)
4. [Skills에 통합](#4-skills에-통합)
5. [테스트 및 검증](#5-테스트-및-검증)
6. [주요 MCP 서버 추가 예시](#6-주요-mcp-서버-추가-예시)
7. [문제 해결](#7-문제-해결)

---

## 1. MCP 서버 추가 개요

### 1.1 추가 프로세스

```
새 MCP 서버 발견
    ↓
설치 및 테스트
    ↓
Lazy MCP config.json에 등록
    ↓
(선택) Skills 생성
    ↓
검증 및 배포
```

### 1.2 추가 방식 2가지

#### 방식 A: Preload (항상 로드)
- 자주 사용하는 MCP 서버
- 토큰 비용이 낮은 MCP 서버
- 예: context7, ssh

#### 방식 B: Lazy Load (필요시 로드)
- 가끔 사용하는 MCP 서버
- 토큰 비용이 높은 MCP 서버
- 예: github, grafana

---

## 2. 사전 준비

### 2.1 MCP 서버 정보 수집

새 MCP 서버를 추가하기 전에 다음 정보를 확인하세요:

```bash
# 필수 정보
1. MCP 서버 이름: 예) "filesystem"
2. 실행 명령어: 예) "npx -y @modelcontextprotocol/server-filesystem"
3. 필수 인수: 예) ["--allowed-directories", "/home/user"]
4. 환경 변수: 예) {"API_KEY": "your-key"}
5. 제공 도구 수: 예) 5개 도구
```

### 2.2 MCP 서버 설치 및 테스트

```bash
# 1. MCP 서버 설치
# (NPM 패키지인 경우)
npm install -g @modelcontextprotocol/server-filesystem

# (Go 바이너리인 경우)
go install github.com/some/mcp-server@latest

# (Python 패키지인 경우)
pip install mcp-server-package

# 2. 단독 실행 테스트
npx -y @modelcontextprotocol/server-filesystem \
  --allowed-directories /tmp

# 예상: MCP 서버가 정상 실행되고 stdio로 통신 시작
```

### 2.3 도구 목록 확인

```bash
# MCP 서버가 제공하는 도구 확인
# (방법 1: 문서 확인)
# https://github.com/modelcontextprotocol/servers 등

# (방법 2: 직접 호출)
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | \
  npx -y @modelcontextprotocol/server-filesystem \
  --allowed-directories /tmp
```

---

## 3. Lazy MCP에 추가

### 3.1 config.json 수정

```bash
# config.json 백업
cd ~/lazy-mcp
cp config.json config.json.backup

# 편집
vim config.json
```

### 3.2 Preload 방식 추가

**언제 사용**: 자주 사용하는 필수 MCP 서버

```json
{
  "mcpProxy": {
    "hierarchyPath": "/home/USER/lazy-mcp/testdata/mcp_hierarchy",
    "options": {
      "lazyLoad": true
    }
  },
  "mcpServers": {
    // 기존 서버들...

    // 새 MCP 서버 추가 (Preload)
    "filesystem": {
      "transportType": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "--allowed-directories",
        "/home/USER/documents"
      ],
      "env": {},
      "options": {
        "lazyLoad": false,
        "preload": true
      }
    }
  }
}
```

**특징**:
- ✅ Claude Code 시작 시 자동 로드
- ✅ 즉시 사용 가능
- ⚠️ 초기 토큰 소비

### 3.3 Lazy Load 방식 추가

**언제 사용**: 가끔 사용하는 MCP 서버

```json
{
  "mcpServers": {
    // 기존 서버들...

    // 새 MCP 서버 추가 (Lazy Load)
    "slack": {
      "transportType": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}",
        "SLACK_TEAM_ID": "T1234567"
      },
      "options": {
        "lazyLoad": true,
        "preload": false
      }
    }
  }
}
```

**특징**:
- ✅ 초기 토큰 소비 없음
- ✅ 필요할 때 자동 활성화 (1-2초)
- ⚠️ 첫 사용 시 약간 지연

### 3.4 도구 계층 구조 생성

```bash
cd ~/lazy-mcp

# 새 MCP 서버의 도구 목록 생성
timeout 30s ./build/structure_generator \
  --server "filesystem" \
  --config ./config.json \
  --output ./testdata/mcp_hierarchy

# 생성 확인
ls -lh testdata/mcp_hierarchy/filesystem/
```

---

## 4. Skills에 통합

### 4.1 전용 Skill 생성 (권장)

새 MCP 서버 전용 Skill을 만들어 사용성을 높입니다.

```bash
# Skill 디렉토리 생성
mkdir -p ~/.claude/skills/filesystem-manager

# SKILL.md 생성
vim ~/.claude/skills/filesystem-manager/SKILL.md
```

**SKILL.md 템플릿**:

```markdown
---
name: filesystem-manager
description: 파일 시스템 관리 전문가. 파일 읽기, 쓰기, 디렉토리 탐색.
allowed-tools: read_file, write_file, list_directory, create_directory, delete_file
---

# Filesystem Manager

## Purpose

로컬 파일 시스템을 관리합니다. 파일 읽기/쓰기, 디렉토리 탐색, 파일 검색 등을 수행합니다.

## Core Capabilities

### 1. 파일 읽기

**Tools Used**:
- `read_file`: 파일 내용 읽기

**Example Use Cases**:
- "README.md 파일 읽어줘"
- "config.json 내용 확인해줘"

**Usage Pattern**:
```
User: "~/documents/notes.txt 읽어줘"
→ read_file(path="/home/user/documents/notes.txt")
→ 파일 내용 반환
```

### 2. 파일 쓰기

**Tools Used**:
- `write_file`: 파일 생성/수정

**Example Use Cases**:
- "새 파일 생성해줘"
- "이 내용을 파일로 저장해줘"

**Usage Pattern**:
```
User: "이 내용을 ~/memo.txt로 저장해줘"
→ write_file(
    path="/home/user/memo.txt",
    content="메모 내용"
  )
→ 파일 생성 완료
```

### 3. 디렉토리 탐색

**Tools Used**:
- `list_directory`: 디렉토리 내용 조회

**Example Use Cases**:
- "이 폴더에 뭐가 있어?"
- "문서 폴더 목록 보여줘"

**Usage Pattern**:
```
User: "~/documents 폴더 목록 보여줘"
→ list_directory(path="/home/user/documents")
→ 파일 및 디렉토리 목록 반환
```

## Best Practices

### 1. 경로 사용
- ✅ 절대 경로 사용: `/home/user/file.txt`
- ✅ ~ 확장 지원: `~/file.txt`
- ⚠️ 상대 경로 주의: `./file.txt`

### 2. 권한 확인
- ✅ allowed-directories 내부만 접근 가능
- ⚠️ 시스템 파일 수정 주의

### 3. 파일 크기
- ✅ 작은 파일 (<1MB) 직접 읽기
- ⚠️ 큰 파일은 부분 읽기 권장

## Version

- **Skill Version**: 1.0.0
- **MCP Server**: filesystem
- **Tools**: 5개
- **Last Updated**: 2025-11-15

---

**Maintained by**: Your Name
**Related Skills**: None
**MCP Server**: @modelcontextprotocol/server-filesystem
```

### 4.2 기존 Skill에 통합

기존 Skill에 새 MCP 도구를 추가할 수도 있습니다.

```markdown
---
name: existing-skill
description: ...
allowed-tools: existing_tool1, existing_tool2, NEW_TOOL_FROM_NEW_MCP
---
```

---

## 5. 테스트 및 검증

### 5.1 MCP 연결 테스트

```bash
# Lazy MCP 재시작
pkill -f mcp-proxy

# Claude Code 재시작
pkill -f "claude-code"

# Claude Code에서 확인
/mcp
```

**예상 출력**:
```
Connected MCP Servers:
✅ lazy-mcp-proxy
   - filesystem (preloaded 또는 lazy-load)
   - (기타 서버들...)
```

### 5.2 Skill 테스트

```
Claude Code에서:

"~/documents 폴더 목록 보여줘"
→ filesystem-manager Skill 사용
→ list_directory 도구 호출
→ 결과 반환
```

### 5.3 토큰 영향 확인

```
/context
```

**Preload 추가 시**:
- MCP Tools 토큰 증가 (약 0.5-2k)
- 총 토큰이 200k 이하인지 확인

**Lazy Load 추가 시**:
- MCP Tools 토큰 변화 없음 (약 100-200 토큰만 증가)

---

## 6. 주요 MCP 서버 추가 예시

### 6.1 Filesystem MCP

**설치**:
```bash
# 패키지 설치 불필요 (npx 사용)
```

**config.json**:
```json
"filesystem": {
  "transportType": "stdio",
  "command": "npx",
  "args": [
    "-y",
    "@modelcontextprotocol/server-filesystem",
    "--allowed-directories",
    "/home/USER/documents",
    "/home/USER/projects"
  ],
  "options": {
    "lazyLoad": false,
    "preload": true
  }
}
```

**제공 도구**: read_file, write_file, list_directory, create_directory, delete_file

---

### 6.2 Slack MCP

**설치**:
```bash
# Slack Bot Token 발급
# https://api.slack.com/apps

export SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN}"
export SLACK_TEAM_ID="T1234567"
```

**config.json**:
```json
"slack": {
  "transportType": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-slack"],
  "env": {
    "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}",
    "SLACK_TEAM_ID": "T1234567"
  },
  "options": {
    "lazyLoad": true,
    "preload": false
  }
}
```

**제공 도구**: post_message, list_channels, get_channel_history 등

---

### 6.3 Google Drive MCP

**설치**:
```bash
# OAuth 인증 파일 준비
# credentials.json을 ~/.gdrive/에 저장
```

**config.json**:
```json
"google-drive": {
  "transportType": "stdio",
  "command": "npx",
  "args": [
    "-y",
    "@modelcontextprotocol/server-gdrive",
    "--credentials-path",
    "/home/USER/.gdrive/credentials.json"
  ],
  "options": {
    "lazyLoad": true,
    "preload": false
  }
}
```

**제공 도구**: search_files, read_file, upload_file, create_folder 등

---

### 6.4 Postgres MCP

**설치**:
```bash
# PostgreSQL 연결 정보 준비
export DB_URL="postgresql://user:password@localhost:5432/dbname"
```

**config.json**:
```json
"postgres": {
  "transportType": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-postgres"],
  "env": {
    "POSTGRES_URL": "postgresql://user:password@localhost:5432/dbname"
  },
  "options": {
    "lazyLoad": true,
    "preload": false
  }
}
```

**제공 도구**: query, list_tables, describe_table 등

---

### 6.5 Brave Search MCP

**설치**:
```bash
# Brave Search API Key 발급
# https://brave.com/search/api/

export BRAVE_API_KEY="${BRAVE_API_KEY}"
```

**config.json**:
```json
"brave-search": {
  "transportType": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-brave-search"],
  "env": {
    "BRAVE_API_KEY": "${BRAVE_API_KEY}"
  },
  "options": {
    "lazyLoad": true,
    "preload": false
  }
}
```

**제공 도구**: web_search, local_search 등

---

### 6.6 Puppeteer MCP (웹 자동화)

**설치**:
```bash
# Chromium 설치 (Ubuntu/Debian)
sudo apt-get install -y chromium-browser
```

**config.json**:
```json
"puppeteer": {
  "transportType": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-puppeteer"],
  "options": {
    "lazyLoad": true,
    "preload": false
  }
}
```

**제공 도구**: navigate, screenshot, click, fill_form 등

---

## 7. 문제 해결

### 7.1 MCP 서버가 인식 안 됨

**증상**:
```
/mcp
❌ new-mcp-server not found
```

**해결**:
```bash
# 1. config.json 확인
cat ~/lazy-mcp/config.json | python3 -m json.tool

# 2. 경로 확인
which npx
# 또는
ls -lh ~/mcp-servers/new-server/

# 3. 수동 실행 테스트
npx -y @modelcontextprotocol/server-NEW

# 4. Lazy MCP 재시작
pkill -f mcp-proxy
# Claude Code 재시작
```

### 7.2 도구가 표시 안 됨

**증상**:
```
/mcp
✅ new-mcp-server
   - (no tools)
```

**해결**:
```bash
# 도구 계층 구조 재생성
cd ~/lazy-mcp
rm -rf testdata/mcp_hierarchy/new-server/

timeout 30s ./build/structure_generator \
  --server "new-server" \
  --config ./config.json \
  --output ./testdata/mcp_hierarchy

# Claude Code 재시작
```

### 7.3 환경 변수 오류

**증상**:
```
Error: API_KEY is required
```

**해결**:
```json
// config.json의 env 섹션 확인
"env": {
  "API_KEY": "your-actual-key-here",
  "OTHER_VAR": "value"
}

// 민감한 정보는 별도 파일로 관리
"env": {
  "API_KEY": "$ENV:MY_API_KEY"
}
```

```bash
# 환경 변수 설정
export MY_API_KEY="your-key"
echo 'export MY_API_KEY="your-key"' >> ~/.bashrc
```

### 7.4 Lazy Load 작동 안 함

**증상**:
Lazy Load MCP가 자동 활성화되지 않음

**해결**:
```json
// config.json 확인
"options": {
  "lazyLoad": true,   // ✓ true 확인
  "preload": false    // ✓ false 확인
}
```

```bash
# Lazy MCP 프록시 재시작
pkill -f mcp-proxy
# Claude Code 재시작

# 사용 시도
"새 MCP 서버 사용해줘"
→ 1-2초 후 자동 활성화
```

---

## 8. MCP 서버 제거

### 8.1 config.json에서 제거

```bash
# 백업
cp ~/lazy-mcp/config.json ~/lazy-mcp/config.json.backup

# 편집 (해당 서버 블록 삭제)
vim ~/lazy-mcp/config.json
```

### 8.2 도구 계층 구조 삭제

```bash
rm -rf ~/lazy-mcp/testdata/mcp_hierarchy/removed-server/
```

### 8.3 Skill 제거 (선택)

```bash
rm -rf ~/.claude/skills/removed-server-skill/
```

### 8.4 Claude Code 재시작

```bash
pkill -f "claude-code"
```

---

## 9. 베스트 프랙티스

### 9.1 MCP 서버 선택 기준

**Preload 권장**:
- 매일 사용하는 MCP (예: filesystem, ssh)
- 토큰 비용 낮음 (<1k)
- 빠른 응답 필요

**Lazy Load 권장**:
- 가끔 사용하는 MCP (예: slack, gdrive)
- 토큰 비용 높음 (>2k)
- 1-2초 지연 허용

### 9.2 토큰 관리

```bash
# 추가 전 토큰 확인
/context
→ 현재: 158k/200k (79%)

# Preload 추가 시 예상
→ 예상: 160k/200k (80%) - 2k 증가

# Lazy Load 추가 시 예상
→ 예상: 158k/200k (79%) - 변화 없음
```

**목표**: 총 토큰 180k 이하 유지 (90%)

### 9.3 Skill 네이밍

```
filesystem-manager      ✓ 명확
file-ops               ✓ 간결
fs                     ✗ 너무 짧음
filesystem_operations  ✗ 언더스코어 (하이픈 권장)
```

### 9.4 문서화

새 MCP 추가 시 다음을 문서화하세요:

```markdown
## Added MCP Servers

### filesystem (2025-11-15)
- **Purpose**: 로컬 파일 시스템 관리
- **Tools**: 5개 (read_file, write_file 등)
- **Load Type**: Preload
- **Token Impact**: +1.2k
- **Skill**: filesystem-manager
```

---

## 10. 공식 MCP 서버 목록

### 10.1 ModelContextProtocol 공식 서버

**저장소**: https://github.com/modelcontextprotocol/servers

**주요 서버**:
- `@modelcontextprotocol/server-filesystem` - 파일 시스템
- `@modelcontextprotocol/server-github` - GitHub
- `@modelcontextprotocol/server-gitlab` - GitLab
- `@modelcontextprotocol/server-postgres` - PostgreSQL
- `@modelcontextprotocol/server-sqlite` - SQLite
- `@modelcontextprotocol/server-slack` - Slack
- `@modelcontextprotocol/server-gdrive` - Google Drive
- `@modelcontextprotocol/server-brave-search` - Brave Search
- `@modelcontextprotocol/server-puppeteer` - 웹 자동화

### 10.2 커뮤니티 MCP 서버

**검색**: https://www.npmjs.com/search?q=mcp-server

**예시**:
- `mcp-server-redis` - Redis
- `mcp-server-mongodb` - MongoDB
- `mcp-server-docker` - Docker
- `mcp-server-aws` - AWS

---

## 11. 자동화 스크립트

### 11.1 MCP 추가 스크립트

```bash
#!/usr/bin/env bash
# add-mcp.sh - MCP 서버 자동 추가 스크립트

# 사용법: ./add-mcp.sh <server-name> <npm-package> [preload|lazy]

SERVER_NAME="$1"
NPM_PACKAGE="$2"
LOAD_TYPE="${3:-lazy}"

if [ -z "$SERVER_NAME" ] || [ -z "$NPM_PACKAGE" ]; then
    echo "사용법: $0 <server-name> <npm-package> [preload|lazy]"
    echo "예: $0 filesystem @modelcontextprotocol/server-filesystem preload"
    exit 1
fi

# config.json 백업
cp ~/lazy-mcp/config.json ~/lazy-mcp/config.json.backup

# 새 서버 블록 생성
if [ "$LOAD_TYPE" = "preload" ]; then
    LAZY_LOAD="false"
    PRELOAD="true"
else
    LAZY_LOAD="true"
    PRELOAD="false"
fi

# config.json에 추가 (jq 사용)
jq ".mcpServers.\"$SERVER_NAME\" = {
    \"transportType\": \"stdio\",
    \"command\": \"npx\",
    \"args\": [\"-y\", \"$NPM_PACKAGE\"],
    \"env\": {},
    \"options\": {
        \"lazyLoad\": $LAZY_LOAD,
        \"preload\": $PRELOAD
    }
}" ~/lazy-mcp/config.json > ~/lazy-mcp/config.json.tmp

mv ~/lazy-mcp/config.json.tmp ~/lazy-mcp/config.json

echo "✓ $SERVER_NAME 추가 완료 (Load Type: $LOAD_TYPE)"
echo ""
echo "다음 단계:"
echo "  1. 도구 계층 구조 생성:"
echo "     cd ~/lazy-mcp"
echo "     ./build/structure_generator --server \"$SERVER_NAME\" --config ./config.json --output ./testdata/mcp_hierarchy"
echo ""
echo "  2. Claude Code 재시작"
echo ""
echo "  3. 확인: /mcp"
```

---

## 12. 체크리스트

새 MCP 서버 추가 시:

- [ ] MCP 서버 정보 수집 (이름, 명령어, 도구)
- [ ] 단독 실행 테스트 성공
- [ ] config.json에 추가
- [ ] Load Type 결정 (Preload/Lazy Load)
- [ ] 도구 계층 구조 생성
- [ ] (선택) Skill 생성
- [ ] Claude Code 재시작
- [ ] `/mcp` 명령으로 확인
- [ ] 토큰 영향 확인 (`/context`)
- [ ] 기능 테스트 (실제 도구 호출)
- [ ] 문서화 (추가 이력 기록)

---

## 📞 지원

MCP 추가 중 문제 발생 시:

1. **TROUBLESHOOTING.md** - "2. MCP 연결 문제" 참조
2. **MCP 서버 문서** - 공식 README 확인
3. **GitHub Issues** - MCP 서버 저장소 Issues
4. **이메일**: support@hwandam.kr

---

**최종 업데이트**: 2025-11-15
**버전**: 1.0.0
**테스트 환경**: Ubuntu 22.04, Lazy MCP v1.0
