# Hallucination Verification Pipeline

> Design Ref: §3.4 — 할루시네이션 검증

## Overview

큐레이션된 뉴스 각각에 대해 3단계 검증을 수행한다.
검증에 실패한 뉴스는 제외하거나 수정한다.

## Stage 1: URL 유효성 검증

각 뉴스의 `original_url`에 대해 WebFetch를 실행한다.

- **HTTP 200**: PASS — 다음 단계로 진행
- **4xx/5xx/timeout**: FAIL — 해당 뉴스를 **완전 제외**
- **리다이렉트**: 최종 URL로 `original_url`을 갱신하고 PASS

WebFetch 타임아웃: 10초.
리다이렉트 추적: 최대 3회.

## Stage 2: 원문 교차검증 + ★★★ 맥락 추출

WebFetch로 가져온 원문 페이지 내용을 확인한다.
이 단계는 **등급별로 fetch prompt를 분기**한다 — ★★★ 기사는 검증 + 추가 맥락 추출까지 한 번에 수행하여 별도 API 호출을 발생시키지 않는다.

### 등급별 분기 로직

```
for each article:
    if article.rating_level == 3:    # ★★★
        prompt = 〈A. ★★★ 확장 프롬프트〉
        result = WebFetch(article.original_url, prompt)
        # result는 verify 결과 + context_fragment 포함
        article.summary_why = (article.summary_why + " " + result.context_fragment).strip()
    else:                            # ★★, ★
        prompt = 〈B. 표준 verify 프롬프트〉
        result = WebFetch(article.original_url, prompt)
```

### A. ★★★ 확장 프롬프트

```
Confirm this URL is live and the title/publish-date match what we have:
  - expected_title_en: "{title_en}"
  - expected_publish_date: "{publish_date}"

Additionally, extract from the article body any of:
  (a) 유사 선례 / 과거 사례 — "이전 X 사건과 같이…"
  (b) 진행 중 트렌드 연결 — "Y 흐름의 한 축이다…"
  (c) 경쟁사·관련 당사자 움직임 인용

Return:
  - verify_status: "match" | "mismatch" | "unreadable"
  - corrected_title (if mismatch and correctable, else "")
  - corrected_date (if mismatch and correctable, else "")
  - context_fragment: single Korean fragment 60~80자
    suitable to append to summary_why,
    or empty string if nothing extractable / paywalled.
```

### B. 표준 verify 프롬프트 (★★, ★)

```
Confirm this URL is live and the title/publish-date match:
  - expected_title_en: "{title_en}"
  - expected_publish_date: "{publish_date}"

Return:
  - verify_status: "match" | "mismatch" | "unreadable"
  - corrected_title (if mismatch and correctable, else "")
  - corrected_date (if mismatch and correctable, else "")
```

### 검증 항목 (등급 무관 공통)

1. **팩트 일치**: 제목·발행일·핵심 수치/기관명이 원문과 일치하는가?
   - 불일치 + 수정 가능: 원문 기준으로 `title_*`, `publish_date`, 그리고 가능하면 `summary_core/detail`을 보정
   - 불일치 + 수정 불가: 해당 뉴스 **제외**

2. **시의성**: 기사 발행일이 최근 24시간 이내인가?
   - 24시간 초과: 해당 뉴스 **제외**

### ★★★ context_fragment 처리

- 비어있음 (paywall, 추출 실패, 공허한 표현 자기검열): `summary_why`는 LLM 시사점만으로 유지
- 정상 추출: `summary_why`의 마지막에 한 칸 띄우고 append
- ★★★ 5건 중 fragment 포함률이 50% 미만이면 curation 단계 경고 출력 (페이지는 정상 발행)

## Stage 3: 메타데이터 완전성

각 뉴스에 다음 메타데이터가 모두 존재하는지 확인한다:

| Field | Required | Action if Missing |
|-------|----------|-------------------|
| `source_name` (매체명) | Yes | 원문 페이지에서 추출 시도, 불가 시 "출처 미확인" 표시 |
| `publish_date` (발행일) | Yes | 원문 페이지에서 추출 시도, 불가 시 "날짜 미확인" 표시 |
| `original_url` (원문 링크) | Yes | Stage 1 통과 시 반드시 존재 |

- 메타데이터 1개 누락: "미확인" 태그 부착 후 **포함**
- 메타데이터 2개 이상 누락: 해당 뉴스 **제외**

## 검증 결과 기록

각 뉴스에 다음 필드를 추가한다:

- `verification_status`: `passed` | `failed` | `unverified`
- `verification_notes`: 실패 사유 (선택적)

`verification_status`가 `passed`인 뉴스만 다음 단계(HTML Generation)에 전달한다.

## Security Note

- WebFetch 응답은 텍스트만 파싱한다. 스크립트 실행 금지.
- 뉴스 제목·요약에서 HTML 특수문자를 이스케이프한다:
  `<` → `&lt;`, `>` → `&gt;`, `&` → `&amp;`, `"` → `&quot;`, `'` → `&#39;`
- `original_url`은 `https://`로 시작하는 URL만 허용한다.

## Output

검증을 통과한 10~20건의 뉴스를 HTML Generation 단계에 전달한다.
