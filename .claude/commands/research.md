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

When this command is invoked, the user provides their research query as an argument (e.g., `/research How does authentication work?`). Begin research immediately.

1. **Read any directly mentioned files first:**
   - If the user mentions specific files, read them FULLY first
   - **IMPORTANT**: Use the Read tool WITHOUT limit/offset parameters to read entire files
   - **CRITICAL**: Read these files yourself in the main context before spawning any sub-tasks
   - This ensures you have full context before decomposing the research

2. **Analyze and decompose the research question:**
   - Break down the user's query into composable research areas
   - Identify specific components, patterns, or concepts to investigate
   - Create a research plan using TodoWrite to track all subtasks
   - Use concrete TodoWrite structure:
     ```
     1. [in_progress] Identify relevant components
     2. [pending] Research component A with finder agent
     3. [pending] Analyze component B with analyzer agent
     4. [pending] Synthesize findings
     5. [pending] Write research document
     ```
   - Consider which components are relevant:
     - Configuration files (JSON, YAML, TOML, etc.)
     - Source code (application logic, modules, classes)
     - Scripts (automation, build, deployment)
     - Tests (unit, integration, e2e)
     - Documentation (README, guides, API docs)
     - Infrastructure (Docker, CI/CD, deployment configs)

3. **Spawn parallel sub-agent tasks for comprehensive research:**
   - Create multiple Task agents to research different aspects concurrently
   - We have specialized agents for repository research:

   **For finding files and patterns:**
   - Use the **finder** agent (subagent_type="general-purpose") to:
     - Locate relevant files (WHERE)
     - Show code patterns (WHAT)
     - Extract implementation examples
     - Example prompt: "Find all API endpoint definitions in the codebase and show their implementation patterns"

   **For deep analysis:**
   - Use the **analyzer** agent (subagent_type="general-purpose") to:
     - Trace execution flows (HOW)
     - Analyze technical implementation details
     - Explain step-by-step processing
     - Example prompt: "Analyze how the authentication middleware works, tracing the complete flow from request to response"

   **For package and framework documentation:**
   - Use the **Skill** tool (core:hex-docs-search) to:
     - Research Hex packages (Phoenix, Ecto, Ash, Credo, Sobelow, etc.)
     - Find module and function documentation
     - Understand integration patterns
     - Example: "Research Phoenix.Router plug pipelines in hex docs"
   - Use Skill when you need official package documentation vs code search
   - Combine Skill research with finder/analyzer for comprehensive understanding

   **IMPORTANT**: All agents are documentarians, not critics. They will describe what exists without suggesting improvements or identifying issues.

   **Key principles:**
   - Start with finder to discover what exists
   - Use analyzer for deep understanding of how things work
   - Run multiple agents in parallel when researching different aspects
   - Each agent knows its job - be specific about what you're looking for
   - Remind agents they are documenting, not evaluating or improving

4. **Wait for all sub-agents to complete and synthesize findings:**
   - IMPORTANT: Wait for ALL sub-agent tasks to complete before proceeding
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
   - Get current date/time: `date -u +"%Y-%m-%d %H:%M:%S %Z"`
   - Get git info: `git log -1 --format="%H" && git branch --show-current && git config user.name`
   - Determine filename: `.thoughts/research-YYYY-MM-DD-topic-description.md`
     - Format: `.thoughts/research-YYYY-MM-DD-topic-description.md` where:
       - YYYY-MM-DD is today's date
       - topic-description is a brief kebab-case description
     - Examples:
       - `.thoughts/research-2025-01-23-authentication-flow.md`
       - `.thoughts/research-2025-01-23-api-endpoint-structure.md`
       - `.thoughts/research-2025-01-23-configuration-loading.md`

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
     tags: [research, relevant-topics]
     status: complete
     ---

     # Research: [User's Question/Topic]

     **Date**: [Current date and time]
     **Researcher**: [Git user name]
     **Git Commit**: [Current commit hash]
     **Branch**: [Current branch name]
     **Repository**: [Repository name]

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
   - Create the file at the determined path
   - Use the Write tool to create the document with all gathered information
   - Ensure all file references include line numbers
   - Include code snippets for key patterns

8. **Present findings:**
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

## Repository-Agnostic Research Considerations:

- **Configuration Files**: JSON, YAML, TOML, XML, INI, etc.
- **Source Code**: Language-specific files (.js, .ts, .py, .go, .rs, .ex, .java, etc.)
- **Build/Deployment**: Dockerfiles, CI/CD configs, Makefiles, package.json, etc.
- **Tests**: Unit tests, integration tests, e2e tests
- **Documentation**: README files, API docs, guides, wikis
- **Infrastructure**: Kubernetes configs, Terraform, deployment scripts
- **Data**: Database schemas, migrations, seed files

## Pattern Categories to Research:

- **Architecture Patterns**: MVC, microservices, layered architecture, event-driven
- **Data Handling**: Database access, caching, serialization, validation
- **API Patterns**: REST, GraphQL, RPC, endpoints, middleware
- **Authentication/Authorization**: Auth flows, session management, permissions
- **Error Handling**: Exception handling, logging, monitoring
- **Testing Patterns**: Test structure, mocking, fixtures
- **Build/Deployment**: CI/CD pipelines, containerization, orchestration
- **Configuration**: Config loading, environment variables, feature flags

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

**User**: `/research` then "How does authentication work in this application?"

**Process**:
1. Read any mentioned files
2. Create TodoWrite with research subtasks
3. Spawn parallel agents:
   - finder: "Find all authentication-related files and show their implementation patterns"
   - analyzer: "Analyze the authentication middleware, tracing the execution flow from request to verification"
4. Wait for completion
5. Synthesize findings into research document
6. Present summary with key patterns and file references

**User**: "How is the database configured?"

**Process**:
1. Spawn parallel agents:
   - finder: "Find all database configuration files and connection setup code"
   - analyzer: "Analyze how the database connection is established and configured"
2. Synthesize findings about config patterns, connection pooling, and initialization
3. Present comprehensive documentation with examples

**User**: "What testing frameworks are used and how are tests structured?"

**Process**:
1. Spawn parallel agents:
   - finder: "Find all test files and identify testing frameworks in use"
   - analyzer: "Analyze test structure, setup/teardown patterns, and assertion styles"
2. Synthesize findings about testing approach and conventions
3. Present documentation with test examples
