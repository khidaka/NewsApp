<!--
## Sync Impact Report

**Version Change**: (none — initial fill) → 1.0.0

### Modified Principles
- All principles: filled from template placeholders (new project, no prior values)

### Added Sections
- Core Principles (I–V)
- Technical Standards
- Development Workflow
- Governance

### Removed Sections
- None

### Templates Requiring Updates
- ✅ `.specify/templates/plan-template.md` — Constitution Check gate references are generic and remain valid
- ✅ `.specify/templates/spec-template.md` — No principle-specific sections; template is compatible
- ✅ `.specify/templates/tasks-template.md` — Task structure aligns with Test-First and user-story principles

### Deferred TODOs
- TODO(RATIFICATION_DATE): confirm original adoption date if this project was started before today
-->

# NewsApp Constitution

## Core Principles

### I. Content-First Architecture

Every feature MUST serve content delivery, discovery, or consumption. Features that do not
directly improve how users find, read, or interact with news articles require explicit
justification before implementation.

- Data models MUST be designed around articles, sources, and user reading behaviour
- APIs MUST be optimised for read-heavy workloads (news is read far more than written)
- Caching strategies MUST be considered at design time for every content-serving endpoint
- No feature adds complexity unless it improves the content experience

**Rationale**: A news app lives or dies by the quality of its content pipeline. Structural
decisions that compromise content delivery speed or reliability are prohibited.

### II. Performance & Reliability

The app MUST meet response-time and availability targets that match user expectations for
a live news product.

- Article list endpoints MUST respond in ≤200 ms (p95) under normal load
- The app MUST remain usable when upstream news sources are slow or unavailable (graceful
  degradation required)
- Background refresh MUST not block UI rendering
- Any feature that adds >50 ms latency to the critical reading path MUST be justified

**Rationale**: Users open news apps for timely information. Slow or unreliable experiences
cause permanent churn.

### III. Test-First Development (NON-NEGOTIABLE)

TDD is mandatory for all new features and bug fixes:

1. Write tests → get user approval → confirm tests fail → implement → confirm tests pass
2. Red-Green-Refactor cycle is strictly enforced
3. Unit tests MUST cover all business-logic services
4. Integration tests MUST cover all API endpoints and data-source adapters
5. No implementation task is marked complete until its tests pass

**Rationale**: News data pipelines have subtle edge cases (malformed feeds, encoding issues,
duplicate articles). Tests catch regressions before they reach users.

### IV. User Experience Excellence

The reading experience MUST be clean, fast, and distraction-free.

- Article views MUST render within 300 ms of navigation
- The app MUST support offline reading for previously fetched articles
- Accessibility (WCAG 2.1 AA) is a hard requirement, not a nice-to-have
- UI complexity MUST be justified: every new UI element requires a corresponding user scenario

**Rationale**: Readers choose news apps largely on reading comfort. UX regressions directly
impact retention.

### V. Simplicity & Maintainability

Start simple; introduce abstraction only when a concrete need repeats three or more times.

- YAGNI: do not implement features for hypothetical future requirements
- Each module or service MUST have a single, clearly named responsibility
- Dependencies MUST be evaluated for maintenance cost before adoption
- Complexity violations MUST be recorded in the plan's Complexity Tracking table

**Rationale**: News apps accumulate features quickly. A simple architecture keeps the
codebase navigable as the team and feature set grow.

## Technical Standards

- **Language/Runtime**: NEEDS CLARIFICATION — to be resolved during the first feature plan
- **Primary Framework**: NEEDS CLARIFICATION — determined per platform (web/mobile/API)
- **Data Sources**: RSS/Atom feeds, REST news APIs (e.g., NewsAPI), or scrapers — per feature spec
- **Storage**: NEEDS CLARIFICATION — relational DB preferred for article metadata; object store for
  assets
- **Testing Tools**: NEEDS CLARIFICATION — resolved per language during planning
- **API Style**: RESTful JSON by default; GraphQL only with explicit justification
- **Security**: All external data MUST be sanitised before storage or rendering; no raw HTML
  injection from feed content

## Development Workflow

- Feature branches follow the naming convention `###-feature-name` (sequential numbering)
- Every feature MUST have a `spec.md` before a `plan.md` is created
- `plan.md` MUST include a Constitution Check section that gates implementation
- Tasks in `tasks.md` MUST be ordered by user-story priority (P1 → P2 → P3)
- PRs require at least one reviewer and all CI checks passing before merge
- Commits after each logical task or checkpoint (auto-commit hooks are configured)
- Post-implementation: run the quickstart validation documented in `quickstart.md`

## Governance

This Constitution supersedes all other project practices. Amendments MUST:

1. Be proposed with a written rationale describing the problem solved
2. Increment the version according to semantic versioning (MAJOR/MINOR/PATCH)
3. Include a migration plan if existing features are affected
4. Update all dependent templates and runtime guidance documents

All PRs and design reviews MUST verify compliance with the Core Principles. Complexity
exceptions MUST be documented in the relevant plan's Complexity Tracking table before
implementation begins.

For runtime development guidance, refer to `CLAUDE.md` in the project root.

**Version**: 1.0.0 | **Ratified**: 2026-05-29 | **Last Amended**: 2026-05-29
