import axios, { AxiosInstance } from "axios";

export interface BitbucketConfig {
  username: string;
  appPassword: string;
  workspace?: string;
}

interface SearchResponse {
  values: any[];
  next?: string;
}

export class BitbucketClient {
  private client: AxiosInstance;
  private workspace?: string;
  private static readonly BASE_URL = "https://api.bitbucket.org/2.0";

  constructor(config: BitbucketConfig) {
    const auth = Buffer.from(`${config.username}:${config.appPassword}`).toString("base64");
    this.client = axios.create({
      baseURL: BitbucketClient.BASE_URL,
      headers: {
        Authorization: `Basic ${auth}`,
        Accept: "application/json",
      },
      timeout: 30000,
    });
    this.workspace = config.workspace;
  }

  private async paginate<T>(url: string, maxPages: number = 5): Promise<T[]> {
    const results: T[] = [];
    let nextUrl: string | undefined = url;
    let pageCount = 0;

    while (nextUrl && pageCount < maxPages) {
      const response = await this.client.get<SearchResponse>(nextUrl);
      if (response.data.values) {
        results.push(...response.data.values);
      }
      nextUrl = response.data.next;
      pageCount++;
    }

    return results;
  }

  private formatSize(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(2)} KB`;
    if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
  }

  async listWorkspaces(): Promise<string> {
    try {
      const workspaces = await this.paginate<any>("/workspaces");
      if (workspaces.length === 0) {
        return "No workspaces found.";
      }

      const formatted = workspaces.map((ws) => {
        const name = ws.name || "N/A";
        const slug = ws.slug || "N/A";
        const isPrivate = ws.is_private ? "Private" : "Public";
        const desc = ws.description ? `\n     Description: ${ws.description}` : "";
        return `  • ${name} (slug: ${slug}) [${isPrivate}]${desc}`;
      });

      return `## Bitbucket Workspaces (${workspaces.length} found)\n\n${formatted.join("\n\n")}`;
    } catch (error: any) {
      throw new Error(`Failed to list workspaces: ${error.response?.data?.error?.message || error.message}`);
    }
  }

  async listRepositories(workspace: string): Promise<string> {
    const ws = workspace || this.workspace;
    if (!ws) {
      throw new Error("Workspace is required. Provide it as a parameter or set BITBUCKET_WORKSPACE env var.");
    }

    try {
      const repos = await this.paginate<any>(`/repositories/${ws}`);
      if (repos.length === 0) {
        return `No repositories found in workspace '${ws}'.`;
      }

      const formatted = repos.map((repo) => {
        const name = repo.name || "N/A";
        const slug = repo.slug || "N/A";
        const language = repo.language || "Unknown";
        const isPrivate = repo.is_private ? "Private" : "Public";
        const desc = repo.description ? `\n     Description: ${repo.description}` : "";
        const updated = repo.updated_on ? `\n     Last updated: ${new Date(repo.updated_on).toLocaleDateString()}` : "";
        return `  • ${name} (slug: ${slug})\n     Language: ${language} | ${isPrivate}${desc}${updated}`;
      });

      return `## Repositories in '${ws}' (${repos.length} found)\n\n${formatted.join("\n\n")}`;
    } catch (error: any) {
      throw new Error(`Failed to list repositories: ${error.response?.data?.error?.message || error.message}`);
    }
  }

  async getRepository(workspace: string, repoSlug: string): Promise<string> {
    const ws = workspace || this.workspace;
    if (!ws) {
      throw new Error("Workspace is required.");
    }
    if (!repoSlug) {
      throw new Error("Repository slug is required.");
    }

    try {
      const response = await this.client.get(`/repositories/${ws}/${repoSlug}`);
      const repo = response.data;

      const lines = [
        `## Repository: ${repo.name}`,
        ``,
        `**Slug:** ${repo.slug}`,
        `**UUID:** ${repo.uuid}`,
        `**Description:** ${repo.description || "N/A"}`,
        `**Language:** ${repo.language || "Unknown"}`,
        `**Size:** ${this.formatSize(repo.size || 0)}`,
        `**Visibility:** ${repo.is_private ? "Private" : "Public"}`,
        `**Created:** ${repo.created_on ? new Date(repo.created_on).toLocaleString() : "N/A"}`,
        `**Updated:** ${repo.updated_on ? new Date(repo.updated_on).toLocaleString() : "N/A"}`,
        `**Main Branch:** ${repo.mainbranch?.name || "N/A"}`,
        `**Web URL:** ${repo.links?.html?.href || "N/A"}`,
        `**Clone URLs:**`,
      ];

      if (repo.links?.clone) {
        repo.links.clone.forEach((c: any) => {
          lines.push(`  - ${c.name}: ${c.href}`);
        });
      }

      return lines.join("\n");
    } catch (error: any) {
      throw new Error(`Failed to get repository: ${error.response?.data?.error?.message || error.message}`);
    }
  }

  async listBranches(workspace: string, repoSlug: string): Promise<string> {
    const ws = workspace || this.workspace;
    if (!ws) {
      throw new Error("Workspace is required.");
    }
    if (!repoSlug) {
      throw new Error("Repository slug is required.");
    }

    try {
      const branches = await this.paginate<any>(`/repositories/${ws}/${repoSlug}/refs/branches?sort=-target.date`);
      if (branches.length === 0) {
        return `No branches found in '${ws}/${repoSlug}'.`;
      }

      const formatted = branches.map((branch) => {
        const name = branch.name || "N/A";
        const commitHash = branch.target?.hash || "N/A";
        const shortHash = commitHash.substring(0, 7);
        const date = branch.target?.date
          ? new Date(branch.target.date).toLocaleDateString()
          : "N/A";
        return `  • ${name} (commit: ${shortHash}, date: ${date})`;
      });

      return `## Branches in '${ws}/${repoSlug}' (${branches.length} found)\n\n${formatted.join("\n")}`;
    } catch (error: any) {
      throw new Error(`Failed to list branches: ${error.response?.data?.error?.message || error.message}`);
    }
  }

  async listCommits(workspace: string, repoSlug: string, branch?: string): Promise<string> {
    const ws = workspace || this.workspace;
    if (!ws) {
      throw new Error("Workspace is required.");
    }
    if (!repoSlug) {
      throw new Error("Repository slug is required.");
    }

    try {
      let url = `/repositories/${ws}/${repoSlug}/commits`;
      if (branch) {
        url += `/${branch}`;
      }
      const commits = await this.paginate<any>(url, 2);

      if (commits.length === 0) {
        return `No commits found in '${ws}/${repoSlug}'.`;
      }

      const formatted = commits.map((commit) => {
        const hash = (commit.hash || "N/A").substring(0, 7);
        const message = (commit.message || "N/A").split("\n")[0];
        const author = commit.author?.raw || commit.author?.user?.display_name || "N/A";
        const date = commit.date ? new Date(commit.date).toLocaleString() : "N/A";
        return `  • ${hash} - ${message}\n    Author: ${author} | Date: ${date}`;
      });

      return `## Recent Commits in '${ws}/${repoSlug}'${branch ? ` (branch: ${branch})` : ""}\n\n${formatted.join("\n\n")}`;
    } catch (error: any) {
      throw new Error(`Failed to list commits: ${error.response?.data?.error?.message || error.message}`);
    }
  }

  async getCommit(workspace: string, repoSlug: string, commitId: string): Promise<string> {
    const ws = workspace || this.workspace;
    if (!ws) {
      throw new Error("Workspace is required.");
    }
    if (!repoSlug) {
      throw new Error("Repository slug is required.");
    }
    if (!commitId) {
      throw new Error("Commit ID is required.");
    }

    try {
      const response = await this.client.get(`/repositories/${ws}/${repoSlug}/commit/${commitId}`);
      const commit = response.data;

      const lines = [
        `## Commit: ${commit.hash}`,
        ``,
        `**Author:** ${commit.author?.raw || "N/A"}`,
        `**Date:** ${commit.date ? new Date(commit.date).toLocaleString() : "N/A"}`,
        `**Message:**`,
        commit.message || "N/A",
        ``,
      ];

      if (commit.summary) {
        lines.push(`**Summary:** ${commit.summary.markup || commit.summary.raw || "N/A"}`);
      }

      return lines.join("\n");
    } catch (error: any) {
      throw new Error(`Failed to get commit: ${error.response?.data?.error?.message || error.message}`);
    }
  }

  async browseDirectory(
    workspace: string,
    repoSlug: string,
    path: string = "",
    branch?: string
  ): Promise<string> {
    const ws = workspace || this.workspace;
    if (!ws) {
      throw new Error("Workspace is required.");
    }
    if (!repoSlug) {
      throw new Error("Repository slug is required.");
    }

    try {
      const cleanPath = path.replace(/^\/+|\/+$/g, "");
      let url = `/repositories/${ws}/${repoSlug}/src`;
      url += branch ? `/${branch}` : `/${await this.getDefaultBranch(ws, repoSlug)}`;
      url += cleanPath ? `/${cleanPath}` : "";
      url += `?fields=values.path,values.type,values.size,values.links.self`;

      const response = await this.client.get(url);
      const entries = response.data.values || [];

      if (entries.length === 0) {
        return `Directory '${path}' is empty or does not exist in '${ws}/${repoSlug}'.`;
      }

      const directories = entries
        .filter((e: any) => e.type === "commit_directory")
        .map((d: any) => `  📁 ${d.path}/`);
      const files = entries
        .filter((e: any) => e.type === "commit_file")
        .map((f: any) => {
          const size = f.size ? ` (${this.formatSize(f.size)})` : "";
          return `  📄 ${f.path}${size}`;
        });

      const allEntries = [...directories, ...files];

      const branchInfo = branch || await this.getDefaultBranch(ws, repoSlug);
      return `## Contents of '${path || "/"}' in '${ws}/${repoSlug}' (branch: ${branchInfo})\n\n${allEntries.join("\n")}`;
    } catch (error: any) {
      throw new Error(`Failed to browse directory: ${error.response?.data?.error?.message || error.message}`);
    }
  }

  async getFileContent(
    workspace: string,
    repoSlug: string,
    path: string,
    branch?: string
  ): Promise<string> {
    const ws = workspace || this.workspace;
    if (!ws) {
      throw new Error("Workspace is required.");
    }
    if (!repoSlug) {
      throw new Error("Repository slug is required.");
    }
    if (!path) {
      throw new Error("File path is required.");
    }

    try {
      const cleanPath = path.replace(/^\/+/, "");
      const ref = branch || await this.getDefaultBranch(ws, repoSlug);
      const url = `/repositories/${ws}/${repoSlug}/src/${ref}/${cleanPath}`;

      const response = await this.client.get(url, {
        responseType: "text",
        transformResponse: [(data) => data],
      });

      const fileContent = response.data as string;
      const fileName = path.split("/").pop() || path;
      const extension = fileName.split(".").pop()?.toLowerCase() || "";

      const header = `## File: ${path} (branch: ${ref})\n**Size:** ${this.formatSize(Buffer.byteLength(fileContent))}\n\n`;

      // Determine language for markdown code fence
      const langMap: { [key: string]: string } = {
        ts: "typescript", tsx: "typescript", js: "javascript", jsx: "javascript",
        py: "python", java: "java", go: "go", rb: "ruby", php: "php",
        c: "c", cpp: "cpp", cs: "csharp", rs: "rust", swift: "swift",
        kt: "kotlin", scala: "scala", sh: "bash", yml: "yaml", yaml: "yaml",
        json: "json", xml: "xml", html: "html", css: "css", scss: "scss",
        sql: "sql", md: "markdown", txt: "text", dockerfile: "dockerfile",
      };

      const lang = langMap[extension] || "";

      return `${header}\`\`\`${lang}\n${fileContent}\n\`\`\``;
    } catch (error: any) {
      throw new Error(`Failed to get file content: ${error.response?.data?.error?.message || error.message}`);
    }
  }

  async searchCode(workspace: string, repoSlug: string, query: string): Promise<string> {
    const ws = workspace || this.workspace;
    if (!ws) {
      throw new Error("Workspace is required.");
    }
    if (!repoSlug) {
      throw new Error("Repository slug is required.");
    }
    if (!query) {
      throw new Error("Search query is required.");
    }

    try {
      const searchQuery = `repo:${ws}/${repoSlug} ${query}`;
      const response = await this.client.get("/search/code", {
        params: {
          search_query: searchQuery,
          fields: "values(path,file.links.self,file.commit.repository,content_matches)",
        },
      });

      const results = response.data.values || [];

      if (results.length === 0) {
        return `No code matches found for query '${query}' in '${ws}/${repoSlug}'.`;
      }

      const formatted = results.map((result: any, index: number) => {
        const filePath = result.path || "N/A";
        const matches = result.content_matches || [];

        let matchText = "";
        if (matches.length > 0) {
          matchText = matches
            .slice(0, 3)
            .map((m: any) => {
              const lines = m.lines || [];
              return lines
                .map((line: any) => `    ${line.prefix || ""}\x1b[33m${line.match || ""}\x1b[0m${line.supply || ""}`)
                .join("\n");
            })
            .join("\n");
        }

        return `### ${index + 1}. ${filePath}\n${matchText}`;
      });

      return `## Code Search Results for '${query}' in '${ws}/${repoSlug}' (${results.length} matches)\n\n${formatted.join("\n\n---\n\n")}`;
    } catch (error: any) {
      throw new Error(`Failed to search code: ${error.response?.data?.error?.message || error.message}`);
    }
  }

  async getPullRequests(
    workspace: string,
    repoSlug: string,
    state: string = "OPEN"
  ): Promise<string> {
    const ws = workspace || this.workspace;
    if (!ws) {
      throw new Error("Workspace is required.");
    }
    if (!repoSlug) {
      throw new Error("Repository slug is required.");
    }

    try {
      const prs = await this.paginate<any>(
        `/repositories/${ws}/${repoSlug}/pullrequests?state=${state}&fields=values.id,values.title,values.author.display_name,values.state,values.links.html.href,values.created_on`
      );

      if (prs.length === 0) {
        return `No ${state} pull requests found in '${ws}/${repoSlug}'.`;
      }

      const formatted = prs.map((pr) => {
        const id = pr.id || "N/A";
        const title = pr.title || "N/A";
        const author = pr.author?.display_name || "N/A";
        const prState = pr.state || "N/A";
        const date = pr.created_on ? new Date(pr.created_on).toLocaleDateString() : "N/A";
        const link = pr.links?.html?.href || "N/A";
        return `  • PR #${id}: ${title}\n    Author: ${author} | State: ${prState} | Created: ${date}\n    Link: ${link}`;
      });

      return `## Pull Requests in '${ws}/${repoSlug}' (${state}) - ${prs.length} found\n\n${formatted.join("\n\n")}`;
    } catch (error: any) {
      throw new Error(`Failed to get pull requests: ${error.response?.data?.error?.message || error.message}`);
    }
  }

  async getReadme(workspace: string, repoSlug: string, branch?: string): Promise<string> {
    const ws = workspace || this.workspace;
    if (!ws) {
      throw new Error("Workspace is required.");
    }
    if (!repoSlug) {
      throw new Error("Repository slug is required.");
    }

    const readmeVariants = [
      "README.md", "readme.md", "README.MD",
      "README.rst", "readme.rst",
      "README.txt", "readme.txt",
      "README", "readme",
    ];

    for (const variant of readmeVariants) {
      try {
        const ref = branch || await this.getDefaultBranch(ws, repoSlug);
        const url = `/repositories/${ws}/${repoSlug}/src/${ref}/${variant}`;
        const response = await this.client.get(url, {
          responseType: "text",
          transformResponse: [(data) => data],
          validateStatus: (status) => status < 400,
        });

        if (response.status === 200 && response.data) {
          return `## README from '${ws}/${repoSlug}' (branch: ${ref})\n\n${response.data}`;
        }
      } catch {
        // Try next variant
        continue;
      }
    }

    return `No README file found in '${ws}/${repoSlug}'.`;
  }

  async getCommitDiff(workspace: string, repoSlug: string, commitId: string): Promise<string> {
    const ws = workspace || this.workspace;
    if (!ws) {
      throw new Error("Workspace is required.");
    }
    if (!repoSlug) {
      throw new Error("Repository slug is required.");
    }
    if (!commitId) {
      throw new Error("Commit ID is required.");
    }

    try {
      const url = `/repositories/${ws}/${repoSlug}/diff/${commitId}`;
      const response = await this.client.get(url, {
        headers: { Accept: "text/plain" },
        responseType: "text",
        transformResponse: [(data) => data],
      });

      return `## Diff for commit ${commitId} in '${ws}/${repoSlug}'\n\n\`\`\`diff\n${response.data}\n\`\`\``;
    } catch (error: any) {
      throw new Error(`Failed to get commit diff: ${error.response?.data?.error?.message || error.message}`);
    }
  }

  private async getDefaultBranch(workspace: string, repoSlug: string): Promise<string> {
    try {
      const response = await this.client.get(`/repositories/${workspace}/${repoSlug}`);
      const mainBranch = response.data.mainbranch?.name;
      if (mainBranch) {
        return mainBranch;
      }
    } catch {
      // Fall through to default
    }
    return "main";
  }
}