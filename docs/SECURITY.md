# 보안 가이드 (SECURITY)

> MCP + Skills 배포 시 보안 모범 사례

---

## 🔒 보안 원칙

### 1. 절대 포함하지 말 것

다음 정보는 **절대로** Git 저장소나 문서에 포함하지 마세요:

- ❌ 실제 비밀번호
- ❌ API 키 및 토큰
- ❌ 데이터베이스 자격 증명
- ❌ SSH 키 및 인증서
- ❌ 환경별 설정 파일 (`.env`)
- ❌ 실제 호스트명 및 IP 주소
- ❌ 실제 사용자 이름 (서비스 계정)

---

## 🛡️ 환경 변수 사용

### 올바른 방법

**❌ 잘못된 예시** (하드코딩):
```json
{
  "env": {
    "DB_PASSWORD": "mySecretPassword123",
    "API_KEY": "sk-1234567890abcdef"
  }
}
```

**✅ 올바른 예시** (환경 변수):
```json
{
  "env": {
    "DB_PASSWORD": "${DB_PASSWORD}",
    "API_KEY": "${API_KEY}"
  }
}
```

---

## 📝 .env 파일 관리

### .env.example 작성

민감한 정보 대신 **템플릿**을 제공하세요:

**.env.example**:
```bash
# Database Configuration
DB_HOST=your-database-host
DB_PORT=5432
DB_NAME=your-database-name
DB_USER=your-database-user
DB_PASSWORD=your-database-password

# API Keys
SLACK_BOT_TOKEN=xoxb-your-slack-token
BRAVE_API_KEY=your-brave-api-key

# Ollama (Optional)
OLLAMA_HOST=http://localhost:11434
```

### 실제 .env 파일

```bash
# 1. 템플릿 복사
cp .env.example .env

# 2. 실제 값으로 편집
vim .env

# 3. 권한 설정 (중요!)
chmod 600 .env
```

---

## 🔐 .gitignore 설정

반드시 `.gitignore`에 추가:

```gitignore
# 환경 변수
.env
.env.*
!.env.example

# 백업 파일 (민감한 정보 포함 가능)
*.backup
*-backup/

# 로그 (민감한 정보 포함 가능)
*.log
logs/

# 설정 파일 (실제 값 포함)
config.json
!config.example.json
```

---

## 🚨 민감한 정보 노출 시 대응

### 1. 즉시 조치

```bash
# 1. 해당 커밋 제거 (로컬)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/sensitive/file" \
  --prune-empty --tag-name-filter cat -- --all

# 2. 강제 푸시 (주의!)
git push origin --force --all
```

### 2. 자격 증명 변경

노출된 모든 자격 증명을 **즉시 변경**:
- 비밀번호
- API 키
- 토큰
- SSH 키

### 3. GitHub Secret Scanning 확인

GitHub는 자동으로 비밀 정보를 스캔합니다. 알림을 확인하세요.

---

## 📋 배포 전 체크리스트

배포하기 전에 다음을 확인하세요:

- [ ] 모든 비밀번호가 환경 변수로 처리됨
- [ ] `.env` 파일이 `.gitignore`에 포함됨
- [ ] `.env.example`이 제공됨
- [ ] 문서에 실제 자격 증명이 없음
- [ ] 설정 파일에 실제 호스트명이 없음
- [ ] 로그 파일이 `.gitignore`에 포함됨

---

## 🔍 민감한 정보 검색

배포 전 검사:

```bash
# 비밀번호 검색
grep -r -i "password.*=" . --include="*.md" --include="*.json"

# API 키 검색
grep -r -i "api.*key.*=" . --include="*.md" --include="*.json"

# 토큰 검색
grep -r -i "token.*=" . --include="*.md" --include="*.json"

# 특정 도메인 검색 (예시)
grep -r "your-domain\.com" . --include="*.md" --include="*.json"
```

---

## 🎯 모범 사례

### 1. 환경별 설정 분리

```bash
# 개발 환경
config/development.json

# 스테이징 환경
config/staging.json

# 프로덕션 환경
config/production.json

# Git에는 템플릿만 포함
config/config.example.json
```

### 2. Secrets 관리 도구 사용

프로덕션 환경에서는 전문 도구 사용 권장:

- **HashiCorp Vault**: 중앙화된 비밀 관리
- **AWS Secrets Manager**: AWS 환경
- **Azure Key Vault**: Azure 환경
- **Google Secret Manager**: GCP 환경

### 3. 최소 권한 원칙

- 각 서비스에 필요한 **최소한의 권한만** 부여
- 읽기 전용 계정 사용 (가능한 경우)
- 정기적으로 권한 검토

---

## 📞 보안 문제 신고

보안 문제를 발견하면:

1. **공개 이슈로 보고하지 마세요**
2. 이메일로 비공개 보고: security@hwandam.kr
3. 24-48시간 내 응답 예상

---

## 🔄 정기 보안 검토

### 월별

- [ ] 사용하지 않는 API 키 삭제
- [ ] 비밀번호 만료 확인
- [ ] 로그 파일 검토 (민감한 정보 노출 여부)

### 분기별

- [ ] 전체 코드베이스 스캔
- [ ] 의존성 취약점 검사
- [ ] 권한 재검토

### 연간

- [ ] 모든 비밀번호 변경
- [ ] API 키 갱신
- [ ] SSH 키 재생성

---

## 📚 참고 자료

- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **GitHub Security Best Practices**: https://docs.github.com/en/code-security
- **12-Factor App**: https://12factor.net/

---

**마지막 업데이트**: 2025-11-15
**버전**: 1.0.0
