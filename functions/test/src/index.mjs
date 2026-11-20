const OLLAMA_URL = `http://${process.env.OLLAMA_HOST ?? '127.0.0.1:11434'}`;
const MODEL = process.env.OLLAMA_MODEL;

export const handler = async (event) => {
  const prompt =
    event?.prompt ?? 'Why is the sky blue? Answer in one sentence.';

  const res = await fetch(`${OLLAMA_URL}/api/generate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: MODEL, prompt, stream: false }),
  });

  if (!res.ok) {
    throw new Error(`ollama returned ${res.status}: ${await res.text()}`);
  }

  const data = await res.json();
  console.log(
    `ollama: model=${MODEL} total=${data.total_duration / 1e6}ms ` +
      `load=${data.load_duration / 1e6}ms eval_tokens=${data.eval_count}`,
  );

  return { model: MODEL, prompt, response: data.response };
};
