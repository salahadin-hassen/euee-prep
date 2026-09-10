import assert from "node:assert/strict";
import { describe, it, beforeEach, afterEach } from "node:test";
import { dispatchExtractionWorker, type DispatchResult } from "./dispatch.ts";

describe("dispatchExtractionWorker", () => {
  const originalEnv = { ...process.env };
  let fetchCalls: { url: string; init: RequestInit }[] = [];
  let fetchResponses: { ok: boolean; status: number; text: string }[] = [];
  let fetchIndex = 0;

  beforeEach(() => {
    fetchCalls = [];
    fetchResponses = [];
    fetchIndex = 0;
    process.env.GITHUB_ACTIONS_DISPATCH_TOKEN = "ghp_test_token_123";
    process.env.GITHUB_REPO_OWNER = "test-owner";
    process.env.GITHUB_REPO_NAME = "test-repo";
    process.env.GITHUB_WORKFLOW_FILE = "worker.yml";

    (globalThis as any).fetch = async (url: string | URL | Request, init?: RequestInit): Promise<Response> => {
      const urlStr = typeof url === "string" ? url : url instanceof URL ? url.toString() : url.url;
      fetchCalls.push({ url: urlStr, init: init ?? {} });
      const resp = fetchResponses[fetchIndex++] ?? { ok: true, status: 204, text: "" };
      return {
        ok: resp.ok,
        status: resp.status,
        text: async () => resp.text,
        json: async () => ({}),
      } as Response;
    };
  });

  afterEach(() => {
    process.env = { ...originalEnv };
    delete (globalThis as any).fetch;
  });

  it("sends correct request to GitHub API", async () => {
    fetchResponses = [{ ok: true, status: 204, text: "" }];
    const result = await dispatchExtractionWorker("job-uuid-123");

    assert.equal(result.ok, true);
    assert.equal(fetchCalls.length, 1);
    assert.equal(fetchCalls[0].url, "https://api.github.com/repos/test-owner/test-repo/actions/workflows/worker.yml/dispatches");

    const body = JSON.parse(fetchCalls[0].init.body as string);
    assert.equal(body.ref, "master");
    assert.equal(body.inputs.job_id, "job-uuid-123");

    const headers = fetchCalls[0].init.headers as Record<string, string>;
    assert.equal(headers.Authorization, "Bearer ghp_test_token_123");
    assert.equal(headers["X-GitHub-Api-Version"], "2022-11-28");
  });

  it("returns ok on 204 response", async () => {
    fetchResponses = [{ ok: true, status: 204, text: "" }];
    const result = await dispatchExtractionWorker("job-1");
    assert.equal(result.ok, true);
    assert.equal(result.error, undefined);
  });

  it("returns ok on 200 response", async () => {
    fetchResponses = [{ ok: true, status: 200, text: "" }];
    const result = await dispatchExtractionWorker("job-1");
    assert.equal(result.ok, true);
  });

  it("returns error on 403 (PAT lacks scope)", async () => {
    fetchResponses = [{ ok: false, status: 403, text: '{"message":"resource not accessible"}' }];
    const result = await dispatchExtractionWorker("job-1");
    assert.equal(result.ok, false);
    assert.ok(result.error?.includes("403"));
  });

  it("returns error on 404 (repo/workflow not found)", async () => {
    fetchResponses = [{ ok: false, status: 404, text: '{"message":"Not Found"}' }];
    const result = await dispatchExtractionWorker("job-1");
    assert.equal(result.ok, false);
    assert.ok(result.error?.includes("404"));
  });

  it("returns error on 422 (validation error)", async () => {
    fetchResponses = [{ ok: false, status: 422, text: '{"message":"Validation Failed"}' }];
    const result = await dispatchExtractionWorker("job-1");
    assert.equal(result.ok, false);
    assert.ok(result.error?.includes("422"));
  });

  it("returns error on 500 (server error)", async () => {
    fetchResponses = [{ ok: false, status: 500, text: "Internal Server Error" }];
    const result = await dispatchExtractionWorker("job-1");
    assert.equal(result.ok, false);
    assert.ok(result.error?.includes("500"));
  });

  it("returns error on network failure", async () => {
    (globalThis as any).fetch = async () => { throw new TypeError("fetch failed"); };
    const result = await dispatchExtractionWorker("job-1");
    assert.equal(result.ok, false);
    assert.ok(result.error?.includes("fetch failed"));
  });

  it("returns error when env vars are missing", async () => {
    delete process.env.GITHUB_ACTIONS_DISPATCH_TOKEN;
    const result = await dispatchExtractionWorker("job-1");
    assert.equal(result.ok, false);
    assert.ok(result.error?.includes("not configured"));
    assert.equal(fetchCalls.length, 0);
  });

  it("returns error when REPO_OWNER is missing", async () => {
    delete process.env.GITHUB_REPO_OWNER;
    const result = await dispatchExtractionWorker("job-1");
    assert.equal(result.ok, false);
    assert.equal(fetchCalls.length, 0);
  });

  it("does not log the token", async () => {
    fetchResponses = [{ ok: true, status: 204, text: "" }];
    const logs: string[] = [];
    const origLog = console.log;
    const origError = console.error;
    console.log = (...args: unknown[]) => logs.push(args.join(" "));
    console.error = (...args: unknown[]) => logs.push(args.join(" "));

    await dispatchExtractionWorker("job-1");

    console.log = origLog;
    console.error = origError;
    for (const log of logs) {
      assert.ok(!log.includes("ghp_test_token_123"), `Token leaked in log: ${log}`);
    }
  });

  it("sends minimum payload — only job_id", async () => {
    fetchResponses = [{ ok: true, status: 204, text: "" }];
    await dispatchExtractionWorker("job-42");

    const body = JSON.parse(fetchCalls[0].init.body as string);
    assert.deepEqual(Object.keys(body).sort(), ["inputs", "ref"]);
    assert.deepEqual(Object.keys(body.inputs), ["job_id"]);
    assert.equal(body.inputs.job_id, "job-42");
  });
});
