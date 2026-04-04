# AI News Daily Generator

> Design Ref: §3.1 — 메인 오케스트레이터

## Execution Context

- Working directory: ai-news/ (project root)
- Triggered by: Claude Code Remote Trigger (cron 08:00 KST)
- Required tools: WebSearch, WebFetch, Read, Write, Bash (git)

## Pipeline

아래 7단계를 순서대로 실행한다. 각 단계에서 참조할 프롬프트 파일을 Read로 읽은 뒤 지시사항을 따른다.

---

### Step 1: Load Config

```
Read config/sources.json
```

검색 소스, 카테고리, 제한값(maxSearchCalls, targetArticles)을 확인한다.

---

### Step 2: Web Search

```
Read scripts/search-strategy.md
```

search-strategy.md의 지시에 따라 3-Layer WebSearch를 실행한다.
- L1: 권위 소스 5회
- L2: 테마별 4회
- L3: 한국 3회
- 총 12회 이내

결과: 30~50건의 raw results (title_en, original_url, source_name, publish_date)

---

### Step 3: Curate

```
Read scripts/curation-rules.md
```

curation-rules.md의 지시에 따라 큐레이션을 수행한다.
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

#### 5a. site/index.html 생성

- `{css_path}` → `style.css`
- `{archive_link}` → `archive/index.html`
- `{date}` → 오늘 날짜 (YYYY-MM-DD)
- `{total_count}` → 뉴스 건수
- `{generated_time}` → 현재 시각 (HH:MM)
- 카테고리별 섹션을 생성하고, 각 카테고리 내 뉴스를 중요도 내림차순으로 배치
- 뉴스가 0건인 카테고리는 섹션 자체를 생략
- HTML 특수문자 이스케이프 필수 (XSS 방지)

```
Write site/index.html
```

#### 5b. site/archive/{YYYY-MM-DD}.html 생성

- `{css_path}` → `../style.css`
- `{archive_link}` → `index.html`
- 나머지는 index.html과 동일한 내용

```
Write site/archive/{YYYY-MM-DD}.html
```

#### 5c. site/archive/index.html 업데이트

```
Read templates/archive-index.html
```

기존 site/archive/index.html이 있으면 읽어서 오늘 날짜 항목을 목록 최상단에 추가한다.
없으면 새로 생성한다. 목록은 최신순 정렬.

```
Write site/archive/index.html
```

---

### Step 6: Archive Cleanup

90일 이전 아카이브를 정리한다.

```bash
# 90일 이전 파일 목록 확인
find site/archive/ -name "????-??-??.html" -mtime +90
```

- 해당 파일들을 삭제한다.
- site/archive/index.html에서 삭제된 날짜의 항목도 제거한다.
- 삭제할 파일이 없으면 이 단계를 건너뛴다.

---

### Step 7: Deploy

```bash
git add site/
git commit -m "chore: update ai news {YYYY-MM-DD}"
git push origin main
```

- git push 실패 시 1회 재시도한다.
- 재시도도 실패하면 로컬에 생성된 HTML을 유지하고 종료한다.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| WebSearch 결과 0건 | "뉴스 수집에 실패했습니다" 메시지만 포함한 index.html 생성 후 배포 |
| 큐레이션 결과 < 5건 | "오늘은 주요 AI 뉴스가 적습니다" 메시지를 페이지 상단에 표시 |
| 특정 카테고리 0건 | 해당 카테고리 섹션을 생략 |
| WebFetch 타임아웃 | 해당 뉴스 제외 (검증 불가) |
| HTML 생성 오류 | 이전 index.html 유지, 에러 로그만 commit |
| git push 실패 | 1회 재시도 → 실패 시 로컬 유지 |

## Output

GitHub Pages에 오늘의 AI 뉴스가 자동으로 배포된다.
