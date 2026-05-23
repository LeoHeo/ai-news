# Macro Briefing Topic Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new `macro` topic to the ai-news system that produces a structured 4-section global macro briefing (Sector Facts → PEST → Falsification → Executive Summary) daily at 07:30 KST.

**Architecture:** Reuses the existing per-topic file pattern (`config/{topic}.json` + `scripts/run-{topic}.sh` + Claude orchestrator prompt). Adds a topic-specific orchestrator prompt (`scripts/generate-macro.md`) instead of extending the 7-step `scripts/generate.md`, because the 4-section analytical output is structurally different from the existing category-listing format. Adds a topic-specific HTML template and OG SVG. No changes to `ai`/`fintech` pipelines.

**Tech Stack:** Bash, Claude CLI (`-p` non-interactive), WebSearch/WebFetch, plain HTML/CSS/SVG, launchd (macOS).

**Spec:** `docs/superpowers/specs/2026-05-23-macro-briefing-design.md`

---

## File Structure

Files this plan creates or modifies:

| File | Action | Responsibility |
|------|--------|----------------|
| `config/macro.json` | Create | Topic metadata, search layers, categories, safeguards, OG colors, verification policy |
| `templates/news-macro.html` | Create | 4-section daily briefing page layout with placeholders |
| `templates/og-macro.svg` | Create | OG image template (dark + amber/red accent) with `{action_plan}` and `{validity}` placeholders |
| `scripts/generate-macro.md` | Create | Claude orchestrator prompt — 7-step macro pipeline (search → verify → 4 sections → render → archive → deploy) |
| `scripts/run-macro.sh` | Create | launchd entry point; invokes `claude -p` with `generate-macro.md` |
| `site/style.css` | Modify | Append macro-only CSS classes (`.executive-summary`, `.sector-facts`, `.pest`, `.falsification`, `.action-badge-{level}`, `.validity`) |
| `site/index.html` | Modify | Add `매크로 브리핑` tab + topic card |
| `templates/index.html` | Modify | Same as `site/index.html` so future regenerations carry the macro tab |
| `CLAUDE.md` | Modify | Add macro row to Topics table; add `macro/` to Site Structure tree |
| `README.md` | Modify | Add macro row to Topics table |
| `~/Library/LaunchAgents/com.user.macro-news.plist` | Create (user step) | 07:30 KST daily schedule |

No deletions. No edits to existing `ai`/`fintech` config, scripts, or generated pages.

---

## Task 1: Create `config/macro.json`

**Files:**
- Create: `/Users/leoheo/dev/ai-news/config/macro.json`

- [ ] **Step 1: Write the config file**

```json
{
  "topic": {
    "id": "macro",
    "name": "Global Macro Briefing",
    "name_ko": "글로벌 매크로 브리핑"
  },
  "system_role": "월스트리트 시니어 매크로 퀀트 비서. 대중 노이즈를 제거하고 자본의 진짜 이동 경로를 추적한다. 예측·감정 배제, 통제된 구조 하에서 사실만 해체한다.",
  "safeguards": {
    "fact_first": "영어 원문 우선 탐색 (Reuters, AP, CNBC, FT, MarketWatch, Yahoo Finance). Bloomberg/WSJ는 헤드라인만 인용.",
    "time_box_hours": 24,
    "default_action": "No Action",
    "conclusion_placement": "마지막 섹션에서 단 한 번"
  },
  "layers": {
    "L1_authority": {
      "description": "영어 free-access 매체",
      "sources": [
        { "site": "reuters.com", "query": "markets" },
        { "site": "apnews.com", "query": "economy markets" },
        { "site": "cnbc.com", "query": "markets" },
        { "site": "ft.com", "query": "markets" },
        { "site": "marketwatch.com", "query": "markets" },
        { "site": "finance.yahoo.com", "query": "markets" }
      ]
    },
    "L2_paywalled_headlines": {
      "description": "유료 매체 — 헤드라인 + 요약만 인용 가능",
      "sources": [
        { "site": "bloomberg.com", "query": "markets", "mode": "headline_only" },
        { "site": "wsj.com", "query": "markets", "mode": "headline_only" }
      ]
    },
    "L3_korean": {
      "description": "한국 매크로 보도",
      "queries": [
        "연합뉴스 경제 시장",
        "한국경제 코스피",
        "환율 한국은행"
      ]
    }
  },
  "categories": [
    { "id": "global",      "name_ko": "글로벌" },
    { "id": "us",          "name_ko": "미국" },
    { "id": "europe",      "name_ko": "유럽" },
    { "id": "china",       "name_ko": "중국" },
    { "id": "japan",       "name_ko": "일본" },
    { "id": "korea",       "name_ko": "한국" },
    { "id": "crypto",      "name_ko": "암호화폐" },
    { "id": "bonds",       "name_ko": "채권" },
    { "id": "commodities", "name_ko": "원자재" },
    { "id": "tech",        "name_ko": "IT/Tech" }
  ],
  "items_per_category": { "min": 3, "max": 5, "if_empty": "특이사항 없음" },
  "verification_policy": {
    "free_sources":      ["url_ok", "fetch_body", "timestamp_within_24h"],
    "paywalled_sources": ["url_ok", "headline_visible", "timestamp_within_24h"]
  },
  "limits": {
    "maxSearchCalls": 20,
    "maxRawResults": 60
  },
  "archive": { "retentionDays": 90 },
  "site": {
    "url": "https://leoheo.github.io/ai-news",
    "name": "News Daily"
  },
  "og": {
    "gradient_start": "#0a0a14",
    "gradient_mid":   "#1a1a2e",
    "gradient_end":   "#0d0d18",
    "accent_start":   "#fbbf24",
    "accent_end":     "#ef4444"
  }
}
```

- [ ] **Step 2: Validate JSON parses**

Run: `python3 -m json.tool /Users/leoheo/dev/ai-news/config/macro.json > /dev/null && echo OK`

Expected output: `OK`

- [ ] **Step 3: Commit**

```bash
git -C /Users/leoheo/dev/ai-news add config/macro.json
git -C /Users/leoheo/dev/ai-news commit -m "feat(macro): add topic config with safeguards and verification policy"
```

---

## Task 2: Create `templates/og-macro.svg`

**Files:**
- Create: `/Users/leoheo/dev/ai-news/templates/og-macro.svg`

- [ ] **Step 1: Write the SVG template**

Macro-specific placeholders: `{action_plan}` badge + `{validity}` line, replacing the generic `{total_count}건의 뉴스` chip from `og-template.svg`.

```xml
<svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%"   style="stop-color:{og_gradient_start}"/>
      <stop offset="50%"  style="stop-color:{og_gradient_mid}"/>
      <stop offset="100%" style="stop-color:{og_gradient_end}"/>
    </linearGradient>
    <linearGradient id="accent" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%"   style="stop-color:{og_accent_start}"/>
      <stop offset="100%" style="stop-color:{og_accent_end}"/>
    </linearGradient>
  </defs>

  <rect width="1200" height="630" fill="url(#bg)"/>
  <rect x="80" y="180" width="120" height="4" rx="2" fill="url(#accent)"/>

  <text x="80" y="260" font-family="system-ui, -apple-system, sans-serif"
        font-size="60" font-weight="700" fill="#ffffff">
    {topic_name}
  </text>

  <text x="80" y="330" font-family="system-ui, -apple-system, sans-serif"
        font-size="38" fill="rgba(255,255,255,0.75)">
    {date}
  </text>

  <rect x="80" y="370" width="280" height="56" rx="28"
        fill="url(#accent)" opacity="0.85"/>
  <text x="220" y="406" font-family="system-ui, -apple-system, sans-serif"
        font-size="24" font-weight="700" fill="#0a0a14" text-anchor="middle">
    Action: {action_plan}
  </text>

  <text x="80" y="490" font-family="system-ui, -apple-system, sans-serif"
        font-size="22" fill="rgba(255,255,255,0.6)">
    유효: {validity}
  </text>

  <text x="80" y="570" font-family="system-ui, -apple-system, sans-serif"
        font-size="20" fill="rgba(255,255,255,0.3)">
    News Daily — Global Macro · Curated by Claude
  </text>

  <circle cx="1050" cy="120" r="80"  fill="rgba(251,191,36,0.04)"/>
  <circle cx="1100" cy="220" r="130" fill="rgba(239,68,68,0.03)"/>
</svg>
```

- [ ] **Step 2: Validate SVG is well-formed XML**

Run: `xmllint --noout /Users/leoheo/dev/ai-news/templates/og-macro.svg && echo OK`

Expected output: `OK`

If `xmllint` is missing on the system, fall back to: `python3 -c "import xml.etree.ElementTree as ET; ET.parse('/Users/leoheo/dev/ai-news/templates/og-macro.svg'); print('OK')"`

- [ ] **Step 3: Confirm `rsvg-convert` can render a sample**

Substitute placeholders with literal values and convert to PNG to confirm the SVG is renderable:

```bash
cd /tmp && sed \
  -e 's/{og_gradient_start}/#0a0a14/g' \
  -e 's/{og_gradient_mid}/#1a1a2e/g' \
  -e 's/{og_gradient_end}/#0d0d18/g' \
  -e 's/{og_accent_start}/#fbbf24/g' \
  -e 's/{og_accent_end}/#ef4444/g' \
  -e 's/{topic_name}/Global Macro Briefing/g' \
  -e 's/{date}/2026-05-23/g' \
  -e 's/{action_plan}/No Action/g' \
  -e 's/{validity}/CPI 발표 전까지/g' \
  /Users/leoheo/dev/ai-news/templates/og-macro.svg > /tmp/og-macro-sample.svg
rsvg-convert -w 1200 -h 630 /tmp/og-macro-sample.svg -o /tmp/og-macro-sample.png && file /tmp/og-macro-sample.png
```

Expected output last line contains: `PNG image data, 1200 x 630`.

If `rsvg-convert` is not installed (`command not found`), record it and continue — the production pipeline already has a fallback branch in `scripts/generate.md` and `generate-macro.md` will use the same fallback. Note this for the manual end-to-end test in Task 13.

- [ ] **Step 4: Commit**

```bash
git -C /Users/leoheo/dev/ai-news add templates/og-macro.svg
git -C /Users/leoheo/dev/ai-news commit -m "feat(macro): add OG image template with action_plan badge"
```

---

## Task 3: Create `templates/news-macro.html`

**Files:**
- Create: `/Users/leoheo/dev/ai-news/templates/news-macro.html`

This template uses the same SEO meta block as `templates/news.html` (so OG/Twitter/JSON-LD are uniform across topics) but the `<body>` is a 4-section layout instead of category-listing.

- [ ] **Step 1: Write the full template**

```html
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{topic_name} — {date}</title>
    <!-- SEO Meta -->
    <meta name="description" content="{og_description}">
    <link rel="canonical" href="{page_url}">
    <!-- Open Graph -->
    <meta property="og:title" content="{topic_name} — {date} | 오늘의 글로벌 매크로 브리핑">
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
    <meta name="twitter:title" content="{topic_name} — {date} | 오늘의 글로벌 매크로 브리핑">
    <meta name="twitter:description" content="{og_description}">
    <meta name="twitter:image" content="{og_image_url}">
    <!-- JSON-LD -->
    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "Report",
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
    <link rel="stylesheet" href="{css_path}">
</head>
<body>
    <header>
        <h1>{topic_name}</h1>
        <p class="date">{date} (KST)</p>
        <p class="summary validity">유효: {validity}</p>
        <nav>
            <a href="{home_link}">Home</a>
            <a href="{archive_link}">Archive</a>
        </nav>
    </header>

    <main>
        <!-- 1. Executive Summary (상단 배치 — 리더 편의 우선) -->
        <section class="executive-summary">
            <h2>⚡ Executive Summary</h2>
            <ol class="summary-lines">
                <li>{summary_line_1}</li>
                <li>{summary_line_2}</li>
                <li>{summary_line_3}</li>
            </ol>
            <p class="action-plan">
                Action Plan:
                <span class="action-badge action-badge-{action_plan_slug}">{action_plan}</span>
            </p>
        </section>

        <!-- 2. Sector Fact Check -->
        <section class="sector-facts">
            <h2>📊 Sector Fact Check</h2>
            <!-- 카테고리별 카드 반복 (10개 카테고리, 각 3-5건 또는 "특이사항 없음") -->
            <div class="sector-card" id="sector-{category_id}">
                <h3>{category_name_ko}</h3>
                <ol class="fact-list">
                    <!-- 팩트 아이템 반복; 빈 카테고리는 .empty 클래스의 한 줄로 대체 -->
                    <li class="fact-item" id="fact-{category_id}-{n}">
                        <span class="fact-index">[{category_id}.{n}]</span>
                        <span class="fact-headline">{headline}</span>
                        <span class="fact-detail">{one_sentence}</span>
                        <span class="fact-source">
                            (<a href="{original_url}" target="_blank" rel="noopener">{source_name}</a>)
                        </span>
                    </li>
                    <!-- 또는 빈 카테고리: -->
                    <!-- <li class="fact-item empty">특이사항 없음</li> -->
                </ol>
            </div>
        </section>

        <!-- 3. PEST -->
        <section class="pest">
            <h2>🌐 PEST 거시 환경</h2>
            <dl>
                <dt>P (Politics)</dt>     <dd>{pest_politics}</dd>
                <dt>E (Economy)</dt>      <dd>{pest_economy}</dd>
                <dt>S (Society)</dt>      <dd>{pest_society}</dd>
                <dt>T (Technology)</dt>   <dd>{pest_technology}</dd>
            </dl>
        </section>

        <!-- 4. Falsification -->
        <section class="falsification">
            <h2>⚠️ Falsification (반증 조건)</h2>
            <p>{falsification_trigger}</p>
        </section>
    </main>

    <footer>
        <p>Curated by Claude | Auto-generated at {generated_time} KST</p>
        <p class="disclaimer">본 브리핑은 AI가 자동 수집·분석한 결과이며, 투자 권유가 아닙니다.
           원문 출처와 본인의 판단으로 확인하세요.</p>
    </footer>
</body>
</html>
```

- [ ] **Step 2: Sanity-check template placeholders**

Run: `grep -o '{[a-z_][a-z0-9_]*}' /Users/leoheo/dev/ai-news/templates/news-macro.html | sort -u`

Expected: a deduplicated list including at minimum:
`{action_plan}, {action_plan_slug}, {archive_link}, {category_id}, {category_name_ko}, {css_path}, {date}, {falsification_trigger}, {generated_time}, {headline}, {home_link}, {n}, {og_description}, {og_image_url}, {one_sentence}, {original_url}, {page_url}, {pest_economy}, {pest_politics}, {pest_society}, {pest_technology}, {site_url}, {source_name}, {summary_line_1}, {summary_line_2}, {summary_line_3}, {topic_name}, {validity}`

No `{TBD}` or `{TODO}` entries.

- [ ] **Step 3: Commit**

```bash
git -C /Users/leoheo/dev/ai-news add templates/news-macro.html
git -C /Users/leoheo/dev/ai-news commit -m "feat(macro): add 4-section briefing HTML template"
```

---

## Task 4: Append macro-only CSS classes to `site/style.css`

**Files:**
- Modify: `/Users/leoheo/dev/ai-news/site/style.css` (append at end)

- [ ] **Step 1: Append the new block to the end of the file**

Use the Edit tool to append after the existing last line. The new block ONLY adds new selectors; it does not touch any existing selector.

```css

/* ===================================================================
   Macro Briefing — 4-section layout (Design Ref: spec §4.2)
   Topic-scoped: applies only to pages under site/macro/
   =================================================================== */

.validity {
    color: #ef4444;
    font-weight: 500;
}

.executive-summary,
.sector-facts,
.pest,
.falsification {
    margin-bottom: 32px;
    padding: 16px 20px;
    background: #fff;
    border-radius: 4px;
}

.executive-summary {
    border-left: 4px solid #fbbf24;
}

.executive-summary h2,
.sector-facts h2,
.pest h2,
.falsification h2 {
    font-size: 1.1em;
    font-weight: 600;
    color: #1a1a1a;
    margin-bottom: 12px;
}

.summary-lines {
    margin: 0 0 12px 20px;
}

.summary-lines li {
    margin-bottom: 6px;
    line-height: 1.5;
}

.action-plan {
    font-size: 0.95em;
    color: #444;
}

.action-badge {
    display: inline-block;
    padding: 4px 12px;
    border-radius: 12px;
    font-size: 0.85em;
    font-weight: 700;
    margin-left: 8px;
    text-transform: uppercase;
    letter-spacing: 0.04em;
}

.action-badge-aggressive {
    background: #fee2e2;
    color: #b91c1c;
}

.action-badge-defensive {
    background: #fef3c7;
    color: #92400e;
}

.action-badge-no-action {
    background: #e5e7eb;
    color: #374151;
}

.sector-card {
    margin-bottom: 16px;
    padding-bottom: 12px;
    border-bottom: 1px solid #eee;
}

.sector-card:last-child {
    border-bottom: none;
    padding-bottom: 0;
    margin-bottom: 0;
}

.sector-card h3 {
    font-size: 0.95em;
    font-weight: 600;
    color: #555;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-bottom: 8px;
}

.fact-list {
    list-style: none;
    padding: 0;
    margin: 0;
}

.fact-item {
    padding: 6px 0;
    font-size: 0.9em;
    line-height: 1.5;
}

.fact-item .fact-index {
    color: #999;
    font-family: ui-monospace, "SF Mono", Menlo, monospace;
    font-size: 0.85em;
    margin-right: 6px;
}

.fact-item .fact-headline {
    font-weight: 600;
    color: #1a1a1a;
    margin-right: 6px;
}

.fact-item .fact-detail {
    color: #444;
    margin-right: 6px;
}

.fact-item .fact-source {
    color: #888;
    font-size: 0.85em;
}

.fact-item .fact-source a {
    color: #0066cc;
    text-decoration: none;
}

.fact-item .fact-source a:hover {
    text-decoration: underline;
}

.fact-item.empty {
    color: #aaa;
    font-style: italic;
}

.pest dl {
    margin: 0;
}

.pest dt {
    font-weight: 700;
    color: #1a1a1a;
    margin-top: 8px;
}

.pest dt:first-child {
    margin-top: 0;
}

.pest dd {
    margin: 4px 0 0 0;
    color: #444;
    font-size: 0.95em;
    line-height: 1.5;
}

.falsification {
    border-left: 4px solid #ef4444;
}

.falsification p {
    color: #444;
    line-height: 1.6;
}
```

- [ ] **Step 2: Verify the file still parses as CSS (rough check)**

Run: `awk '{ for(i=1;i<=length($0);i++){c=substr($0,i,1); if(c=="{")o++; else if(c=="}")cc++ }} END{ printf "open=%d close=%d\n",o,cc }' /Users/leoheo/dev/ai-news/site/style.css`

Expected: `open=N close=N` (open and close counts are equal — brace balance preserved).

- [ ] **Step 3: Commit**

```bash
git -C /Users/leoheo/dev/ai-news add site/style.css
git -C /Users/leoheo/dev/ai-news commit -m "feat(macro): add CSS for 4-section briefing layout"
```

---

## Task 5: Create `scripts/generate-macro.md` (orchestrator prompt)

**Files:**
- Create: `/Users/leoheo/dev/ai-news/scripts/generate-macro.md`

This is the most important file in the plan — it is the Claude prompt that runs end-to-end at 07:30 KST. It is separate from `scripts/generate.md` (which handles the ai/fintech 7-step category-listing pipeline). Reuse the same Search/Verification helpers conceptually but inline the macro-specific structural rules so the prompt is self-contained.

- [ ] **Step 1: Write the orchestrator prompt**

```markdown
# Global Macro Briefing Generator

> Spec: docs/superpowers/specs/2026-05-23-macro-briefing-design.md
> Topic: `macro` only. (For `ai` / `fintech`, use scripts/generate.md instead.)

## Execution Context

- Working directory: ai-news/ (project root)
- Triggered by: launchd at 07:30 KST via scripts/run-macro.sh
- Required tools: WebSearch, WebFetch, Read, Write, Edit, Bash (git, sed, rsvg-convert)
- Topic parameter is always `macro`. Today's date is provided as `{date}` (YYYY-MM-DD).

## Persona (Structural Safeguards — DO NOT VIOLATE)

You are a Wall Street senior macro quant assistant. Strip retail noise, trace where capital actually moves. No prediction, no emotion. Operate only inside the controls below.

1. **Fact-First**: Search English sources first (Reuters, AP, CNBC, FT, MarketWatch, Yahoo Finance). Bloomberg/WSJ are paywalled — quote headlines only.
2. **Time-Box (24H Limit)**: Every fact must be reported within the past 24 hours from `{date}` 07:30 KST. If a category has no qualifying fact, write `특이사항 없음`. Do NOT pull older articles.
3. **Default = No Action**: When in doubt, the recommended stance is "No Action".
4. **Conclusion comes LAST**: Do NOT leak any summary or directional bias before Step 6. Steps 1–5 are dry facts and structural analysis only.

## Pipeline (run in order)

---

### Step 1: Load Config

```
Read config/macro.json
```

Confirm these fields are present and use them throughout:
- `topic.id`, `topic.name`, `topic.name_ko`
- `system_role`, `safeguards`
- `layers.L1_authority.sources`, `layers.L2_paywalled_headlines.sources`, `layers.L3_korean.queries`
- `categories` (10 categories: global, us, europe, china, japan, korea, crypto, bonds, commodities, tech)
- `items_per_category.min` (3), `items_per_category.max` (5), `items_per_category.if_empty` ("특이사항 없음")
- `verification_policy.free_sources`, `verification_policy.paywalled_sources`
- `limits.maxSearchCalls` (20), `limits.maxRawResults` (60)
- `archive.retentionDays` (90)
- `site.url`, `og.*`

---

### Step 2: Time-Boxed Search

Goal: gather raw items per category from the past 24 hours.

Execution order (respect `limits.maxSearchCalls` as a hard cap):
1. **L1 (free)**: For each `layers.L1_authority.sources[i]`, run `WebSearch("site:{site} {query} past 24 hours")`. One call per source.
2. **L2 (paywall headlines)**: For each `layers.L2_paywalled_headlines.sources[i]`, run `WebSearch("site:{site} {query} past 24 hours")`. Mark resulting items with `mode: "headline_only"` — they CANNOT be cross-verified by fetching the body.
3. **L3 (Korean)**: For each `layers.L3_korean.queries[i]`, run `WebSearch("{query} 오늘")`.

For each search result, extract:
- `title_en` (or `title_ko` for L3)
- `original_url`
- `source_name`
- `publish_date` and `publish_time` if available
- `mode`: `"full"` (default) or `"headline_only"` (L2)

Drop any result whose timestamp is older than 24 hours from `{date}` 07:30 KST. If timestamp cannot be inferred, keep for Step 3 verification.

Stop early if total WebSearch calls reach `limits.maxSearchCalls`.

---

### Step 3: Verification (per `verification_policy`)

For each candidate item:

**If `mode == "full"` (free source):**
1. `WebFetch(original_url)` with 10s timeout. HTTP 200 required (follow up to 3 redirects).
2. Confirm the body contains the headline (or a clear paraphrase). Reject if body is obviously unrelated.
3. Re-confirm `publish_date` from the page. If still > 24h old → DROP.

**If `mode == "headline_only"` (Bloomberg/WSJ):**
1. `WebFetch(original_url)` to confirm URL returns 200 and a visible headline (paywall preview is fine).
2. Confirm timestamp ≤ 24h. If the page does not expose a timestamp, DROP.
3. Do NOT fabricate body content. The one-sentence fact must be derivable from the headline alone.

Mark survivors with `verification_status: "passed"`. Drop the rest. Only `passed` items advance.

---

### Step 4: Assemble Sector Fact Check (10 categories)

For each of the 10 categories in `config.categories` (in the same order as the config array):
- Pick the 3–5 most informationally dense items belonging to that category. Use the headline content to classify (e.g., FOMC → `us` or `bonds` depending on which is dominant; ECB → `europe`; Bitcoin ETF → `crypto`).
- If fewer than 3 items remain after verification, include what is available (1–2 is OK).
- If 0 items remain, render exactly: `특이사항 없음`.

For each fact, prepare:
- `index`: `{category_id}.{n}` (1-based within the category, e.g., `us.1`, `us.2`)
- `headline`: dry, neutral one-line headline in Korean (translate from English if needed; keep proper nouns in original)
- `one_sentence`: one Korean sentence stating the verified fact (numbers, names, dates only — no interpretation)
- `source_name`, `original_url`

---

### Step 5: PEST + Falsification

Using ONLY the indices produced in Step 4, write:

**PEST (one line each, must cite at least one index):**
- `pest_politics`   — selections + tariffs + war + regulation risk
- `pest_economy`    — central bank policy + inflation + employment
- `pest_society`    — fear/greed sentiment + crowd narrative
- `pest_technology` — AI / leading sector momentum + earnings

Reference indices in brackets, e.g. `미·중 관세 협상 재개 시그널 [us.2, china.1]`. If a PEST dimension has no supporting fact, write `특이사항 없음` for that line.

**Falsification:**
- One sentence: "내일/다음 주 ___ 지표 또는 이벤트가 ___ 결과를 보이면 본 브리핑 폐기."

---

### Step 6: Executive Summary (LAST — do not draft earlier)

Now and ONLY now produce:

1. `summary_line_1`, `summary_line_2`, `summary_line_3` — three Korean sentences summarizing today's dominant variable(s). State the root cause, not the headline.
2. `action_plan` — exactly one of `Aggressive` / `Defensive` / `No Action`. Default to `No Action` unless evidence is overwhelming. Compute `action_plan_slug`:
   - `Aggressive`  → `aggressive`
   - `Defensive`   → `defensive`
   - `No Action`   → `no-action`
   - Any other value → coerce to `No Action` / `no-action`.
3. `validity` — short Korean clause stating the analysis window, e.g. `미국 CPI 발표 전까지`.

---

### Step 7: Render

#### 7-meta: Prepare SEO meta values

- `og_description`: `"{date} 글로벌 매크로 브리핑. Action: {action_plan} · 유효: {validity}. 미국·유럽·중국·일본·한국·암호화폐·채권·원자재·IT 섹터 24시간 팩트 체크."` — escape HTML entities (`"` `&` `<` `>` `'`).
- `page_url`:
  - Today's page: `{site.url}/macro/`
  - Archive day: `{site.url}/macro/archive/{date}.html`
  - Archive index: `{site.url}/macro/archive/`
- `og_image_url`:
  - On success: `{site.url}/assets/og-macro-{date}.png`
  - On rsvg-convert failure: `{site.url}/assets/og-home.png` (fallback)

#### 7-og: Render OG image

```
Read templates/og-macro.svg
```

Substitute placeholders with literal values:
- `{og_gradient_start}`, `{og_gradient_mid}`, `{og_gradient_end}` ← `config.og`
- `{og_accent_start}`, `{og_accent_end}` ← `config.og`
- `{topic_name}` ← `config.topic.name`
- `{date}` ← `{date}`
- `{action_plan}` ← Step 6 value
- `{validity}` ← Step 6 value

```
Write site/assets/og-macro-{date}.svg
```

```bash
rsvg-convert -w 1200 -h 630 site/assets/og-macro-{date}.svg -o site/assets/og-macro-{date}.png && rm site/assets/og-macro-{date}.svg
```

If `rsvg-convert` is unavailable or exits non-zero, log a warning and leave `site/assets/og-macro-{date}.svg` in place; set `og_image_url` to the fallback above.

#### 7a: Render today's page — site/macro/index.html

```
Read templates/news-macro.html
```

Substitute placeholders. For repeated structures (sector-card and fact-item) duplicate the template fragment per category and per fact:
- `{css_path}` → `../style.css`
- `{home_link}` → `../index.html`
- `{archive_link}` → `archive/index.html`
- `{topic_name}` → `config.topic.name` (`Global Macro Briefing`)
- `{date}` → `{date}`
- `{generated_time}` → `HH:MM` (current KST time)
- `{validity}` → Step 6
- `{summary_line_1..3}` → Step 6
- `{action_plan}` / `{action_plan_slug}` → Step 6
- For each category in order: emit one `<div class="sector-card">` block.
  - `{category_id}` → e.g. `us`
  - `{category_name_ko}` → from `config.categories[i].name_ko`
  - For each fact item:
    - `{n}` → 1-based index
    - `{headline}`, `{one_sentence}` → Step 4
    - `{original_url}`, `{source_name}` → Step 4 (URL must start with `https://`)
  - Empty category → render `<li class="fact-item empty">특이사항 없음</li>` (single item)
- `{pest_politics}`, `{pest_economy}`, `{pest_society}`, `{pest_technology}` → Step 5
- `{falsification_trigger}` → Step 5
- SEO placeholders (`{og_description}`, `{page_url}`, `{og_image_url}`, `{site_url}`) → Step 7-meta

HTML-escape all text values (`<` `>` `&` `"` `'`). URLs must already be safe (`https://` only).

```
Write site/macro/index.html
```

#### 7b: Render archive day — site/macro/archive/{date}.html

Same content as 7a, but with these differences:
- `{css_path}` → `../../style.css`
- `{home_link}` → `../../index.html`
- `{archive_link}` → `index.html`
- `{page_url}` → `{site.url}/macro/archive/{date}.html`

```
Write site/macro/archive/{date}.html
```

#### 7c: Update archive list — site/macro/archive/index.html

```
Read templates/archive-index.html
```

If `site/macro/archive/index.html` exists, read it and prepend today's entry to the `<ul class="archive-list">`. Otherwise create from the template.
- `{css_path}` → `../../style.css`
- `{home_link}` → `../../index.html`
- `{today_link}` → `../index.html`
- `{topic_name}` → `Global Macro Briefing`
- `{page_url}` → `{site.url}/macro/archive/`
- `{og_image_url}` → today's OG image URL (reuse from Step 7-meta)
- `{site_url}` → `config.site.url`
- Entry line: `<li><a href="{date}.html">{date}</a> <span class="count">Action: {action_plan}</span></li>`

The macro `archive-list` reuses the same `.count` style as ai/fintech, but the content is the action plan instead of an article count — this is intentional, since macro doesn't have a comparable count.

```
Write site/macro/archive/index.html
```

#### 7d: Update home — site/index.html

```
Read site/index.html
```

Ensure the macro tab and topic-card are present (they were inserted statically in Task 9 of the plan). Update only the macro card's `<p class="date">` and `<p class="count">` lines:
- `<p class="date">{date}</p>`
- `<p class="count">Action: {action_plan} · 유효: {validity}</p>`

Do NOT touch the AI or Fintech cards.

```
Write site/index.html
```

---

### Step 8: Archive Cleanup (90 days)

```bash
find site/macro/archive/ -name "????-??-??.html" -mtime +90 -print -delete
```

Then remove the same dates from `site/macro/archive/index.html`. If no files match, skip.

---

### Step 9: Deploy

```bash
git add site/macro/ site/index.html site/assets/og-macro-{date}.png
git commit -m "chore: update macro news {date}"
git push origin main
```

Match the existing commit-message convention. On push failure, retry once; if that also fails, leave the local files and exit non-zero.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| WebSearch returns 0 results across all layers | Render all 10 categories as `특이사항 없음`. Set `summary_line_*` to "유의미한 신규 변수 부재.", `action_plan = "No Action"`, `validity = "다음 정기 업데이트까지"`. Still publish. |
| Single category has < 3 items after verification | Include what is available (≥1). Do not pad with older or off-topic items. |
| `maxSearchCalls` limit hit mid-pipeline | Stop search immediately. Proceed with whatever passed verification. |
| WebFetch timeout (10s) | Drop that item. |
| OG image conversion fails | Use `og-home.png` fallback; do not abort the page render. |
| LLM proposes an `action_plan` outside the 3 allowed values | Coerce to `No Action` / `no-action`. |
| `git push` fails | Retry once. If still failing, exit with non-zero status but keep local files committed. |
```

- [ ] **Step 2: Verify the file was written and contains all 9 steps + persona + error table**

Run: `grep -cE '^### Step [1-9]:' /Users/leoheo/dev/ai-news/scripts/generate-macro.md`

Expected: `9`

Run: `grep -c "Structural Safeguards" /Users/leoheo/dev/ai-news/scripts/generate-macro.md`

Expected: `1`

Run: `grep -c "Error Handling" /Users/leoheo/dev/ai-news/scripts/generate-macro.md`

Expected: `1`

- [ ] **Step 3: Commit**

```bash
git -C /Users/leoheo/dev/ai-news add scripts/generate-macro.md
git -C /Users/leoheo/dev/ai-news commit -m "feat(macro): add 9-step orchestrator prompt with structural safeguards"
```

---

## Task 6: Create `scripts/run-macro.sh`

**Files:**
- Create: `/Users/leoheo/dev/ai-news/scripts/run-macro.sh`

- [ ] **Step 1: Write the runner**

Mirror `scripts/run-fintech.sh` exactly, swapping topic and orchestrator file.

```bash
#!/bin/bash
# Macro Briefing Daily — launchd에서 실행되는 스크립트
# Schedule: cron 07:30 KST

export PATH="/Users/leoheo/.local/bin:/Users/leoheo/.nvm/versions/node/v22.22.0/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export HOME="/Users/leoheo"

cd /Users/leoheo/dev/ai-news

TOPIC="macro"
DATE=$(date +%Y-%m-%d)
LOG="/Users/leoheo/dev/ai-news/logs/generate-${TOPIC}-${DATE}.log"

echo "=== ${TOPIC} News Daily: ${DATE} $(date +%H:%M:%S) ===" >> "$LOG"

claude -p \
  --dangerously-skip-permissions \
  --allowedTools "WebSearch,WebFetch,Bash,Read,Write,Edit,Glob,Grep" \
  --model sonnet \
  "Read scripts/generate-macro.md and follow ALL instructions exactly. Execute the full 9-step pipeline. Topic is '${TOPIC}'. Today's date is ${DATE}." \
  >> "$LOG" 2>&1

echo "=== Completed: $(date +%H:%M:%S) ===" >> "$LOG"
```

- [ ] **Step 2: Make executable and verify syntax**

```bash
chmod +x /Users/leoheo/dev/ai-news/scripts/run-macro.sh
bash -n /Users/leoheo/dev/ai-news/scripts/run-macro.sh && echo OK
```

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git -C /Users/leoheo/dev/ai-news add scripts/run-macro.sh
git -C /Users/leoheo/dev/ai-news commit -m "feat(macro): add launchd entry-point script"
```

---

## Task 7: Update `templates/index.html` (home template — adds macro tab + card slot)

**Files:**
- Modify: `/Users/leoheo/dev/ai-news/templates/index.html`

The home template currently shows a single repeatable `topic-tabs` and `topic-card` block. Make the macro entries explicit so the home page always carries them regardless of which topic last regenerated.

- [ ] **Step 1: Read the file**

Read `/Users/leoheo/dev/ai-news/templates/index.html` to confirm the current `<nav class="topic-tabs">` and `<section class="topic-card">` markers.

- [ ] **Step 2: Edit — replace the nav block**

Use the Edit tool to change:

Old:
```html
    <nav class="topic-tabs">
        <!-- 토픽별 탭 (generate.md Step 5d에서 동적 생성) -->
        <a href="{topic_id}/index.html" class="tab">{topic_name_ko}</a>
    </nav>
```

New:
```html
    <nav class="topic-tabs">
        <!-- 토픽별 탭 (generate.md Step 5d / generate-macro.md Step 7d에서 동적 생성) -->
        <a href="ai/index.html" class="tab">AI 뉴스</a>
        <a href="fintech/index.html" class="tab">핀테크 뉴스</a>
        <a href="macro/index.html" class="tab">매크로 브리핑</a>
    </nav>
```

- [ ] **Step 3: Edit — replace the single topic-card with three explicit cards**

Old:
```html
        <!-- 각 토픽의 최신 뉴스 요약 카드 -->
        <section class="topic-card">
            <h2><a href="{topic_id}/index.html">{topic_name}</a></h2>
            <p class="date">{date}</p>
            <p class="count">{topic_name_ko} {total_count}건</p>
            <a href="{topic_id}/index.html" class="read-more">자세히 보기</a>
        </section>
```

New:
```html
        <!-- 각 토픽의 최신 뉴스 요약 카드 -->
        <section class="topic-card">
            <h2><a href="ai/index.html">AI News Daily</a></h2>
            <p class="date">{ai_date}</p>
            <p class="count">AI 뉴스 {ai_total_count}건</p>
            <a href="ai/index.html" class="read-more">자세히 보기</a>
        </section>

        <section class="topic-card">
            <h2><a href="fintech/index.html">Fintech News Daily</a></h2>
            <p class="date">{fintech_date}</p>
            <p class="count">핀테크 뉴스 {fintech_total_count}건</p>
            <a href="fintech/index.html" class="read-more">자세히 보기</a>
        </section>

        <section class="topic-card">
            <h2><a href="macro/index.html">Global Macro Briefing</a></h2>
            <p class="date">{macro_date}</p>
            <p class="count">Action: {macro_action_plan} · 유효: {macro_validity}</p>
            <a href="macro/index.html" class="read-more">자세히 보기</a>
        </section>
```

- [ ] **Step 4: Verify the template now references all three topics**

Run: `grep -cE 'href="(ai|fintech|macro)/index.html"' /Users/leoheo/dev/ai-news/templates/index.html`

Expected: `6` (3 tabs + 3 card links).

- [ ] **Step 5: Commit**

```bash
git -C /Users/leoheo/dev/ai-news add templates/index.html
git -C /Users/leoheo/dev/ai-news commit -m "feat(macro): add macro tab and card to home template"
```

---

## Task 8: Update `site/index.html` (currently-deployed home page — visible now, before first macro run)

**Files:**
- Modify: `/Users/leoheo/dev/ai-news/site/index.html`

The deployed home page should show the macro tab immediately so the navigation isn't broken between the commit and the first 07:30 KST run. Insert the macro tab + card with placeholder date `Coming soon` until the orchestrator overwrites it.

- [ ] **Step 1: Read the file**

Read `/Users/leoheo/dev/ai-news/site/index.html` to find the existing tabs and cards.

- [ ] **Step 2: Edit — add the macro tab**

Use Edit. Append the macro `<a>` tag inside `<nav class="topic-tabs">`. Find:
```html
        <a href="ai/index.html" class="tab">AI 뉴스</a>
        <a href="fintech/index.html" class="tab">핀테크 뉴스</a>
    </nav>
```
Replace with:
```html
        <a href="ai/index.html" class="tab">AI 뉴스</a>
        <a href="fintech/index.html" class="tab">핀테크 뉴스</a>
        <a href="macro/index.html" class="tab">매크로 브리핑</a>
    </nav>
```

- [ ] **Step 3: Edit — add the macro topic-card**

Find the closing `</main>` and insert a new `<section class="topic-card">` directly before it:

```html
        <section class="topic-card">
            <h2><a href="macro/index.html">Global Macro Briefing</a></h2>
            <p class="date">Coming soon</p>
            <p class="count">Action: — · 유효: —</p>
            <a href="macro/index.html" class="read-more">자세히 보기</a>
        </section>

    </main>
```

- [ ] **Step 4: Verify three tabs and three cards are present**

```bash
grep -c 'class="tab"' /Users/leoheo/dev/ai-news/site/index.html
grep -c 'class="topic-card"' /Users/leoheo/dev/ai-news/site/index.html
```

Expected: `3` and `3`.

- [ ] **Step 5: Commit**

```bash
git -C /Users/leoheo/dev/ai-news add site/index.html
git -C /Users/leoheo/dev/ai-news commit -m "feat(macro): add macro tab and placeholder card to deployed home"
```

---

## Task 9: Create the `site/macro/` directory skeleton

**Files:**
- Create: `/Users/leoheo/dev/ai-news/site/macro/.gitkeep`
- Create: `/Users/leoheo/dev/ai-news/site/macro/archive/.gitkeep`

This guarantees the orchestrator's `Write site/macro/index.html` succeeds on the first run (the parent directories already exist).

- [ ] **Step 1: Create directories and placeholders**

```bash
mkdir -p /Users/leoheo/dev/ai-news/site/macro/archive
: > /Users/leoheo/dev/ai-news/site/macro/.gitkeep
: > /Users/leoheo/dev/ai-news/site/macro/archive/.gitkeep
ls -la /Users/leoheo/dev/ai-news/site/macro /Users/leoheo/dev/ai-news/site/macro/archive
```

Expected: both directories exist and contain `.gitkeep`.

- [ ] **Step 2: Commit**

```bash
git -C /Users/leoheo/dev/ai-news add site/macro/.gitkeep site/macro/archive/.gitkeep
git -C /Users/leoheo/dev/ai-news commit -m "chore(macro): create site/macro/ skeleton"
```

---

## Task 10: Update `CLAUDE.md`

**Files:**
- Modify: `/Users/leoheo/dev/ai-news/CLAUDE.md`

- [ ] **Step 1: Edit — extend the Topics table**

Use Edit. Old:
```
| Topic | Config | Schedule | Categories |
|-------|--------|----------|------------|
| AI | config/ai.json | 08:00 KST | Models, Products, Research, Industry, Regulation |
| Fintech | config/fintech.json | 08:30 KST | Payments, Remittance, Digital Banking, Lending, Regulation, Investment |
```

New:
```
| Topic | Config | Schedule | Categories |
|-------|--------|----------|------------|
| AI | config/ai.json | 08:00 KST | Models, Products, Research, Industry, Regulation |
| Fintech | config/fintech.json | 08:30 KST | Payments, Remittance, Digital Banking, Lending, Regulation, Investment |
| Macro | config/macro.json | 07:30 KST | Global, US, Europe, China, Japan, Korea, Crypto, Bonds, Commodities, IT/Tech |
```

- [ ] **Step 2: Edit — extend the Site Structure tree**

Old:
```
└── fintech/
    ├── index.html      ← 오늘의 핀테크 뉴스
    └── archive/
```

New:
```
├── fintech/
│   ├── index.html      ← 오늘의 핀테크 뉴스
│   └── archive/
└── macro/
    ├── index.html      ← 오늘의 글로벌 매크로 브리핑 (4-section)
    └── archive/
```

- [ ] **Step 3: Edit — add a Key Rules note**

Append the following line at the end of the `## Key Rules` bullet list:
```
- macro 토픽은 4-section 브리핑 (Sector Facts → PEST → Falsification → Executive Summary). 출력 구조가 ai/fintech와 다르므로 별도 prompt(scripts/generate-macro.md)와 별도 템플릿(templates/news-macro.html)을 사용
```

- [ ] **Step 4: Verify**

```bash
grep -c "macro" /Users/leoheo/dev/ai-news/CLAUDE.md
```

Expected: `>= 4` (Topics row, Site Structure entry, Key Rules note, plus any other mentions).

- [ ] **Step 5: Commit**

```bash
git -C /Users/leoheo/dev/ai-news add CLAUDE.md
git -C /Users/leoheo/dev/ai-news commit -m "docs(macro): update CLAUDE.md with macro topic"
```

---

## Task 11: Update `README.md`

**Files:**
- Modify: `/Users/leoheo/dev/ai-news/README.md`

- [ ] **Step 1: Edit — extend the public Topics table**

Old:
```
| Topic | Schedule (KST) | Categories |
|-------|:--------------:|------------|
| AI | 08:00 | Models, Products, Research, Industry, Regulation |
| Fintech | 08:30 | Payments, Remittance, Digital Banking, Lending, Regulation, Investment |
```

New:
```
| Topic | Schedule (KST) | Categories |
|-------|:--------------:|------------|
| Macro | 07:30 | Global, US, Europe, China, Japan, Korea, Crypto, Bonds, Commodities, IT/Tech |
| AI | 08:00 | Models, Products, Research, Industry, Regulation |
| Fintech | 08:30 | Payments, Remittance, Digital Banking, Lending, Regulation, Investment |
```

(Macro listed first because it runs first.)

- [ ] **Step 2: Edit — extend Project Structure tree**

Old:
```
    ├── ai/           ← AI 뉴스
    └── fintech/      ← 핀테크 뉴스
```

New:
```
    ├── ai/           ← AI 뉴스
    ├── fintech/      ← 핀테크 뉴스
    └── macro/        ← 글로벌 매크로 브리핑 (4-section)
```

- [ ] **Step 3: Edit — extend the opening summary**

Old: `매일 글로벌 AI/핀테크 뉴스를 자동 수집 · 큐레이션하여 GitHub Pages로 배포하는 개인용 뉴스레터.`

New: `매일 글로벌 AI / 핀테크 / 매크로 브리핑을 자동 수집 · 큐레이션하여 GitHub Pages로 배포하는 개인용 뉴스레터.`

- [ ] **Step 4: Verify**

```bash
grep -c "Macro\|macro" /Users/leoheo/dev/ai-news/README.md
```

Expected: `>= 3`.

- [ ] **Step 5: Commit**

```bash
git -C /Users/leoheo/dev/ai-news add README.md
git -C /Users/leoheo/dev/ai-news commit -m "docs(macro): update README with macro topic"
```

---

## Task 12: Author the launchd plist (user step — not committed)

**Files:**
- Create: `/Users/leoheo/Library/LaunchAgents/com.user.macro-news.plist` (machine-local, not in repo)

The existing `ai` and `fintech` scheduling is also outside the repo (no plist is tracked in git, matching what was observed at plan-writing time). Keep that convention.

- [ ] **Step 1: Write the plist file**

```bash
cat > /Users/leoheo/Library/LaunchAgents/com.user.macro-news.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.macro-news</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/leoheo/dev/ai-news/scripts/run-macro.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>7</integer>
        <key>Minute</key>
        <integer>30</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/Users/leoheo/dev/ai-news/logs/launchd-macro.out.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/leoheo/dev/ai-news/logs/launchd-macro.err.log</string>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
PLIST
echo "wrote /Users/leoheo/Library/LaunchAgents/com.user.macro-news.plist"
```

- [ ] **Step 2: Load into launchd**

```bash
launchctl bootout gui/$(id -u)/com.user.macro-news 2>/dev/null
launchctl bootstrap gui/$(id -u) /Users/leoheo/Library/LaunchAgents/com.user.macro-news.plist
launchctl print gui/$(id -u)/com.user.macro-news | grep -E '(state|next firing)'
```

Expected: state is `not running` (correct — only fires at 07:30) AND a `next firing` line is present.

- [ ] **Step 3: Note — this step has no commit (plist is machine-local)**

No `git add` / `git commit` for this task.

---

## Task 13: End-to-end manual run

**Files:** (none — verification only)

- [ ] **Step 1: Confirm `claude` CLI and `rsvg-convert` are on PATH**

```bash
command -v claude && command -v rsvg-convert
```

Expected: two paths. If `rsvg-convert` is missing, install with `brew install librsvg` first (the orchestrator has a fallback but the test should exercise the success path).

- [ ] **Step 2: Trigger the runner once**

```bash
bash /Users/leoheo/dev/ai-news/scripts/run-macro.sh
```

This will block until the Claude session finishes (can take 3–8 minutes). The script writes to `logs/generate-macro-$(date +%Y-%m-%d).log`. While waiting, you may inspect the log with `tail -f` in another shell.

- [ ] **Step 3: Verify generated files exist**

```bash
DATE=$(date +%Y-%m-%d)
ls -la /Users/leoheo/dev/ai-news/site/macro/index.html
ls -la /Users/leoheo/dev/ai-news/site/macro/archive/${DATE}.html
ls -la /Users/leoheo/dev/ai-news/site/macro/archive/index.html
ls -la /Users/leoheo/dev/ai-news/site/assets/og-macro-${DATE}.png
```

Expected: all four files exist and are non-empty.

- [ ] **Step 4: Verify the page has all 4 sections**

```bash
for sel in 'class="executive-summary"' 'class="sector-facts"' 'class="pest"' 'class="falsification"'; do
  count=$(grep -c "$sel" /Users/leoheo/dev/ai-news/site/macro/index.html)
  printf '%-30s count=%s\n' "$sel" "$count"
done
```

Expected: each line shows `count=1`.

- [ ] **Step 5: Verify the action_plan badge uses one of three allowed classes**

```bash
grep -oE 'action-badge-(aggressive|defensive|no-action)' /Users/leoheo/dev/ai-news/site/macro/index.html | sort -u
```

Expected: exactly one line, one of `action-badge-aggressive` / `action-badge-defensive` / `action-badge-no-action`.

- [ ] **Step 6: Verify PEST indices reference real sector-fact ids**

```bash
# Extract all referenced indices from PEST/Falsification text
grep -oE '\[[a-z]+\.[0-9]+\]' /Users/leoheo/dev/ai-news/site/macro/index.html | sort -u > /tmp/macro-refs.txt
# Extract all defined fact-item ids
grep -oE 'id="fact-[a-z]+-[0-9]+"' /Users/leoheo/dev/ai-news/site/macro/index.html | sed -E 's/id="fact-([a-z]+)-([0-9]+)"/[\1.\2]/' | sort -u > /tmp/macro-defs.txt
# Every reference must have a definition
comm -23 /tmp/macro-refs.txt /tmp/macro-defs.txt
```

Expected: comm output is **empty** (every `[cat.n]` reference resolves to a real fact). If non-empty, the orchestrator broke its citation contract; investigate before continuing.

- [ ] **Step 7: Open in a browser to eyeball the layout**

```bash
open /Users/leoheo/dev/ai-news/site/macro/index.html
```

Visually confirm: header (date + validity), Executive Summary block with badge, 10 sector cards (filled or "특이사항 없음"), 4 PEST lines, Falsification line, footer.

- [ ] **Step 8: Check OG image**

```bash
open /Users/leoheo/dev/ai-news/site/assets/og-macro-$(date +%Y-%m-%d).png
```

Visually confirm: dark background, amber/red accent bar, title, date, action_plan badge, validity line.

- [ ] **Step 9: No code commit (artifacts were already committed by the orchestrator's Step 9)**

`git -C /Users/leoheo/dev/ai-news log -1 --oneline` should show `chore: update macro news YYYY-MM-DD`.

---

## Task 14: Regression check — ai and fintech still work

**Files:** (none — verification only)

- [ ] **Step 1: Confirm shared files were not broken**

```bash
python3 -m json.tool /Users/leoheo/dev/ai-news/config/ai.json > /dev/null && echo ai-config-OK
python3 -m json.tool /Users/leoheo/dev/ai-news/config/fintech.json > /dev/null && echo fintech-config-OK
bash -n /Users/leoheo/dev/ai-news/scripts/run-ai.sh && echo ai-sh-OK
bash -n /Users/leoheo/dev/ai-news/scripts/run-fintech.sh && echo fintech-sh-OK
test -f /Users/leoheo/dev/ai-news/scripts/generate.md && echo generate-md-OK
```

Expected: all five `OK` lines.

- [ ] **Step 2: Confirm shared `style.css` still parses (brace-balance)**

Already done in Task 4 Step 2; spot-check again:

```bash
awk '{ for(i=1;i<=length($0);i++){c=substr($0,i,1); if(c=="{")o++; else if(c=="}")cc++ }} END{ if(o==cc) print "balanced "o"="cc; else print "BROKEN "o"!="cc }' /Users/leoheo/dev/ai-news/site/style.css
```

Expected: `balanced N=N`.

- [ ] **Step 3: Open existing pages to confirm they still render**

```bash
open /Users/leoheo/dev/ai-news/site/ai/index.html
open /Users/leoheo/dev/ai-news/site/fintech/index.html
open /Users/leoheo/dev/ai-news/site/index.html
```

Expected: each page looks visually identical to before, EXCEPT the home page now shows three tabs and three topic-cards instead of two.

- [ ] **Step 4: No commit** (verification only)

---

## Self-Review Checklist (run before declaring the plan done)

- All file paths absolute and correct? ✓
- Every step's code/command shown inline? ✓
- All spec sections covered:
  - §3.1 (file list) → Tasks 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12
  - §4.1 (config schema) → Task 1
  - §4.2 (HTML layout) → Task 3
  - §4.3 (orchestrator) → Task 5
  - §4.4 (runner) → Task 6
  - §4.5 (launchd) → Task 12
  - §4.6 (home update) → Tasks 7, 8
  - §5 (error handling) → Task 5 (Error Handling table inside the orchestrator) + Task 13 fallback notes
  - §6 (test strategy) → Tasks 13 (manual run), 14 (regression)
- Type/name consistency:
  - `action_plan_slug` values: `aggressive` / `defensive` / `no-action` — used identically in Task 3 (CSS classes), Task 4 (CSS rules), Task 5 (Step 6 coercion), Task 13 Step 5 (verification grep)
  - PEST keys: `pest_politics` / `pest_economy` / `pest_society` / `pest_technology` — same in Tasks 3 and 5
  - Fact index format `[cat.n]` and corresponding HTML `id="fact-cat-n"` — both defined in Task 3 and verified in Task 13 Step 6
- No `TBD`, `TODO`, `fill in later`. ✓

---

## Plan complete and saved to `docs/superpowers/plans/2026-05-23-macro-briefing.md`.

Two execution options:

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — execute tasks in this session using `executing-plans`, batch execution with checkpoints.

Which approach?
