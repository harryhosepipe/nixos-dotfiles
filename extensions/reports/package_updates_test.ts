import { report } from "./package_updates.ts";

function assert(value: unknown, message: string): asserts value {
  if (!value) throw new Error(message);
}

function contextFor(data: Record<string, unknown>) {
  const calls: unknown[][] = [];
  const context = {
    stepExecutions: [{
      stepName: "package-updates",
      modelType: "@pablo/nix-package-updates",
      modelId: "current-run-instance",
      dataHandles: [{ name: "package-updates", version: 7 }],
    }],
    dataRepository: {
      getContent: (...args: unknown[]) => {
        calls.push(args);
        return Promise.resolve(new TextEncoder().encode(JSON.stringify(data)));
      },
    },
  };
  return { context, calls };
}

Deno.test("check report displays versions and statuses from this run's artifact", async () => {
  const { context, calls } = contextFor({
    mode: "check",
    results: [
      { package: "pi", current: "1.3.0", latest: "1.4.0", status: "available", error: null, changedFiles: [] },
      { package: "dokploy-cli", current: "0.30.7", latest: "0.30.7", status: "up-to-date", error: null, changedFiles: [] },
    ],
    summary: { available: 1, "up-to-date": 1 },
    validation: { status: "not-run" },
  });
  const output = await report.execute(context);
  assert(output.markdown.includes("| pi | 1.3.0 | 1.4.0 | Update available |"), "Missing Pi version details");
  assert(output.markdown.includes("| dokploy-cli | 0.30.7 | 0.30.7 | Up to date |"), "Missing current package status");
  assert(output.markdown.includes("2 packages checked"), "Missing checked count");
  assert(JSON.stringify(calls[0]) === JSON.stringify([
    "@pablo/nix-package-updates", "current-run-instance", "package-updates", 7,
  ]), "The report must read this run's specific artifact version");
});

Deno.test("update report includes review location and validation failures", async () => {
  const { context } = contextFor({
    mode: "update",
    results: [
      { package: "pi", current: "1.3.0", latest: "1.4.0", status: "updated", error: null, changedFiles: ["modules/home/pi.nix"] },
      { package: "sanity-cli", current: "8.13.1", latest: "8.22.0", status: "failed", error: "download | failed\ntry later", changedFiles: [] },
    ],
    summary: { updated: 1, failed: 1 },
    validation: { status: "failed", error: "Evaluation error" },
    branch: "updates/nix-packages-test",
    worktree: "/tmp/example-updates/test",
  });
  const output = await report.execute(context);
  for (const expected of ["Update prepared", "download \\| failed try later", "modules/home/pi.nix", "updates/nix-packages-test", "/tmp/example-updates/test", "Configuration evaluation: failed", "Evaluation error"]) {
    assert(output.markdown.includes(expected), `Missing ${expected}`);
  }
});

Deno.test("missing current-run output does not read stale data", async () => {
  let read = false;
  const output = await report.execute({
    stepExecutions: [],
    dataRepository: {
      getContent: () => {
        read = true;
        return Promise.resolve(null);
      },
    },
  });
  assert(!read, "Missing output must not fall back to an older run");
  assert("status" in output.json && output.json.status === "missing-result", "Missing output should be explained");
});
