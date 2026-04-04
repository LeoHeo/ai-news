# AI News Daily Planning Document

> **Summary**: 매일 08:00 KST에 전세계 AI 뉴스를 자동 수집·큐레이션하여 정적 웹페이지로 제공하는 개인용 뉴스레터
>
> **Project**: ai-news
> **Version**: 0.1.0
> **Author**: leoheo
> **Date**: 2026-04-04
> **Status**: Draft
> **Method**: Plan Plus (Brainstorming-Enhanced PDCA)

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 매일 쏟아지는 글로벌 AI 뉴스를 직접 찾아 읽기엔 시간이 부족하고, 중요한 뉴스를 놓치기 쉬움 |
| **Solution** | Claude Code Remote Trigger(cron)로 매일 아침 자동으로 웹 검색 → 3-Layer 전략으로 고품질 뉴스 수집 → 할루시네이션 검증 → 한국어 번역·요약 → GitHub Pages 배포 |
| **Function/UX Effect** | 아침에 웹페이지 한 곳만 열면 5분 이내에 카테고리별·중요도별로 정리된 AI 뉴스를 한국어로 확인 가능 |
| **Core Value** | 매일 아침 신뢰할 수 있는 AI 뉴스 큐레이션을 자동으로 받아보는 개인 AI 브리핑 시스템 |

---

## 1. User Intent Discovery

### 1.1 Core Problem

매일 쏟아지는 전세계 AI 뉴스를 일일이 찾아 읽을 시간이 없다. 중요한 뉴스를 놓치지 않으면서도 빠르게 훑어볼 수 있는 자동화된 개인 큐레이션 시스템이 필요하다.

### 1.2 Target Users

| User Type | Usage Context | Key Need |
|-----------|---------------|----------|
| 본인 (개인용) | 매일 아침 출근 전/후 브라우저로 확인 | 5분 이내 AI 트렌드 파악, 한국어로 정리 |

### 1.3 Success Criteria

- [ ] 매일 08:00 KST에 자동으로 뉴스가 수집·게시됨 (안정적 발행)
- [ ] 중복·저품질 뉴스 없이 10~20건의 고품질 큐레이션 (높은 품질)
- [ ] 5분 이내에 오늘의 AI 트렌드를 파악할 수 있는 구성 (빠른 훑어보기)
- [ ] 할루시네이션 없는 신뢰할 수 있는 뉴스 요약 (검증된 정보)

### 1.4 Constraints

| Constraint | Details | Impact |
|------------|---------|--------|
| 웹 검색 의존 | Claude WebSearch로 수집하므로 접근 불가 사이트 존재 가능 | Medium |
| Cron 정확도 | Claude Code Remote Trigger의 cron 실행 시간 오차 가능 | Low |
| 비용 | Claude Code 사용량에 따른 비용 발생 | Low |

---

## 2. Alternatives Explored

### 2.1 Approach A: Claude Code Cron + Static Site — Selected

| Aspect | Details |
|--------|---------|
| **Summary** | Claude Code Remote Trigger(cron)로 매일 자동 실행, 웹 검색으로 뉴스 수집, HTML 생성 후 GitHub Pages 배포 |
| **Pros** | 서버 불필요, 무료 호스팅, Claude가 직접 큐레이션·요약·번역, 유지보수 최소 |
| **Cons** | Claude Code Remote Trigger 의존, 웹 검색 범위 제한 가능 |
| **Effort** | Low |
| **Best For** | 개인용, 최소 인프라, 빠른 구축 |

### 2.2 Approach B: Node.js + RSS/API + Static Site

| Aspect | Details |
|--------|---------|
| **Summary** | Node.js 스크립트로 RSS 피드 및 뉴스 API 크롤링, LLM API로 요약, 정적 사이트 빌드 |
| **Pros** | 뉴스 소스 세밀 제어, 안정적 RSS 기반 수집, 확장성 |
| **Cons** | 서버/VPS 필요, API 키 관리, LLM API 비용 발생, 구축 복잡도 높음 |
| **Effort** | High |
| **Best For** | 소스 커스터마이징이 중요한 경우 |

### 2.3 Approach C: GitHub Actions + Python

| Aspect | Details |
|--------|---------|
| **Summary** | GitHub Actions cron으로 Python 스크립트 실행, 웹 스크래핑/API로 수집, LLM API로 정리, GitHub Pages 배포 |
| **Pros** | 서버 불필요, CI/CD 내장, 버전 관리 자동 |
| **Cons** | GitHub Actions cron 정확도 낮음(±15분), 실행 시간 제한, LLM API 비용 |
| **Effort** | Medium |
| **Best For** | GitHub 생태계 활용 원할 때 |

### 2.4 Decision Rationale

**Selected**: Approach A — Claude Code Cron + Static Site
**Reason**: 개인용 목적에 가장 적합. 서버 없이 무료로 운영 가능하고, Claude가 수집·큐레이션·번역·검증을 모두 처리하므로 별도 코드 최소화. 빠른 구축 및 낮은 유지보수 비용.

---

## 3. YAGNI Review

### 3.1 Included (v1 Must-Have)

- [ ] 3-Layer 전략 웹 검색으로 AI 뉴스 수집
- [ ] 카테고리 분류 (모델/제품/연구/산업/규제)
- [ ] 중요도 평가 (★★★ / ★★ / ★)
- [ ] 한줄 요약 + 한국어 번역
- [ ] 할루시네이션 방지 3단계 검증 (URL 유효성 → 원문 교차검증 → 메타데이터 표시)
- [ ] 정적 HTML 웹페이지 생성 (index.html + 날짜별 아카이브)
- [ ] GitHub Pages 자동 배포
- [ ] 매일 08:00 KST Claude Code cron 자동 실행

### 3.2 Deferred (v2+ Maybe)

| Feature | Reason for Deferral | Revisit When |
|---------|---------------------|--------------|
| 이메일 발송 | 개인용이므로 웹페이지로 충분 | 다른 사람과 공유 필요 시 |
| RSS 피드 제공 | 개인 소비 목적이므로 불필요 | 외부 구독자 생기면 |
| 검색 기능 | 아카이브가 쌓인 후 필요 | 1개월+ 운영 후 |
| 다크 모드 | UX 개선이지만 MVP에 불필요 | v1 안정화 후 |

### 3.3 Removed (Won't Do)

| Feature | Reason for Removal |
|---------|-------------------|
| 구독자 관리 시스템 | 개인용이므로 불필요 |
| 다국어(영/중/일) 동시 지원 | 한국어 하나로 충분 |
| AI 뉴스 댓글/토론 기능 | 개인 큐레이션 목적에 불필요 |
| 추천 알고리즘 | 모든 뉴스를 보여주면 충분 |

---

## 4. Scope

### 4.1 In Scope

- [ ] 3-Layer 웹 검색 기반 AI 뉴스 수집 (글로벌 + 한국)
- [ ] Claude 기반 큐레이션 (분류·요약·중요도·번역)
- [ ] 할루시네이션 방지 3단계 검증 파이프라인
- [ ] 정적 HTML 웹페이지 생성 (깔끔한 뉴스레터 디자인)
- [ ] 날짜별 아카이브 페이지
- [ ] GitHub Pages 자동 배포
- [ ] Claude Code Remote Trigger cron 스케줄링

### 4.2 Out of Scope

- 이메일/Slack/Discord 알림 — (v2 검토)
- RSS/Atom 피드 — (v2 검토)
- 검색·필터링 기능 — (v2 검토)
- 사용자 인증/구독 관리 — (개인용이므로 불필요)
- 모바일 앱 — (반응형 웹으로 대체)

---

## 5. Requirements

### 5.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | 3-Layer 전략으로 글로벌 AI 뉴스 웹 검색 수집 (10~20건) | High | Pending |
| FR-02 | 수집된 뉴스를 5개 카테고리로 분류 (모델/제품/연구/산업/규제) | High | Pending |
| FR-03 | 각 뉴스에 중요도 평가 (★★★/★★/★) | High | Pending |
| FR-04 | 영어 뉴스 한국어 번역 (제목·요약) + 원문 링크 유지 | High | Pending |
| FR-05 | URL 유효성 + 원문 교차검증 + 메타데이터 표시 (3단계 검증) | High | Pending |
| FR-06 | 정적 HTML 페이지 생성 (index.html 덮어쓰기 + archive/{date}.html) | High | Pending |
| FR-07 | git commit & push로 GitHub Pages 자동 배포 | High | Pending |
| FR-08 | Claude Code Remote Trigger로 매일 08:00 KST 자동 실행 | High | Pending |

### 5.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| 신뢰성 | 매일 08:00 ± 30분 이내 발행 | cron 실행 로그 확인 |
| 품질 | 할루시네이션 0건 (원문과 불일치 없음) | 3단계 검증 파이프라인 |
| 성능 | 전체 수집·생성·배포 10분 이내 완료 | 실행 시간 로그 |
| 가독성 | 5분 이내 전체 뉴스 훑어보기 가능 | 뉴스 10~20건 + 한줄 요약 |

---

## 6. Success Criteria

### 6.1 Definition of Done

- [ ] 3-Layer 검색으로 AI 뉴스 10~20건 수집
- [ ] 카테고리 분류·중요도 평가·한국어 번역 완료
- [ ] 3단계 할루시네이션 검증 통과
- [ ] 깔끔한 HTML 뉴스레터 페이지 생성
- [ ] GitHub Pages 배포 성공
- [ ] Claude Code cron 스케줄 등록 완료
- [ ] 3일 연속 자동 발행 성공 검증

### 6.2 Quality Criteria

- [ ] 모든 뉴스 링크 유효 (404 없음)
- [ ] 요약 내용과 원문 일치
- [ ] 중복 뉴스 0건
- [ ] 모바일 반응형 레이아웃

---

## 7. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| 웹 검색 결과 부족 (AI 뉴스 없는 날) | Medium | Low | 최소 뉴스 수 미달 시 "오늘은 주요 뉴스가 적습니다" 메시지 표시 |
| Claude Code Remote Trigger 실패 | High | Low | 수동 실행 가능한 스크립트 구성, 실패 시 재시도 로직 |
| 할루시네이션 검증에서 원문 접근 불가 | Medium | Medium | 접근 불가 시 해당 뉴스 제외, 검증 불가 표시 |
| GitHub Pages 배포 실패 | Medium | Low | git push 실패 시 재시도, 수동 배포 가이드 준비 |
| 웹 검색 비용 증가 | Low | Low | 검색 쿼리 수 제한 (최대 10회), 모니터링 |

---

## 8. Architecture Considerations

### 8.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | Simple structure (`components/`, `lib/`, `types/`) | Static sites, portfolios, landing pages | **v** |
| **Dynamic** | Feature-based modules, BaaS integration (bkend.ai) | Web apps with backend, SaaS MVPs, fullstack apps | |
| **Enterprise** | Strict layer separation, DI, microservices | High-traffic systems, complex architectures | |

### 8.2 Key Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| 뉴스 수집 방법 | RSS / API / WebSearch | WebSearch | 별도 API 키 불필요, Claude 내장 기능 활용 |
| 호스팅 | Vercel / Netlify / GitHub Pages | GitHub Pages | 무료, git push만으로 배포, 최소 설정 |
| 스케줄링 | GitHub Actions / cron / Claude Trigger | Claude Code Remote Trigger | 별도 인프라 불필요, Claude 생태계 내 통합 |
| 뉴스 언어 | 영어 원문 / 한국어 번역 | 한국어 번역 + 원문 링크 | 빠른 훑어보기 위해 한국어, 원문 접근성 유지 |
| 검증 방식 | 없음 / URL만 / 3단계 | 3단계 검증 | 할루시네이션 방지 최우선 |

### 8.3 Component Overview

```
ai-news/
├── site/
│   ├── index.html              # 오늘의 뉴스 (매일 덮어쓰기)
│   ├── style.css               # 뉴스레터 스타일시트
│   └── archive/
│       └── YYYY-MM-DD.html     # 날짜별 아카이브
├── scripts/
│   └── generate.md             # Claude agent 실행 프롬프트
├── templates/
│   └── news.html               # HTML 뉴스 템플릿
├── CLAUDE.md                   # 프로젝트 설정·규칙
└── docs/
    └── 01-plan/
        └── features/
            └── ai-news-daily.plan.md  # 이 문서
```

### 8.4 Data Flow

```
[Claude Code Remote Trigger — Cron 08:00 KST]
    │
    ▼
[3-Layer Web Search]
    ├── Layer 1: 권위 소스 직접 타겟
    │   "site:techcrunch.com AI", "site:theverge.com AI",
    │   "site:arxiv.org AI", "site:venturebeat.com AI"
    ├── Layer 2: 테마별 정밀 검색
    │   "OpenAI OR Anthropic OR Google DeepMind {today}",
    │   "AI startup funding {today}",
    │   "AI regulation policy {today}"
    └── Layer 3: 한국 AI 뉴스
        "AI 인공지능 뉴스", "네이버 카카오 AI"
    │
    ▼
[Raw Results: 30~50건]
    │
    ▼
[Claude 큐레이션]
    ├── 중복 제거
    ├── 관련성 필터 (AI 관련만)
    ├── 카테고리 분류 (모델/제품/연구/산업/규제)
    ├── 중요도 평가 (★★★/★★/★)
    └── 한줄 요약 + 한국어 번역
    │
    ▼
[할루시네이션 검증 파이프라인]
    ├── 1차: URL 유효성 검증 (WebFetch)
    ├── 2차: 원문 교차 검증 (요약 ↔ 원문 일치 확인)
    └── 3차: 메타데이터 필수 표기 (출처·날짜·원문링크)
    │
    ▼
[최종 뉴스: 10~20건]
    │
    ▼
[HTML 생성]
    ├── index.html 덮어쓰기 (오늘의 뉴스)
    └── archive/{date}.html 생성
    │
    ▼
[git add → commit → push]
    │
    ▼
[GitHub Pages 자동 배포 완료]
```

---

## 9. Convention Prerequisites

### 9.1 Applicable Conventions

- [ ] HTML/CSS 정적 사이트 (프레임워크 없음)
- [ ] 시맨틱 HTML5 마크업
- [ ] 반응형 디자인 (모바일 대응)
- [ ] 파일명 규칙: archive/{YYYY-MM-DD}.html
- [ ] Git 커밋 메시지: "chore: update ai news {date}"

---

## 10. Next Steps

1. [ ] Write design document (`/pdca design ai-news-daily`)
2. [ ] HTML 템플릿 디자인 확정
3. [ ] Claude agent 프롬프트 작성 (scripts/generate.md)
4. [ ] GitHub Pages 설정
5. [ ] Claude Code Remote Trigger cron 등록
6. [ ] 3일 연속 자동 발행 테스트

---

## Appendix: Brainstorming Log

> Key decisions from Plan Plus Phases 1-4.

| Phase | Question | Answer | Decision |
|-------|----------|--------|----------|
| Intent Q1 | 핵심 목적 | 개인 큐레이션 | 개인용 자동 뉴스 브리핑 |
| Intent Q2 | 전달 방식 | 웹 페이지 | GitHub Pages 정적 사이트 |
| Intent Q3 | 성공 기준 | 안정 발행 + 높은 품질 + 빠른 훑어보기 | 3가지 모두 MVP에 반영 |
| Alternatives | 3가지 접근법 비교 | Approach A 선택 | Claude Cron + Static Site (최소 인프라) |
| YAGNI | 기능 범위 | 4개 핵심 기능 모두 포함 | 이메일, RSS, 검색 등은 Out of Scope |
| Design 4-1 | 아키텍처 | 승인 | Cron → WebSearch → HTML → GitHub Pages |
| Design 4-2 | 컴포넌트 | 승인 | 5개 컴포넌트 구성 확정 |
| Design 4-3 | 데이터 흐름 | 검색 품질 개선 요청 | 3-Layer 검색 전략으로 업그레이드 |
| Design 추가 | 번역·검증 | 영어→한국어 번역 + 할루시네이션 검증 | 3단계 검증 파이프라인 추가 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-04-04 | Initial draft (Plan Plus) | leoheo |
