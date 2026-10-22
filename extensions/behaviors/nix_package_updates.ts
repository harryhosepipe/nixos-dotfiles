import { z } from "npm:zod@4.4.1";

const argsSchema = z.object({
  mode: z.enum(["check", "update"]).default("check"),
  packages: z.string().default("all"),
});

const resultSchema = z.object({
  mode: z.string(),
  repository: z.string(),
  checkedAt: z.string(),
  results: z.array(z.object({
    package: z.string(),
    current: z.string(),
    latest: z.string(),
    status: z.string(),
    source: z.string(),
    channel: z.string(),
    error: z.string().nullable(),
    changedFiles: z.array(z.string()),
    details: z.record(z.string(), z.unknown()),
  })),
  summary: z.record(z.string(), z.number()),
  validation: z.object({ status: z.string() }).passthrough(),
  built: z.literal(false),
  activated: z.literal(false),
}).passthrough();

/** Repository-specific release checks and isolated, unbuilt package updates. */
export const behavior = {
  type: "@pablo/nix-package-updates",
  version: "2026.10.22.1",
  globalArguments: z.object({}),
  resources: {
    result: {
      description: "Release checks, update branch, changed files, and validation results",
      schema: resultSchema,
      lifetime: "30d",
      garbageCollection: 30,
    },
  },
  methods: {
    run: {
      description: "Check the package allowlist or prepare updates without builds or activation",
      arguments: argsSchema,
      execute: async (
        args: z.infer<typeof argsSchema>,
        context: {
          repoDir: string;
          signal: AbortSignal;
          writeResource: (
            spec: string,
            name: string,
            data: Record<string, unknown>,
          ) => Promise<{ name: string }>;
        },
      ) => {
        const result = await new Deno.Command("python3", {
          args: [
            `${context.repoDir}/tools/package_updates.py`,
            "--repo", context.repoDir,
            "--mode", args.mode,
            "--packages", args.packages,
          ],
          cwd: context.repoDir,
          signal: context.signal,
          stdout: "piped",
          stderr: "piped",
        }).output();
        const output = new TextDecoder().decode(result.stdout);
        let parsed;
        try {
          parsed = JSON.parse(output);
        } catch {
          const stderr = new TextDecoder().decode(result.stderr).slice(-2000);
          throw new Error(`Updater did not return a JSON report: ${stderr}`);
        }
        if (parsed.error) throw new Error(parsed.error);
        const report = resultSchema.parse(parsed);
        const handle = await context.writeResource("result", "package-updates", report);
        if (!result.success) {
          throw new Error("Package checks or validation failed; see this run's persisted result");
        }
        return { dataHandles: [handle] };
      },
    },
  },
};
