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
