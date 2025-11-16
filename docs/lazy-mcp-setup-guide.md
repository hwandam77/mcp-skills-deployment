# Lazy MCP - 자동 MCP 서버 로딩 가이드

**작성일**: 2025-11-14
**목적**: Claude Code에서 필요한 MCP 서버만 자동으로 로드하여 토큰 절약

---

## 🎯 Lazy MCP란?

**Lazy MCP**는 MCP 프록시 서버로, Claude Code가 **필요할 때만** MCP 도구를 로드하도록 합니다.

### 핵심 기능
- ✅ **On-demand 로딩**: 사용하지 않는 MCP 도구는 컨텍스트에서 제외
- ✅ **자동 활성화**: 대화 중 필요하면 자동으로 MCP 서버 활성화
- ✅ **토큰 절약**: 초기 컨텍스트 최대 95% 절감 가능
- ✅ **재시작 불필요**: 세션 중 동적 로딩 지원

### 실제 사례
- **2개 MCP 도구 숨김**: 34,000 토큰 절약 (17% 절감)
- **여러 서버 관리**: 초기 108k → 5k 토큰 (95% 절감)

---

## 🔍 작동 원리

### 기존 방식 (문제)
```
Claude Code 시작
  ↓
모든 MCP 서버 로드
  ↓
모든 도구 정의 로드 (77k 토큰 소비)
  ↓
대화 시작
```

### Lazy MCP 방식 (해결)
```
Claude Code 시작
  ↓
Lazy MCP 프록시만 로드 (2개 메타 도구만)
  ↓
대화 중 "GitHub 이슈 생성" 요청
  ↓
자동으로 GitHub MCP 서버 로드
  ↓
도구 실행 후 결과 반환
```

### 2개의 메타 도구

#### 1. `get_tools_in_category(path)`
도구 계층 구조 탐색:
```javascript
// 루트 카테고리 조회
get_tools_in_category("")
→ { "categories": { "github": "...", "coding_tools": "..." } }

// 하위 카테고리 조회
get_tools_in_category("github")
→ { "tools": { "create_issue": "...", "search_repos": "..." } }
```

#### 2. `execute_tool(tool_path, arguments)`
도구 실행 (자동 서버 활성화):
```javascript
execute_tool("github.create_issue", {
  "repo": "owner/repo",
  "title": "Bug report",
  "body": "Description"
})
→ GitHub MCP 서버 자동 로드 (최초 1회)
→ 도구 실행
→ 결과 반환
```

---

## 📦 설치 방법

### Prerequisites
- Go 1.21+ 설치 필요
- 기존 MCP 서버들 (github, grafana 등)

### Step 1: Lazy MCP 저장소 클론
```bash
cd ~/service/MCP
git clone https://github.com/voicetreelab/lazy-mcp.git
cd lazy-mcp
```

### Step 2: 빌드
```bash
make build
```

빌드 완료 후 생성되는 파일:
- `build/mcp-proxy`: 프록시 서버 실행 파일
- `build/structure_generator`: 계층 구조 생성 도구

### Step 3: 설정 파일 생성

**`config.json`** 생성:
```json
{
  "mcpProxy": {
    "baseURL": "http://localhost",
    "addr": ":9090",
    "name": "MCP Lazy Load Proxy",
    "version": "1.0.0",
    "type": "stdio",
    "hierarchyPath": "testdata/mcp_hierarchy",
    "options": {
      "lazyLoad": true
    }
  },
  "mcpServers": {
      "transportType": "stdio",
      "command": "node",
      "args": [
      ],
      "env": {},
      "options": {
        "lazyLoad": true
      }
    },
      "transportType": "stdio",
      "command": "node",
      "args": [
        "/path/to/MCP/Knowledge_Base-MCP/local_mcp/kb-mcp-wrapper.js"
      ],
      "env": {},
      "options": {
        "lazyLoad": true
      }
    },
    "context7": {
      "transportType": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@context7/mcp-server"
      ],
      "env": {},
      "options": {
        "lazyLoad": true
      }
    },
    "ssh": {
      "transportType": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-ssh"
      ],
      "env": {},
      "options": {
        "lazyLoad": true
      }
    },
    "github": {
      "transportType": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      },
      "options": {
        "lazyLoad": true
      }
    },
    "grafana": {
      "transportType": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-grafana"
      ],
      "env": {},
      "options": {
        "lazyLoad": true
      }
    }
  }
}
```

### Step 4: 도구 계층 구조 생성
```bash
./build/structure_generator --config config.json --output testdata/mcp_hierarchy
```

이 명령은:
1. 각 MCP 서버에 연결
2. 사용 가능한 모든 도구 조회
3. 계층 구조 JSON 파일 생성

### Step 5: Claude Code에 등록

#### Option A: 직접 등록 (stdio)
```bash
claude mcp add --transport stdio lazy-mcp-proxy \
  /path/to/MCP/lazy-mcp/build/mcp-proxy -- \
  --config /path/to/MCP/lazy-mcp/config.json
```

#### Option B: `.claude.json` 수동 편집
```json
{
  "mcpServers": {
    "lazy-mcp-proxy": {
      "type": "stdio",
      "command": "/path/to/MCP/lazy-mcp/build/mcp-proxy",
      "args": [
        "--config",
        "/path/to/MCP/lazy-mcp/config.json"
      ],
      "env": {}
    }
  }
}
```

---

## 🎯 사용 시나리오

### 시나리오 1: 일반 개발 작업
```
Claude Code 시작
  ↓
Lazy MCP 프록시만 로드 (~2k 토큰)
  ↓
  ↓
초기 토큰: ~19k (기존: 77k)
```

### 시나리오 2: GitHub 작업 필요
```
사용자: "GitHub 이슈 생성해줘"
  ↓
Claude가 get_tools_in_category("github") 자동 호출
  ↓
GitHub MCP 서버 자동 활성화
  ↓
execute_tool("github.create_issue", {...}) 실행
  ↓
작업 완료
```

### 시나리오 3: Grafana 모니터링
```
사용자: "Grafana 대시보드 조회해줘"
  ↓
Grafana MCP 서버 자동 활성화
  ↓
도구 실행
  ↓
작업 완료 후 서버는 메모리에 유지 (재사용 가능)
```

---

## 📊 예상 효과

### 토큰 사용량 비교

| 상태 | MCP 토큰 | 전체 토큰 | 비율 |
|-----|---------|---------|------|
| **기존 (전체 활성화)** | 77.1k | 234k | 117% ❌ |
| **수동 최적화 (4개만)** | 19k | 176k | 88% ✅ |
| **Lazy MCP (초기)** | ~5-10k | ~160k | 80% ✅ |
| **Lazy MCP (필요시 로드)** | 동적 증가 | 동적 증가 | - |

### 장점
✅ **완전 자동**: 사용자가 직접 전환할 필요 없음
✅ **지능적 로딩**: 대화 맥락에 따라 자동 판단
✅ **재시작 불필요**: 세션 중 동적 활성화
✅ **모든 도구 사용 가능**: 필요하면 언제든 자동 로드

### 단점
⚠️ **초기 로딩 지연**: 처음 사용 시 MCP 서버 활성화 시간 필요 (1-2초)
⚠️ **복잡성 증가**: 추가 프록시 레이어 관리 필요
⚠️ **디버깅 어려움**: 문제 발생 시 프록시 레이어 추가 확인 필요

---

## 🔧 고급 설정

### 필수 도구 사전 로드

일부 도구는 항상 사용하므로 사전 로드 가능:

**`config.json`**:
```json
{
  "mcpServers": {
      "options": {
        "lazyLoad": false,  // 항상 로드
        "preload": true
      }
    },
    "github": {
      "options": {
        "lazyLoad": true,   // 필요시 로드
        "preload": false
      }
    }
  }
}
```

### 카테고리 커스터마이징

도구를 논리적 카테고리로 그룹화:

**`testdata/mcp_hierarchy/root.json`**:
```json
{
  "type": "category",
  "name": "root",
  "description": "Root category",
  "categories": {
    "ai_tools": {
      "description": "AI coding assistants (Codex, Qwen, Gemini)",
      "usage": "Use for code generation, review, and AI assistance"
    },
    "github_tools": {
      "description": "GitHub integration tools",
      "usage": "Use for PR, issues, and repo management"
    },
    "monitoring_tools": {
      "description": "Monitoring and observability",
      "usage": "Use for Grafana dashboards and metrics"
    }
  }
}
```

---

## 🐛 트러블슈팅

### 문제 1: 도구 로딩 실패
```bash
# 로그 확인
tail -f ~/service/MCP/lazy-mcp/logs/proxy.log

# MCP 서버 직접 테스트
```

### 문제 2: 계층 구조 생성 실패
```bash
# 개별 MCP 서버 연결 테스트
npx -y @modelcontextprotocol/server-github
```

### 문제 3: Claude Code 인식 안 됨
```bash
# .claude.json 검증
jq . ~/.claude.json

# MCP 서버 재등록
claude mcp remove lazy-mcp-proxy
claude mcp add --transport stdio lazy-mcp-proxy ...
```

---

## 🔄 대안: MCP Hot Reload

**완전 자동화보다 개발 편의성**이 목적이라면 **MCP Hot Reload** 고려:

### mcp-reloader (개발용)
```bash
# 설치
npm install -g mcp-reloader

# Claude Code에 등록
claude mcp add --transport stdio mcp-reloader \
  npx mcp-reloader -- \
  node /path/to/your-mcp-server.js
```

**장점**:
- MCP 서버 코드 변경 시 자동 재시작
- 세션 유지 (연결 끊김 없음)
- 개발 워크플로우 개선

**단점**:
- 토큰 절약 효과 없음
- 개발 환경용 (프로덕션 부적합)

---

## 📚 참고 자료

- **Lazy MCP GitHub**: https://github.com/voicetreelab/lazy-mcp
- **MCP Reloader**: https://github.com/mizchi/mcp-reloader
- **Claude Code MCP 문서**: https://docs.claude.com/en/docs/claude-code/mcp
- **Feature Request #7336**: Lazy Loading for MCP Servers (95% context reduction)
- **Feature Request #6638**: Dynamic loading/unloading during sessions

---

## 🤔 결론 및 권장사항

### 현재 상황
- 수동 최적화로 **77k → 19k** 토큰 달성 (75% 절감)
- 4개 핵심 MCP 서버만 활성화

### Lazy MCP 적용 시
- **초기 토큰**: 5-10k (추가 50% 절감)
- **자동 로딩**: GitHub, Grafana 필요시 자동 활성화
- **재시작 불필요**: 세션 중 동적 관리

### 권장 사항

#### Option 1: 현재 상태 유지 (추천)
**이유**:
- 이미 88% 토큰 효율 달성 (176k/200k)
- 단순하고 안정적
- 필요시 `/mcp` 명령으로 수동 관리 가능

**적합한 경우**:
- 토큰 사용량이 정상 범위
- 작업 패턴이 일정함
- 복잡성 최소화 선호

#### Option 2: Lazy MCP 도입 (고급 사용자)
**이유**:
- 완전 자동화
- 최대 토큰 절약 (80% 수준)
- 모든 MCP 서버 사용 가능 (필요시)

**적합한 경우**:
- 다양한 MCP 서버 사용
- 토큰 한계 자주 도달
- 자동화 선호

**도입 절차**:
1. 테스트 환경에서 설치 및 테스트 (1-2시간)
2. 정상 작동 확인 후 프로덕션 적용
3. 2주간 모니터링 후 평가

---

**작성**: Claude Code (Sonnet 4.5)
**분석 기반**: lazy-mcp GitHub + Web Search + 실제 설정 파일 분석
