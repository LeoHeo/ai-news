# News Daily Generator

> Design Ref: §3.1 — 메인 오케스트레이터 (멀티토픽)

## Execution Context

- Working directory: ai-news/ (project root)
- Triggered by: Claude Code Remote Trigger (토픽별 cron)
- Required tools: WebSearch, WebFetch, Read, Write, Bash (git)
- **Topic parameter**: `{topic}` — 실행 시 전달됨 (예: ai, fintech)

## Pipeline

아래 7단계를 순서대로 실행한다. 각 단계에서 참조할 프롬프트 파일을 Read로 읽은 뒤 지시사항을 따른다.

---

### Step 1: Load Config

```
Read config/{topic}.json
```

토픽 설정을 확인한다:
- `topic.id`, `topic.name`, `topic.name_ko` — 토픽 메타데이터
- `layers` — 검색 소스 (L1~L4)
- `categories` — 카테고리 목록
- `relevance_filter` — 관련성 필터 규칙
- `limits` — maxSearchCalls, targetArticles
- `archive.retentionDays` — 보존 기간

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
- 중복 제거 → 관련성 필터 → 카테고리 분류 → 중요도 평가 → 한국어 번역·요약

결과: 10~20건의 큐레이션된 뉴스

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
- SEO 메타 태그 placeholder 치환:
  - `{site_url}` → config의 `site.url` (나머지는 템플릿에 고정값)

```
Write site/index.html
```

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

```bash
git add site/
git commit -m "chore: update {topic} news {YYYY-MM-DD}"
git push origin main
```

- `{topic}`은 토픽 ID (예: ai, fintech)
- git push 실패 시 1회 재시도한다.
- 재시도도 실패하면 로컬에 생성된 HTML을 유지하고 종료한다.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| WebSearch 결과 0건 | "뉴스 수집에 실패했습니다" 메시지만 포함한 index.html 생성 후 배포 |
| 큐레이션 결과 < 5건 | "오늘은 주요 뉴스가 적습니다" 메시지를 페이지 상단에 표시 |
| 특정 카테고리 0건 | 해당 카테고리 섹션을 생략 |
| WebFetch 타임아웃 | 해당 뉴스 제외 (검증 불가) |
| HTML 생성 오류 | 이전 index.html 유지, 에러 로그만 commit |
| git push 실패 | 1회 재시도 → 실패 시 로컬 유지 |

## Output

GitHub Pages에 오늘의 {topic} 뉴스가 자동으로 배포된다.
