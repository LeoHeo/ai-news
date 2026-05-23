# Curation Rules

> Design Ref: §3.3 — 큐레이션 규칙 (멀티토픽)

## Overview

Search에서 수집된 30~50건의 raw results를 10~20건의 고품질 뉴스로 큐레이션한다.
아래 단계를 순서대로 적용한다.

**토픽 config**: `config/{topic}.json`의 `categories`, `relevance_filter`를 참조한다.

## Step 1: 중복 제거

- 동일 URL 제거
- 동일 사건을 다룬 기사가 여러 매체에서 나온 경우, 가장 권위 있는 매체 1건만 유지

## Step 2: 관련성 필터

config의 `relevance_filter` 규칙을 적용한다.

**컨텐츠 겹침 처리**: 기사의 주된 내용을 기준으로 판단한다.
- 예: "AI 기반 핀테크 스타트업 투자" → 주된 내용이 AI 기술이면 AI 토픽, 핀테크 투자/사업이면 Fintech 토픽
- 기사의 핵심 주제가 현재 토픽의 영역인지를 기준으로 포함/제외한다.

## Step 3: 카테고리 분류

각 뉴스를 config의 `categories`에 정의된 카테고리 중 하나로 분류한다.

각 카테고리의 `description` 필드를 분류 기준으로 사용한다:

| Category ID | 분류 기준 |
|-------------|----------|
| config에 정의된 각 카테고리 | 해당 카테고리의 `description` 참조 |

## Step 3a: 테마 키워드 추출 (P3)

Step 3 카테고리 분류와 **같은 LLM 호출에서 통합 처리** — 별도 API 호출 발생 없음.

### 입력
- `state/{topic}-themes.json`의 `themes[].keyword` + `themes[].example_titles` (Step 1에서 로드)
- 분류 중인 기사 (title_ko, title_en, summary_core)

### 출력 (각 기사에 추가)
- `theme_keyword` (필수): kebab-case 영문 3~5단어 슬러그
- `theme_keyword_aux` (선택): 스팬 케이스용 보조 슬러그 1개
- `is_new_keyword` (boolean): 기존 메모리에 있던 슬러그면 false, 새로 만든 거면 true

### 매칭 알고리즘

1. **기존 슬러그 우선 재사용**: LLM은 themes[] 목록을 보고 "이 기사가 기존 슬러그와 같은 사건인가?" 판단
   - 같은 당사자 + 같은 행위/사건 → **동일** (재사용)
     예: "PayPal 인력 감축 발표" + "PayPal 비용절감 계획" → 동일 슬러그
   - 같은 산업 트렌드이지만 다른 당사자 → **별개** (새 슬러그)
     예: "Bunq 멕시코 라이선스" + "Nubank 미국 라이선스" → 둘 다 challenger-bank이지만 별개
   - 추가 전개·후속 보도 → **동일** (재사용)
     예: "CSRC, UP Fintech 제재" + "CSRC 후속 처분 공개" → 동일

2. **새 슬러그 생성 규칙**:
   - kebab-case 영문 3~5 단어
   - 기업명·정부기관·핵심 사건 명사 조합 (예: `paypal-restructuring`, `bunq-mexico-license`, `koscom-finger-mou`)
   - 너무 일반적인 키워드 금지 (`fintech-news`, `payment-update` 등)
   - 한국 기사도 영문 슬러그 사용
   - 5단어 초과 시 자동 절단

3. **스팬 케이스**:
   - 최대 2개 슬러그 (`theme_keyword` 주, `theme_keyword_aux` 보조)
   - 강등 평가에는 **주 키워드만** 사용

### 메모리 부재 시
첫 실행 또는 메모리 파일 corrupt 시 themes[]는 빈 배열. 모든 기사가 새 슬러그 생성. 이번 회차 강등은 일어나지 않음.

## Step 4: 중요도 평가

각 뉴스에 3단계 중요도를 부여한다:

| Rating | 기준 |
|--------|------|
| **★★★** | 업계 판도를 바꾸는 메이저 뉴스 (대형 출시, 대규모 규제, 빅딜) |
| **★★** | 주목할 만한 뉴스 (제품 업데이트, 중간 규모 투자, 주요 논문/보고서) |
| **★** | 알아두면 좋은 뉴스 (소규모 업데이트, 분석 기사, 커뮤니티 소식) |

`rating_level`도 함께 설정한다: ★★★=3, ★★=2, ★=1

## Step 4a: 반복 테마 강등 (P3)

Step 4 직후, 메모리의 `themes[]`를 조회해 반복 테마에 대해 ★ 강등을 적용한다.

### 임계값 (7일 윈도우)

| `theme.count` (메모리에서 조회) | 판정 | 동작 |
|---------------|------|------|
| 1~2 | 신선 | 강등 없음 |
| 3~4 | 반복 | ★ -1 강등 후보 |
| 5+ | 포화 | ★ -1 강등 + 큐레이션 경고 로그 |

**바닥**: ★ 유지. 강등은 ★★★→★★, ★★→★까지만. 절대 제외하지 않는다.

### 강등 알고리즘

```
for each article:
    if not is_new_keyword:
        theme = memory.themes.find(keyword == article.theme_keyword)
        if theme.count >= 3:
            # 면제 판단
            is_exempt = check_exemption(article, theme)
            if is_exempt:
                article.demote_log = "강등 면제 — 새 전개"
                # rating 유지
            else:
                article.original_rating_level = article.rating_level
                article.rating_level = max(1, article.rating_level - 1)
                article.rating_stars = recompute_stars(article.rating_level)
                article.rating_demoted = True
                article.rating_demote_reason = f"7일 내 {theme.keyword} {theme.count}회 등장"
```

### 강등 면제 조건 (LLM 판단)

다음 중 하나에 해당하면 강등을 **보류**한다 (rating 그대로 유지):

1. **새 전개 (escalation / follow-up)**
   - 추가 규제 액션 (1차 발표 → 2차 시행령)
   - 후속 딜 클로징 (인수 발표 → 인수 종료)
   - 입장 변화 (찬성 → 반대, 신청 → 철회)

2. **임팩트 점프**
   - 같은 슬러그라도 수치·영향이 명확히 더 커진 경우
   - 예: 1차 100M 추가 손실 → 2차 1B 손실 확정
   - LLM이 임팩트 차이를 명시할 수 있을 때만 적용. 모호하면 강등 진행

(새 당사자는 슬러그 매칭에서 자동으로 별개 처리되므로 별도 면제 조건 아님)

### 강등 흔적 보존

강등된 기사는 다음 메타 필드 유지 (Step 5의 HTML 렌더링 시 hidden comment로만 archive에 흘려보냄):

```json
{
  "rating_level": 2,
  "original_rating_level": 3,
  "rating_demoted": true,
  "rating_demote_reason": "7일 내 stablecoin-uk-regulation 4회 등장"
}
```

archive HTML의 해당 `<article>` 직전에 `<!-- demoted from ★★★ — stablecoin-uk-regulation 4회 -->` 형태로 코멘트만 삽입. 사용자 페이지에는 노출 안 함.

### 가드레일

- 한 페이지 내 강등 발생 비율이 50% 초과 → 큐레이션 경고 (메모리 과적합 가능성)
- ★★★이 모두 강등되어 페이지에서 0건이 되면 → 가장 최근(publish_date 기준) ★★★ 1건 강등 취소

## Step 5: 한국어 번역·3-block 요약

각 뉴스에 대해 title_ko + 3개의 요약 블록을 생성한다.

### title_ko
제목을 한국어로 번역한다.

### summary_core (50~80자, 1문장) — 필수
무엇이 일어났나 — 사실 한 줄.
- 헤드라인과 다른 워딩 사용 (정보 중복 방지)
- 동사 능동형, 단정형
- 의문문·감탄문 금지

### summary_detail (100~180자, 2문장) — 필수
숫자·당사자·시점 — 핵심 디테일.
- 숫자(액수·%·기간), 당사자(인물·회사·정부기관), 시점(날짜·분기) 중 **최소 2개** 포함
- 객관 사실 나열, 6하원칙 중심

### summary_why (80~150자, 1~2문장) — 등급별 적용
왜 중요한가 — 시사점·맥락.
- 다른 기사·이전 사례·구조적 흐름과의 연결을 강제
- "~을 시사한다", "~의 변곡점", "~ 흐름과 맞물려" 같은 해석/연결 어법
- ★★★ 기사는 Step 4 Stage 2의 fetch fragment가 자동 append됨 (verification.md 참조)

### 등급별 적용 매트릭스

| 등급 | summary_core | summary_detail | summary_why | ★★★ fetch 맥락 |
|------|--------------|----------------|-------------|---------------|
| ★★★ | 필수 | 필수 | 필수 (강도↑) | 필수 (Step 4 Stage 2에서 통합 처리) |
| ★★ | 필수 | 필수 | 필수 (강도 보통) | — |
| ★ | 필수 | 필수 | 선택 — 자연스러운 연결고리가 있을 때만, 억지로 만들면 빈 값으로 둔다 | — |

`summary_why`가 빈 값/null이면 HTML 렌더링에서 해당 블록 자체가 생략된다.
★★★인데 `summary_why`를 생성하지 못하면 → 해당 기사를 ★★로 강등한다.

### 가드레일 — 공허한 표현 금지

다음 표현은 어떤 블록에도 사용하지 않는다:
- "주목할 만하다"
- "트렌드의 일부다"
- "흥미롭다"
- "지켜볼 필요가 있다"
- "큰 의미를 갖는다"

대신 **구체적 연결**을 명시한다:
- ❌ "이는 주목할 만한 변화다."
- ✅ "Klarna의 풀뱅크 전환·Affirm의 B2B 확장과 동시기에 일어나는 결제→은행 수렴 흐름의 한 축이다."

### 품질 경고

한 페이지 내 다음 조건 충족 시 큐레이션 단계에서 경고 로그를 출력한다 (페이지는 정상 발행):
- `summary_why` 누락 비율 30% 초과
- 공허한 표현이 1건이라도 통과됨
- ★★★ 기사 중 fetch fragment 포함률 50% 미만 (paywall 매체 비율 고려)

### 번역 규칙

- 고유명사는 번역하지 않는다 (회사명, 서비스명 등 원문 유지)
- 기관명은 첫 등장 시 영문을 병기한다 (예: 미국 국립과학재단(NSF))
- 기술 용어는 널리 쓰이는 한국어가 있으면 사용, 없으면 원문 유지

## Step 6: 선별 우선순위

10~20건 범위로 맞출 때 다음 우선순위를 적용한다:

### 포함 우선순위 (높은 순)

1. **★★★ 뉴스는 무조건 포함** — 개수 무관, 절대 제외하지 않는다.
2. **L1~L3에서 온 ★★ 뉴스 우선** — 권위 매체·테마·한국 뉴스의 ★★는 우선 포함한다.
3. **L4(소셜)는 보충 역할** — L1~L3에서 놓친 새로운 뉴스만 추가한다. L1~L3과 동일 사건이면 L4를 제외한다.
4. **★ 뉴스로 채움** — 10건 미만이면 ★ 뉴스를 추가하여 최소 10건을 맞춘다.

### 초과 시 제거 순서 (20건 초과 시)

1. ★ 뉴스부터 제거 (L4 소셜 → L3 한국 → L2 테마 → L1 권위 순)
2. 그래도 초과면 ★★ 뉴스 중 L4 소셜부터 제거
3. ★★★ 뉴스는 절대 제거하지 않는다

### P3 보호 규칙

**강등된 기사 (`rating_demoted == true`)는 비강등 ★ 뉴스보다 늦게 제거한다.**

이유: 강등된 기사는 원래 ★★★/★★였던 임팩트 있는 기사. 7일 반복 페널티로 등급이 내려간 것이지 본질적 중요도가 낮아진 게 아니므로, 비강등 ★보다 우선 보존한다.

제거 순서 (강등 인지 반영):
1. 비강등 ★ 뉴스 (L4 → L3 → L2 → L1)
2. 강등된 ★ 뉴스 (있다면)
3. 비강등 ★★ 뉴스 중 L4 → ...
4. 강등된 ★★ 뉴스
5. ★★★ 뉴스는 절대 제거 안 함

## Step 6a: Today's Top 5 선정 (P3)

선별이 끝난 큐레이션 기사 풀에서 카테고리를 횡단하는 상위 5건을 뽑아 페이지 상단 밴드에 배치한다.

### 슬롯 분배 (총 5개)

| Slot | 기준 |
|------|------|
| 1~3 | 강등 안 된 ★★★ 기사 중 카테고리 다양성 만족, 임팩트 순 |
| 4 | 한국 매체(머니투데이·한경·이투데이·디지털데일리·서울경제 등) 1건 보장. ★★★ 이미 잡혔으면 ★★→★ 순 |
| 5 | 1~4에서 안 잡힌 카테고리 중 가장 높은 등급의 기사 1건 (다양성 보완) |

### 카테고리 다양성

- Top 5 내 같은 카테고리는 **최대 2건**
- 6개 카테고리 중 최소 **3개 카테고리**가 Top 5에 등장
- 못 채우면 ★★★ 1건을 ★★로 swap해서 다양성 확보 (단 1회까지)

### 한국 슬롯 처리

| 상황 | 동작 |
|------|------|
| 한국 매체 ★★★ 존재 | Slot 1~3 안에 자연 포함, Slot 4는 카테고리 다양성 슬롯으로 재사용 |
| 한국 매체 ★★ 존재 | Slot 4에 배치 |
| 한국 매체 ★ 만 존재 | Slot 4에 ★ 1건 배치 |
| 한국 매체 0건 | Slot 4 생략 → 결과는 Top 4 (헤더도 "Today's Top 4"로 동적 변경) |

### 슬롯 메타 추가

선정된 기사에 다음 필드 추가:

```json
{
  "top5_rank": 1,
  "top5_anchor": "regulation-uk-stablecoin"
}
```

`top5_anchor`는 해당 기사의 `<article id="...">` 값과 일치해야 함 (HTML 렌더링 단계에서 자동 부여).

### 가드레일

- 큐레이션 후보 < 5건 → Top N으로 자동 축소 (헤더도 동적)
- ★★★ 0건인 날 → 슬롯 모두 ★★/★로 채우고 페이지 상단에 "주요 임팩트 적은 날" 안내 한 줄
- Top 5 LLM 선정 호출 1회 (~200토큰)

## Step 7: 정렬

- 카테고리 내에서 중요도 내림차순 (★★★ → ★★ → ★)으로 정렬한다.
- 뉴스가 0건인 카테고리는 결과에서 제외한다.

## Step 8: 메모리 갱신 + 만료 (P3)

Step 7 정렬 완료 후, Step 5(HTML 생성)와 Step 7(Deploy) 사이에 실행한다.

### 알고리즘

```
memory = load(state/{topic}-themes.json)  # Step 1에서 로드된 객체 재사용

for each article in final curated list:
    primary = article.theme_keyword
    existing = memory.themes.find(keyword == primary)
    if existing:
        existing.count += 1
        existing.last_seen = today
        # example_titles FIFO 갱신
        existing.example_titles = (existing.example_titles + [article.title_ko])[-3:]
    else:
        memory.themes.append({
            "keyword": primary,
            "first_seen": today,
            "last_seen": today,
            "count": 1,
            "example_titles": [article.title_ko]
        })

# 8일 경과 항목 제거
memory.themes = [t for t in memory.themes if days_between(today, t.last_seen) <= 7]

# size cap (50개 / 50KB)
if len(memory.themes) > 50:
    memory.themes = sorted by last_seen desc, take first 50

memory.updated = today
memory.version = 1
memory.window_days = 7

write(state/{topic}-themes.json, memory)
```

### Boundary 조건

- 같은 회차 내 같은 keyword가 여러 기사에 등장 → count는 기사 수만큼 증가
- 보조 키워드 (`theme_keyword_aux`)는 메모리 갱신에 사용하지 않음 (주 키워드만)
- 강등된 기사도 메모리 카운트에는 반영됨 (강등은 노출 등급일 뿐, 사건 발생은 발생)

### 재구축 모드 (Fallback)

다음 조건 모두 해당 시 자동 발동:

1. 메모리 파일 부재 또는 파싱 실패
2. 마지막 `updated`가 8일 이상 전 (또는 missing)
3. archive에 최근 7일치 파일이 3개 이상 존재

→ LLM이 archive 7일치 HTML 파일을 읽어 슬러그·count를 추정해서 themes[]를 재생성한 뒤 이번 회차 Step 4a를 진행한다. 정확도는 낮지만 zero memory보다 낫다.

비용: +5,000~7,000토큰 (비상 시만 발생).

### 보안 / 무결성

- `example_titles` 내용에서 HTML 특수문자 이스케이프 (`<`, `>`, `&`, `"`, `'`)
- `keyword`는 정규식 `^[a-z][a-z0-9-]{2,49}$`만 허용 — 위반 시 자동 normalize
- 파일 size > 50KB 시 가장 오래된 themes 제거
- `last_seen`이 미래 날짜면 데이터 오염으로 간주, 해당 항목 제거 + 경고 로그

## Step 7: 정렬

- 카테고리 내에서 중요도 내림차순 (★★★ → ★★ → ★)으로 정렬한다.
- 뉴스가 0건인 카테고리는 결과에서 제외한다.

## Output

10~20건의 큐레이션된 뉴스를 다음 단계(Verification)에 전달한다.
각 뉴스는 다음 필드를 포함한다:

- `title_en`, `title_ko`
- `summary_core` (필수), `summary_detail` (필수), `summary_why` (등급별, 빈 문자열 허용)
- `original_url`, `source_name`, `publish_date`
- `category`, `rating`, `rating_level`
- `theme_keyword` (P3 필수), `theme_keyword_aux` (P3 선택), `is_new_keyword` (P3)
- `rating_demoted` (P3, boolean), `original_rating_level` (P3, 강등 시), `rating_demote_reason` (P3, 강등 시)
- `top5_rank` (P3, 1~5 또는 null), `top5_anchor` (P3, 선정된 기사만)

> **폐기 (Deprecated)**: `summary_ko` 단일 필드는 더 이상 사용하지 않는다.
> 90일 이내 archive는 legacy 단일 요약을 유지하지만, 신규 큐레이션은 반드시 3-block을 생성한다.
