# 3-Layer Web Search Strategy

> Design Ref: §3.2 — 3-Layer 검색 전략

## Overview

글로벌 AI 뉴스를 3개 레이어로 검색하여 30~50건의 raw results를 수집한다.
최대 WebSearch 호출 12회. 각 레이어의 쿼리를 순서대로 실행한다.

## Layer 1: 권위 소스 직접 타겟 (5회)

주요 테크 미디어를 site: 연산자로 직접 검색한다.

config/sources.json의 `L1_authority.sources`를 읽어 각 소스별로 WebSearch를 실행한다:

```
WebSearch("site:{site} {query}")
```

소스 목록:
1. `site:techcrunch.com AI`
2. `site:theverge.com AI artificial intelligence`
3. `site:venturebeat.com AI`
4. `site:arxiv.org AI machine learning`
5. `site:reuters.com artificial intelligence`

## Layer 2: 테마별 정밀 검색 (4회)

주요 기업, 분야별로 테마 검색한다. `{today}`는 오늘 날짜(YYYY-MM-DD)로 치환한다.

config/sources.json의 `L2_thematic.queries`를 읽어 각 쿼리를 실행한다:

1. `OpenAI OR Anthropic OR Google DeepMind {today}`
2. `AI startup funding investment {today}`
3. `AI regulation policy government {today}`
4. `large language model benchmark {today}`

## Layer 3: 한국 AI 뉴스 (3회)

한국어 AI 뉴스를 검색한다.

config/sources.json의 `L3_korean.queries`를 읽어 실행한다:

1. `AI 인공지능 뉴스 오늘`
2. `네이버 카카오 삼성 AI`
3. `한국 AI 스타트업`

## 수집 규칙

- 각 WebSearch 결과에서 **최근 24시간 이내** 뉴스만 채택한다.
- 수집 단계에서 **중복 URL을 즉시 제거**한다.
- 각 결과에서 다음 정보를 추출한다:
  - `title_en`: 원문 제목
  - `original_url`: 기사 URL
  - `source_name`: 매체명
  - `publish_date`: 발행일 (YYYY-MM-DD)

## Output

30~50건의 raw results를 다음 단계(Curation)에 전달한다.
