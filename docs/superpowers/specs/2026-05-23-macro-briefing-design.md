# 글로벌 매크로 브리핑 (macro) 토픽 추가 — 설계 문서

작성일: 2026-05-23
상태: 설계 승인 대기

## 1. 배경 및 목표

### 1.1 배경
현재 ai-news 시스템은 두 개 토픽(`ai`, `fintech`)을 운영 중이며, 각 토픽은 "카테고리별 기사 나열" 구조의 일일 큐레이션을 GitHub Pages로 배포한다. 사용자는 이와 별개로 월스트리트 시니어 매크로 퀀트 비서 페르소나의 **구조화된 글로벌 매크로 브리핑**을 매일 받기를 원한다.

### 1.2 목표
- 신규 토픽 `macro`를 기존 토픽 시스템과 동일한 패턴(`config/{topic}.json` + `scripts/run-{topic}.sh` + launchd) 하에 추가한다.
- 출력은 단순 기사 나열이 아니라 **4섹션 구조 분석 리포트**(Sector Facts → PEST → Falsification → Executive Summary)로 렌더링한다.
- 24시간 시간 박스, 영어 원문 우선, "No Action 기본값" 등 macro 전용 통제 규칙을 시스템에 내장한다.
- 기존 `ai` / `fintech` 파이프라인에는 어떠한 회귀도 발생시키지 않는다.

### 1.3 비목표 (YAGNI)
- 토픽 N개 무한 확장을 위한 일반화된 prompt 엔진 리팩토링 (현재 토픽 3개에서는 과설계).
- 실시간 스트리밍, 푸시 알림, 이메일 발송 (정적 사이트로 충분).
- macro 페이지 내 차트·인터랙티브 그래프 (텍스트 브리핑이 1차 목표).
- 토픽 간 cross-reference 또는 통합 대시보드.

## 2. 핵심 의사결정 (브레인스토밍 결과)

| # | 결정 | 선택 | 사유 |
|---|------|------|------|
| 1 | 통합 방식 | 신규 토픽 `macro`로 추가 | 기존 시스템 패턴 재사용, 토픽 독립성 유지 |
| 2 | 페이지 구조 | 단일 페이지 4섹션 세로 배치 | 하나의 URL에서 전체 흐름 파악 |
| 3 | 섹션 순서 | Executive Summary 상단 + 나머지 하단 | 리더 편의 우선 (프롬프트의 "결론 하방 배치"는 LLM 생성 순서 통제 규칙이지 렌더링 순서 규칙이 아님) |
| 4 | 스케줄 | 매일 1회 07:30 KST | 미장 마감 직후 + 아시아 조장 이전 |
| 5 | 소스 전략 | 영어 다소스 하이브리드 | Bloomberg/WSJ paywall 회피, Reuters/AP/CNBC/FT/MarketWatch/Yahoo Finance를 1차 |
| 6 | 출처 참조 | Sector Facts에 인덱스, PEST/Falsification에서 `[국가.번호]` 역참조 | 모든 해석이 공개된 팩트로 역추적 가능 |
| 7 | 검증 완화 | paywall 시 "헤드라인 + 게시 시각만 검증" fallback 허용 | 엄격 검증 시 macro 페이지가 거의 비어버림 |
| 8 | prompt 엔진 | `scripts/generate-macro.md` 별도 작성 | 7-step pipeline과 4섹션 구조 분리, ai/fintech 회귀 위험 차단 |
| 9 | OG 컬러 | 다크 베이스 + 앰버/레드 액센트 | 엄격·경고 톤 |

## 3. 아키텍처

### 3.1 파일 추가/변경 목록

```
config/macro.json                    [신규]
scripts/generate-macro.md            [신규] ─ macro 전용 4섹션 프롬프트
scripts/run-macro.sh                 [신규]
templates/news-macro.html            [신규] ─ 4섹션 레이아웃
templates/og-macro.svg               [신규] ─ OG 이미지 템플릿
site/macro/index.html                [자동 생성, 매일]
site/macro/archive/                  [자동 생성, 매일]
site/index.html                      [수정] ─ 탭 + 카드 추가
~/Library/LaunchAgents/com.user.macro-news.plist  [신규] ─ 07:30 KST
CLAUDE.md                            [수정] ─ Topics 표 + Site Structure에 macro 추가
```

### 3.2 데이터 흐름

```
launchd (07:30 KST)
  └─> scripts/run-macro.sh
       └─> claude -p (sonnet) — generate-macro.md 지시 수행
            ├─ Step 1: time-box 검색 (L1 영어 free → L2 paywall headline → L3 한국어)
            ├─ Step 2: 3단계 검증 (URL → 원문/헤드라인 → 게시 시각 ≤ 24h)
            ├─ Step 3: 카테고리별 3-5건 정리 (빈 카테고리는 "특이사항 없음")
            ├─ Step 4: PEST 4줄 작성 (Sector Facts 인덱스 역참조)
            ├─ Step 5: Falsification 작성 (반증 트리거)
            ├─ Step 6: Executive Summary + Action Plan + 유효기간 (마지막에 1회)
            └─ Step 7: HTML 렌더 (templates/news-macro.html) + OG 이미지 + 아카이브 이동 + 90일 정리
```

## 4. 컴포넌트 상세

### 4.1 config/macro.json 스키마

기존 fintech.json 구조를 유지하되, macro 전용 필드를 추가한다.

```json
{
  "topic": {
    "id": "macro",
    "name": "Global Macro Briefing",
    "name_ko": "글로벌 매크로 브리핑"
  },
  "system_role": "월스트리트 시니어 매크로 퀀트 비서. 대중 노이즈를 제거하고 자본의 진짜 이동 경로를 추적한다. 예측·감정 배제, 통제된 구조 하에서 사실만 해체한다.",
  "safeguards": {
    "fact_first": "영어 원문 우선 탐색 (Reuters, AP, CNBC, FT, MarketWatch, Yahoo Finance). Bloomberg/WSJ는 헤드라인만 인용.",
    "time_box_hours": 24,
    "default_action": "No Action",
    "conclusion_placement": "마지막 섹션에서 단 한 번"
  },
  "layers": {
    "L1_authority": {
      "description": "영어 free-access 매체",
      "sources": [
        { "site": "reuters.com", "query": "markets" },
        { "site": "apnews.com", "query": "economy markets" },
        { "site": "cnbc.com", "query": "markets" },
        { "site": "ft.com", "query": "markets" },
        { "site": "marketwatch.com", "query": "markets" },
        { "site": "finance.yahoo.com", "query": "markets" }
      ]
    },
    "L2_paywalled_headlines": {
      "description": "유료 매체 — 헤드라인 + 요약만 인용 가능",
      "sources": [
        { "site": "bloomberg.com", "query": "markets", "mode": "headline_only" },
        { "site": "wsj.com", "query": "markets", "mode": "headline_only" }
      ]
    },
    "L3_korean": {
      "description": "한국 매크로 보도",
      "queries": [
        "연합뉴스 경제 시장",
        "한국경제 코스피",
        "환율 한국은행"
      ]
    }
  },
  "categories": [
    { "id": "global",      "name_ko": "글로벌" },
    { "id": "us",          "name_ko": "미국" },
    { "id": "europe",      "name_ko": "유럽" },
    { "id": "china",       "name_ko": "중국" },
    { "id": "japan",       "name_ko": "일본" },
    { "id": "korea",       "name_ko": "한국" },
    { "id": "crypto",      "name_ko": "암호화폐" },
    { "id": "bonds",       "name_ko": "채권" },
    { "id": "commodities", "name_ko": "원자재" },
    { "id": "tech",        "name_ko": "IT/Tech" }
  ],
  "items_per_category": { "min": 3, "max": 5, "if_empty": "특이사항 없음" },
  "verification_policy": {
    "free_sources":      ["url_ok", "fetch_body", "timestamp_within_24h"],
    "paywalled_sources": ["url_ok", "headline_visible", "timestamp_within_24h"]
  },
  "limits": {
    "maxSearchCalls": 20,
    "maxRawResults": 60
  },
  "archive": { "retentionDays": 90 },
  "site": {
    "url": "https://leoheo.github.io/ai-news",
    "name": "News Daily"
  },
  "og": {
    "gradient_start": "#0a0a14",
    "gradient_mid":   "#1a1a2e",
    "gradient_end":   "#0d0d18",
    "accent_start":   "#fbbf24",
    "accent_end":     "#ef4444"
  }
}
```

### 4.2 templates/news-macro.html 레이아웃

```
<header>
  🌍 글로벌 매크로 브리핑
  {date}  ·  유효: {validity}        ← 예: "미국 CPI 발표 전까지 유효"
</header>

<section class="executive-summary">
  ⚡ Executive Summary
   - 시장 총평 3줄
   - Action Plan: [No Action] 배지 (Aggressive=red, Defensive=amber, No Action=gray)
</section>

<section class="sector-facts">
  📊 Sector Fact Check
   카테고리별 카드 10개:
     [global.1] 헤드라인 / 한 문장 팩트 / (출처 링크)
     [global.2] ...
   빈 카테고리는 "특이사항 없음" 회색 카드
</section>

<section class="pest">
  🌐 PEST 거시 환경
   P (Politics):  ... [us.2, korea.1]
   E (Economy):   ... [us.1, bonds.3]
   S (Society):   ... [crypto.2]
   T (Technology):... [tech.1, tech.4]
</section>

<section class="falsification">
  ⚠️ Falsification (반증 조건)
   폐기 트리거: "내일 발표될 ___ 지표가 ___ 수치를 보이면 본 브리핑 폐기"
</section>

<footer>
  생성 시각: {generated_at}  ·  다음 업데이트: 익일 07:30 KST
</footer>
```

기존 `style.css`를 재사용하고, macro 전용 클래스(`.executive-summary`, `.sector-facts`, `.pest`, `.falsification`, `.action-badge-{level}`)만 추가한다.

### 4.3 scripts/generate-macro.md 파이프라인

기존 `scripts/generate.md`(7-step pipeline)와는 별개로 작성한다. 골격:

```
You are a Wall Street senior macro quant assistant. Follow these steps EXACTLY.

STEP 1 — Time-boxed search
  - For each of 10 categories, search English sources from past 24h
  - L1 (free) → L2 (paywall headlines) → L3 (Korean) order
  - maxSearchCalls = 20 hard limit

STEP 2 — Verification
  - Free source: url 200 + fetch body + timestamp ≤ 24h
  - Paywall source: url 200 + headline visible + timestamp ≤ 24h
  - If timestamp cannot be confirmed → drop the item (do NOT include)

STEP 3 — Sector Fact Check assembly
  - 3-5 items per category, dry headline + one-sentence fact + source
  - Index format: [{category_id}.{n}]
  - Empty category → "특이사항 없음"

STEP 4 — PEST scanning
  - P / E / S / T one line each
  - Must reference at least one Sector Fact index in brackets

STEP 5 — Falsification
  - One sentence: "내일/다음 주 ___이 발표되면 본 브리핑 폐기"

STEP 6 — Executive Summary (LAST — do not draft earlier)
  - 3-line market summary (root cause)
  - Action Plan: choose ONE of Aggressive / Defensive / No Action (default = No Action)
  - Validity window: "Valid until ___"

STEP 7 — Render
  - Fill templates/news-macro.html with above
  - Move previous site/macro/index.html to site/macro/archive/{date}.html
  - Generate OG image (rsvg-convert from templates/og-macro.svg)
  - Delete archive entries older than 90 days
```

### 4.4 scripts/run-macro.sh

기존 `run-fintech.sh`와 동일한 패턴. `TOPIC="macro"`, 호출 대상 prompt만 `scripts/generate-macro.md`로 변경.

### 4.5 launchd plist

`StartCalendarInterval`: Hour=7, Minute=30. ai(08:00) / fintech(08:30)와 30분 이상 간격 유지.

### 4.6 site/index.html 변경

```html
<nav class="topic-tabs">
  <a href="ai/index.html" class="tab">AI 뉴스</a>
  <a href="fintech/index.html" class="tab">핀테크 뉴스</a>
  <a href="macro/index.html" class="tab">매크로 브리핑</a>   <!-- 추가 -->
</nav>

<!-- topic-card 3번째 추가 -->
<section class="topic-card">
  <h2><a href="macro/index.html">Global Macro Briefing</a></h2>
  <p class="date">{date}</p>
  <p class="count">{action_plan} · {validity}</p>
  <a href="macro/index.html" class="read-more">자세히 보기</a>
</section>
```

## 5. 에러 처리

| 상황 | 동작 |
|------|------|
| 모든 카테고리에서 24h 이내 팩트 0건 | 각 카테고리 "특이사항 없음"으로 채우고, Executive Summary는 "유의미한 신규 변수 부재, No Action" 고정 |
| paywall 헤드라인도 fetch 실패 | 해당 소스 skip, 다른 소스로 대체 |
| 검색 호출 limit (20) 초과 | 즉시 중단하고 현재까지 수집된 팩트로 렌더 |
| 사이트 빌드 중 OG 이미지 변환 실패 (rsvg-convert 없음) | 텍스트 페이지만 발행하고 OG는 기본 이미지(og-home.png) fallback |
| Action Plan에서 LLM이 3종(Aggressive/Defensive/No Action) 외 값 출력 | 검증 단계에서 강제 "No Action"으로 교정 |

## 6. 테스트 전략

- **수동 1회 실행**: `bash scripts/run-macro.sh` → `site/macro/index.html` 생성 확인 → 브라우저에서 4섹션 모두 채워졌는지, 인덱스 참조가 깨지지 않는지 확인.
- **검증 회귀**: 동일 명령을 다음 날 1회 더 실행 → 전일분이 `site/macro/archive/{date}.html`로 이동했는지, 90일 정리 로직이 (mock 디렉터리에서) 동작하는지.
- **ai/fintech 회귀**: macro 추가 후 `bash scripts/run-ai.sh`, `bash scripts/run-fintech.sh` 각 1회 실행하여 기존 토픽 출력이 동일한지 diff 확인.
- **빈 카테고리 시뮬레이션**: 일부 카테고리에 의도적으로 검색 차단 (예: 한국 뉴스 query 비활성화) → "특이사항 없음" 카드가 정상 렌더되는지.

## 7. 마이그레이션 / 롤백

- **추가 작업뿐**, 기존 파일 수정은 `site/index.html`와 `CLAUDE.md` 두 개에 국한.
- 롤백 시: launchd plist unload + 추가 파일 삭제 + `site/index.html` 탭/카드 원복.
- `site/macro/` 디렉터리는 git에서 추적되더라도 별도 삭제로 정리 가능 (기존 archive policy와 동일 동작).

## 8. 미해결 사항

- (없음. 모든 핵심 의사결정 확정.)

## 9. 참고

- 원본 사용자 프롬프트: "글로벌 뉴스 브리핑 엔진 v2.0" (Structural Safeguards: Fact-First / Time-Box 24H / Default No Action / 결론 하방 배치)
- 기존 패턴 참조 파일: `config/fintech.json`, `scripts/run-fintech.sh`, `scripts/generate.md`, `templates/news.html`
