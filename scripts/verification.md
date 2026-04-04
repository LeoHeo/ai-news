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

## Stage 2: 원문 교차검증

WebFetch로 가져온 원문 페이지 내용을 확인한다.

검증 항목:
1. **요약 정확성**: `summary_ko`의 내용이 원문과 일치하는가?
   - 날짜, 수치, 기업명, 제품명 등 팩트가 맞는지 확인
   - 불일치 발견 시: 원문 기준으로 `summary_ko`를 수정
   - 수정 불가능할 정도의 불일치: 해당 뉴스 **제외**

2. **시의성**: 기사 발행일이 최근 24시간 이내인가?
   - 24시간 초과: 해당 뉴스 **제외**

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
