# Plan: Fintech News Enrichment

> Plan Plus — Brainstorming-Enhanced PDCA Planning
> Created: 2026-05-23

---

## Executive Summary

| Perspective | Description |
|------------|-------------|
| **Problem** | Fintech 토픽이 빈약함 — 양 부족, 헤드라인 수준 요약, 단조로운 영미권 소스, 카테고리·테마 커버리지 누락, 같은 테마 반복. 5가지 증상이 동시 발생 |
| **Solution** | Approach C 하이브리드 — (1) 검색 폭 확장 (소스·테마·한국어), (2) 요약 깊이 강화 (3-block + ★★★ 맥락), (3) 7일 테마 메모리로 반복 방지 + 상단 Today's Top 5 밴드 |
| **UX Effect** | Bloomberg 5-Things 스타일 일일 브리핑(주) + 트렌드 인사이트(보조) + 새 패턴 발견(약간). 카테고리당 1~2건 누락 일소, 매일 동일 헤드라인 반복 감소 |
| **Core Value** | 같은 시간 안에 더 넓게·더 깊게·덜 중복되게 — 수동 보조 없이 일일 브리핑 가치 회복 |

---

## 1. User Intent Discovery

### Core Problem
사용자가 "fintech가 빈약하다"고 느끼는 5가지 동시 증상:
1. **양 부족** — 카테고리당 1~2건만 나오는 날이 잦음 (오늘 Lending 1건)
2. **얕음/뻔함** — 헤드라인 + 2~3문장 요약, 시사점·맥락 부재
3. **소스 단조** — L1 권위매체 5개 영미권에 집중, 아시아·B2B 인프라 누락
4. **커버리지 누락** — 스테이블코인/RWA, 인슈테크/웰스테크, 한국 심층 등
5. **반복** — 같은 테마가 며칠 연속 비슷한 톤으로 등장

### Target Use Case
- **주(70%)**: 일일 브리핑 — Bloomberg 5-Things 스타일, 폭넓게 스캔
- **보조(20%)**: 트렌드 추적 — 구조적 변화·규제 방향·딜 패턴 해석
- **약간(10%)**: 아이디어 소스 — 새 모델·기술 스택·UX 사례 수집

### Success Criteria
- 일일 기사 수 15~25건으로 상향 안정화 (현재 12~16)
- ★★★/★★ 기사에 "왜 중요한가" 한 단락 필수 포함
- 카테고리별 최소 2건 보장 (Lending 1건 날 사라짐)
- 7일 내 동일 테마 반복 시 ★ 1단계 강등으로 자연 분산
- 상단 Today's Top 5 밴드에서 30초 스캔 가능

### Constraints
- 기존 7단계 파이프라인은 유지 (`scripts/generate.md` 비변경)
- 정적 사이트 (GitHub Pages), Claude Code Schedule 실행 환경
- 토큰·시간 비용 증가가 있더라도 일일 실행 budget 내 수렴
- 변경은 fintech 토픽에 우선 적용, ai/macro는 검증 후 별도 결정

---

## 2. Alternatives Explored

### Approach A: 검색 폭 확장만
- **Pros**: config만 변경, 즉시 양·다양성 개선
- **Cons**: 깊이·반복 문제 그대로. "뻔한 헤드라인의 더 많은 버전"
- **Verdict**: 5가지 증상 중 2개만 해결

### Approach B: 요약 깊이만 강화
- **Pros**: "뻔함" 즉시 해소, 작은 변경
- **Cons**: 양·소스·커버리지·반복은 그대로
- **Verdict**: 5가지 증상 중 1개만 해결

### ✅ Approach C: 하이브리드 (Selected)
- **Pros**: 5가지 증상 모두 동시 처치, 일일 브리핑 + 트렌드 + 아이디어 3가지 활용 모드 모두 커버
- **Cons**: 변경 범위 최대, 토큰·시간 비용 최대, 7일 메모리 상태 파일 추가 필요
- **Mitigation**: 단계적 구현 (P1 → 관찰 → P2 → P3)으로 비용·리스크 분산

---

## 3. YAGNI Review

### ✅ Included (v1)

**Phase 1 — 검색 폭**
- L1 권위매체 5 → 10~12개 (TechCrunch, Bloomberg, FT, Sifted, NikkeiAsia, KrAsia, The Block 등)
- L2 테마 4 → 7~8개 (스테이블코인/RWA, B2B 결제 인프라, 인슈테크/웰스테크, 아시아 핀테크 추가)
- L3 한국 3 → 5~6개 (site: 한경/머니투데이/디지털데일리 명시 추가)
- `limits.maxSearchCalls` 15 → 25
- `limits.targetArticles` {10,20} → {15,25}

**Phase 2 — 요약 깊이**
- 요약을 3-block으로: `summary_core` (1문장) + `summary_detail` (2문장) + `summary_why` (1~2문장 시사점)
- ★★★ 기사는 WebFetch 1회 추가로 `summary_why`에 유사 선례·맥락 명시
- `templates/news.html`의 `.summary` 영역을 3개 sub-block으로 분리 렌더링

**Phase 3 — 메모리 + Top 5**
- 새 파일 `state/fintech-themes.json` — 최근 7일 테마 키워드 빈도 누적
- 큐레이션 단계에서 추출한 이번 회차 테마가 7일 메모리 상위 키워드와 겹치면 해당 기사 ★ -1 (최소 ★)
- 단, 진짜 새 전개(예: 추가 규제·후속 딜)면 강등 보류 — curation-rules에 판단 기준 명시
- 상단 Today's Top 5 밴드: 카테고리 횡단 최상위 5건 헤드라인-only 섹션 (Bloomberg 5-Things)
- Top 5 선정 규칙: ★★★ 우선 → 카테고리 다양성 → 한국 1건 보장

### ❌ Out of Scope
- AI/macro 토픽 적용 (P3 안정화 후 별도 결정)
- 주간 트렌드 리포트 (Saturday 자동 요약)
- 카테고리 자동 신설 (예: 스테이블코인을 독립 카테고리로 승격) — 일단 기존 6개 안에 흡수
- 외부 LLM 임베딩 기반 테마 클러스터링 — 키워드 단순 매칭으로 시작
- 다국어 (영문 미러)
- 사용자 피드백 루프 (👍/👎)
- 개별 기사 영구 ID/퍼머링크
- `scripts/generate.md` 오케스트레이션 변경 (Step 1~7 골격 그대로)

---

## 4. Architecture

### 4.1 7단계 파이프라인 변경 매트릭스

| Step | 변경 여부 | Phase | 변경 내용 |
|------|----------|-------|----------|
| 1. Load Config | ✓ | P1 | 확장된 fintech.json 로드 (구조 동일, 값 증가) |
| 2. Web Search | ✓ | P1 | 더 많은 쿼리 (소스·테마·KR 확장). search-strategy.md 비변경 |
| 3. Curate | ✓ | P2, P3 | 3-block 요약 생성, ★★★ 맥락 fetch, 7일 메모리 조회·강등, Top 5 선정, 메모리 갱신 |
| 4. Verify | - | - | 변경 없음 |
| 5. Generate HTML | ✓ | P2, P3 | 3-block 렌더링, Top 5 밴드 섹션 추가 |
| 6. Archive Cleanup | - | - | 변경 없음 |
| 7. Deploy | ✓ | P3 | push 파일 목록에 `state/fintech-themes.json` 추가 |

### 4.2 변경 대상 파일

| 파일 | 변경 유형 | Phase |
|------|----------|-------|
| `config/fintech.json` | 수정 (값 확장) | P1 |
| `scripts/curation-rules.md` | 수정 (3-block, 메모리, Top 5 규칙 추가) | P2, P3 |
| `templates/news.html` | 수정 (3-block + Top 5 밴드 마크업) | P2, P3 |
| `state/fintech-themes.json` | 신설 | P3 |
| `site/style.css` | 수정 (Top 5 밴드 + 3-block 스타일) | P2, P3 |

### 4.3 데이터 흐름 (변경 부분만)

```
Step 3 Curate (P2,P3 적용 후):
  raw_results
    → 중복 제거 / 관련성 필터 / 카테고리 분류 (기존)
    → [P3] 테마 키워드 추출 → state/fintech-themes.json 조회
    → 중요도 평가 + [P3] 7일 반복 시 ★ -1 강등
    → [P2] 한국어 번역 + 3-block 요약 생성
    → [P2] ★★★ 기사: WebFetch로 맥락 보강 → summary_why 강화
    → [P3] Top 5 선정 (카테고리 횡단)
    → [P3] state/fintech-themes.json 갱신 (오늘 테마 += 1, 7일 초과분 만료)
  → curated_articles (with summary_core/detail/why + top5_flag)
```

### 4.4 `state/fintech-themes.json` 스키마

```json
{
  "version": 1,
  "updated": "2026-05-23",
  "window_days": 7,
  "themes": [
    { "keyword": "stablecoin-genius-act", "first_seen": "2026-05-17", "last_seen": "2026-05-23", "count": 4 },
    { "keyword": "up-fintech-csrc-penalty", "first_seen": "2026-05-22", "last_seen": "2026-05-23", "count": 2 }
  ]
}
```

- `keyword`: 큐레이션 단계에서 LLM이 기사별로 슬러그 형태 생성 (3~5단어 hyphen-case)
- `count >= 3` 이면 "반복 테마" 판정 → 신규 기사 ★ -1 강등 후보
- `last_seen` 기준 8일 경과 시 항목 삭제

### 4.5 Top 5 밴드 HTML 위치

```html
<main>
  <!-- NEW: Top 5 band (P3) -->
  <section class="top5-band">
    <h2>Today's Top 5</h2>
    <ol> ... 5개 헤드라인 + 카테고리 태그 + 앵커링크 ... </ol>
  </section>

  <!-- 기존 카테고리 섹션 (P2 적용으로 3-block 요약) -->
  <section class="category" id="regulation"> ... </section>
  ...
</main>
```

---

## 5. Implementation Phases

### Phase 1 — 검색 폭 확장 (config-only)

**변경 파일**: `config/fintech.json` 한 개

**작업**:
1. `layers.L1_authority.sources` 5 → 10~12개 추가
2. `layers.L2_thematic.queries` 4 → 7~8개 (스테이블코인/RWA, B2B 인프라, 인슈테크, 아시아 추가)
3. `layers.L3_korean.queries` 3 → 5~6개 (site: 한경/머니투데이/디지털데일리)
4. `limits.maxSearchCalls` 15 → 25
5. `limits.targetArticles` {10,20} → {15,25}

**Done 조건**: 다음 자동 실행 후 archive에서 일일 기사 수 ≥ 15, 카테고리 최소 2건 충족 빈도 ≥ 5/7일

**Rollback**: 이전 fintech.json으로 1-line git revert

---

### Phase 2 — 요약 깊이 강화 (상세 설계)

**변경 파일 4개**: `scripts/curation-rules.md`, `scripts/verification.md`, `templates/news.html`, `site/style.css` (+`generate.md` 비변경)

#### 2.1 3-block 요약 스키마

| Block | 역할 | 분량 | 톤 |
|-------|------|------|-----|
| `summary_core` | 무엇이 일어났나 — 사실 한 줄 | 50~80자 (1문장) | 헤드라인 확장형, 동사 능동 |
| `summary_detail` | 숫자·당사자·시점 | 100~180자 (2문장) | 객관 사실, 6하원칙 중 최소 2개 |
| `summary_why` | 왜 중요한가 — 시사점·맥락 | 80~150자 (1~2문장) | 해석/연결, "~을 시사한다", "~의 변곡점", "~ 흐름과 맞물려" |

기존 `summary_ko` 필드는 폐기. 한 페이지 내 `summary_why` 누락 30% 초과 시 큐레이션 품질 경고.

**가드레일 — 공허한 표현 금지**: "주목할 만하다", "트렌드의 일부다", "흥미롭다"

#### 2.2 등급별 적용 매트릭스

| 등급 | core | detail | why | ★★★ fetch 맥락 |
|------|------|--------|-----|---------------|
| ★★★ | 필수 | 필수 | 필수 (강도↑) | 필수 (Step 4 Stage 2에서 통합 처리) |
| ★★ | 필수 | 필수 | 필수 (강도 보통) | — |
| ★ | 필수 | 필수 | 선택 — 자연스러운 연결고리가 있을 때만 | — |

- `summary_why` 빈 값일 때 renderer는 해당 `<p class="summary-why">` 블록 자체를 생략
- ★★★인데 `summary_why` 누락 → ★★로 강등

#### 2.3 ★★★ 맥락 fetch 구현 (별도 호출 없음)

**핵심**: 기존 Step 4 Verify의 Stage 2 WebFetch를 등급별 분기로 확장 — **추가 API 호출 0건**.

★★★용 fetch prompt:
```
Confirm this URL is live and title/publish-date match.
Additionally extract any of:
  (a) 유사 선례 / 과거 사례
  (b) 진행 중 트렌드 연결
  (c) 경쟁사·관련 당사자 움직임 인용
Return single Korean fragment (60~80자) or empty string.
```

★★/★용 fetch prompt: 기존 verify-only 유지.

추출된 fragment는 `summary_why`의 마지막 절로 합쳐짐:
```
summary_why = "{LLM이 작성한 시사점}. {fetch fragment}"
```

**실패 처리**:
| 상황 | 동작 |
|------|------|
| paywall → 추출 실패 | fragment = "" → LLM 시사점만 |
| Fetch 타임아웃 | 기존과 동일: 기사 제외 |
| 공허한 fragment | LLM 자기 검열로 빈 값 반환 |
| ★★★ 5건 중 fetch context 0건 | 페이지는 정상 발행, curation 단계 경고만 |

**비용**: ★★★ 5건/일 × 추가 400토큰 = +2,000토큰/일 ≈ 무시할 수준.

#### 2.4 파일별 변경 구조

**`scripts/curation-rules.md`** — Step 5 재작성 + Output 섹션 확장 (~40~50라인)
- 기존 "한국어 번역·요약" → "한국어 번역·3-block 요약"
- 3-block 스키마, 등급별 매트릭스, 가드레일 명시
- Output 필드 목록: `summary_core/detail/why` 추가, `summary_ko` 폐기

**`scripts/verification.md`** — Stage 2 등급별 분기 (~15~20라인)
- rating_level == 3 시 확장 prompt, 그 외 기존 prompt
- 추출된 fragment를 `summary_why`에 append

**`templates/news.html`** — line 73 교체 + copyArticle() 수정 (~10라인)
- `<p class="summary">{summary_ko}</p>` → 3개 블록
- `summary_why_block` 조건부 placeholder (빈 값이면 통째 생략)
- copyArticle()이 3블록을 결합해 클립보드 텍스트 생성

**`site/style.css`** — 3개 클래스 추가 (~20라인)
```css
.news-item .summary-core { font-weight: 600; line-height: 1.55; }
.news-item .summary-detail { color: #666; line-height: 1.55; margin-top: 6px; }
.news-item .summary-why {
  border-left: 3px solid #f39c12;  /* ★★ accent와 매칭 */
  padding-left: 12px;
  margin-top: 10px;
  font-style: italic;
  color: #444;
}
```
기존 `.summary` 클래스는 **legacy fallback로 유지** (90일 archive 호환).

#### 2.5 Done 기준 (구체 수치)

| 측정 | 목표 |
|------|------|
| ★★★ 기사 3-block 충족률 | 100% |
| ★★ 기사 3-block 충족률 | ≥ 80% |
| ★★★ `summary_why` fetch fragment 포함률 | ≥ 50% (paywall 비율 고려) |
| 공허한 표현 발생 | 0건 |
| 전체 `summary_why` 누락 | < 30% |

평가: P2 배포 후 첫 1회 자동 실행 결과 채점.

#### 2.6 마이그레이션 / 롤백

- **마이그레이션**: 기존 90일 archive 비변경. `.summary` legacy 스타일 유지로 두 포맷 자연 공존
- **롤백 3-stage**: 
  - Stage 1: `style.css`만 revert (시각만 되돌림)
  - Stage 2: 4개 파일 일괄 revert (단일 summary 복귀)
  - Stage 3: P1까지 revert (가장 보수적)
- P2를 단일 커밋(혹은 명확한 commit-range)으로 묶어 푸시 — `git revert` 한 번으로 복귀 가능하도록

#### 2.7 P2 Dry-run 프로토콜

1. 4개 파일 로컬 수정
2. 수동 dry-run으로 `site/fintech/dry-run/2026-05-NN.html` 재생성
3. 3-block 의도대로 나오는지, summary_why 공허하지 않은지 육안 확인
4. OK → 커밋 + push (P1과 동일하게 `git reset --hard` 이슈 회피)

#### 2.8 범위 외 (P2)

- AI/macro 토픽 동일 적용 (P3 안정화 후 별도 결정)
- 외부 RAG/임베딩
- 새 카테고리 신설
- 모바일 전용 CSS 최적화

---

### Phase 3 — 7일 메모리 + Top 5 밴드 (상세 설계)

**변경 파일 5개**: `state/fintech-themes.json`(신설), `scripts/curation-rules.md`, `scripts/generate.md`, `templates/news.html`, `site/style.css`

#### 3.1 메모리 스키마 (`state/fintech-themes.json`)

```json
{
  "version": 1,
  "updated": "2026-05-23",
  "window_days": 7,
  "themes": [
    {
      "keyword": "stablecoin-uk-regulation",
      "first_seen": "2026-05-17",
      "last_seen": "2026-05-23",
      "count": 4,
      "example_titles": ["...", "...", "..."]
    }
  ]
}
```

- 키워드 슬러그: kebab-case 영문 3~5단어 (한국 기사도 영문 슬러그)
- `example_titles`: 디버깅·매칭 보조용 최대 3개 (FIFO)
- 토픽별 분리 (`{topic}-themes.json`)

물리적 제약: themes[] 최대 50개, 파일 size < 50KB, 8일 경과 항목 자동 만료.

#### 3.2 테마 키워드 추출 (Step 3a)

위치: `curation-rules.md` Step 3(카테고리 분류) 직후.

- LLM에 기존 themes[].keyword + example_titles 제공
- 새 기사가 기존 슬러그와 같은 사건이면 재사용, 아니면 새 슬러그 생성
- 스팬 케이스(두 테마 걸침): 주 키워드 + 보조 `theme_keyword_aux`
- **별도 API 호출 없음** — 카테고리 LLM 출력에 필드 추가로 통합

매칭 가이드:
- 같은 당사자 + 같은 행위 → 동일 (재사용)
- 같은 트렌드, 다른 당사자 → 별개 (새 슬러그)
- 추가 전개·후속 보도 → 동일 (재사용)

#### 3.3 반복 감지 + 강등 (Step 4a)

| `theme.count` | 판정 | 동작 |
|---------------|------|------|
| 1~2 | 신선 | 강등 없음 |
| 3~4 | 반복 | ★ -1 강등 후보 |
| 5+ | 포화 | ★ -1 강등 + 큐레이션 경고 |

**바닥**: ★ 유지 (제외 안 함). 강등은 ★★★→★★, ★★→★까지만.

**면제 조건** (LLM 판단):
1. 새 전개 (추가 규제·후속 딜·입장 변화)
2. 새 당사자 (이미 슬러그 매칭에서 자동 처리)
3. 임팩트 점프 (수치·영향이 명확히 더 커짐)

**강등 흔적 보존**: `rating_demoted: true`, `original_rating_level`, `rating_demote_reason` 메타에 기록. HTML 노출 안 함 (archive HTML hidden comment로만).

**Step 6 보호 규칙 수정**: "20건 초과 제거" 시 강등 기사는 비강등 ★ 뉴스보다 늦게 제거.

**★★★ 0건 보호**: ★★★이 모두 강등되어 페이지에서 0건이 되면, 가장 최근 ★★★ 1건 강등 취소.

#### 3.4 Today's Top 5 밴드 (Step 6a)

후보 풀: Step 7 정렬까지 완료된 큐레이션 기사 전체.

**슬롯 분배**:
- Slot 1~3: ★★★ 우선 (강등 안 된 것), 카테고리 다양성 만족
- Slot 4: 한국 매체 1건 보장 (가능한 가장 높은 등급)
- Slot 5: 카테고리 다양성 보완 (남은 카테고리 중 최고 등급)

**카테고리 다양성**: 최대 2건/카테고리, 최소 3개 카테고리 등장.

**한국 슬롯 처리**:
| 상황 | 동작 |
|------|------|
| 한국 ★★★ 존재 | 자연 포함, Slot 4는 다양성 슬롯 재사용 |
| 한국 ★★/★ 만 | Slot 4에 배치 |
| 한국 0건 | Slot 4 생략 → Top 4 |

**HTML 위치**: `<main>` 최상단, 첫 `<section class="category">` 앞.

**형식**: 헤드라인만 (요약 노출 안 함). 카테고리 태그 + 등급 + 앵커 점프 링크. 각 `<article>`에 `id="{anchor}"` 부여 필요.

**가드레일**:
- 큐레이션 후보 < 5건 → Top 5 → Top N 자동 축소
- ★★★ 0건 날 → 슬롯 모두 ★★/★, "주요 임팩트 적은 날" 안내

#### 3.5 메모리 영속화 + Deploy 통합

**파이프라인 통합 시점**:

```
Step 1   Load Config + Read state/fintech-themes.json
Step 3a  테마 추출 (메모리 keyword 매칭에 사용)
Step 4a  반복 감지 (count >= 3 판정)
Step 8   메모리 갱신 + 8일 만료 (NEW, deploy 직전)
Step 7   Deploy — push 파일 목록에 state/{topic}-themes.json 추가
```

**Fallback — 재구축 모드**:
- 메모리 파일 부재/corrupt + archive 7일치 있음 → LLM이 archive 분석해서 메모리 재추론
- 비상 시만 발동 (+5,000 토큰)

**초기 빈 파일**: P3 첫 커밋에 `themes: []` 상태로 포함.

**보안**: PII 0건, example_titles HTML 특수문자 sanitize, size cap 50KB.

#### 3.6 변경 파일 5개 요약

| 파일 | 변경 |
|------|------|
| `state/fintech-themes.json` | 신설 (~10라인) |
| `scripts/curation-rules.md` | Step 3a + 4a + 6a + 8 추가 (~80라인) |
| `scripts/generate.md` | Step 1 메모리 로드 + Step 7a push 한 줄 + Step 8 명시 (~15라인) |
| `templates/news.html` | Top 5 밴드 마크업 + article id (~20라인) |
| `site/style.css` | `.top5-band` 스타일 (~40라인) |

총 ~165라인.

#### 3.7 Done 기준

| 측정 | 목표 |
|------|------|
| 메모리 파일 매일 정상 갱신 | updated/count/last_seen 정상 변동 |
| 8일 경과 항목 자동 만료 | 7일 후 확인 |
| 반복 테마 강등 발생률 | 5~20% (효과 vs 과적합 균형) |
| 강등 면제 발생률 | 강등 후보 중 10~30% |
| Top 5 매일 노출 | 5건(혹은 안내) 보장 |
| Top 5 카테고리 다양성 | 최소 3개 카테고리 |
| Top 5 한국 슬롯 | 한국 매체 가용 시 100% |

#### 3.8 리스크

| 리스크 | 완화책 |
|--------|--------|
| 슬러그 일관성 부족 → 매칭 실패 | normalize 규칙 명시 |
| 과적극 강등 → 중요 후속 누락 | 면제 가이드 + ★★★ 0건 보호 |
| Top 5와 본문 중복 산만 | Top 5는 헤드라인만 |
| MCP push 실패 → 메모리 깨짐 | 재구축 모드 |
| 메모리 파일 비대화 | 만료 + size cap 양쪽 제어 |

#### 3.9 롤백 (4-stage)

- **Stage 1**: Top 5 시각만 revert (template + css의 .top5-band 부분)
- **Stage 2**: 강등 로직 revert (curation-rules Step 4a)
- **Stage 3**: 전체 P3 revert (5개 파일) + state 파일 삭제
- **Stage 4**: P2까지 revert (가장 보수적)

각 stage는 단일 git revert 가능하도록 P3를 **3개 커밋으로 분리** 푸시:
1. 메모리 + 강등 + generate.md push 통합 (Step 3a, 4a, 8 + state + generate)
2. Top 5 시각 (curation Step 6a + template + css)
3. (선택) docs commit

#### 3.10 비용 (P3 추가분)

- 메모리 관련 LLM 호출: +500토큰/일 (대부분 카테고리 LLM 통합)
- Top 5 선정 LLM: +200토큰/일
- 평상시 합계: **+700토큰/일 ≈ $0.003**
- 재구축 모드 (비상): +5,000토큰/회

#### 3.11 범위 외 (P3)

- AI/macro 토픽 적용 (검증 후)
- 임베딩 기반 클러스터링
- 주간 트렌드 리포트
- 사용자 피드백 루프
- 개별 기사 영구 ID
- Top 5 RSS·이메일

---

## 6. Risks & Mitigations

| 리스크 | 영향 | 완화책 |
|--------|------|--------|
| P1으로 검색 쿼리 증가 → WebSearch 한도 초과 | 일일 실행 실패 | `maxSearchCalls=25`로 cap. 초과 시 L4 소셜부터 스킵 |
| P2 ★★★ 맥락 fetch 토큰 비용 폭증 | budget 초과 | ★★★ 기사당 WebFetch 1회로 cap, 실패 시 fetch 생략하고 summary_why는 LLM 기반 |
| P3 메모리 파일 GitHub push 실패 → 7일 윈도우 깨짐 | 강등 로직 무력화 | push 실패해도 다음 회차 LLM이 archive 7일을 재추론할 수 있도록 fallback 명시 |
| 테마 키워드 슬러그 매칭이 너무 엄격해 강등 안 됨 | "반복" 그대로 | curation-rules에 "유사 키워드 동일 테마로 간주" 판단 가이드 명시 |
| 강등이 너무 적극적이라 진짜 중요한 후속 뉴스가 강등됨 | 중요 뉴스 누락 | curation-rules에 "새 전개(추가 제재, 후속 딜, 입장 변화)면 강등 보류" 규정 |
| Top 5와 본문 중복 노출이 산만함 | UX 저하 | Top 5는 헤드라인 + 앵커링크만, 요약은 본문에 한 번만 |

---

## 7. Out of Scope (재확인)

- AI/macro 토픽 동시 적용
- 주간 트렌드 자동 리포트
- 임베딩 기반 테마 클러스터링
- 다국어/영문 미러
- 사용자 피드백 루프
- 개별 기사 영구 ID
- `scripts/generate.md` 골격 변경
- `scripts/search-strategy.md` 변경
- `scripts/verification.md` 변경

---

## 8. Brainstorming Log

| 결정 | 근거 |
|------|------|
| Approach C 선택 | 빈약함의 원인 5가지가 모두 동시 발생 — 부분 처방으로 만족도 회복 불가 |
| 일일 브리핑(주) + 트렌드(보조) + 아이디어(약간) | 사용자 직접 응답 — 활용 모드 우선순위 명시 |
| 검색·요약·메모리를 P1/P2/P3로 분해 | 변경 범위·토큰 비용 분산, 각 단계 효과 별도 관찰 가능 |
| AI/macro 토픽은 보류 | fintech 검증 후 패턴 이식이 안전. macro는 4-section 구조라 별도 설계 필요 |
| 메모리는 단순 키워드 빈도로 시작 | 임베딩 기반은 over-engineering. archive 재추론 fallback도 가능 |
| Top 5 밴드는 헤드라인만 | 본문과의 중복 노출 방지, 30초 스캔 동선 확보 |

---

## 9. Next Steps

1. **사용자 승인** (이 문서 검토)
2. **/pdca design fintech-enrichment** (선택) — 디자인 문서로 진행하거나 곧바로 Phase 1 do로 이동
3. **Phase 1 구현** — `config/fintech.json` 확장 + 1회 자동 실행 관찰
4. **Phase 1 결과 리뷰** — 다음 1~2회 archive 기사 수·카테고리 분포 확인 후 Phase 2 진행 여부 결정
5. **Phase 2 구현** — 큐레이션·템플릿·CSS 업데이트
6. **Phase 3 구현** — 메모리·Top 5·deploy 목록 추가
