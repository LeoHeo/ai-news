# News Daily

## Project Overview
매일 토픽별 글로벌 뉴스를 자동 수집·큐레이션하여 GitHub Pages로 배포하는 개인용 뉴스레터.

### Topics
| Topic | Config | Schedule | Categories |
|-------|--------|----------|------------|
| AI | config/ai.json | 08:00 KST | Models, Products, Research, Industry, Regulation |
| Fintech | config/fintech.json | 08:30 KST | Payments, Remittance, Digital Banking, Lending, Regulation, Investment |

## Key Rules
- site/ 디렉토리는 자동 생성됨 — 수동 편집 금지
- scripts/*.md는 Claude agent 프롬프트 — 자연어로 작성, 토픽 파라미터({topic}) 사용
- templates/*.html은 placeholder 사용 ({date}, {title_ko}, {topic_name} 등)
- templates/*.svg는 OG 이미지 템플릿 — 빌드 타임에 SVG→PNG 변환 (rsvg-convert)
- config/{topic}.json에서 토픽별 검색 소스·카테고리·필터·OG ���상 관리
- 모든 뉴스는 3단계 검증 필수 (URL → 원문 → 메타데이터)
- 모든 페이지에 SEO 메타 태그 필수 (OG + Twitter Cards + JSON-LD)

## Site Structure
```
site/
├── index.html          ← 탭 UI (토픽 선택)
├── style.css           ← 공통 스타일
├── assets/
│   ├── og-home.png     ← 홈 OG 이미지 (정적)
│   └── og-{topic}-{date}.png ← 토픽별 OG 이미지 (동적 생성)
├── ai/
│   ├── index.html      ← 오늘의 AI 뉴스
│   └── archive/
└── fintech/
    ├── index.html      ← 오늘의 핀테크 뉴스
    └── archive/
```

## Adding a New Topic
1. config/{topic}.json 생성 (ai.json 참고) — `site`, `og` 섹션 포함
2. scripts/run-{topic}.sh 생성 (run-ai.sh 참고)
3. site/{topic}/ 디렉토리 생성
4. site/index.html 탭에 새 토픽 추가
5. launchd plist에 새 스케줄 등록

## Git Convention
- Commit message: "chore: update {topic} news YYYY-MM-DD"
- Auto-generated files only in site/
- Deploy branch: main, deploy dir: /site

## Archive Policy
- 보존 기간: 90일
- 90일 이전 아카이브 자동 삭제 (토픽별 독립)
