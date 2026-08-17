import { Tool } from "@modelcontextprotocol/sdk/types.js";

export const TOOLS: Tool[] = [
  {
    name: "list_workspaces",
    description: "List all Bitbucket workspaces accessible by the authenticated user. Returns workspace names, slugs, and descriptions.",
    inputSchema: {
      type: "object",
      properties: {},
    },
  },
  {
    name: "list_repositories",
    description: "List all repositories in a Bitbucket workspace. Returns repository names, slugs, descriptions, and links.",
    inputSchema: {
      type: "object",
      properties: {
        workspace: {
          type: "string",
          description: "The workspace slug (e.g., 'my-team'). Optional if BITBUCKET_WORKSPACE env var is set.",
        },
      },
      required: [],
    },
  },
  {
    name: "get_repository",
    description: "Get detailed information about a specific repository including its description, language, size, and URLs.",
    inputSchema: {
      type: "object",
      properties: {
        workspace: {
          type: "string",
          description: "The workspace slug. Optional if BITBUCKET_WORKSPACE env var is set.",
        },
        repo_slug: {
          type: "string",
          description: "The repository slug (e.g., 'my-repo').",
        },
      },
      required: ["repo_slug"],
    },
  },
  {
    name: "list_branches",
    description: "List all branches in a repository. Returns branch names and latest commit hashes.",
    inputSchema: {
      type: "object",
      properties: {
        workspace: {
          type: "string",
          description: "The workspace slug. Optional if BITBUCKET_WORKSPACE env var is set.",
        },
        repo_slug: {
          type: "string",
          description: "The repository slug.",
        },
      },
      required: ["repo_slug"],
    },
  },
  {
    name: "list_commits",
    description: "List recent commits in a repository, optionally filtered by branch. Returns commit messages, authors, dates, and hashes.",
    inputSchema: {
      type: "object",
      properties: {
        workspace: {
          type: "string",
          description: "The workspace slug. Optional if BITBUCKET_WORKSPACE env var is set.",
        },
        repo_slug: {
          type: "string",
          description: "The repository slug.",
        },
        branch: {
          type: "string",
          description: "The branch name or commit hash to list commits from. Defaults to the main branch.",
        },
      },
      required: ["repo_slug"],
    },
  },
  {
    name: "get_commit",
    description: "Get detailed information about a specific commit including author, message, date, and files changed.",
    inputSchema: {
      type: "object",
      properties: {
        workspace: {
          type: "string",
          description: "The workspace slug. Optional if BITBUCKET_WORKSPACE env var is set.",
        },
        repo_slug: {
          type: "string",
          description: "The repository slug.",
        },
        commit_id: {
          type: "string",
          description: "The commit hash (SHA).",
        },
      },
      required: ["repo_slug", "commit_id"],
    },
  },
  {
    name: "browse_directory",
    description: "Browse the contents of a directory in a repository. Returns file and folder names, types, and paths. Use this to explore the repository structure.",
    inputSchema: {
      type: "object",
      properties: {
        workspace: {
          type: "string",
          description: "The workspace slug. Optional if BITBUCKET_WORKSPACE env var is set.",
        },
        repo_slug: {
          type: "string",
          description: "The repository slug.",
        },
        path: {
          type: "string",
          description: "The directory path to browse (e.g., 'src/components'). Use empty string or '/' for root.",
        },
        branch: {
          type: "string",
          description: "The branch name. Defaults to the main branch.",
        },
      },
      required: ["repo_slug"],
    },
  },
  {
    name: "get_file_content",
    description: "Read the full content of a file in a repository. Returns the raw file content as text. Use this to read source code files.",
    inputSchema: {
      type: "object",
      properties: {
        workspace: {
          type: "string",
          description: "The workspace slug. Optional if BITBUCKET_WORKSPACE env var is set.",
        },
        repo_slug: {
          type: "string",
          description: "The repository slug.",
        },
        path: {
          type: "string",
          description: "The file path (e.g., 'src/index.ts').",
        },
        branch: {
          type: "string",
          description: "The branch name. Defaults to the main branch.",
        },
      },
      required: ["repo_slug", "path"],
    },
  },
  {
    name: "search_code",
    description: "Search for code across a repository using Bitbucket's code search. Returns matching files and snippet previews.",
    inputSchema: {
      type: "object",
      properties: {
        workspace: {
          type: "string",
          description: "The workspace slug. Optional if BITBUCKET_WORKSPACE env var is set.",
        },
        repo_slug: {
          type: "string",
          description: "The repository slug.",
        },
        query: {
          type: "string",
          description: "The search query string.",
        },
      },
      required: ["repo_slug", "query"],
    },
  },
  {
    name: "get_pull_requests",
    description: "List pull requests in a repository. Returns PR titles, authors, states, and descriptions.",
    inputSchema: {
      type: "object",
      properties: {
        workspace: {
          type: "string",
          description: "The workspace slug. Optional if BITBUCKET_WORKSPACE env var is set.",
        },
        repo_slug: {
          type: "string",
          description: "The repository slug.",
        },
        state: {
          type: "string",
          enum: ["OPEN", "MERGED", "DECLINED", "SUPERSEDED"],
          description: "Filter by PR state. Defaults to OPEN.",
        },
      },
      required: ["repo_slug"],
    },
  },
  {
    name: "get_readme",
    description: "Fetch and read the README file of a repository. Automatically finds README.md, README.txt, or readme.rst.",
    inputSchema: {
      type: "object",
      properties: {
        workspace: {
          type: "string",
          description: "The workspace slug. Optional if BITBUCKET_WORKSPACE env var is set.",
        },
        repo_slug: {
          type: "string",
          description: "The repository slug.",
        },
        branch: {
          type: "string",
          description: "The branch name. Defaults to the main branch.",
        },
      },
      required: ["repo_slug"],
    },
  },
  {
    name: "get_commit_diff",
    description: "Get the diff/patch of a specific commit showing all changes made. Returns unified diff format.",
    inputSchema: {
      type: "object",
      properties: {
        workspace: {
          type: "string",
          description: "The workspace slug. Optional if BITBUCKET_WORKSPACE env var is set.",
        },
        repo_slug: {
          type: "string",
          description: "The repository slug.",
        },
        commit_id: {
          type: "string",
          description: "The commit hash (SHA).",
        },
      },
      required: ["repo_slug", "commit_id"],
    },
  },
];