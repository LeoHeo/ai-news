# Design: SEO Meta Tags for Link Sharing

> Architecture: Option C — Pragmatic Balance
> Plan Ref: docs/01-plan/features/seo-meta-tags.plan.md
> Created: 2026-04-05

---

## Context Anchor

| Key | Value |
|-----|-------|
| WHY | 링크 공유 시 메신저/SNS에서 리치 미리보기가 표시되지 않는 문제 해결 |
| WHO | 본인 (개인 뉴스레터 운영자, 메신저로 링크 공유) |
| RISK | SVG→PNG 변환 도구 미설치, GitHub Pages 캐시 지연 |
| SUCCESS | 카카오톡/Slack/Discord/Twitter에서 제목+설명+이미지 미리보기 표시 |
| SCOPE | OG + Twitter Cards + JSON-LD + 빌드 타임 동적 OG 이미지 |

---

## 1. Overview

3개 HTML 템플릿에 SEO 메타 태그(OG, Twitter Cards, JSON-LD)를 추가하고, 뉴스 생성 시 SVG→PNG로 동적 OG 이미지를 빌드 타임에 생성한다.

**Selected Architecture**: Option C — Pragmatic Balance
- 메타 태그는 각 템플릿에 직접 삽입 (include 메커니즘 불필요)
- 토픽별 색상/설정은 `config/{topic}.json`의 `og` 섹션에서 관리
- OG 이미지 생성은 `generate.md` Step 5에 통합

---

## 2. Config Schema Changes

### 2.1 config/{topic}.json에 `site` + `og` 섹션 추가

**ai.json 추가분:**
```json
{
  "site": {
    "url": "https://leoheo.github.io/ai-news",
    "name": "News Daily"
  },
  "og": {
    "gradient_start": "#0f0c29",
    "gradient_mid": "#302b63",
    "gradient_end": "#24243e",
    "accent_start": "#667eea",
    "accent_end": "#764ba2"
  }
}
```

**fintech.json 추가분:**
```json
{
  "site": {
    "url": "https://leoheo.github.io/ai-news",
    "name": "News Daily"
  },
  "og": {
    "gradient_start": "#0a2e1a",
    "gradient_mid": "#1a5c3a",
    "gradient_end": "#0d3320",
    "accent_start": "#34d399",
    "accent_end": "#059669"
  }
}
```

> `site.url`은 모든 토픽에서 동일. `og` 색상만 토픽별 차별화.
> 새 토픽 추가 시 config에 `og` 섹션만 추가하면 됨.

---

## 3. Template Changes

### 3.1 templates/news.html

`<head>` 내 `<title>` 다음에 삽입:

```html
    <!-- SEO Meta -->
    <meta name="description" content="{og_description}">
    <link rel="canonical" href="{page_url}">

    <!-- Open Graph -->
    <meta property="og:title" content="{topic_name} — {date}">
    <meta property="og:description" content="{og_description}">
    <meta property="og:type" content="article">
    <meta property="og:url" content="{page_url}">
    <meta property="og:image" content="{og_image_url}">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:locale" content="ko_KR">
    <meta property="og:site_name" content="News Daily">

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="{topic_name} — {date}">
    <meta name="twitter:description" content="{og_description}">
    <meta name="twitter:image" content="{og_image_url}">

    <!-- JSON-LD -->
    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "CollectionPage",
      "name": "{topic_name} — {date}",
      "description": "{og_description}",
      "url": "{page_url}",
      "image": "{og_image_url}",
      "isPartOf": {
        "@type": "WebSite",
        "name": "News Daily",
        "url": "{site_url}"
      },
      "datePublished": "{date}",
      "inLanguage": "ko"
    }
    </script>
```

### 3.2 templates/index.html

`<head>` 내 `<title>` 다음에 삽입:

```html
    <!-- SEO Meta -->
    <meta name="description" content="AI-curated daily news across topics">
    <link rel="canonical" href="{site_url}">

    <!-- Open Graph -->
    <meta property="og:title" content="News Daily">
    <meta property="og:description" content="AI-curated daily news across topics">
    <meta property="og:type" content="website">
    <meta property="og:url" content="{site_url}">
    <meta property="og:image" content="{site_url}/assets/og-home.png">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:locale" content="ko_KR">
    <meta property="og:site_name" content="News Daily">

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="News Daily">
    <meta name="twitter:description" content="AI-curated daily news across topics">
    <meta name="twitter:image" content="{site_url}/assets/og-home.png">

    <!-- JSON-LD -->
    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "WebSite",
      "name": "News Daily",
      "description": "AI-curated daily news across topics",
      "url": "{site_url}",
      "inLanguage": "ko"
    }
    </script>
```

### 3.3 templates/archive-index.html

`<head>` 내 `<title>` 다음에 삽입:

```html
    <!-- SEO Meta -->
    <meta name="description" content="{topic_name} 뉴스 아카이브">
    <link rel="canonical" href="{page_url}">

    <!-- Open Graph -->
    <meta property="og:title" content="{topic_name} — Archive">
    <meta property="og:description" content="{topic_name} 뉴스 아카이브">
    <meta property="og:type" content="website">
    <meta property="og:url" content="{page_url}">
    <meta property="og:image" content="{og_image_url}">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:locale" content="ko_KR">
    <meta property="og:site_name" content="News Daily">

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary">
    <meta name="twitter:title" content="{topic_name} — Archive">
    <meta name="twitter:description" content="{topic_name} 뉴스 아카이브">
    <meta name="twitter:image" content="{og_image_url}">

    <!-- JSON-LD -->
    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "CollectionPage",
      "name": "{topic_name} — Archive",
      "description": "{topic_name} 뉴스 아카이브",
      "url": "{page_url}",
      "isPartOf": {
        "@type": "WebSite",
        "name": "News Daily",
        "url": "{site_url}"
      },
      "inLanguage": "ko"
    }
    </script>
```

---

## 4. OG Image Generation

### 4.1 SVG Template: `templates/og-template.svg`

```svg
<svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:{og_gradient_start}"/>
      <stop offset="50%" style="stop-color:{og_gradient_mid}"/>
      <stop offset="100%" style="stop-color:{og_gradient_end}"/>
    </linearGradient>
    <linearGradient id="accent" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:{og_accent_start}"/>
      <stop offset="100%" style="stop-color:{og_accent_end}"/>
    </linearGradient>
  </defs>

  <rect width="1200" height="630" fill="url(#bg)"/>
  <rect x="80" y="180" width="120" height="4" rx="2" fill="url(#accent)"/>

  <text x="80" y="260" font-family="system-ui, -apple-system, sans-serif"
        font-size="64" font-weight="700" fill="#ffffff">
    {topic_name}
  </text>

  <text x="80" y="330" font-family="system-ui, -apple-system, sans-serif"
        font-size="40" fill="rgba(255,255,255,0.75)">
    {date}
  </text>

  <rect x="80" y="370" width="200" height="48" rx="24"
        fill="rgba(255,255,255,0.1)" stroke="rgba(255,255,255,0.2)" stroke-width="1"/>
  <text x="180" y="401" font-family="system-ui, -apple-system, sans-serif"
        font-size="22" fill="rgba(255,255,255,0.9)" text-anchor="middle">
    {total_count}건의 뉴스
  </text>

  <text x="80" y="480" font-family="system-ui, -apple-system, sans-serif"
        font-size="22" fill="rgba(255,255,255,0.5)">
    {og_category_summary}
  </text>

  <text x="80" y="570" font-family="system-ui, -apple-system, sans-serif"
        font-size="20" fill="rgba(255,255,255,0.3)">
    News Daily — Curated by Claude
  </text>

  <circle cx="1050" cy="120" r="80" fill="rgba(255,255,255,0.03)"/>
  <circle cx="1100" cy="200" r="120" fill="rgba(255,255,255,0.02)"/>
</svg>
```

### 4.2 Placeholder 매핑

| SVG Placeholder | 값 출처 |
|----------------|---------|
| `{og_gradient_start}` | `config.og.gradient_start` |
| `{og_gradient_mid}` | `config.og.gradient_mid` |
| `{og_gradient_end}` | `config.og.gradient_end` |
| `{og_accent_start}` | `config.og.accent_start` |
| `{og_accent_end}` | `config.og.accent_end` |
| `{topic_name}` | `config.topic.name` |
| `{date}` | 오늘 날짜 (YYYY-MM-DD) |
| `{total_count}` | 큐레이션된 뉴스 건수 |
| `{og_category_summary}` | `"Models 4건 · Products 3건 · ..."` |

### 4.3 Home OG Image

`site/assets/og-home.png`는 토픽 무관 정적 이미지.
- 배경: 뉴트럴 다크 (#1a1a2e → #2d2d44)
- 텍스트: "News Daily" + "AI-curated daily news across topics"
- 최초 1회 생성 후 고정 (generate.md에서 매번 생성하지 않음)

**생성 방법**: `templates/og-home.svg`를 별도로 만들어 `rsvg-convert`로 1회 변환.
og-template.svg와 동일 구조이나 색상은 뉴트럴 다크, 텍스트는 사이트명 고정.
구현 시 Do phase에서 SVG 작성 → PNG 변환 → `site/assets/og-home.png`로 커밋.
이후 변경 불필요 (사이트명이 바뀌지 않는 한).

### 4.4 SVG→PNG 변환

**도구**: `rsvg-convert` (librsvg)

```bash
# 설치 (1회)
brew install librsvg

# 변환 명령
rsvg-convert -w 1200 -h 630 site/assets/og-{topic}-{date}.svg \
  -o site/assets/og-{topic}-{date}.png
```

**Fallback**: `rsvg-convert` 미설치 시
- 경고 메시지 출력
- 토픽별 기본 정적 이미지 사용 (`site/assets/og-{topic}-default.png`)
- 정적 이미지는 최초 1회 수동 생성

---

## 5. generate.md Pipeline Changes

### 5.1 Step 5 확장 구조

기존 Step 5 (Generate HTML) 내에 Step 5-meta를 삽입:

```
Step 5: Generate HTML
  │
  ├─ Step 5-meta: 메타 데이터 준비 (NEW)
  │   ├─ ① og_description 생성
  │   ├─ ② page_url 조합
  │   ├─ ③ SVG→PNG 변환
  │   └─ ④ og_image_url 조합
  │
  ├─ Step 5a: site/{topic}/index.html (+ 메타 태그 치환)
  ├─ Step 5b: site/{topic}/archive/{date}.html (+ 메타 태그 치환)
  ├─ Step 5c: site/{topic}/archive/index.html (+ 메타 태그 치환)
  └─ Step 5d: site/index.html (+ 메타 태그 치환)
```

### 5.2 Step 5-meta 상세

generate.md에 추가할 내용:

```markdown
### Step 5-meta: SEO Meta Data Preparation

큐레이션 완료된 뉴스 데이터를 기반으로 메타 태그용 값을 준비한다.

#### ① og_description 생성

카테고리별 기사 수를 집계하여 요약 문자열을 만든다:
- 형식: `"{topic_name_ko} {total_count}건 | {cat1} {n}건, {cat2} {n}건, ..."`
- 예: `"AI 뉴스 15건 | Models 4건, Products 3건, Research 3건, Industry 3건, Regulation 2건"`
- 기사 0건인 카테고리는 생략

#### ② page_url 조합

config의 `site.url`을 읽어 각 페이지의 절대 URL을 조합한다:
- 뉴스 페이지: `{site.url}/{topic.id}/`
- 아카이브 날짜 페이지: `{site.url}/{topic.id}/archive/{date}.html`
- 아카이브 목록: `{site.url}/{topic.id}/archive/`
- 홈: `{site.url}`

og_image_url 매핑:
- 뉴스 페이지 / 아카이브 날짜 페이지: `{site.url}/assets/og-{topic}-{date}.png` (당일 동적 생성)
- 아카이브 목록: 가장 최근 생성된 `og-{topic}-{date}.png` 사용 (오늘의 이미지 재활용)
- 홈: `{site.url}/assets/og-home.png` (정적)

#### ③ OG 이미지 생성

config의 `og` 섹션에서 색상 값을 읽어 SVG 템플릿의 placeholder를 치환한다.

Read templates/og-template.svg
→ {og_gradient_start}, {og_gradient_mid} 등을 config.og 값으로 치환
→ {topic_name}, {date}, {total_count}, {og_category_summary} 치환
→ Write site/assets/og-{topic}-{date}.svg

Bash: rsvg-convert -w 1200 -h 630 site/assets/og-{topic}-{date}.svg \
        -o site/assets/og-{topic}-{date}.png

변환 성공 시 임시 SVG 파일 삭제.
변환 실패 시 (rsvg-convert 미설치):
  - 경고 로그 출력
  - site/assets/og-{topic}-default.png 가 있으면 그것을 사용
  - 없으면 og:image 메타 태그 자체를 생략

#### ④ og_image_url 조합

- `{site.url}/assets/og-{topic}-{date}.png`
- fallback 시: `{site.url}/assets/og-{topic}-default.png`
```

### 5.3 Step 5a~5d 변경사항

각 HTML 생성 시 기존 placeholder에 추가로 치환할 항목:

| 기존 Step | 추가 치환 |
|-----------|----------|
| 5a (뉴스 index.html) | `{og_description}`, `{page_url}`, `{og_image_url}`, `{site_url}` |
| 5b (아카이브 날짜 페이지) | 5a와 동일. `{page_url}` = `{site.url}/{topic.id}/archive/{date}.html`, `{og_description}` = 뉴스 index와 동일 (같은 날짜의 동일 뉴스) |
| 5c (아카이브 index.html) | `{page_url}`, `{og_image_url}`, `{site_url}` (og_description은 템플릿에 고정) |
| 5d (홈 index.html) | `{site_url}` (나머지는 템플릿에 고정) |

### 5.4 Step 7 (Deploy) 변경

git add 대상에 `site/assets/` 포함:

```bash
git add site/
# site/assets/og-*.png 가 자동 포함됨
```

---

## 6. File Change Summary

| # | 파일 | 변경 유형 | 변경 내용 |
|---|------|----------|----------|
| 1 | `config/ai.json` | 수정 | `site` + `og` 섹션 추가 |
| 2 | `config/fintech.json` | 수정 | `site` + `og` 섹션 추가 |
| 3 | `templates/news.html` | 수정 | `<head>`에 SEO 메타 블록 삽입 |
| 4 | `templates/index.html` | 수정 | `<head>`에 SEO 메타 블록 삽입 |
| 5 | `templates/archive-index.html` | 수정 | `<head>`에 SEO 메타 블록 삽입 |
| 6 | `templates/og-template.svg` | **신규** | OG 이미지 SVG 템플릿 |
| 7 | `scripts/generate.md` | 수정 | Step 5-meta 추가 + Step 5a~5d 치환 확장 |

---

## 7. Edge Cases

| Case | Handling |
|------|----------|
| 뉴스 0건 | og_description: "{topic_name_ko} 0건" — 메타 태그는 그대로 생성 |
| rsvg-convert 미설치 | 경고 출력 + default 이미지 fallback + 없으면 og:image 생략 |
| og_description 내 특수문자 (`"`, `&`, `<`) | HTML entity 이스케이프 (`&quot;`, `&amp;`, `&lt;`) |
| JSON-LD 내 `{og_description}` 특수문자 | JSON string 이스케이프 (`\"`, `\\`) |
| 카테고리 이름에 한글 포함 | SVG text 렌더링 지원 (system-ui 폰트) |
| 기존 아카이브 페이지에 메타 없음 | 새로 생성되는 페이지부터 적용. 기존 아카이브는 수정 불필요 |

---

## 8. Test Plan

| # | 검증 항목 | 방법 |
|---|----------|------|
| T1 | 메타 태그 존재 확인 | 생성된 HTML에서 `og:title`, `og:description`, `twitter:card`, `application/ld+json` 존재 확인 |
| T2 | Placeholder 치환 확인 | `{page_url}`, `{og_description}` 등이 실제 값으로 치환되었는지 확인 |
| T3 | OG 이미지 파일 생성 | `site/assets/og-{topic}-{date}.png` 파일 존재 + 1200x630px 확인 |
| T4 | OG 이미지 fallback | rsvg-convert 없을 때 경고 + default 이미지 사용 확인 |
| T5 | JSON-LD 유효성 | 생성된 JSON-LD를 JSON.parse로 파싱 가능 확인 |
| T6 | 특수문자 이스케이프 | `&`, `"`, `<` 가 포함된 토픽명/설명에서 HTML/JSON 깨지지 않음 |
| T7 | 실제 미리보기 | opengraph.xyz 또는 카카오톡 공유로 미리보기 표시 확인 |

---

## 9. Dependencies

| 의존성 | 용도 | 설치 |
|--------|------|------|
| `librsvg` (rsvg-convert) | SVG→PNG 변환 | `brew install librsvg` |

> 필수 아님 — 미설치 시 정적 이미지 fallback.
> 동적 이미지가 필요할 때만 설치.

---

## 10. Out of Scope (from Plan)

- Facebook App ID, Twitter site handle
- 개별 기사 단위 메타 태그
- robots.txt, sitemap.xml
- 외부 이미지 생성 서비스

---

## 11. Implementation Guide

### 11.1 Implementation Order

```
1. config 수정 (ai.json, fintech.json)     — 설정 기반 준비
2. templates/og-template.svg 생성           — OG 이미지 템플릿
3. templates/news.html 수정                 — 메타 태그 추가
4. templates/index.html 수정                — 메타 태그 추가
5. templates/archive-index.html 수정        — 메타 태그 추가
6. scripts/generate.md 수정                 — 파이프라인 확장
7. site/assets/og-home.png 생성             — 홈용 정적 이미지
8. 검증 (로컬 실행 → 메타 태그 확인)
```

### 11.2 Module Map

| Module | Files | Description |
|--------|-------|-------------|
| M1: Config | config/ai.json, config/fintech.json | site + og 섹션 추가 |
| M2: OG Image | templates/og-template.svg, site/assets/og-home.png | SVG 템플릿 + 홈 이미지 |
| M3: Templates | templates/news.html, index.html, archive-index.html | 메타 태그 삽입 |
| M4: Pipeline | scripts/generate.md | Step 5-meta 추가 + 치환 로직 확장 |

### 11.3 Session Guide

전체가 한 세션에 구현 가능한 규모 (파일 7개, 대부분 삽입/추가).

**추천: 단일 세션**
```
/pdca do seo-meta-tags                    # 전체 구현
```

모듈별 분할이 필요한 경우:
```
/pdca do seo-meta-tags --scope M1,M2      # Config + OG Image
/pdca do seo-meta-tags --scope M3,M4      # Templates + Pipeline
```
