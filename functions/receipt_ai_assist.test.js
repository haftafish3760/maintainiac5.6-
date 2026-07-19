const assert = require('node:assert/strict');
const test = require('node:test');
const {
  requestOpenAiAssist,
  validateAssistRequest,
} = require('./receipt_ai_assist');

const validRequest = {
  organizationId: 'personal_org',
  receiptId: 'receipt_1',
  userConfirmedAssist: true,
  receiptMode: 'detailed',
  categoryHint: 'materials',
  lines: [
    {sourceText: 'HDWR 12.99', displayText: 'HDWR 12.99'},
    {sourceText: 'TOTAL 12.99', displayText: 'TOTAL 12.99'},
  ],
};

test('receipt AI evidence preserves source and display text', () => {
  const result = validateAssistRequest(validRequest, 2000);
  assert.equal(result.lines[0].sourceText, 'HDWR 12.99');
  assert.equal(result.lines[0].displayText, 'HDWR 12.99');
});

test('receipt AI requires explicit user confirmation', () => {
  assert.throws(
    () => validateAssistRequest({...validRequest, userConfirmedAssist: false}, 2000),
    /explicitly confirmed/,
  );
});

test('receipt AI rejects unsupported source evidence', () => {
  assert.throws(
    () => validateAssistRequest({...validRequest, lines: [{sourceText: ''}]}, 2000),
    /Missing source text/,
  );
});

test('receipt AI returns evidence-backed structured candidates', async () => {
  const response = await requestOpenAiAssist({
    apiKey: 'not-a-real-key',
    evidence: validateAssistRequest(validRequest, 2000),
    maxOutputTokens: 1200,
    fetchImpl: async () => new Response(JSON.stringify({
      output_text: JSON.stringify({
        merchant: {value: 'HDWR', sourceLineIndexes: [0], confidence: 0.6, reason: 'First line'},
        date: {value: '', sourceLineIndexes: [], confidence: 0, reason: 'Not present'},
        subtotal: {value: '', sourceLineIndexes: [], confidence: 0, reason: 'Not present'},
        tax: {value: '', sourceLineIndexes: [], confidence: 0, reason: 'Not present'},
        total: {value: '12.99', sourceLineIndexes: [1], confidence: 0.9, reason: 'Total label'},
        warnings: [],
      }),
    }), {status: 200}),
  });
  assert.equal(response.total.value, '12.99');
  assert.deepEqual(response.total.sourceLineIndexes, [1]);
});
