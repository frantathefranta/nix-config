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
        // --max-model-len 128000 is the *total* context (prompt + output).
        contextWindow: 128_000,
        // Output cap per request; leaves headroom under the 128k total for the prompt.
        maxTokens: 32_768,
      },
    ],
  });
}
