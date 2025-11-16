# Skills 세분화 상세 분석

## 현재 상태 요약

### 생성된 Domain-Specific Skills (4개)

1. **kb-system** (7개 도구 사용)
2. **ssh-operator** (4개 도구 사용)
3. **github-manager** (execute_tool 사용)
4. **context7-docs** (2개 도구 사용)

### 기존 CLI-based Skills (3개)

5. **codex-architect** (Codex CLI 전체)
6. **qwen-code-engineer** (Qwen CLI 전체)
7. **gemini-content-creator** (Gemini CLI 전체)

---

## 🔍 세분화 가능 영역 분석

### 1. Knowledge Base MCP - 17개 미사용 도구 발견!

#### 현재 kb-system이 사용하는 도구 (7개)
```yaml
allowed-tools:
  - kb_health            # Health check
  - kb_search            # Document search (keyword)
  - kb_document_create   # Create document
  - kb_document_update   # Update document
  - kb_upload            # Upload from file
  - kb_version_create    # Create version
  - kb_version_list      # List versions
```

#### 누락된 도구 (17개)

##### A. Knowledge Graph Tools (6개) - 완전 누락
```yaml
# 새 Skill: kb-knowledge-graph
allowed-tools:
  - kg_create_entities    # 엔티티 생성 (개념, 사람, 객체)
  - kg_create_relations   # 엔티티 간 관계 생성
  - kg_add_observations   # 엔티티에 관찰/메모 추가
  - kg_add_tags           # 엔티티 태그 추가
  - kg_search_knowledge   # 지식 그래프 검색
  - kg_read_graph         # 전체 그래프 조회
```

**사용 예시:**
```
User: "FastAPI와 PostgreSQL의 관계를 지식 그래프에 추가해줘"
→ kg_create_entities(["FastAPI", "PostgreSQL"])
→ kg_create_relations(["FastAPI depends_on PostgreSQL"])

User: "FastAPI에 대한 정보 추가"
→ kg_add_observations(
    entity_name="FastAPI",
    observations=["비동기 웹 프레임워크", "Python 3.7+ 지원"]
  )
```

##### B. AI-Powered Tools (7개) - 완전 누락
```yaml
# 새 Skill: kb-ai-assistant
allowed-tools:
  - kb_embedding_generate   # 문서 임베딩 생성 (BGE-M3)
  - kb_search_semantic      # 시맨틱 검색 (벡터 유사도)
  - kb_search_hybrid_v2     # 하이브리드 검색 (키워드 30% + 시맨틱 70%)
  - kb_auto_tag             # AI 자동 태깅 (Gemma3)
  - kb_summarize            # 문서 요약 (Gemma3)
  - kb_ask                  # RAG 기반 Q&A
  - kb_image_analyze        # 이미지 분석 (Gemma3 Vision)
```

**사용 예시:**
```
User: "모든 문서에 임베딩 생성해줘"
→ kb_embedding_generate(batch_all=true, limit=100)

User: "WebSocket과 의미적으로 유사한 문서 검색"
→ kb_search_semantic(query="WebSocket", limit=10)

User: "문서 123번 요약해줘"
→ kb_summarize(document_id=123, length="medium")

User: "FastAPI의 async 처리 방식에 대해 설명해줘"
→ kb_ask(
    question="FastAPI의 async 처리 방식",
    num_sources=3
  )
```

##### C. Large Document Support (3개) - 완전 누락
```yaml
# kb-system에 통합 또는 별도 Skill
allowed-tools:
  - kb_document_get_meta        # 문서 메타데이터만 조회
  - kb_document_get_chunk       # 문서 청크 조회 (대용량 문서)
  - kb_document_search_within   # 문서 내 검색
```

**사용 예시:**
```
User: "대용량 문서 123번의 메타데이터만 보여줘"
→ kb_document_get_meta(document_id=123)

User: "문서 123번의 2번째 청크 조회"
→ kb_document_get_chunk(document_id=123, chunk_index=1)

User: "문서 123번 안에서 'async' 키워드 검색"
→ kb_document_search_within(
    document_id=123,
    query="async",
    max_results=5
  )
```

##### D. Unified Search (1개)
```yaml
# kb-system 또는 kb-ai-assistant에 추가
allowed-tools:
  - unified_search   # KB 문서 + KG 엔티티 동시 검색
```

**사용 예시:**
```
User: "WebSocket에 대한 모든 정보 검색 (문서 + 지식 그래프)"
→ unified_search(
    query="WebSocket",
    search_documents=true,
    search_entities=true,
    limit=10
  )
```

---

### 2. Codex-Qwen-Gemini MCP - 이미 잘 분리됨 ✅

현재 Skills:
- **codex-architect**: Codex CLI 전체 (3개 도구)
- **qwen-code-engineer**: Qwen CLI 전체 (8개 도구)
- **gemini-content-creator**: Gemini CLI 전체 (7개 도구)

**추가 세분화 가능 여부:**

#### Qwen Skill 세분화 (선택적)
```yaml
# 현재: qwen-code-engineer (8개 도구)
#   - qwen_cli, qwen_session_chat, qwen_session_clear
#   - qwen_explain_code, qwen_generate_code
#   - qwen_refactor_code, qwen_review_code, qwen_sandbox

# 제안 1: 유지 (현재 상태가 합리적)
# 제안 2: 세분화
#   - qwen-code-generator: generate_code, sandbox
#   - qwen-code-reviewer: review_code, refactor_code
#   - qwen-code-explainer: explain_code
```

**권장: 현재 상태 유지** (8개 도구를 3개 Skills로 나누면 오히려 복잡해짐)

---

### 3. SSH, Context7, GitHub - 이미 최적 ✅

- **ssh-operator**: 4개 도구 모두 사용 중
- **context7-docs**: 2개 도구 모두 사용 중
- **github-manager**: execute_tool로 lazy-loading 사용 중

추가 세분화 불필요.

---

## 🎯 세분화 제안 우선순위

### 최우선 (High Priority) - Knowledge Base 3개 Skills 추가

#### 1. kb-knowledge-graph (6개 도구)
```yaml
---
name: kb-knowledge-graph
description: Knowledge Graph 관리 전문가. 엔티티, 관계, 관찰 추가 및 검색.
allowed-tools: kg_create_entities, kg_create_relations, kg_add_observations, kg_add_tags, kg_search_knowledge, kg_read_graph
---
```

**효과:**
- 지식 그래프 기능을 명확하게 분리
- 프로젝트 관계, 기술 스택 연관성 관리
- 팀원, 컴포넌트, 의존성 추적

**사용 사례:**
- "프로젝트 아키텍처를 지식 그래프로 표현해줘"
- "FastAPI와 관련된 모든 기술 검색"
- "팀원별 담당 프로젝트 관계 추가"

#### 2. kb-ai-assistant (7개 도구)
```yaml
---
name: kb-ai-assistant
description: AI 기반 KB 어시스턴트. 시맨틱 검색, 자동 태깅, 요약, RAG Q&A, 이미지 분석.
allowed-tools: kb_embedding_generate, kb_search_semantic, kb_search_hybrid_v2, kb_auto_tag, kb_summarize, kb_ask, kb_image_analyze
---
```

**효과:**
- 의미 기반 검색으로 정확도 향상
- 자동 태깅으로 문서 분류 자동화
- RAG 기반 Q&A로 자연어 질문 응답
- 이미지 분석으로 다이어그램 이해

**사용 사례:**
- "비슷한 내용의 문서 찾아줘" (시맨틱 검색)
- "모든 문서에 자동으로 태그 달아줘"
- "FastAPI 인증 방식에 대해 KB에서 답변해줘" (RAG)
- "아키텍처 다이어그램 이미지 분석해줘"

#### 3. kb-system-enhanced (기존 kb-system에 4개 도구 추가)
```yaml
---
name: kb-system
description: Enhanced KB 시스템 관리자. 문서 CRUD, 대용량 문서, 통합 검색.
allowed-tools:
  # 기존 7개
  kb_health, kb_search, kb_document_create, kb_document_update,
  kb_upload, kb_version_create, kb_version_list,
  # 추가 4개
  kb_document_get_meta, kb_document_get_chunk,
  kb_document_search_within, unified_search
---
```

**효과:**
- 대용량 문서 처리 능력 향상
- 문서 내 상세 검색 가능
- KB + KG 통합 검색

---

### 선택적 (Optional) - Qwen Skill 세분화

**권장하지 않음** (현재 상태가 이미 적절함)

Qwen은 코드 생성/리뷰/리팩토링이 모두 연관된 작업이므로, 하나의 Skill에 통합하는 것이 더 효율적입니다.

---

## 📊 예상 효과

### Before (현재)
- **총 Skills**: 7개
- **KB 관련 Skills**: 1개 (kb-system, 7개 도구)
- **미사용 KB 도구**: 17개 (71% 활용 안 됨!)

### After (제안 적용 시)
- **총 Skills**: 9개 (+2)
- **KB 관련 Skills**: 3개
  - kb-system-enhanced (11개 도구)
  - kb-knowledge-graph (6개 도구)
  - kb-ai-assistant (7개 도구)
- **미사용 KB 도구**: 0개 (100% 활용!)

---

## 🎯 다음 단계 제안

### Option 1: 전체 적용 (최대 효과)
1. kb-knowledge-graph Skill 생성
2. kb-ai-assistant Skill 생성
3. kb-system을 kb-system-enhanced로 업그레이드

**예상 시간**: 30분
**효과**: Knowledge Base 기능 100% 활용

### Option 2: 우선순위만 적용
1. kb-ai-assistant Skill 생성 (가장 임팩트 큼)
2. kb-system에 unified_search만 추가

**예상 시간**: 15분
**효과**: AI 검색 기능 활성화 (50% 개선)

### Option 3: 현재 상태 유지
- 기본 문서 관리만 필요한 경우
- Knowledge Graph와 AI 기능이 불필요한 경우

---

## 💡 권장 사항

**추천: Option 1 (전체 적용)**

이유:
1. Knowledge Base MCP가 24개 도구를 제공하는데 7개만 사용 중 (29%)
2. 특히 AI 도구 (시맨틱 검색, RAG, 요약)는 매우 유용함
3. Knowledge Graph는 복잡한 프로젝트 관계 관리에 필수
4. 구현 난이도 낮음 (기존 패턴 재사용)

예상 효과:
- ✅ 의미 기반 검색으로 정확도 30% 향상
- ✅ RAG Q&A로 자연어 질문 응답 가능
- ✅ Knowledge Graph로 프로젝트 관계 시각화
- ✅ 자동 태깅으로 분류 작업 90% 감소

---

## 📝 구현 우선순위

1. **kb-ai-assistant** (가장 임팩트 큼) ⭐⭐⭐
2. **kb-knowledge-graph** (복잡한 관계 관리) ⭐⭐
3. **kb-system 업그레이드** (대용량 문서 지원) ⭐

---

**작성일**: 2025-11-15
**분석 대상**: Knowledge Base MCP (24개 도구), Codex-Qwen-Gemini MCP (20+ 도구)
**결론**: Knowledge Base에서 17개 도구가 Skills로 분리되지 않았으며, 특히 AI Tools와 Knowledge Graph는 고가치 기능임
