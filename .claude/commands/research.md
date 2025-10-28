---
description: Conduct comprehensive research across the repository to answer user questions
argument-hint: [research-query]
allowed-tools: Read, Grep, Glob, Task, Bash, TodoWrite, Write, Skill
---

# Research

You are tasked with conducting comprehensive research across the repository to answer user questions by spawning parallel sub-agents and synthesizing their findings.

## CRITICAL: YOUR ONLY JOB IS TO DOCUMENT AND EXPLAIN THE CODEBASE AS IT EXISTS TODAY
- DO NOT suggest improvements or changes unless the user explicitly asks for them
- DO NOT critique implementations or identify problems
- DO NOT recommend refactoring, optimization, or architectural changes
- ONLY describe what exists, where it exists, how it works, and how components interact
- You are creating technical documentation of the existing codebase

## Steps to Execute:

When this command is invoked, the user provides their research query as an argument (e.g., `/research How does the plugin system work?`). Begin research immediately.

1. **Read any directly mentioned files first:**
   - If the user mentions specific files, read them FULLY first
   - **IMPORTANT**: Use the Read tool WITHOUT limit/offset parameters to read entire files
   - **CRITICAL**: Read these files yourself in the main context before spawning any sub-tasks
   - This ensures you have full context before decomposing the research

2. **Analyze and decompose the research question:**
   - Break down the user's query into composable research areas
   - Identify specific components to investigate (plugins, hooks, marketplace, tests, scripts)
   - Create a research plan using TodoWrite to track all subtasks
   - Use concrete TodoWrite structure:
     ```
     1. [in_progress] Identify relevant components
     2. [pending] Research component A with finder agent
     3. [pending] Analyze component B with analyzer agent
     4. [pending] Synthesize findings
     5. [pending] Write research document
     ```
   - Mark first todo as completed, second as in_progress before spawning agents
   - Consider which components are relevant:
     - Marketplace structure (marketplace.json)
     - Plugin metadata (plugin.json files)
     - Hook definitions (hooks.json)
     - Hook scripts (bash scripts in plugins/*/scripts/)
     - Test infrastructure (test/plugins/*/test-*-hooks.sh)
     - Documentation (README.md, CLAUDE.md, plugin docs)
     - JSON schemas and validation
     - Integration patterns with Claude Code

3. **Spawn parallel sub-agent tasks for comprehensive research:**
   - Create multiple Task agents to research different aspects concurrently
   - We have specialized agents for repository research:

   **For finding files and patterns:**
   - Use the **finder** agent (subagent_type="general-purpose") to:
     - Locate relevant files (JSON configs, bash scripts, markdown docs)
     - Show implementation patterns
     - Extract examples
     - Example prompt: "Find all plugin.json files and show their structure and metadata patterns"

   **For deep analysis:**
   - Use the **analyzer** agent (subagent_type="general-purpose") to:
     - Trace execution flows (how hooks trigger and execute)
     - Analyze technical implementation details
     - Explain step-by-step processing
     - Example prompt: "Analyze how the core plugin's post-edit hook works, tracing the flow from file edit to hook execution"

   **IMPORTANT**: All agents are documentarians, not critics. They will describe what exists without suggesting improvements or identifying issues.

   **Key principles:**
   - Start with finder to discover what exists
   - Use analyzer for deep understanding of how things work
   - Run multiple agents in parallel when researching different aspects
   - Each agent knows its job - be specific about what you're looking for
   - Remind agents they are documenting, not evaluating or improving

4. **Wait for all sub-agents to complete and synthesize findings:**
   - IMPORTANT: Wait for ALL sub-agent tasks to complete before proceeding
   - Mark second todo as completed, third as in_progress
   - Compile all sub-agent results
   - Connect findings across different components
   - Include specific file paths and line numbers for reference
   - Highlight patterns, connections, and implementation decisions
   - Answer the user's specific questions with concrete evidence

   **Handling Sub-Agent Failures:**
   - If a sub-agent fails or times out, document what was attempted
   - Note which agents failed and why in the research document
   - Proceed with available information from successful agents
   - Mark gaps in coverage in the "Open Questions" section
   - Include error details in a "Research Limitations" section if significant

5. **Gather metadata for the research document:**
   - Mark third todo as completed, fourth as in_progress
   - Get current date/time: `date -u +"%Y-%m-%d %H:%M:%S %Z"`
   - Get git info: `git log -1 --format="%H" && git branch --show-current && git config user.name`
   - Determine filename: `.thoughts/research/research-YYYY-MM-DD-topic-description.md`
     - Format: `.thoughts/research/research-YYYY-MM-DD-topic-description.md` where:
       - YYYY-MM-DD is today's date
       - topic-description is a brief kebab-case description
     - Examples:
       - `.thoughts/research/research-2025-10-27-hook-architecture.md`
       - `.thoughts/research/research-2025-10-27-plugin-structure.md`
       - `.thoughts/research/research-2025-10-27-testing-patterns.md`

6. **Generate research document:**
   - Use the metadata gathered in step 5
   - Structure the document with YAML frontmatter followed by content:
     ```markdown
     ---
     date: [Current date and time in ISO format]
     researcher: [Git user name]
     commit: [Current commit hash]
     branch: [Current branch name]
     repository: [Repository name from git remote]
     topic: "[User's Question/Topic]"
     tags: [research, marketplace, plugins]
     status: complete
     ---

     # Research: [User's Question/Topic]

     **Date**: [Current date and time]
     **Researcher**: [Git user name]
     **Git Commit**: [Current commit hash]
     **Branch**: [Current branch name]
     **Repository**: [Repository name]
     **Project Type**: Claude Code Plugin Marketplace

     ## Research Question
     [Original user query]

     ## Summary
     [High-level overview of what was found, answering the user's question by describing what exists]

     ## Detailed Findings

     [Organize findings based on research type - adapt sections as needed]

     **For component/architecture research, use:**
     ### [Component/Pattern 1]
     - Description of what exists (`path/to/file.ext:7-10`)
     - How it works
     - Current implementation details (without evaluation)
     - Related components

     **For flow/process research, use:**
     ### Step 1: [Phase Name]
     - What happens (`path/to/file.ext:line`)
     - How data flows
     - Related handlers

     **For pattern/convention research, use:**
     ### Pattern: [Pattern Name]
     - Where it's used
     - How it's implemented
     - Examples with file:line references

     ## Code References
     [All relevant file:line references]
     - `path/to/file.ext:9` - [Brief description]
     - `path/to/another/file.ext:16-26` - [Brief description]

     ## [Optional: Implementation Patterns]
     [Include if patterns are central to the research]
     - Pattern 1: [Description]
     - Pattern 2: [Description]

     ## [Optional: Pattern Examples]
     [Include if code examples clarify findings]
     ```language
     // From path/to/file.ext:9
     code example here
     ```

     ## [Optional: Related Research]
     [Include if other research documents are relevant]

     ## [Optional: Open Questions]
     [Include if areas need further investigation]

     ## [Optional: Research Limitations]
     [Include if sub-agents failed or coverage was incomplete]
     ```

7. **Write the research document:**
   - Mark fourth todo as completed, fifth as in_progress
   - Create the file at the determined path
   - Use the Write tool to create the document with all gathered information
   - Ensure all file references include line numbers
   - Include code snippets for key patterns

8. **Present findings:**
   - Mark fifth todo as completed
   - Present a concise summary of findings to the user
   - Include key file references for easy navigation
   - Highlight discovered patterns and implementations
   - Ask if they have follow-up questions or need clarification

9. **Handle follow-up questions:**
   - If the user has follow-up questions, append to the same research document
   - Update the frontmatter fields `last_updated` and `last_updated_by`
   - Add `last_updated_note: "Added follow-up research for [brief description]"` to frontmatter
   - Add a new section: `## Follow-up Research [timestamp]`
   - Spawn new sub-agents as needed for additional investigation
   - Continue updating the document

## Marketplace-Specific Research Considerations:

- **Marketplace Structure**: marketplace.json, plugin metadata, versioning
- **Plugin Components**: plugin.json files, hook definitions (hooks.json), scripts
- **Hook Patterns**: PostToolUse/PreToolUse hooks, blocking vs non-blocking
- **Test Infrastructure**: test/plugins/*/test-*-hooks.sh, hook validation scripts
- **Plugin Scripts**: Bash scripts in plugins/*/scripts/, jq usage, exit codes
- **Documentation**: Plugin README.md files, marketplace README, CLAUDE.md
- **JSON Structure**: marketplace.json schema, plugin.json schema, hooks.json schema

## Pattern Categories to Research:

- **Hook Architecture**: How hooks trigger, JSON output patterns, permission decisions
- **Plugin Structure**: Directory layout, required files, metadata format
- **Testing Patterns**: Hook testing approach, exit code validation, output verification
- **Marketplace Patterns**: Plugin registration, namespace management, version control
- **Script Patterns**: File filtering, command matching, context passing, error handling
- **Validation Patterns**: JSON validation with jq, structure verification
- **Blocking vs Non-Blocking**: permissionDecision vs additionalContext patterns
- **Integration Patterns**: How plugins integrate with Claude Code, tool matching

## Important notes:
- Always use parallel Task agents to maximize efficiency
- Focus on finding concrete file paths and line numbers
- Research documents should be self-contained with all necessary context
- Each sub-agent prompt should be specific and focused on documentation
- Document cross-component connections and patterns
- Include code examples with file:line references
- Keep the main agent focused on synthesis, not deep analysis
- Have sub-agents document patterns as they exist
- **CRITICAL**: You and all sub-agents are documentarians, not evaluators
- **REMEMBER**: Document what IS, not what SHOULD BE
- **NO RECOMMENDATIONS**: Only describe the current state of the codebase
- **File reading**: Always read mentioned files FULLY before spawning sub-tasks
- **Critical ordering**: Follow the numbered steps exactly
  - ALWAYS read mentioned files first before spawning sub-tasks (step 1)
  - ALWAYS wait for all sub-agents to complete before synthesizing (step 4)
  - ALWAYS gather metadata before writing the document (step 5 before step 6)
  - NEVER write the research document with placeholder values
- **Frontmatter consistency**:
  - Always include frontmatter at the beginning
  - Keep frontmatter fields consistent
  - Update frontmatter when adding follow-up research
  - Use snake_case for multi-word field names
  - Tags should be relevant to topics studied

## Example Usage:

**User**: `/research` then "How does the plugin hook system work?"

**Process**:
1. Read any mentioned files
2. Create TodoWrite with research subtasks
3. Spawn parallel agents:
   - finder: "Find all hooks.json files and show their structure and hook definitions"
   - analyzer: "Analyze how hooks trigger and execute, tracing the flow from Claude Code event to hook script"
4. Wait for completion
5. Synthesize findings into research document
6. Present summary with key patterns and file references

**User**: "How is the marketplace structured?"

**Process**:
1. Spawn parallel agents:
   - finder: "Find marketplace.json and all plugin.json files showing the marketplace structure"
   - analyzer: "Analyze how plugins are registered and organized in the marketplace"
2. Synthesize findings about marketplace patterns and plugin organization
3. Present comprehensive documentation with examples

**User**: "What testing patterns are used for hook validation?"

**Process**:
1. Spawn parallel agents:
   - finder: "Find all test scripts and identify testing patterns"
   - analyzer: "Analyze how hooks are tested, including exit code validation and output verification"
2. Synthesize findings about testing approach and conventions
3. Present documentation with test examples
