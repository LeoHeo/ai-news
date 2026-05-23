# Plan: SEO Meta Tags for Link Sharing

> Plan Plus — Brainstorming-Enhanced PDCA Planning
> Created: 2026-04-05

---

## Executive Summary

| Perspective | Description |
|------------|-------------|
| **Problem** | 뉴스 페이지 링크를 메신저(카카오톡, Slack, Discord)나 SNS에 공유하면 제목/설명/이미지 없이 URL만 표시됨 |
| **Solution** | Open Graph + Twitter Cards + JSON-LD 메타 태그를 모든 페이지 템플릿에 추가하고, 빌드 타임에 동적 OG 이미지를 생성 |
| **UX Effect** | 링크 공유 시 토픽명, 날짜, 기사 수, 카테고리 요약이 포함된 리치 미리보기가 자동 표시됨 |
| **Core Value** | 공유받는 사람이 클릭 전에 뉴스 내용을 파악할 수 있어 공유 효과 극대화 |

---

## 1. User Intent Discovery

### Core Problem
뉴스 페이지 링크를 공유할 때 메신저에서 미리보기(제목, 설명, 이미지)가 표시되지 않아 공유 경험이 빈약함.

### Target Users
본인 (개인용 뉴스레터 운영자) — 메신저를 통해 뉴스 링크를 공유하는 사용 패턴.

### Success Criteria
- 카카오톡/Slack/Discord에서 링크 공유 시 제목 + 설명 + 이미지가 미리보기로 표시
- Twitter/X에서 Summary Card 형태로 표시
- Google 검색에서 구조화 데이터 인식

### Constraints
- 정적 사이트 (GitHub Pages) — 서버 사이드 렌더링 불가
- 뉴스 생성 파이프라인(generate.md)에 통합 필요
- 추가 외부 서비스 의존 최소화

---

## 2. Alternatives Explored

### Approach A: OG 태그 핵심만
- **Pros**: 간결, 의존성 없음
- **Cons**: Twitter/X 카드 미지원, 검색엔진 구조화 데이터 없음
- **Verdict**: 메신저만 커버. 확장성 부족

### Approach B: OG + Twitter Cards
- **Pros**: 메신저 + SNS 커버
- **Cons**: JSON-LD 없어 검색엔진 최적화 부족
- **Verdict**: 적절하나 SEO 불완전

### ✅ Approach C: OG + Twitter Cards + JSON-LD (Selected)
- **Pros**: 메신저 + SNS + 검색엔진 완전 커버
- **Cons**: 태그 수 많음, JSON-LD 유지 필요
- **Verdict**: 한 번 세팅하면 유지보수 부담 적음. 풀 SEO 패키지

---

## 3. YAGNI Review

### ✅ Included (v1)
- OG 기본 태그 (title, description, url, type)
- OG 이미지 — 빌드 타임 SVG→PNG 동적 생성
- Twitter Cards (summary card)
- JSON-LD 구조화 데이터 (WebSite, CollectionPage)

### ❌ Out of Scope
- 동적 OG 이미지 외부 서비스 (Cloudinary 등)
- 뉴스 개별 기사 단위 메타 태그 (개별 기사 페이지 없음)
- Facebook App ID, Twitter site handle
- robots.txt, sitemap.xml (별도 feature)

---

## 4. Architecture

### 4.1 수정 대상

| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| `templates/news.html` | 수정 | `<head>`에 OG + Twitter + JSON-LD 메타 추가 |
| `templates/index.html` | 수정 | `<head>`에 OG + Twitter + JSON-LD 메타 추가 |
| `templates/archive-index.html` | 수정 | `<head>`에 OG + Twitter + JSON-LD 메타 추가 |
| `templates/og-template.svg` | **신규** | OG 이미지용 SVG 템플릿 |
| `scripts/generate.md` | 수정 | OG description 생성 + SVG→PNG 변환 스텝 추가 |

### 4.2 페이지별 메타 전략

| 페이지 | og:type | og:title | og:description | JSON-LD |
|--------|---------|----------|---------------|---------|
| Home (`site/index.html`) | `website` | `News Daily` | `AI-curated daily news across topics` | `WebSite` |
| News (`site/{topic}/index.html`) | `article` | `{topic_name} — {date}` | `{topic_name_ko} {total_count}건 \| {category별 count}` | `CollectionPage` |
| Archive (`site/{topic}/archive/index.html`) | `website` | `{topic_name} — Archive` | `{topic_name} 뉴스 아카이브` | `CollectionPage` |

### 4.3 새 Placeholder 목록

| Placeholder | 예시 값 | 사용 위치 |
|-------------|---------|----------|
| `{page_url}` | `https://leoheo.github.io/ai-news/ai/` | og:url, canonical, JSON-LD |
| `{og_description}` | `AI 뉴스 15건 \| Models 4건, Products 3건...` | og:description, meta description, JSON-LD |
| `{og_image_url}` | `https://leoheo.github.io/ai-news/assets/og-ai-2026-04-05.png` | og:image, twitter:image |
| `{site_url}` | `https://leoheo.github.io/ai-news` | JSON-LD base URL |

### 4.4 OG 이미지 생성 파이프라인

```
SVG 템플릿 (templates/og-template.svg)
  ↓ placeholder 치환 ({topic_name}, {date}, {total_count})
  ↓ 
치환된 SVG 문자열
  ↓ Bash: rsvg-convert 또는 sharp/puppeteer로 PNG 변환
  ↓
site/assets/og-{topic}-{date}.png (1200x630px)
```

**SVG 템플릿 설계:**
- 크기: 1200x630px (OG 이미지 권장 규격)
- 내용: 토픽명 (대) + 날짜 + 기사 수 + 브랜딩("News Daily")
- 토픽별 배경색 차별화 (AI: blue계열, Fintech: green계열)

### 4.5 데이터 흐름

```
generate.md Step 5 (Generate HTML) 확장:

  기존 Step 5a~5d 사이에 삽입:

  Step 5-meta: 메타 데이터 조합
    ① og_description 생성: 카테고리별 기사 수 집계
    ② page_url 조합: site_url + topic path
    ③ SVG→PNG 변환: og-template.svg → site/assets/og-{topic}-{date}.png
    ④ og_image_url 조합: site_url + assets path

  Step 5a~5d: 각 HTML 생성 시 메타 태그 placeholder도 함께 치환
```

---

## 5. Template Changes

### 5.1 news.html `<head>` 추가 내용

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

### 5.2 index.html `<head>` 추가 내용

```html
<meta name="description" content="AI-curated daily news across topics">
<link rel="canonical" href="{site_url}">

<meta property="og:title" content="News Daily">
<meta property="og:description" content="AI-curated daily news across topics">
<meta property="og:type" content="website">
<meta property="og:url" content="{site_url}">
<meta property="og:image" content="{site_url}/assets/og-home.png">
<meta property="og:locale" content="ko_KR">
<meta property="og:site_name" content="News Daily">

<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="News Daily">
<meta name="twitter:description" content="AI-curated daily news across topics">
<meta name="twitter:image" content="{site_url}/assets/og-home.png">

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

### 5.3 archive-index.html `<head>` 추가 내용

```html
<meta name="description" content="{topic_name} 뉴스 아카이브">
<link rel="canonical" href="{page_url}">

<meta property="og:title" content="{topic_name} — Archive">
<meta property="og:description" content="{topic_name} 뉴스 아카이브">
<meta property="og:type" content="website">
<meta property="og:url" content="{page_url}">
<meta property="og:image" content="{og_image_url}">
<meta property="og:locale" content="ko_KR">
<meta property="og:site_name" content="News Daily">

<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="{topic_name} — Archive">
<meta name="twitter:description" content="{topic_name} 뉴스 아카이브">

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

## 6. Implementation Steps

### Step 1: OG 이미지 SVG 템플릿 생성
- `templates/og-template.svg` 신규 생성
- 1200x630px, 토픽별 색상 분기, placeholder 포함
- Home용 정적 이미지도 별도 생성 (`site/assets/og-home.png`)

### Step 2: 템플릿 메타 태그 추가
- `templates/news.html` — §5.1 내용 추가
- `templates/index.html` — §5.2 내용 추가
- `templates/archive-index.html` — §5.3 내용 추가

### Step 3: generate.md 파이프라인 확장
- Step 5에 메타 데이터 조합 로직 추가 (og_description, page_url 등)
- SVG→PNG 변환 스텝 추가
- Step 5a~5d에서 새 placeholder 치환 로직 반영

### Step 4: config 업데이트
- `config/ai.json`, `config/fintech.json`에 `site_url` 필드 추가 (또는 generate.md에 상수로 정의)
- 토픽별 OG 이미지 색상 설정

### Step 5: 검증
- 로컬에서 HTML 생성 후 메타 태그 확인
- [Facebook Sharing Debugger](https://developers.facebook.com/tools/debug/) 또는 [opengraph.xyz](https://www.opengraph.xyz/) 로 미리보기 확인
- OG 이미지 1200x630px 규격 확인

---

## 7. Brainstorming Log

| Phase | Key Decision | Rationale |
|-------|-------------|-----------|
| Phase 1 | 메신저 중심 미리보기 | 주 공유 채널이 카카오톡, Slack 등 메신저 |
| Phase 1 | 모든 페이지 적용 | 홈, 뉴스, 아카이브 모두 공유 가능성 있음 |
| Phase 2 | Approach C (OG+Twitter+JSON-LD) 선택 | 한 번 구현하면 유지보수 부담 적고 풀 커버리지 |
| Phase 3 | 전체 4개 항목 포함 | 모두 필수 — 불필요한 항목 없음 |
| Phase 4 | 빌드 타임 SVG→PNG 동적 이미지 | 날짜/기사수가 이미지에 반영되어 더 유용한 미리보기 |
| Phase 4 | JSON-LD에서 JSON 특수문자 주의 | 정적 생성이므로 빌드 시점에 이스케이프 처리 |

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| SVG→PNG 변환 도구 미설치 | OG 이미지 생성 불가 | rsvg-convert (librsvg) 사용, brew로 설치 가능. 실패 시 정적 이미지 fallback |
| GitHub Pages 캐시로 OG 이미지 갱신 지연 | 이전 이미지가 한동안 표시될 수 있음 | 파일명에 날짜 포함하여 캐시 무효화 |
| JSON-LD 내 특수문자 | JSON 파싱 에러 | 뉴스 제목/요약 등은 JSON-LD에 포함하지 않음 (페이지 레벨 메타만) |
