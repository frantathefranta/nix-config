import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * Provider for models served through OpenWebUI's OpenAI-compatible API
 * (OpenWebUI Settings > Account > API Keys for the key).
 *
 * https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/custom-provider.md
 */
export default function (pi: ExtensionAPI) {
  pi.registerProvider("openwebui", {
    name: "OpenWebUI",
    baseUrl: process.env.OPENWEBUI_BASE_URL ?? "http://localhost:3000/api",
    // "$VAR" is resolved by pi from the environment at request time.
    apiKey: "$OPENWEBUI_API_KEY",
    api: "openai-completions",
    // Sent on every request to this provider.
    headers: {
      "x-osc-wait": "true",
    },
    models: [
      {
        // Verify against: curl -s "$OPENWEBUI_BASE_URL/models" \
        //   -H "Authorization: Bearer $OPENWEBUI_API_KEY" | jq '.data[].id'
        id: "qwen3-coder-next",
        name: "Qwen3 Coder Next",
        // Served via vLLM/Dynamo with --dyn-reasoning-parser qwen3 (thinking enabled).
        // If reasoning output looks garbled or leaks into the answer text, try
        // adding compat: { thinkingFormat: "qwen" } below.
        reasoning: true,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        // --max-model-len 256000 is the *total* context (prompt + output).
        contextWindow: 256_000,
      },
      {
        id: "qwen35-122b-fp8",
        name: "Qwen3.5 122B FP8",
        reasoning: true,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 262_144,
      },
      {
        id: "gpt-oss-120b",
        name: "GPT-OSS 120B",
        reasoning: true,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 131_072,
      },
      {
        id: "qwen3-coder-30b",
        name: "Qwen3 Coder 30B",
        reasoning: true,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128_000,
      },
      {
        id: "qwen36-fp8",
        name: "Qwen3.6 FP8",
        reasoning: true,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 256_000,
      },
    ],
  });
}
