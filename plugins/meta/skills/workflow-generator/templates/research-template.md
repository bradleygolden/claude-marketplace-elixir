---
description: Conduct comprehensive research across the Elixir repository to answer questions
argument-hint: [research-query]
allowed-tools: Read, Grep, Glob, Task, Bash, TodoWrite, Write, Skill
---

# Research

You are tasked with conducting comprehensive research across the Elixir repository to answer user questions by spawning parallel sub-agents and synthesizing their findings.

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
   - Identify specific Elixir modules, functions, or patterns to investigate
   - Create a research plan using TodoWrite to track all subtasks
   - Use concrete TodoWrite structure:
     ```
     1. [in_progress] Identify relevant Elixir modules and components
     2. [pending] Research component A with finder agent
     3. [pending] Analyze component B with analyzer agent
     4. [pending] Synthesize findings
     5. [pending] Write research document
     ```
   - Consider which Elixir components are relevant:
     - Mix configuration and dependencies
     - Application modules and supervision trees
     - Contexts (Phoenix) or domain modules
     - Schemas and Ecto queries
     - Controllers, LiveViews, and routes (Phoenix)
     - GenServers, Agents, and other processes
     - Tests (ExUnit)
     - Configuration files

3. **Spawn parallel sub-agent tasks for comprehensive research:**
   - Create multiple Task agents to research different aspects concurrently
   - We have specialized agents for repository research:

   **For finding files and patterns:**
   - Use the **finder** agent (subagent_type="general-purpose") to:
     - Locate relevant Elixir files (`.ex`, `.exs`)
     - Show code patterns (modules, functions, behaviours)
     - Extract implementation examples
     - Example prompt: "Find all {{PROJECT_TYPE_SPECIFIC}} in the codebase and show their implementation patterns"

   **For deep analysis:**
   - Use the **analyzer** agent (subagent_type="general-purpose") to:
     - Trace execution flows through Elixir modules
     - Analyze technical implementation details
     - Explain step-by-step processing
     - Example prompt: "Analyze how the authentication plug works, tracing the complete flow from request to response"

   **For package and framework documentation:**
   - Use **core:hex-docs-search** skill for API documentation:
     - Research Hex packages (Phoenix, Ecto, Ash, Credo, etc.)
     - Find module and function documentation
     - Understand API reference and integration patterns
     - Example: `Skill(command="core:hex-docs-search")` with prompt about Phoenix.Router
   - Use **core:usage-rules** skill for best practices:
     - Find package-specific coding conventions and patterns
     - See good/bad code examples from package maintainers
     - Understand common mistakes to avoid
     - Example: `Skill(command="core:usage-rules")` with prompt about Ash querying best practices
   - Use skills when you need official documentation/conventions vs code search
   - Combine skill research with finder/analyzer for comprehensive understanding

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
   - Connect findings across different Elixir modules and components
   - Include specific file paths and line numbers for reference
   - Highlight patterns, connections, and implementation decisions
   - Answer the user's specific questions with concrete evidence from the codebase

   **Handling Sub-Agent Failures:**
   - If a sub-agent fails or times out, document what was attempted
   - Note which agents failed and why in the research document
   - Proceed with available information from successful agents
   - Mark gaps in coverage in the "Open Questions" section
   - Include error details in a "Research Limitations" section if significant

5. **Gather metadata for the research document:**
   - Get current date/time: `date -u +"%Y-%m-%d %H:%M:%S %Z"`
   - Get git info: `git log -1 --format="%H" && git branch --show-current && git config user.name`
   - Determine filename: `{{DOCS_LOCATION}}/research-YYYY-MM-DD-topic-description.md`
     - Format: `{{DOCS_LOCATION}}/research-YYYY-MM-DD-topic-description.md` where:
       - YYYY-MM-DD is today's date
       - topic-description is a brief kebab-case description
     - Examples:
       - `{{DOCS_LOCATION}}/research-2025-01-23-authentication-flow.md`
       - `{{DOCS_LOCATION}}/research-2025-01-23-ecto-queries.md`
       - `{{DOCS_LOCATION}}/research-2025-01-23-phoenix-contexts.md`

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
     tags: [research, elixir, {{PROJECT_TYPE_TAGS}}]
     status: complete
     ---

     # Research: [User's Question/Topic]

     **Date**: [Current date and time]
     **Researcher**: [Git user name]
     **Git Commit**: [Current commit hash]
     **Branch**: [Current branch name]
     **Repository**: [Repository name]
     **Project Type**: {{PROJECT_TYPE}}

     ## Research Question
     [Original user query]

     ## Summary
     [High-level overview of what was found, answering the user's question by describing what exists in the Elixir codebase]

     ## Detailed Findings

     [Organize findings based on research type - adapt sections as needed]

     **For module/component research, use:**
     ### [Module/Component 1]
     - Description of what exists (`path/to/file.ex:7-10`)
     - How it works
     - Current implementation details (without evaluation)
     - Related modules and dependencies

     **For flow/process research, use:**
     ### Step 1: [Phase Name]
     - What happens (`path/to/file.ex:line`)
     - How data flows through the pipeline
     - Related handlers and processes

     **For pattern/convention research, use:**
     ### Pattern: [Pattern Name]
     - Where it's used in the codebase
     - How it's implemented
     - Examples with file:line references

     ## Code References
     [All relevant file:line references from Elixir files]
     - `lib/my_app/accounts/user.ex:9` - [Brief description]
     - `lib/my_app_web/controllers/session_controller.ex:16-26` - [Brief description]

     ## [Optional: Implementation Patterns]
     [Include if Elixir patterns are central to the research]
     - Pattern 1: [Description]
     - Pattern 2: [Description]

     ## [Optional: Pattern Examples]
     [Include if code examples clarify findings]
     ```elixir
     # From lib/my_app/accounts.ex:9
     def get_user(id) do
       # implementation
     end
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
   - Include Elixir code snippets for key patterns

8. **Present findings:**
   - Present a concise summary of findings to the user
   - Include key file references for easy navigation (module:line format)
   - Highlight discovered patterns and implementations
   - Ask if they have follow-up questions or need clarification

9. **Handle follow-up questions:**
   - If the user has follow-up questions, append to the same research document
   - Update the frontmatter fields `last_updated` and `last_updated_by`
   - Add `last_updated_note: "Added follow-up research for [brief description]"` to frontmatter
   - Add a new section: `## Follow-up Research [timestamp]`
   - Spawn new sub-agents as needed for additional investigation
   - Continue updating the document

## Elixir-Specific Research Considerations:

- **Mix Project Structure**: config/, lib/, test/, priv/, mix.exs
- **Application Modules**: Application start, supervision trees, workers
- **Contexts** (Phoenix): Bounded contexts, public API functions
- **Schemas**: Ecto schemas, changesets, validations
- **Controllers/LiveViews** (Phoenix): Request handling, renders, assigns
- **Queries**: Ecto queries, Repo operations
- **GenServers/Agents**: Process-based state, message handling
- **Plugs**: Middleware, request transformation
- **Tests**: ExUnit tests, test helpers, fixtures
- **Configuration**: Config files, runtime config, environment variables

## Pattern Categories to Research:

- **Supervision Patterns**: Supervisor trees, restart strategies, child specs
- **Data Handling**: Ecto schemas, queries, transactions, changesets
- **Phoenix Patterns**: Contexts, controllers, LiveView, channels
- **Process Patterns**: GenServer, Agent, Task, GenStage
- **Authentication/Authorization**: Plugs, Guardian, Pow, custom auth
- **Error Handling**: {:ok, result}/{:error, reason}, with blocks, error tracking
- **Testing Patterns**: ExUnit, mocks (Mox), fixtures, factories
- **API Patterns**: JSON APIs, GraphQL (Absinthe), REST endpoints

## Important notes:
- Always use parallel Task agents to maximize efficiency
- Focus on finding concrete file paths and line numbers for Elixir modules
- Research documents should be self-contained with all necessary context
- Each sub-agent prompt should be specific and focused on documentation
- Document cross-module connections and patterns
- Include Elixir code examples with file:line references
- Keep the main agent focused on synthesis, not deep analysis
- Have sub-agents document Elixir patterns as they exist
- **CRITICAL**: You and all sub-agents are documentarians, not evaluators
- **REMEMBER**: Document what IS, not what SHOULD BE
- **NO RECOMMENDATIONS**: Only describe the current state of the Elixir codebase
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
  - Tags should include elixir and project-type specific tags

## Example Usage:

**User**: `/research` then "How does authentication work in this application?"

**Process**:
1. Read any mentioned files
2. Create TodoWrite with research subtasks
3. Spawn parallel agents:
   - finder: "Find all authentication-related modules and show their implementation patterns"
   - analyzer: "Analyze the authentication plug, tracing the execution flow from request to verification"
   - Skill: Search hex docs for Guardian/Pow/relevant auth library
4. Wait for completion
5. Synthesize findings into research document
6. Present summary with key patterns and file references

**User**: "How are Ecto queries structured in this codebase?"

**Process**:
1. Spawn parallel agents:
   - finder: "Find all Ecto query modules and show their query patterns"
   - analyzer: "Analyze how queries are composed and executed in the main contexts"
2. Synthesize findings about query patterns, composition, and Repo usage
3. Present comprehensive documentation with Elixir examples

**User**: "What LiveView components are used and how are they structured?"

**Process**:
1. Spawn parallel agents:
   - finder: "Find all LiveView modules and identify component patterns"
   - analyzer: "Analyze LiveView lifecycle, handle_event patterns, and assign management"
2. Synthesize findings about LiveView approach and conventions
3. Present documentation with LiveView examples
