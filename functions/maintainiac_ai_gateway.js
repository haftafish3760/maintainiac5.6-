class MaintainiacAiGatewayError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function outputText(response) {
  if (typeof response?.output_text === 'string') return response.output_text;
  const textParts = [];
  for (const item of Array.isArray(response?.output) ? response.output : []) {
    for (const content of Array.isArray(item?.content) ? item.content : []) {
      if (typeof content?.text === 'string') textParts.push(content.text);
    }
  }
  return textParts.join('\n');
}

async function requestStructuredOpenAiResponse({
  apiKey,
  model,
  instructions,
  input,
  outputSchema,
  outputSchemaName,
  maxOutputTokens,
  fetchImpl = fetch,
}) {
  if (typeof apiKey !== 'string' || !apiKey || typeof model !== 'string' ||
      !model || typeof instructions !== 'string' || typeof input !== 'string' ||
      !outputSchema || typeof outputSchemaName !== 'string' ||
      !Number.isInteger(maxOutputTokens) || maxOutputTokens < 100 ||
      maxOutputTokens > 4000) {
    throw new MaintainiacAiGatewayError(
      'failed-precondition',
      'AI assistance configuration is invalid.',
    );
  }
  let response;
  try {
    response = await fetchImpl('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        instructions,
        input,
        max_output_tokens: maxOutputTokens,
        text: {
          format: {
            type: 'json_schema',
            name: outputSchemaName,
            strict: true,
            schema: outputSchema,
          },
        },
      }),
    });
  } catch (_) {
    throw new MaintainiacAiGatewayError(
      'unavailable',
      'AI assistance is temporarily unavailable.',
    );
  }
  const requestId = response.headers?.get?.('x-request-id') || '';
  let body;
  try {
    body = await response.json();
  } catch (_) {
    throw new MaintainiacAiGatewayError(
      'unavailable',
      'AI assistance is temporarily unavailable.',
    );
  }
  if (!response.ok) {
    console.warn('maintainiac_ai_gateway_failed', {status: response.status, requestId});
    throw new MaintainiacAiGatewayError(
      'unavailable',
      'AI assistance is temporarily unavailable.',
    );
  }
  return outputText(body);
}

module.exports = {
  MaintainiacAiGatewayError,
  requestStructuredOpenAiResponse,
};
