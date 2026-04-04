# AI News Daily Design Document

> **Summary**: 매일 08:00 KST에 전세계 AI 뉴스를 자동 수집·큐레이션하여 정적 웹페이지로 제공하는 개인용 뉴스레터
>
> **Feature**: ai-news-daily
> **Version**: 0.1.0
> **Author**: leoheo
> **Date**: 2026-04-04
> **Status**: Draft
> **Architecture**: Option B — Clean Architecture (모듈별 분리)
> **Plan Reference**: `docs/01-plan/features/ai-news-daily.plan.md`

---

## Pipeline References

| Phase | Document | Status |
|-------|----------|--------|
| Schema (Phase 1) | N/A — 프롬프트 기반 프로젝트, 별도 스키마 불필요 | Skip |
| Convention (Phase 2) | Section 10 CLAUDE.md Specification에 포함 | Inline |
| Mockup (Phase 3) | N/A — 템플릿 HTML로 대체 (Section 4) | Skip |
| API (Phase 4) | N/A — API 없음 (정적 사이트) | Skip |
| Design System (Phase 5) | Section 5 Style Design에 포함 | Inline |
| Plan | `docs/01-plan/features/ai-news-daily.plan.md` | Complete |

---

## Context Anchor

| Dimension | Content |
|-----------|---------|
| **WHY** | 매일 쏟아지는 글로벌 AI 뉴스를 직접 찾아 읽기엔 시간 부족, 중요한 뉴스를 놓치기 쉬움 |
| **WHO** | 본인 (개인용) — 매일 아침 5분 이내 AI 트렌드 파악 |
| **RISK** | 할루시네이션, 웹 검색 결과 부족, Remote Trigger 실패, 배포 실패 |
| **SUCCESS** | 매일 자동 발행, 10~20건 고품질, 5분 이내 훑어보기, 검증된 정보 |
| **SCOPE** | 웹 검색 수집 → 큐레이션 → 검증 → HTML 생성 → GitHub Pages 배포 |

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 매일 쏟아지는 글로벌 AI 뉴스를 직접 찾아 읽기엔 시간이 부족하고, 중요한 뉴스를 놓치기 쉬움 |
| **Solution** | Claude Code Remote Trigger(cron) + 모듈화된 프롬프트 아키텍처(검색/큐레이션/검증/생성 분리)로 자동 파이프라인 구축 |
| **Function/UX Effect** | 아침에 웹페이지 한 곳만 열면 5분 이내에 카테고리별·중요도별로 정리된 AI 뉴스를 한국어로 확인 가능 |
| **Core Value** | 매일 아침 신뢰할 수 있는 AI 뉴스 큐레이션을 자동으로 받아보는 개인 AI 브리핑 시스템 |

---

## 1. Overview

### 1.1 Design Goals

- **모듈성**: 검색 전략, 큐레이션 규칙, 검증 로직을 독립 파일로 분리하여 개별 수정 가능
- **신뢰성**: 3단계 할루시네이션 검증 파이프라인으로 거짓 정보 방지
- **자동화**: Claude Code Remote Trigger(cron)로 매일 무인 운영
- **가독성**: 깔끔한 뉴스레터 스타일 HTML로 5분 이내 훑어보기

### 1.2 Architecture Selection

**Selected**: Option B — Clean Architecture

| 비교 항목 | Option A (Minimal) | Option B (Clean) | Option C (Pragmatic) |
|-----------|-------------------|-------------------|---------------------|
| 파일 수 | ~5개 | **~10개+** | ~7개 |
| 모듈 분리 | 없음 | **완전 분리** | 부분 분리 |
| 수정 용이성 | 전체 영향 | **모듈별 독립** | 중간 |
| 확장성 | 낮음 | **높음** | 중간 |
| 구축 복잡도 | 낮음 | **중간** | 낮음 |

**선택 이유**: 검색 전략, 큐레이션 규칙, 검증 로직이 각각 독립적으로 진화할 가능성이 높음. 초기 구축 비용은 약간 높지만, 운영 중 개별 모듈 수정이 빈번할 것으로 예상됨.

---

## 2. Project Structure

```
ai-news/
├── site/                           # GitHub Pages 배포 대상 (정적 사이트)
│   ├── index.html                  # 오늘의 뉴스 (매일 덮어쓰기)
│   ├── style.css                   # 공통 스타일시트
│   └── archive/
│       ├── index.html              # 아카이브 목록 페이지
│       └── YYYY-MM-DD.html         # 날짜별 아카이브
│
├── scripts/                        # Claude agent 프롬프트 모듈
│   ├── generate.md                 # 메인 오케스트레이터 (전체 파이프라인 조율)
│   ├── search-strategy.md          # 3-Layer 웹 검색 전략
│   ├── curation-rules.md           # 큐레이션 · 분류 · 중요도 규칙
│   └── verification.md             # 할루시네이션 검증 규칙
│
├── templates/                      # HTML 템플릿
│   ├── news.html                   # 뉴스 페이지 템플릿 (index + archive 공용)
│   └── archive-index.html          # 아카이브 목록 템플릿
│
├── config/                         # 설정 파일
│   └── sources.json                # 검색 소스 · 카테고리 · 키워드 설정
│
├── CLAUDE.md                       # 프로젝트 규칙 · 실행 가이드
└── docs/                           # PDCA 문서
    ├── 01-plan/features/
    │   └── ai-news-daily.plan.md
    └── 02-design/features/
        └── ai-news-daily.design.md # 이 문서
```

### 2.1 디렉토리 역할

| Directory | Role | 변경 빈도 |
|-----------|------|-----------|
| `site/` | GitHub Pages 배포 대상. 매일 자동 생성됨 | 매일 (자동) |
| `scripts/` | Claude agent 프롬프트 모듈. 수집·큐레이션·검증 로직 | 가끔 (튜닝 시) |
| `templates/` | HTML 구조 템플릿. 디자인 변경 시 수정 | 드물게 |
| `config/` | 검색 소스·카테고리 설정. 소스 추가/제거 시 수정 | 가끔 |

---

## 3. Module Design

### 3.1 generate.md — 메인 오케스트레이터

**역할**: Claude Code Remote Trigger가 직접 실행하는 진입점. 전체 파이프라인을 순차적으로 조율.

**실행 흐름**:
```
[Remote Trigger 실행]
    │
    ▼
1. config/sources.json 읽기 (검색 소스 설정 로드)
    │
    ▼
2. scripts/search-strategy.md 참조하여 WebSearch 실행
    │  → Raw Results: 30~50건
    ▼
3. scripts/curation-rules.md 참조하여 큐레이션
    │  → 중복 제거, 분류, 중요도, 번역
    │  → Curated: 10~20건
    ▼
4. scripts/verification.md 참조하여 검증
    │  → URL 유효성, 원문 교차검증, 메타데이터
    │  → Verified: 10~20건
    ▼
5. templates/news.html 참조하여 HTML 생성
    │  → site/index.html 덮어쓰기
    │  → site/archive/{date}.html 생성
    │  → site/archive/index.html 업데이트
    ▼
6. 90일 이전 아카이브 정리 (Archive Cleanup)
    │  → site/archive/{old-date}.html 삭제
    │  → site/archive/index.html에서 해당 항목 제거
    ▼
7. git add site/ → commit → push
    │
    ▼
[GitHub Pages 자동 배포 완료]
```

**generate.md 핵심 지시사항**:
```markdown
# AI News Daily Generator

## Execution Context
- Working directory: ai-news/ (project root)
- Triggered by: Claude Code Remote Trigger (cron 08:00 KST)
- Required tools: WebSearch, WebFetch, Read, Write, Bash (git)

## Pipeline Steps
1. Load config: Read config/sources.json
2. Search: Follow scripts/search-strategy.md → collect 30~50 raw results
3. Curate: Follow scripts/curation-rules.md → filter to 10~20 articles
4. Verify: Follow scripts/verification.md → validate each article
5. Generate: Read templates/news.html → write site/index.html + site/archive/{date}.html + update site/archive/index.html
6. Archive cleanup: Delete site/archive/ files older than 90 days (per config)
7. Deploy: git add site/ && git commit -m "chore: update ai news {date}" && git push
```

### 3.2 search-strategy.md — 3-Layer 검색 전략

**역할**: 웹 검색 쿼리와 실행 순서를 정의.

**3-Layer 구조**:

| Layer | Target | Queries | Expected |
|-------|--------|---------|----------|
| **L1: 권위 소스** | 주요 테크 미디어 직접 타겟 | `site:techcrunch.com AI`, `site:theverge.com AI`, `site:arxiv.org AI`, `site:venturebeat.com AI`, `site:reuters.com AI` | 10~15건 |
| **L2: 테마별** | 주요 기업·분야별 검색 | `OpenAI OR Anthropic OR Google DeepMind {today}`, `AI startup funding {today}`, `AI regulation policy {today}` | 15~25건 |
| **L3: 한국** | 한국 AI 뉴스 | `AI 인공지능 뉴스 오늘`, `네이버 카카오 AI` | 5~10건 |

**검색 규칙**:
- 날짜 필터: 최근 24시간 이내 뉴스만
- 최대 WebSearch 호출: 12회 (L1: 5 + L2: 4 + L3: 3)
- 중복 URL 자동 제거 (수집 단계에서)

### 3.3 curation-rules.md — 큐레이션 규칙

**역할**: 수집된 뉴스의 필터링, 분류, 중요도 평가, 번역 규칙 정의.

**카테고리 분류 (5개)**:

| Category | Description | Examples |
|----------|-------------|---------|
| Models | LLM, 이미지/비디오 생성 모델 발표·업데이트 | GPT-5, Claude 4, Gemini |
| Products | AI 기반 제품·서비스 출시·업데이트 | ChatGPT 기능, Copilot, 새 AI 앱 |
| Research | 논문, 벤치마크, 기술 혁신 | arXiv 논문, SOTA 달성 |
| Industry | 투자, 인수, 파트너십, 기업 동향 | 시리즈 B 투자, 합병 |
| Regulation | AI 정책, 법규, 안전, 윤리 | EU AI Act, 미국 행정명령 |

**중요도 평가 기준**:

| Rating | Criteria |
|--------|----------|
| ★★★ | 업계 판도를 바꾸는 메이저 뉴스 (대형 모델 출시, 대규모 규제, 빅딜) |
| ★★ | 주목할 만한 뉴스 (제품 업데이트, 중간 규모 투자, 주요 논문) |
| ★ | 알아두면 좋은 뉴스 (소규모 업데이트, 분석 기사, 커뮤니티 소식) |

**번역 규칙**:
- 제목: 한국어 번역 (원문 병기)
- 요약: 한국어 2~3문장 (핵심만)
- 고유명사: 번역하지 않음 (OpenAI, Claude, GPT 등 원문 유지)
- 기관명: 첫 등장 시 영문 병기 (예: 미국 국립과학재단(NSF))

### 3.4 verification.md — 할루시네이션 검증

**역할**: 수집·큐레이션된 뉴스의 정확성을 3단계로 검증.

**3단계 파이프라인**:

```
[큐레이션된 뉴스 1건]
    │
    ▼
Stage 1: URL 유효성 검증
    ├── WebFetch로 URL 접근 시도
    ├── HTTP 200 → PASS
    ├── 4xx/5xx/timeout → FAIL → 해당 뉴스 제외
    └── 리다이렉트 → 최종 URL로 갱신
    │
    ▼
Stage 2: 원문 교차검증
    ├── WebFetch로 원문 페이지 내용 확인
    ├── 요약 내용이 원문과 일치하는가?
    ├── 날짜가 최근 24시간 이내인가?
    ├── 일치 → PASS
    └── 불일치 → 요약 수정 또는 제외
    │
    ▼
Stage 3: 메타데이터 필수 표기
    ├── 출처 (매체명) 확인
    ├── 발행일 확인
    ├── 원문 링크 확인
    ├── 모두 있음 → PASS
    └── 누락 → 가능한 보완, 불가 시 "미확인" 표시
    │
    ▼
[검증 완료 — HTML 생성으로 전달]
```

**검증 실패 처리**:
- Stage 1 FAIL: 해당 뉴스 완전 제외
- Stage 2 FAIL: 요약 수정 시도 → 수정 불가 시 제외
- Stage 3 누락: "출처 미확인" 태그 부착 후 포함 (단, 2개 이상 누락 시 제외)

### 3.5 NewsArticle Data Model

파이프라인 전 단계를 관통하는 핵심 데이터 구조. 큐레이션 → 검증 → HTML 생성 간의 계약(contract) 역할.

| Field | Type | Stage | Description |
|-------|------|-------|-------------|
| `title_en` | string | Curation | 영문 원제목 |
| `title_ko` | string | Curation | 한국어 번역 제목 |
| `summary_ko` | string | Curation | 한국어 요약 (2~3문장) |
| `original_url` | string | Search | 원문 URL |
| `source_name` | string | Search | 매체명 (예: TechCrunch, Reuters) |
| `publish_date` | string (YYYY-MM-DD) | Search | 기사 발행일 |
| `category` | enum | Curation | Models / Products / Research / Industry / Regulation |
| `rating` | enum | Curation | ★★★ / ★★ / ★ |
| `rating_level` | number (3/2/1) | Curation | CSS 클래스용 숫자 등급 |
| `verification_status` | enum | Verification | passed / failed / unverified |
| `verification_notes` | string? | Verification | 검증 실패 사유 (선택적) |

**사용 흐름**:
```
Search → { original_url, source_name, publish_date, title_en }
   ↓
Curation → + { title_ko, summary_ko, category, rating, rating_level }
   ↓
Verification → + { verification_status, verification_notes }
   ↓
HTML Generation → 전체 필드를 템플릿 변수로 매핑
```

### 3.6 sources.json — 검색 소스 설정

```json
{
  "layers": {
    "L1_authority": {
      "description": "권위 있는 테크 미디어 직접 타겟",
      "sources": [
        { "site": "techcrunch.com", "query": "AI" },
        { "site": "theverge.com", "query": "AI artificial intelligence" },
        { "site": "venturebeat.com", "query": "AI" },
        { "site": "arxiv.org", "query": "AI machine learning" },
        { "site": "reuters.com", "query": "artificial intelligence" }
      ]
    },
    "L2_thematic": {
      "description": "테마별 정밀 검색",
      "queries": [
        "OpenAI OR Anthropic OR Google DeepMind {today}",
        "AI startup funding investment {today}",
        "AI regulation policy government {today}",
        "large language model benchmark {today}"
      ]
    },
    "L3_korean": {
      "description": "한국 AI 뉴스",
      "queries": [
        "AI 인공지능 뉴스 오늘",
        "네이버 카카오 삼성 AI",
        "한국 AI 스타트업"
      ]
    }
  },
  "categories": ["Models", "Products", "Research", "Industry", "Regulation"],
  "ratings": ["★★★", "★★", "★"],
  "limits": {
    "maxSearchCalls": 12,
    "targetArticles": { "min": 10, "max": 20 },
    "maxRawResults": 50
  },
  "archive": {
    "retentionDays": 90
  }
}
```

---

## 4. Template Design

### 4.1 news.html — 뉴스 페이지 템플릿

**용도**: `site/index.html`과 `site/archive/{date}.html` 공용 템플릿

**HTML 구조**:
```html
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI News Daily — {date}</title>
    <link rel="stylesheet" href="{css_path}">
</head>
<body>
    <header>
        <h1>AI News Daily</h1>
        <p class="date">{date} (KST)</p>
        <p class="summary">오늘의 AI 뉴스 {total_count}건</p>
        <nav>
            <a href="{archive_link}">Archive</a>
        </nav>
    </header>

    <main>
        <!-- 카테고리별 섹션 반복 -->
        <section class="category" id="{category_id}">
            <h2>{category_name}</h2>

            <!-- 뉴스 아이템 반복 (중요도 내림차순) -->
            <article class="news-item rating-{rating_level}">
                <div class="rating">{rating_stars}</div>
                <h3>
                    <a href="{original_url}" target="_blank" rel="noopener">
                        {title_ko}
                    </a>
                </h3>
                <p class="original-title">{title_en}</p>
                <p class="summary">{summary_ko}</p>
                <div class="meta">
                    <span class="source">{source_name}</span>
                    <span class="date">{publish_date}</span>
                    <a href="{original_url}" class="link">원문 보기</a>
                </div>
            </article>
        </section>
    </main>

    <footer>
        <p>Curated by Claude | Auto-generated at {generated_time} KST</p>
        <p class="disclaimer">이 페이지의 뉴스는 AI가 자동 수집·요약한 것입니다.
           정확한 내용은 원문 링크를 확인하세요.</p>
    </footer>
</body>
</html>
```

**CSS Path 규칙**:
- `site/index.html` → `css_path = "style.css"`
- `site/archive/{date}.html` → `css_path = "../style.css"`

### 4.2 archive-index.html — 아카이브 목록 템플릿

```html
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI News Daily — Archive</title>
    <link rel="stylesheet" href="../style.css">
</head>
<body>
    <header>
        <h1>AI News Daily Archive</h1>
        <nav><a href="../index.html">Today's News</a></nav>
    </header>

    <main>
        <ul class="archive-list">
            <!-- 날짜별 항목 (최신순) -->
            <li>
                <a href="{date}.html">{date}</a>
                <span class="count">{article_count}건</span>
            </li>
        </ul>
    </main>

    <footer>
        <p>Curated by Claude | AI News Daily</p>
    </footer>
</body>
</html>
```

---

## 5. Style Design

### 5.1 style.css 설계 원칙

- **모바일 퍼스트**: 기본 스타일은 모바일, `min-width: 768px`부터 데스크톱
- **최소 디자인**: 뉴스레터답게 깔끔하고 가독성 중심
- **시스템 폰트**: 별도 웹폰트 로딩 없이 OS 기본 폰트 사용
- **다크 모드 없음**: v1에서는 라이트 모드만 (YAGNI)

### 5.2 핵심 스타일 규칙

| Element | Style |
|---------|-------|
| 본문 최대 너비 | `max-width: 720px; margin: 0 auto;` |
| 카테고리 구분 | `border-top: 2px solid #eee;` + 카테고리 이름 |
| ★★★ 뉴스 | `border-left: 4px solid #e74c3c;` (빨강 강조) |
| ★★ 뉴스 | `border-left: 4px solid #f39c12;` (주황 강조) |
| ★ 뉴스 | `border-left: 4px solid #95a5a6;` (회색) |
| 원문 제목 | `color: #888; font-size: 0.85em;` |
| 메타 정보 | `color: #999; font-size: 0.8em;` |
| 반응형 | `padding: 16px;` (모바일), `padding: 32px;` (데스크톱) |

---

## 6. Execution Environment

### 6.1 Claude Code Remote Trigger 설정

| Item | Value |
|------|-------|
| 트리거 방식 | Claude Code Remote Trigger (cron) |
| 스케줄 | `0 23 * * *` (UTC) = 08:00 KST |
| 실행 프롬프트 | `scripts/generate.md` 내용을 읽어서 실행 |
| 작업 디렉토리 | 프로젝트 루트 (`ai-news/`) |
| 필요 도구 | WebSearch, WebFetch, Read, Write, Bash |
| 예상 실행 시간 | 5~10분 |
| 타임아웃 | 15분 |

### 6.2 GitHub Pages 설정

| Item | Value |
|------|-------|
| Source Branch | `main` |
| Source Directory | `/site` |
| Custom Domain | 없음 (기본 `{username}.github.io/ai-news`) |
| Build | 불필요 (정적 HTML 직접 배포) |

### 6.3 실패 감지 및 복구

| Scenario | Detection | Recovery |
|----------|-----------|----------|
| Remote Trigger 미실행 | 아침에 페이지 확인 시 어제 날짜 | 수동 실행: `claude -p "$(cat scripts/generate.md)"` |
| WebSearch 결과 부족 | 수집 건수 < 5 | "오늘은 주요 AI 뉴스가 적습니다" 메시지 표시 |
| git push 실패 | Bash 명령 exit code 확인 | 재시도 1회, 실패 시 로컬에 생성된 HTML 유지 |
| HTML 생성 오류 | 이전 index.html과 비교 (파일 크기 0) | 이전 버전 유지, 다음날 자동 복구 |

---

## 7. Data Flow Detail

```
┌─────────────────────────────────────────────────────────┐
│ Claude Code Remote Trigger (cron 08:00 KST)             │
│ Entry: scripts/generate.md                              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Step 1: Load Config                                     │
│ Read config/sources.json                                │
│ Output: search queries, categories, limits              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Step 2: Web Search (scripts/search-strategy.md)         │
│ L1: 권위 소스 (5 sites) → 10~15건                        │
│ L2: 테마별 (4 queries) → 15~25건                         │
│ L3: 한국 (3 queries) → 5~10건                            │
│ Total WebSearch calls: ≤ 12                             │
│ Output: Raw results 30~50건 (title, url, snippet)       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Step 3: Curation (scripts/curation-rules.md)            │
│ 3a. 중복 URL 제거                                        │
│ 3b. AI 관련성 필터 (비관련 제외)                           │
│ 3c. 카테고리 분류 (5개 중 택1)                            │
│ 3d. 중요도 평가 (★★★/★★/★)                              │
│ 3e. 한줄 요약 작성 (한국어 2~3문장)                        │
│ 3f. 제목 한국어 번역                                      │
│ Output: Curated 10~20건                                 │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Step 4: Verification (scripts/verification.md)          │
│ 4a. Stage 1 — URL 유효성 (WebFetch)                      │
│ 4b. Stage 2 — 원문 교차검증 (요약 ↔ 원문)                 │
│ 4c. Stage 3 — 메타데이터 완전성                           │
│ Output: Verified 10~20건 (검증 실패 건 제외)              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Step 5: HTML Generation                                 │
│ 5a. Read templates/news.html                            │
│ 5b. Populate with verified news data                    │
│ 5c. Write site/index.html (오늘 날짜)                    │
│ 5d. Write site/archive/{YYYY-MM-DD}.html                │
│ 5e. Read templates/archive-index.html                   │
│ 5f. Update site/archive/index.html (목록 추가)           │
│ Output: 3 HTML files (index + archive + archive list)   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Step 6: Archive Cleanup                                  │
│ 6a. 현재 날짜 기준 90일 이전 파일 탐색                      │
│ 6b. site/archive/{old-date}.html 삭제                    │
│ 6c. site/archive/index.html에서 해당 항목 제거            │
│ Output: 오래된 아카이브 정리 완료                           │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│ Step 7: Deploy                                          │
│ 7a. git add site/                                       │
│ 7b. git commit -m "chore: update ai news {YYYY-MM-DD}" │
│ 7c. git push origin main                                │
│ Output: GitHub Pages auto-deploy triggered              │
└─────────────────────────────────────────────────────────┘
```

---

## 8. Archive Management

### 8.1 보존 정책

| Rule | Value | Rationale |
|------|-------|-----------|
| 보존 기간 | 90일 | GitHub Pages 용량 고려, 3개월이면 충분 |
| 자동 정리 | generate.md 실행 시 90일 이전 파일 삭제 | 매일 실행 시 자동 관리 |
| 아카이브 목록 | archive/index.html에서 최근 90일만 표시 | 깔끔한 목록 유지 |

### 8.2 정리 로직 (파이프라인 Step 6)

파이프라인 Step 6 (Archive Cleanup)에서 실행:

```
Step 6: Archive Cleanup
- 현재 날짜 기준 90일 이전 파일 탐색
- site/archive/{old-date}.html 삭제
- site/archive/index.html에서 해당 항목 제거
- 삭제된 파일은 Step 7 (Deploy)의 git commit에 포함
```

---

## 9. Error Handling

| Error | Impact | Detection | Action |
|-------|--------|-----------|--------|
| WebSearch 전체 실패 | Critical | 검색 결과 0건 | "뉴스 수집 실패" 메시지 페이지 생성, 이전 index.html 유지 |
| 수집 건수 < 5 | Low | 큐레이션 결과 카운트 | "오늘은 주요 AI 뉴스가 적습니다" 메시지 표시 |
| WebFetch 타임아웃 (검증) | Medium | 개별 URL 접근 실패 | 해당 뉴스 제외 (검증 불가) |
| HTML 생성 실패 | Critical | Write 도구 에러 | 이전 파일 유지, 에러 로그만 commit |
| git push 실패 | High | Bash exit code ≠ 0 | 1회 재시도 → 실패 시 로컬 유지 |
| 카테고리 전체 빈칸 | Low | 특정 카테고리 뉴스 0건 | 해당 카테고리 섹션 숨김 |

---

## 10. Test Plan

### 10.1 Smoke Test (수동)

첫 구현 완료 후 1회 수동 실행하여 전체 파이프라인 동작 확인.

| Test | Method | Pass Criteria |
|------|--------|---------------|
| 검색 수집 | `generate.md` 수동 실행 | WebSearch 결과 ≥ 5건 |
| 큐레이션 | 수집 결과 확인 | 10~20건 분류·요약 완료, 중복 0건 |
| 검증 | 검증 결과 확인 | 모든 뉴스 URL 접근 가능, 원문 일치 |
| HTML 생성 | `site/index.html` 브라우저 확인 | 페이지 정상 렌더링, 모바일 반응형 |
| 아카이브 | `site/archive/{date}.html` 확인 | 아카이브 페이지 생성, 목록에 추가 |
| 배포 | GitHub Pages 접속 | 외부 URL에서 정상 접근 |

### 10.2 Stage별 검증 기준

| Stage | Metric | Min Threshold |
|-------|--------|---------------|
| Search | Raw 수집 건수 | ≥ 10건 |
| Curation | 최종 큐레이션 건수 | 10~20건 |
| Verification | 검증 통과율 | ≥ 80% (10건 중 8건 이상) |
| HTML | 파일 크기 | > 1KB (빈 파일 방지) |
| Deploy | git push exit code | 0 |

### 10.3 3일 연속 자동 발행 Acceptance Test

| Day | Check | Pass Criteria |
|-----|-------|---------------|
| Day 1 | cron 실행 확인 | 08:00~08:30 KST 사이 index.html 갱신 |
| Day 2 | 연속 실행 확인 | Day 1 아카이브 존재 + Day 2 index.html 갱신 |
| Day 3 | 안정성 확인 | 3일 연속 성공, 중복 뉴스 없음, 모든 링크 유효 |

**Acceptance 합격**: 3일 모두 Pass 시 v1.0 릴리스

---

## 11. Security Considerations

| Concern | Risk | Mitigation |
|---------|------|------------|
| **Git Push 인증** | Repository 쓰기 권한 필요 | SSH key 기반 인증 (Remote Trigger 환경에 사전 설정). PAT 사용 시 `repo` scope만 부여, 환경변수로 관리 |
| **HTML XSS** | 웹 검색 결과에 악성 스크립트 포함 가능 | 뉴스 제목·요약에 HTML 태그 이스케이프 처리 (`<`, `>`, `&`, `"`, `'` → HTML entities). `a[href]`는 `https://`로 시작하는 URL만 허용 |
| **WebFetch 안전** | 악성 URL 접근 위험 | 타임아웃 10초 제한, 응답 본문은 텍스트만 파싱 (실행 불가), 리다이렉트 최대 3회 제한 |
| **민감 정보 노출** | API 키, 토큰 등이 커밋에 포함될 위험 | `site/` 디렉토리만 commit. `.gitignore`에 `.env`, `*.key`, `credentials*` 추가 |

---

## 12. CLAUDE.md Specification

프로젝트 루트 `CLAUDE.md`에 포함될 핵심 규칙:

```markdown
# AI News Daily

## Project Overview
매일 08:00 KST에 글로벌 AI 뉴스를 자동 수집·큐레이션하여 GitHub Pages로 배포하는 개인용 뉴스레터.

## Key Rules
- site/ 디렉토리는 자동 생성됨 — 수동 편집 금지
- scripts/*.md는 Claude agent 프롬프트 — 자연어로 작성
- templates/*.html은 placeholder 사용 ({date}, {title_ko} 등)
- config/sources.json에서 검색 소스 관리
- 모든 뉴스는 3단계 검증 필수 (URL → 원문 → 메타데이터)

## Git Convention
- Commit message: "chore: update ai news YYYY-MM-DD"
- Auto-generated files only in site/
- Deploy branch: main, deploy dir: /site

## Archive Policy
- 보존 기간: 90일
- 90일 이전 아카이브 자동 삭제
```

---

## 13. Implementation Guide

### 13.1 Implementation Order

| Step | File(s) | Description | Dependency |
|------|---------|-------------|------------|
| 1 | `CLAUDE.md` | 프로젝트 규칙 파일 생성 | 없음 |
| 2 | `config/sources.json` | 검색 소스 설정 | 없음 |
| 3 | `templates/news.html` | 뉴스 페이지 HTML 템플릿 | 없음 |
| 4 | `templates/archive-index.html` | 아카이브 목록 HTML 템플릿 | 없음 |
| 5 | `site/style.css` | 공통 CSS 스타일시트 | 없음 |
| 6 | `scripts/search-strategy.md` | 3-Layer 검색 전략 프롬프트 | Step 2 |
| 7 | `scripts/curation-rules.md` | 큐레이션 규칙 프롬프트 | 없음 |
| 8 | `scripts/verification.md` | 검증 규칙 프롬프트 | 없음 |
| 9 | `scripts/generate.md` | 메인 오케스트레이터 프롬프트 | Step 2~8 |
| 10 | GitHub Pages 설정 | Repository Settings → Pages | Step 5 |
| 11 | Remote Trigger 등록 | Claude Code cron 스케줄 | Step 9 |
| 12 | 3일 연속 발행 테스트 | 자동 실행 검증 | Step 10~11 |

### 13.2 Module Map

| Module | Key Files | Scope |
|--------|-----------|-------|
| `module-1` | `CLAUDE.md`, `config/sources.json` | 프로젝트 설정 |
| `module-2` | `templates/news.html`, `templates/archive-index.html`, `site/style.css` | UI 템플릿 + 스타일 |
| `module-3` | `scripts/search-strategy.md`, `scripts/curation-rules.md`, `scripts/verification.md` | 프롬프트 모듈 |
| `module-4` | `scripts/generate.md` | 메인 오케스트레이터 |
| `module-5` | GitHub Pages + Remote Trigger | 배포 + 스케줄링 |

### 13.3 Session Guide

| Session | Modules | Estimated | Description |
|---------|---------|-----------|-------------|
| Session 1 | module-1, module-2 | 20분 | 설정 + 템플릿/CSS |
| Session 2 | module-3 | 30분 | 프롬프트 모듈 3개 작성 |
| Session 3 | module-4 | 20분 | 오케스트레이터 + 수동 테스트 |
| Session 4 | module-5 | 15분 | GitHub Pages 설정 + cron 등록 + 검증 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-04 | Initial design (Option B — Clean Architecture) | leoheo |
| 0.2 | 2026-04-04 | Add Data Model, Test Plan, Security, Pipeline References. Unify pipeline to 7 steps. Fix WebSearch budget (10→12) | leoheo |
