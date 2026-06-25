import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { spawnSync } from "child_process";

const COMPOSIO = `${process.env.HOME}/.composio/composio`;

const server = new Server(
  { name: "composio", version: "2.0.0" },
  { capabilities: { tools: {} } },
);

const TOOLS = [
  {
    name: "composio_search",
    description: "Search for Composio tools by use case",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string", description: "Search query (e.g. 'hacker news', 'send email')" },
        limit: { type: "number", default: 5 },
      },
      required: ["query"],
    },
  },
  {
    name: "composio_execute",
    description: "Execute a Composio tool by slug. Use this instead of the built-in composio_composio_execute — this one handles complex JSON correctly.",
    inputSchema: {
      type: "object",
      properties: {
        slug: { type: "string", description: "Tool slug (e.g. HACKERNEWS_GET_TOP_STORIES)" },
        data: { type: "object", description: "Input arguments as JSON object" },
      },
      required: ["slug"],
    },
  },
  {
    name: "composio_run",
    description: "Run inline JavaScript with injected execute() function for multi-step workflows",
    inputSchema: {
      type: "object",
      properties: {
        code: { type: "string", description: "JavaScript code to run (execute() and search() are pre-injected)" },
      },
      required: ["code"],
    },
  },
  {
    name: "composio_tools_list",
    description: "List tools for a toolkit",
    inputSchema: {
      type: "object",
      properties: {
        toolkit: { type: "string", description: "Toolkit slug (e.g. hackernews)" },
      },
      required: ["toolkit"],
    },
  },
  {
    name: "composio_link",
    description: "Connect an account for a toolkit",
    inputSchema: {
      type: "object",
      properties: {
        toolkit: { type: "string", description: "Toolkit slug to link" },
      },
      required: ["toolkit"],
    },
  },
];

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: TOOLS }));

function run(args) {
  const result = spawnSync(COMPOSIO, args, {
    encoding: "utf-8",
    env: { ...process.env, PATH: `${process.env.HOME}/.composio:${process.env.PATH}` },
  });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(result.stderr || `exit code ${result.status}`);
  return result.stdout;
}

function runJSON(args) {
  const out = run(args);
  return JSON.parse(out);
}

function escape(s) {
  return JSON.stringify(s);
}

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "composio_search": {
        const q = args.query;
        const limit = args.limit || 5;
        const out = runJSON(["search", JSON.stringify(q), "--limit", String(limit)]);
        return { content: [{ type: "text", text: JSON.stringify(out, null, 2) }] };
      }
      case "composio_execute": {
        const { slug, data } = args;
        const script = `const r = await execute(${escape(slug)}, ${JSON.stringify(data || {})}); console.log(JSON.stringify(r))`;
        const out = run(["run", script]);
        const logLine = out.split("\n").find(l => l.startsWith("{") || l.startsWith("["));
        return { content: [{ type: "text", text: logLine || out }] };
      }
      case "composio_run": {
        const out = run(["run", args.code]);
        const parts = out.split("\n").filter(l => !l.startsWith("RUN_LOG_FILE="));
        return { content: [{ type: "text", text: parts.join("\n") }] };
      }
      case "composio_tools_list": {
        const out = runJSON(["tools", "list", args.toolkit]);
        return { content: [{ type: "text", text: JSON.stringify(out, null, 2) }] };
      }
      case "composio_link": {
        run(["link", args.toolkit]);
        return { content: [{ type: "text", text: `Linked ${args.toolkit}` }] };
      }
      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (err) {
    return {
      content: [{ type: "text", text: `Error: ${err.message}` }],
      isError: true,
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
