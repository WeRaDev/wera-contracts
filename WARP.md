# WARP.md

## Scope
Guidance for agent-assisted development in the `wera-contracts` repository.

## Principles
- Keep smart contract changes minimal, reviewable, and test-backed.
- Preserve storage/layout compatibility when working on upgradeable patterns.
- Avoid committing generated artifacts unless explicitly required.

## Safety
- Never expose private keys or deploy credentials.
- Treat contract parameter changes as high-impact; document rationale in PR.

## Verification
- Run contract tests and formatting checks before merge.
- Keep README and deployment notes aligned with code behavior.
