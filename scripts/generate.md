# News Daily Generator

> Design Ref: §3.1 — 메인 오케스트레이터 (멀티토픽)

## Execution Context

- Working directory: ai-news/ (project root)
- Triggered by: Claude Code Schedule (토픽별 — AI 08:00 KST, Fintech 08:30 KST)
- Required tools: WebSearch, WebFetch, Read, Write, Bash (git fetch/reset), `mcp__github__push_files`, `mcp__github__delete_file`
- **Topic parameter**: `{topic}` — 실행 시 전달됨 (예: ai, fintech)

## Pipeline

아래 7단계를 순서대로 실행한다. 각 단계에서 참조할 프롬프트 파일을 Read로 읽은 뒤 지시사항을 따른다.

---

### Step 1: Load Config + Theme Memory (P3)

```
Read config/{topic}.json
Read state/{topic}-themes.json    # P3: 7일 테마 메모리, 없으면 빈 themes[]로 시작
```

토픽 설정을 확인한다:
- `topic.id`, `topic.name`, `topic.name_ko` — 토픽 메타데이터
- `layers` — 검색 소스 (L1~L4)
- `categories` — 카테고리 목록
- `relevance_filter` — 관련성 필터 규칙
- `limits` — maxSearchCalls, targetArticles
- `archive.retentionDays` — 보존 기간

테마 메모리 (P3):
- 파일 부재/corrupt → 빈 `{themes: []}`로 진행 (경고 로그)
- `updated`가 8일 이상 전 + archive 7일치 ≥ 3개 존재 → **재구축 모드** 발동
  (LLM이 archive HTML을 분석해서 메모리 재추론)
- 메모리는 Step 3a(테마 추출 매칭), Step 4a(반복 감지·강등)에서 사용되고
  Step 8(메모리 갱신·만료)에서 갱신된 뒤 Step 7 Deploy에 함께 push된다

---

### Step 2: Web Search

```
Read scripts/search-strategy.md
```

search-strategy.md의 지시에 따라 4-Layer WebSearch를 실행한다.
- config에 정의된 layers를 사용한다.
- L1: 권위 소스 (sources 수만큼)
- L2: 테마별 (queries 수만큼)
- L3: 한국 (queries 수만큼)
- L4: 소셜미디어 (queries 수만큼)
- 총 maxSearchCalls 이내

결과: 30~50건의 raw results (title_en, original_url, source_name, publish_date)

---

### Step 3: Curate

```
Read scripts/curation-rules.md
```

curation-rules.md의 지시에 따라 큐레이션을 수행한다.
- config의 `relevance_filter`를 관련성 필터 기준으로 사용한다.
- config의 `categories`를 카테고리 분류 기준으로 사용한다.
- **흐름 (P3 적용 후)**: 중복 제거 → 관련성 필터 → 카테고리 분류 + **테마 추출(Step 3a)** → 중요도 평가 + **반복 감지·강등(Step 4a)** → 한국어 3-block 요약 → 선별 우선순위(강등 보호) → **Top 5 선정(Step 6a)** → 정렬 → **메모리 갱신·만료(Step 8)**

결과: 15~25건의 큐레이션된 뉴스 + 갱신된 테마 메모리 (state/{topic}-themes.json)

---

### Step 4: Verify

```
Read scripts/verification.md
```

verification.md의 지시에 따라 3단계 검증을 수행한다.
- Stage 1: URL 유효성 (WebFetch)
- Stage 2: 원문 교차검증
- Stage 3: 메타데이터 완전성

검증 실패 뉴스는 제외한다.
결과: 10~20건의 검증된 뉴스

---

### Step 5: Generate HTML

```
Read templates/news.html
```

검증된 뉴스 데이터를 templates/news.html 구조에 맞춰 HTML을 생성한다.

#### Step 5-meta: SEO Meta Data Preparation

<!-- Design Ref: §5 — SEO 메타 태그 파이프라인 통합 -->

큐레이션 완료된 뉴스 데이터를 기반으로 메타 태그용 값을 준비한다.

**① og_description 생성**

카테고리별 기사 수를 집계하여 요약 문자열을 만든다:
- 형식: `"오늘의 글로벌 {topic_name_ko} {total_count}건을 AI가 자동 큐레이션했습니다. {cat1} {n}건, {cat2} {n}건, ... 최신 {topic_name_ko} 동향을 한눈에 확인하세요."`
- 예: `"오늘의 글로벌 AI 뉴스 15건을 AI가 자동 큐레이션했습니다. Models 4건, Products 3건, Research 3건, Industry 3건, Regulation 2건. 최신 AI 뉴스 동향을 한눈에 확인하세요."`
- 기사 0건인 카테고리는 생략
- 목표 길이: 110~160자
- HTML 특수문자(`"`, `&`, `<`)는 entity 이스케이프 필수

**② page_url 조합**

config의 `site.url`을 읽어 각 페이지의 절대 URL을 조합한다:
- 뉴스 페이지: `{site.url}/{topic.id}/`
- 아카이브 날짜 페이지: `{site.url}/{topic.id}/archive/{date}.html`
- 아카이브 목록: `{site.url}/{topic.id}/archive/`
- 홈: `{site.url}`

**③ OG 이미지 생성**

config의 `og` 섹션에서 색상 값을 읽어 SVG 템플릿의 placeholder를 치환한다.

```
Read templates/og-template.svg
```

SVG 내 placeholder를 치환한다:
- `{og_gradient_start}`, `{og_gradient_mid}`, `{og_gradient_end}` → config.og 값
- `{og_accent_start}`, `{og_accent_end}` → config.og 값
- `{topic_name}`, `{date}`, `{total_count}` → 뉴스 메타데이터
- `{og_category_summary}` → `"Models 4건 · Products 3건 · ..."` 형식

```
Write site/assets/og-{topic}-{date}.svg
```

```bash
rsvg-convert -w 1200 -h 630 site/assets/og-{topic}-{date}.svg \
  -o site/assets/og-{topic}-{date}.png
rm site/assets/og-{topic}-{date}.svg
```

변환 실패 시 (rsvg-convert 미설치):
- 경고 로그를 출력한다
- `site/assets/og-{topic}-default.png`가 있으면 그것을 사용한다
- 없으면 og:image 관련 메타 태그를 생략한다

**④ og_image_url 조합**

- 성공 시: `{site.url}/assets/og-{topic}-{date}.png`
- fallback 시: `{site.url}/assets/og-{topic}-default.png`

#### 5a. site/{topic}/index.html 생성

- `{css_path}` → `../style.css`
- `{archive_link}` → `archive/index.html`
- `{topic_name}` → config의 `topic.name`
- `{topic_name_ko}` → config의 `topic.name_ko`
- `{date}` → 오늘 날짜 (YYYY-MM-DD)
- `{total_count}` → 뉴스 건수
- `{generated_time}` → 현재 시각 (HH:MM)
- 카테고리별 섹션을 생성하고, 각 카테고리 내 뉴스를 중요도 내림차순으로 배치
- 뉴스가 0건인 카테고리는 섹션 자체를 생략
- HTML 특수문자 이스케이프 필수 (XSS 방지)
- 각 뉴스 `<h3>` 안에 제목 링크 뒤 복사 버튼을 반드시 포함한다 (templates/news.html 참고)
- SEO 메타 태그 placeholder도 함께 치환한다:
  - `{og_description}` → Step 5-meta ①에서 생성한 값
  - `{page_url}` → `{site.url}/{topic.id}/`
  - `{og_image_url}` → Step 5-meta ④에서 조합한 값
  - `{site_url}` → config의 `site.url`

```
Write site/{topic}/index.html
```

#### 5b. site/{topic}/archive/{YYYY-MM-DD}.html 생성

- `{css_path}` → `../../style.css`
- `{archive_link}` → `index.html`
- 나머지는 토픽 index.html과 동일한 내용
- SEO 메타 태그 placeholder 치환 (5a와 동일하되 page_url만 다름):
  - `{page_url}` → `{site.url}/{topic.id}/archive/{YYYY-MM-DD}.html`

```
Write site/{topic}/archive/{YYYY-MM-DD}.html
```

#### 5c. site/{topic}/archive/index.html 업데이트

```
Read templates/archive-index.html
```

기존 site/{topic}/archive/index.html이 있으면 읽어서 오늘 날짜 항목을 목록 최상단에 추가한다.
없으면 새로 생성한다. 목록은 최신순 정렬.
- SEO 메타 태그 placeholder 치환:
  - `{page_url}` → `{site.url}/{topic.id}/archive/`
  - `{og_image_url}` → 오늘의 OG 이미지 재활용 (`{site.url}/assets/og-{topic}-{date}.png`)
  - `{site_url}` → config의 `site.url`

```
Write site/{topic}/archive/index.html
```

#### 5d. site/index.html 업데이트

```
Read templates/index.html
```

메인 페이지(탭 UI)를 업데이트한다. 모든 토픽 디렉토리를 확인하여 탭 목록을 생성한다.

##### 5d.1 — 필수 Read 시퀀스 (P3.2 — stale 방지)

> **배경**: 2026-05-25 archive에서 홈 페이지 AI 카드가 5-23 정보로 stale 발생. 원인은 orchestrator가 ai/index.html을 다시 Read하지 않고 이전 회차 추론을 재사용한 것. 아래 규칙으로 재발 방지.

**원칙**: site/index.html 작성 직전에 각 토픽의 `site/{topic}/index.html`을 Read 도구로 **반드시 새로 읽어** 다음 값을 추출한다. **이전 회차 또는 이전 단계에서 추론한 값을 재사용 금지**.

```
For each topic in [ai, fintech, macro]:
    if exists(site/{topic}/index.html):
        Read site/{topic}/index.html
        extract:
          - date    from <p class="date">{YYYY-MM-DD} (KST)</p>
          - count   from <p class="summary">{topic_name_ko} {N}건</p>
                    (macro의 경우 4-section briefing의 첫 summary 줄을 그대로 사용)
          - title   from <title>{topic_name} — {YYYY-MM-DD}</title>
    else:
        date = "(준비 중)"
        count = "아직 생성되지 않음"
```

추출 값을 **즉시** site/index.html 작성에 사용한다. Read와 Write 사이에 다른 추론·기억 호출을 끼우지 마라.

##### 5d.2 — placeholder 치환

- SEO 메타 태그 placeholder:
  - `{site_url}` → config의 `site.url` (나머지는 템플릿에 고정값)
- 각 토픽 카드 placeholder:
  - `{topic_date}` → 5d.1에서 Read로 추출한 값
  - `{topic_count}` → 5d.1에서 Read로 추출한 값

##### 5d.3 — site/index.html 작성

```
Write site/index.html
```

##### 5d.4 — 작성 후 검증 (P3.2)

작성 직후 **반드시** site/index.html을 Read로 다시 읽어 각 토픽 카드의 date가 site/{topic}/index.html의 date와 일치하는지 검증한다.

```
Read site/index.html
For each topic card in home:
    home_date = parse(<p class="date">)
    topic_date = (5d.1에서 추출한 값)
    if home_date != topic_date:
        log: "STALE DETECTED: {topic} home={home_date} actual={topic_date}"
        # 재시도: 정확한 값으로 다시 Write
        Write site/index.html (with correct values)
```

일치하지 않으면 한 번 더 Write로 재작성. 두 번째도 실패하면 deploy 단계 진행 후 에러 로그만 남긴다.

---

### Step 6: Archive Cleanup

90일 이전 아카이브를 정리한다.

```bash
# 90일 이전 파일 목록 확인
find site/{topic}/archive/ -name "????-??-??.html" -mtime +90
```

- 해당 파일들을 삭제한다.
- site/{topic}/archive/index.html에서 삭제된 날짜의 항목도 제거한다.
- 삭제할 파일이 없으면 이 단계를 건너뛴다.

---

### Step 7: Deploy

`mcp__github__push_files` 툴을 사용해서 GitHub API로 직접 푸시한다 (git push 대신).
이렇게 하면 로컬 git 인증·프록시 설정에 의존하지 않고 Claude Code Schedule 환경에서도 푸시가 동작한다.

**7a. 푸시할 파일 목록**

이번 실행에서 생성·변경된 파일들을 Read로 읽어 내용 전체를 문자열로 준비한다:
- `site/{topic}/index.html` (오늘의 뉴스)
- `site/{topic}/archive/{YYYY-MM-DD}.html` (아카이브 사본)
- `site/{topic}/archive/index.html` (아카이브 목록)
- `site/index.html` (메인 탭 UI)
- **`state/{topic}-themes.json`** (P3 — Step 8에서 갱신된 테마 메모리. push 누락 시 다음 회차 윈도우 깨짐 + 재구축 모드 발동)
- Step 6에서 삭제한 90일 이전 아카이브 파일이 있다면 그 경로도 포함 (content는 빈 문자열이 아니라 별도 처리 필요 → 삭제는 `mcp__github__delete_file`로)

**7b. MCP 푸시 실행**

```
mcp__github__push_files({
  owner: "LeoHeo",
  repo: "ai-news",
  branch: "main",
  message: "chore: update {topic} news {YYYY-MM-DD}",
  files: [
    { path: "site/{topic}/index.html", content: "<7a에서 읽은 내용>" },
    { path: "site/{topic}/archive/{YYYY-MM-DD}.html", content: "..." },
    { path: "site/{topic}/archive/index.html", content: "..." },
    { path: "site/index.html", content: "..." },
    { path: "state/{topic}-themes.json", content: "..." }
  ]
})
```

**7c. 로컬 git 동기화**

MCP 푸시는 GitHub에 새 커밋을 만들지만 로컬 git은 변경되지 않는다.
다음 실행에서 git 상태가 꼬이지 않도록 로컬을 remote에 맞춘다:

```bash
git fetch origin main
git reset --hard origin/main
```

**7d. 실패 처리**

- MCP 푸시 실패 시 1회 재시도한다.
- 재시도도 실패하면 로컬에 생성된 HTML을 유지하고 종료한다 (다음 실행 시 누락 파일 자동 보정).
- `git push`는 사용하지 않는다 (인증/프록시 문제 회피).

---

## Error Handling

| Situation | Action |
|-----------|--------|
| WebSearch 결과 0건 | "뉴스 수집에 실패했습니다" 메시지만 포함한 index.html 생성 후 배포 |
| 큐레이션 결과 < 5건 | "오늘은 주요 뉴스가 적습니다" 메시지를 페이지 상단에 표시 |
| 특정 카테고리 0건 | 해당 카테고리 섹션을 생략 |
| WebFetch 타임아웃 | 해당 뉴스 제외 (검증 불가) |
| HTML 생성 오류 | 이전 index.html 유지, 에러 로그만 commit |
| MCP push 실패 | 1회 재시도 → 실패 시 로컬 유지 |
| **홈 페이지 토픽 카드 stale** (P3.2) | Step 5d.4 검증에서 자동 감지·재작성. 두 번째도 실패면 에러 로그 + deploy 진행 (다음 회차에서 자동 복구) |
| **특정 토픽 디렉토리 부재** | 해당 토픽 카드는 "(준비 중)" placeholder로 표시. 절대 이전 회차 추론값 재사용 금지 |
| **다른 토픽 run이 실패해서 그 토픽 index.html이 오래됨** | 의도된 동작 — 그 토픽의 last successful date를 홈에 그대로 표시. 가짜 갱신 금지 |

#### 재발 방지 운영 가이드

1. **매주 1회 홈 검증** (수동): site/index.html의 각 토픽 카드 date를 site/{topic}/index.html과 직접 비교. 불일치 발견 시 Step 5d.1~5d.4 로직 재검토.
2. **Schedule 발화 실패 모니터링**: Claude Code Schedule 화면에서 매일 3개 토픽(AI/fintech/macro) 모두 발화 성공했는지 주 1회 확인. 누락된 날은 다음 날 자동 복구되지만 stale 가능성 있음.
3. **stale 패턴 발견 시**: 패턴이 반복되면 generate.md Step 5d를 더 강화 (예: 두 번째 재작성도 실패 시 deploy 자체를 차단).

## Output

GitHub Pages에 오늘의 {topic} 뉴스가 자동으로 배포된다.
