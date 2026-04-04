# AI News Daily

## Project Overview
매일 08:00 KST에 글로벌 AI 뉴스를 자동 수집·큐레이션하여 GitHub Pages로 배포하는 개인용 뉴스레터.

## Key Rules
- site/ 디렉토리는 자동 생성됨 — 수동 편집 금지
- scripts/*.md는 Claude agent 프롬프트 — 자연어로 작성
- templates/*.html은 placeholder 사용 ({date}, {title_ko} 등)
- config/sources.json에서 검색 소스 관리
- 모든 뉴스는 3단계 검증 필수 (URL → 원문 → 메타데이터)

## Git Convention
- Commit message: "chore: update ai news YYYY-MM-DD"
- Auto-generated files only in site/
- Deploy branch: main, deploy dir: /site

## Archive Policy
- 보존 기간: 90일
- 90일 이전 아카이브 자동 삭제
