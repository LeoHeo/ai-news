# News Daily

매일 글로벌 AI / 핀테크 / 매크로 브리핑을 자동 수집 · 큐레이션하여 GitHub Pages로 배포하는 개인용 뉴스레터.

**Live Site**: https://leoheo.github.io/ai-news

## Topics

| Topic | Schedule (KST) | Categories |
|-------|:--------------:|------------|
| Macro | 07:30 | Global, US, Europe, China, Japan, Korea, Crypto, Bonds, Commodities, IT/Tech |
| AI | 08:00 | Models, Products, Research, Industry, Regulation |
| Fintech | 08:30 | Payments, Remittance, Digital Banking, Lending, Regulation, Investment |

## How It Works

```
Claude Code Schedule (08:00 / 08:30 KST)
  ↓
scripts/generate.md (orchestrator)
  ↓
WebSearch → Curate → Verify → Generate HTML + OG Image → Deploy
  ↓
GitHub Pages (site/)
```

1. **수집** — 토픽별 4-Layer 검색 (권위 매체, 테마별, 한국, 소셜미디어)
2. **큐레이션** — 중복 제거 → 관련성 필터 → 카테고리 분류 → 중요도 평가 → 한국어 번역/요약
3. **검증** — URL 유효성 → 원문 교차검증 → 메타데이터 완전성 (3단계)
4. **배포** — HTML 생성 + OG 이미지 생성 → MCP GitHub push → GitHub Pages 자동 배포

## Project Structure

```
ai-news/
├── config/           ← 토픽별 설정 (검색 소스, 카테고리, OG 색상)
├── scripts/          ← Claude agent 프롬프트 (자연어 .md)
├── templates/        ← HTML + SVG 템플릿
└── site/             ← 자동 생성 (GitHub Pages deploy)
    ├── assets/       ← OG 이미지 (동적 생성)
    ├── ai/           ← AI 뉴스
    ├── fintech/      ← 핀테크 뉴스
    └── macro/        ← 글로벌 매크로 브리핑 (4-section)
```

## SEO

모든 페이지에 Open Graph, Twitter Cards, JSON-LD 메타 태그가 포함되어 링크 공유 시 리치 미리보기를 제공합니다. 토픽별 OG 이미지는 빌드 타임에 SVG 템플릿으로부터 동적 생성됩니다.

## Tech Stack

- **Orchestration**: Claude Code Schedule (built-in scheduler)
- **Deploy**: GitHub MCP `push_files` (no local git auth required)
- **Search/Curation**: Claude + WebSearch/WebFetch
- **Hosting**: GitHub Pages
- **OG Image**: SVG template + rsvg-convert (librsvg)

## License

Private project.
