#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { BitbucketClient } from "./bitbucket-client.js";
import { TOOLS } from "./tools.js";

// Load configuration from environment variables
const BITBUCKET_USERNAME = process.env.BITBUCKET_USERNAME;
const BITBUCKET_APP_PASSWORD = process.env.BITBUCKET_APP_PASSWORD;
const BITBUCKET_WORKSPACE = process.env.BITBUCKET_WORKSPACE;

if (!BITBUCKET_USERNAME || !BITBUCKET_APP_PASSWORD) {
  console.error("Error: BITBUCKET_USERNAME and BITBUCKET_APP_PASSWORD environment variables are required");
  process.exit(1);
}

const client = new BitbucketClient({
  username: BITBUCKET_USERNAME,
  appPassword: BITBUCKET_APP_PASSWORD,
  workspace: BITBUCKET_WORKSPACE,
});

// Create MCP Server
const server = new Server(
  {
    name: "bitbucket-mcp-server",
    version: "1.0.1",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: TOOLS,
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    let result: string;

    switch (name) {
      case "list_workspaces":
        result = await client.listWorkspaces();
        break;

      case "list_repositories":
        result = await client.listRepositories(
          (args?.workspace as string) || BITBUCKET_WORKSPACE || ""
        );
        break;

      case "get_repository":
        result = await client.getRepository(
          (args?.workspace as string) || BITBUCKET_WORKSPACE || "",
          args?.repo_slug as string
        );
        break;

      case "list_branches":
        result = await client.listBranches(
          (args?.workspace as string) || BITBUCKET_WORKSPACE || "",
          args?.repo_slug as string
        );
        break;

      case "list_commits":
        result = await client.listCommits(
          (args?.workspace as string) || BITBUCKET_WORKSPACE || "",
          args?.repo_slug as string,
          args?.branch as string
        );
        break;

      case "get_commit":
        result = await client.getCommit(
          (args?.workspace as string) || BITBUCKET_WORKSPACE || "",
          args?.repo_slug as string,
          args?.commit_id as string
        );
        break;

      case "browse_directory":
        result = await client.browseDirectory(
          (args?.workspace as string) || BITBUCKET_WORKSPACE || "",
          args?.repo_slug as string,
          args?.path as string,
          args?.branch as string
        );
        break;

      case "get_file_content":
        result = await client.getFileContent(
          (args?.workspace as string) || BITBUCKET_WORKSPACE || "",
          args?.repo_slug as string,
          args?.path as string,
          args?.branch as string
        );
        break;

      case "search_code":
        result = await client.searchCode(
          (args?.workspace as string) || BITBUCKET_WORKSPACE || "",
          args?.repo_slug as string,
          args?.query as string
        );
        break;

      case "get_pull_requests":
        result = await client.getPullRequests(
          (args?.workspace as string) || BITBUCKET_WORKSPACE || "",
          args?.repo_slug as string,
          args?.state as string
        );
        break;

      case "get_readme":
        result = await client.getReadme(
          (args?.workspace as string) || BITBUCKET_WORKSPACE || "",
          args?.repo_slug as string,
          args?.branch as string
        );
        break;

      case "get_commit_diff":
        result = await client.getCommitDiff(
          (args?.workspace as string) || BITBUCKET_WORKSPACE || "",
          args?.repo_slug as string,
          args?.commit_id as string
        );
        break;

      default:
        throw new Error(`Unknown tool: ${name}`);
    }

    return {
      content: [
        {
          type: "text",
          text: result,
        },
      ],
    };
  } catch (error: any) {
    const isTimeout =
      error.code === "ECONNABORTED" ||
      error.code === "ETIMEDOUT" ||
      (error.message && error.message.toLowerCase().includes("timeout"));

    const errorMessage = isTimeout
      ? `Request timed out while contacting Bitbucket API. The file may be large or the network is slow. Please try again or try a smaller file/path.`
      : `Error: ${error.message || String(error)}`;

    return {
      content: [
        {
          type: "text",
          text: errorMessage,
        },
      ],
      isError: true,
    };
  }
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Bitbucket MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});