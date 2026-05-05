import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { Type } from "typebox";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

// Generic MCP -> Pi tool bridge.
// Config is read from ~/.pi/agent/mcp.json and optionally <cwd>/.pi/mcp.json.
// Supported shapes: { "mcpServers": { ... } } or { "servers": { ... } }.

type McpServerConfig = {
  command: string;
  args?: string[];
  env?: Record<string, string>;
  cwd?: string;
  disabled?: boolean;
};

type McpConfigFile = {
  mcpServers?: Record<string, McpServerConfig>;
  servers?: Record<string, McpServerConfig>;
};

type ConnectedServer = {
  name: string;
  client: Client;
  transport: StdioClientTransport;
};

function expandHome(value: string): string {
  if (value === "~") return os.homedir();
  if (value.startsWith("~/")) return path.join(os.homedir(), value.slice(2));
  return value;
}

function readConfigFile(file: string): McpConfigFile {
  try {
    return JSON.parse(fs.readFileSync(expandHome(file), "utf8"));
  } catch {
    return {};
  }
}

function mergeServers(...configs: McpConfigFile[]): Record<string, McpServerConfig> {
  return Object.assign({}, ...configs.map((config) => config.mcpServers ?? config.servers ?? {}));
}

function toolNameFor(serverName: string, mcpToolName: string): string {
  return `mcp_${serverName}_${mcpToolName}`
    .replace(/[^A-Za-z0-9_]/g, "_")
    .replace(/_+/g, "_")
    .replace(/^([^A-Za-z_])/, "_$1")
    .slice(0, 96);
}

function schemaFor(inputSchema: unknown) {
  if (inputSchema && typeof inputSchema === "object") return inputSchema as any;
  return Type.Object({}, { additionalProperties: true }) as any;
}

function contentToText(content: unknown): string {
  if (!Array.isArray(content)) return JSON.stringify(content ?? null, null, 2);

  return content
    .map((item) => {
      if (!item || typeof item !== "object") return String(item);
      const value = item as any;
      if (value.type === "text") return value.text ?? "";
      if (value.type === "image") return `[image ${value.mimeType ?? "unknown"}]`;
      if (value.type === "resource") return `[resource ${value.resource?.uri ?? "unknown"}]`;
      return JSON.stringify(value, null, 2);
    })
    .filter(Boolean)
    .join("\n");
}

function cleanEnv(env: NodeJS.ProcessEnv & Record<string, string | undefined>): Record<string, string> {
  return Object.fromEntries(
    Object.entries(env).filter((entry): entry is [string, string] => typeof entry[1] === "string"),
  );
}

async function connectServer(name: string, cfg: McpServerConfig): Promise<ConnectedServer> {
  const transport = new StdioClientTransport({
    command: cfg.command,
    args: cfg.args ?? [],
    env: cleanEnv({ ...process.env, ...(cfg.env ?? {}) }),
    cwd: cfg.cwd ? expandHome(cfg.cwd) : undefined,
    stderr: "pipe",
  });

  // Keep MCP server stderr out of Pi's TUI. Startup errors still surface through
  // failed connect/listTools calls and the /mcp-<server>-error command.
  transport.stderr?.on("data", () => {});

  const client = new Client({ name: `pi-mcp-bridge-${name}`, version: "0.1.0" });
  await client.connect(transport);
  return { name, client, transport };
}

export default async function (pi: ExtensionAPI) {
  const connected: ConnectedServer[] = [];

  const globalConfig = readConfigFile("~/.pi/agent/mcp.json");
  const projectConfig = readConfigFile(path.join(process.cwd(), ".pi", "mcp.json"));
  const servers = mergeServers(globalConfig, projectConfig);

  if (Object.keys(servers).length === 0) {
    servers["context-mode"] = { command: "context-mode", args: [] };
  }

  for (const [serverName, serverConfig] of Object.entries(servers)) {
    if (serverConfig.disabled) continue;

    try {
      const server = await connectServer(serverName, serverConfig);
      connected.push(server);

      const listed = await server.client.listTools();
      for (const mcpTool of listed.tools ?? []) {
        const piToolName = toolNameFor(serverName, mcpTool.name);

        pi.registerTool({
          name: piToolName,
          label: `MCP ${serverName}: ${mcpTool.name}`,
          description: mcpTool.description ?? `Call MCP tool ${mcpTool.name} on server ${serverName}`,
          promptSnippet: mcpTool.description ?? `Call MCP tool ${mcpTool.name} on server ${serverName}`,
          promptGuidelines: [
            `Use ${piToolName} when the user asks for functionality provided by MCP server '${serverName}' tool '${mcpTool.name}'.`,
          ],
          parameters: schemaFor(mcpTool.inputSchema),
          async execute(_toolCallId, params, signal) {
            const result = await server.client.callTool(
              {
                name: mcpTool.name,
                arguments: params as Record<string, unknown>,
              },
              undefined,
              { signal },
            );

            return {
              content: [{ type: "text", text: contentToText((result as any).content) }],
              details: result as any,
              isError: Boolean((result as any).isError),
            };
          },
        });
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      pi.registerCommand(`mcp-${serverName}-error`, {
        description: `Show MCP startup error for ${serverName}`,
        handler: async (_args, ctx) => {
          ctx.ui.notify(`MCP server '${serverName}' failed: ${message}`, "error");
        },
      });
    }
  }

  pi.registerCommand("mcp-list", {
    description: "List MCP servers connected by the local MCP bridge",
    handler: async (_args, ctx) => {
      const lines = connected.length
        ? connected.map((server) => `- ${server.name}`).join("\n")
        : "No MCP servers connected.";
      ctx.ui.notify(lines, connected.length ? "info" : "warning");
    },
  });

  pi.on("session_shutdown", async () => {
    await Promise.allSettled(connected.map((server) => server.client.close()));
  });
}
