# Plan: copy-article

## Executive Summary

| Perspective | Description |
|-------------|-------------|
| Problem | 뉴스 기사를 Slack/메일/노션 등에 공유할 때 제목·링크·요약을 수동으로 복사·조합해야 함 |
| Solution | 기사별 복사 버튼 클릭 한 번으로 하이퍼링크 제목 + 요약을 리치 텍스트로 클립보드에 복사 |
| UX Effect | 기사 공유가 3단계(제목 복사→URL 복사→요약 복사)에서 1클릭으로 단축 |
| Core Value | 뉴스레터의 핵심 가치인 '큐레이션 결과 공유'를 마찰 없이 지원 |

---

## 1. Feature Overview

- **Feature Name**: copy-article
- **Description**: 각 뉴스 기사 제목 옆 복사 아이콘을 클릭하면 하이퍼링크가 달린 제목과 요약 텍스트가 리치 텍스트로 클립보드에 복사되는 기능

## 2. User Intent Discovery

- **Core Problem**: 뉴스를 다른 사람에게 공유할 때 제목·링크·요약을 각각 복사해야 하는 번거로움
- **Target Users**: 뉴스레터를 읽고 Slack/노션/메일로 공유하는 본인
- **Success Criteria**: 복사 버튼 1클릭으로 리치 텍스트(하이퍼링크 제목 + 요약)가 정상 복사됨

## 3. Alternatives Explored

| Approach | Description | Decision |
|----------|-------------|----------|
| A. 제목 오른쪽 인라인 아이콘 | h3 제목 옆에 작은 clipboard 아이콘 배치 | **채택** - 직관적, 시각적 깔끔 |
| B. 메타 영역 텍스트 링크 | '원문 보기' 옆에 '복사' 텍스트 링크 추가 | 미채택 - 시선 이동 거리가 멀어 UX 불리 |

## 4. YAGNI Review

### Included (v1)
- 복사 버튼 (SVG clipboard icon) + 제목 오른쪽 배치
- 리치 텍스트 복사 (하이퍼링크 제목 + 빈 줄 + 요약)
- 복사 완료 피드백 (아이콘 → 체크마크, 1.5초 후 복원)

### Out of Scope
- hover 시에만 버튼 표시 (불필요한 복잡성)
- 출처 정보 별도 포함 (하이퍼링크에 이미 포함)
- 복사 포맷 선택기 (리치 텍스트 단일 포맷)
- SNS 공유 버튼

## 5. Technical Design

### 5.1 변경 파일

| File | Change |
|------|--------|
| `templates/news.html` | `<h3>` 내부에 복사 버튼 placeholder 추가 |
| `site/style.css` | 복사 버튼 스타일 + 피드백 애니메이션 |
| `scripts/generate.md` | 뉴스 생성 프롬프트에 복사 버튼 HTML 포함 지시 |

### 5.2 복사 버튼 HTML 구조

```html
<h3>
    <a href="{original_url}" target="_blank" rel="noopener">{title_ko}</a>
    <button class="copy-btn" onclick="copyArticle(this)" title="복사">
        <svg><!-- clipboard icon --></svg>
    </button>
</h3>
```

### 5.3 복사 로직 (인라인 script)

```javascript
function copyArticle(btn) {
    const article = btn.closest('.news-item');
    const link = article.querySelector('h3 a');
    const summary = article.querySelector('.summary');
    const title = link.textContent;
    const url = link.href;
    const text = summary.textContent;

    const html = `<a href="${url}">${title}</a><br><br>${text}`;
    const plain = `${title}\n${url}\n\n${text}`;

    navigator.clipboard.write([
        new ClipboardItem({
            'text/html': new Blob([html], {type: 'text/html'}),
            'text/plain': new Blob([plain], {type: 'text/plain'})
        })
    ]).then(() => showCopied(btn));
}
```

### 5.4 복사 포맷

**Rich Text (text/html):**
```html
<a href="https://...">구글 Gemma 4, Apache 2.0 오픈소스로 출시</a><br><br>구글이 Gemma 4를 최초로 Apache 2.0 라이선스로 공개했습니다...
```

**Fallback (text/plain):**
```
구글 Gemma 4, Apache 2.0 오픈소스로 출시
https://...

구글이 Gemma 4를 최초로 Apache 2.0 라이선스로 공개했습니다...
```

### 5.5 피드백 UX

1. 클릭 → 아이콘이 체크마크(✓)로 변경
2. 1.5초 후 원래 clipboard 아이콘으로 복원
3. CSS transition으로 부드러운 전환

## 6. Constraints

- GitHub Pages (HTTPS) → Clipboard API 사용 가능
- 외부 라이브러리 없이 순수 JS로 구현
- 기존 뉴스 생성 스크립트(scripts/generate.md)에서 복사 버튼 HTML을 함께 생성해야 함

## 7. Brainstorming Log

| Phase | Decision |
|-------|----------|
| Copy Format | 리치 텍스트 (하이퍼링크 제목 + 요약) |
| Button Position | 제목(h3) 오른쪽 인라인 |
| Scope | 복사 버튼 + 툴팁 피드백만. 출처/hover/SNS 제외 |
| Line Spacing | 제목과 본문 사이 빈 줄 1개 |
