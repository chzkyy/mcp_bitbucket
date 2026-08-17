# Bitbucket MCP Server

A Model Context Protocol (MCP) server for Bitbucket that allows MCP-compatible clients (such as Claude Desktop) to read repositories and source code from your Bitbucket workspace.

## Features

This server provides the following tools:

| Tool | Description |
|------|-------------|
| `list_workspaces` | List all Bitbucket workspaces accessible by your account |
| `list_repositories` | List repositories in a workspace |
| `get_repository` | Get repository details |
| `list_branches` | List branches in a repository |
| `list_commits` | List commit history |
| `get_commit` | Get details for a specific commit |
| `browse_directory` | Browse repository directory structure |
| `get_file_content` | Read file contents |
| `search_code` | Search code in a repository |
| `get_pull_requests` | List pull requests |
| `get_readme` | Read a repository README |
| `get_commit_diff` | Show commit diff |

## Prerequisites

1. **Node.js** 18 or newer
2. **Bitbucket account** with access to the repositories you want to read
3. **Bitbucket App Password** (do not use your regular account password)

## Create a Bitbucket App Password

1. Sign in to [Bitbucket](https://bitbucket.org)
2. Click your avatar (bottom-right) → **Personal settings**
3. Open **App passwords** in the left menu
4. Click **Create app password**
5. Add a label (for example: `MCP Server`)
6. Grant the following permissions:
   - **Repositories**: `Read`
   - **Pull requests**: `Read`
   - **Workspace**: `Read`
7. Click **Create** and save the generated password (it is shown only once)

## Installation

```bash
# Clone or enter the project folder
cd d:\Projects\Pribadi\MCP_bitbucket

# Install dependencies
npm install

# Build
npm run build
```

## Configure Claude Desktop

### 1) Open Claude Desktop config file

**Windows**

```text
%APPDATA%\Claude\claude_desktop_config.json
```

**macOS**

```text
~/Library/Application Support/Claude/claude_desktop_config.json
```

### 2) Add MCP server configuration

Add this entry to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "bitbucket": {
      "command": "node",
      "args": ["d:\\Projects\\Pribadi\\MCP_bitbucket\\dist\\index.js"],
      "env": {
        "BITBUCKET_USERNAME": "your-bitbucket-username",
        "BITBUCKET_APP_PASSWORD": "your-app-password",
        "BITBUCKET_WORKSPACE": "your-workspace-slug"
      }
    }
  }
}
```

Notes:
- Replace `your-bitbucket-username` with your Bitbucket username
- Replace `your-app-password` with your Bitbucket App Password
- Replace `your-workspace-slug` with your workspace slug (optional; you can also pass workspace as a tool parameter)
- Use double backslashes (`\\`) in Windows paths

### 3) Restart Claude Desktop

Close and reopen Claude Desktop so it can load the MCP server.

## Usage Examples

After setup, you can ask Claude:

- "List all repositories in my workspace"
- "Read `src/index.ts` from repository `my-project`"
- "Show the folder structure of repository `backend-api`"
- "Search for `validateUser` usage in repository `auth-service`"
- "Show recent commits from branch `develop`"
- "Read README from repository `frontend-app`"
- "Show open pull requests"

## Development

```bash
# Build
npm run build

# Run manually (for testing)
BITBUCKET_USERNAME=user BITBUCKET_APP_PASSWORD=pass npm start
```

## Project Structure

```text
MCP_bitbucket/
├── src/
│   ├── index.ts              # Entry point and MCP server setup
│   ├── bitbucket-client.ts   # Bitbucket API client
│   └── tools.ts              # MCP tool definitions
├── dist/                     # Compiled JavaScript output
├── package.json
├── tsconfig.json
└── README.md
```

## Security

- Store App Password in environment variables, not in source code
- Use read-only permissions whenever possible
- All communication uses HTTPS
- Never commit credentials into the repository
