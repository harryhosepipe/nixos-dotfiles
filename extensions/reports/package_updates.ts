type PackageResult = {
  package: string;
  current: string;
  latest: string;
  status: string;
  error: string | null;
  changedFiles: string[];
};

type PackageReport = {
  mode: string;
  results: PackageResult[];
  summary: Record<string, number>;
  validation: { status: string; error?: string };
  branch?: string;
  worktree?: string;
};

type ReportContext = {
  stepExecutions: Array<{
    stepName: string;
    modelType: unknown;
    modelId: string;
    dataHandles: Array<{ name: string; version?: number }>;
  }>;
  dataRepository: {
    getContent: (
      type: unknown,
      modelId: string,
      name: string,
      version?: number,
    ) => Promise<Uint8Array | null>;
  };
};

const statuses: Record<string, string> = {
  available: "Update available",
  "up-to-date": "Up to date",
  "ahead-of-upstream": "Configured version is newer",
  updated: "Update prepared",
  failed: "Failed",
};

function cell(value: string): string {
  return value.replaceAll("|", "\\|").replaceAll(/\r?\n/g, " ");
}

/** Render the current workflow run's stored result as a terminal report. */
export const report = {
  name: "@pablo/package-update-summary",
  description: "Configured and available versions, update status, and validation results",
  scope: "workflow",
  labels: ["packages", "updates"],
  execute: async (context: ReportContext) => {
    const step = context.stepExecutions.find((s) => s.stepName === "package-updates");
    const handle = step?.dataHandles.find((h) => h.name === "package-updates");
    if (!step || !handle) {
      return {
        markdown: "# Package updates\n\nNo package results were produced by this run. Check the failed step's error.\n",
        json: { status: "missing-result" },
      };
    }

    // Read the artifact version from this run, never an unrelated latest result.
    const content = await context.dataRepository.getContent(
      step.modelType,
      step.modelId,
      handle.name,
      handle.version,
    );
    if (!content) throw new Error("This run's package result could not be read");
    const data: PackageReport = JSON.parse(new TextDecoder().decode(content));
    const lines = [
      "# Package updates",
      "",
      `Mode: ${data.mode}. ${data.results.length} packages checked.`,
      "",
      "| Package | Configured | Available | Status |",
      "| --- | --- | --- | --- |",
      ...data.results.map((item) =>
        `| ${cell(item.package)} | ${cell(item.current)} | ${cell(item.latest)} | ${cell(statuses[item.status] ?? item.status)} |`
      ),
      "",
    ];
    for (const item of data.results) {
      if (item.error) lines.push(`- ${item.package}: ${cell(item.error)}`);
      if (item.changedFiles.length) {
        lines.push(`- ${item.package} changed: ${item.changedFiles.join(", ")}`);
      }
    }
    if (data.branch) lines.push("", `Branch: ${data.branch}`);
    if (data.worktree) lines.push("", `Review directory: ${data.worktree}`);
    if (data.mode === "update") {
      lines.push("", `Configuration evaluation: ${data.validation.status}.`);
      if (data.validation.error) lines.push("", cell(data.validation.error));
    }
    lines.push("", "No builds or system activation were run.", "");
    return { markdown: lines.join("\n"), json: data };
  },
};
