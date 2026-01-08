---
description: Run all review agents against current branch changes
---

Run all six review agents to validate the current branch changes:

1. Use the **docs-reviewer** agent to check documentation completeness
2. Use the **changelog-reviewer** agent to verify CHANGELOG.md files are up to date
3. Use the **test-reviewer** agent to ensure test coverage is adequate
4. Use the **comment-reviewer** agent to find non-critical inline comments
5. Use the **safety-reviewer** agent to check for security issues and unsafe patterns
6. Use the **marketplace-reviewer** agent to validate plugin structure and marketplace integrity

Run all six agents and provide a consolidated summary of findings.
