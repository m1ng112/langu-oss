import type {
  EvaluateThemeRequest,
  EvaluateThemeResponse,
  EvaluateThemeData,
  Env,
} from '../types/azure';

export async function handleEvaluateTheme(
  request: Request,
  env: Env
): Promise<Response> {
  // Validate method
  if (request.method !== 'POST') {
    return jsonResponse({ success: false, error: 'Method not allowed' }, 405);
  }

  // Parse request body
  let body: EvaluateThemeRequest;
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ success: false, error: 'Invalid JSON body' }, 400);
  }

  // Validate required fields
  if (!body.recognizedText) {
    return jsonResponse(
      { success: false, error: 'recognizedText is required' },
      400
    );
  }
  if (!body.themeId) {
    return jsonResponse(
      { success: false, error: 'themeId is required' },
      400
    );
  }
  if (!body.themeName) {
    return jsonResponse(
      { success: false, error: 'themeName is required' },
      400
    );
  }
  if (!body.themeDescription) {
    return jsonResponse(
      { success: false, error: 'themeDescription is required' },
      400
    );
  }
  if (!Array.isArray(body.keywords) || body.keywords.length === 0) {
    return jsonResponse(
      { success: false, error: 'keywords must be a non-empty array' },
      400
    );
  }

  // Call Claude API to evaluate the theme response
  const prompt = buildEvaluationPrompt(body);
  const models = ['claude-haiku-4-5-20251001', 'claude-3-haiku-20240307'];

  let claudeResponse: globalThis.Response | null = null;
  let lastError = '';

  for (const model of models) {
    try {
      claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': env.ANTHROPIC_API_KEY,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model,
          max_tokens: 1024,
          messages: [
            {
              role: 'user',
              content: prompt,
            },
          ],
        }),
      });

      if (claudeResponse.ok) {
        break; // Success, exit loop
      }

      // If overloaded (529) or server error (5xx), try next model
      if (claudeResponse.status === 529 || claudeResponse.status >= 500) {
        lastError = `${model}: ${claudeResponse.status}`;
        claudeResponse = null;
        continue;
      }

      // For other errors, return immediately
      const errorBody = await claudeResponse.text();
      return jsonResponse(
        { success: false, error: `Evaluation service error: ${claudeResponse.status} - ${errorBody}` },
        502
      );
    } catch (error) {
      lastError = `${model}: ${error}`;
      claudeResponse = null;
      continue;
    }
  }

  if (!claudeResponse || !claudeResponse.ok) {
    console.error('All Claude models failed:', lastError);
    return jsonResponse(
      { success: false, error: 'Evaluation service temporarily unavailable. Please try again.' },
      503
    );
  }

  let claudeResult: { content: { type: string; text: string }[] };
  try {
    claudeResult = await claudeResponse.json();
  } catch {
    return jsonResponse(
      { success: false, error: 'Invalid response from evaluation service' },
      502
    );
  }

  // Extract the text content from Claude's response
  const textContent = claudeResult.content?.find((c) => c.type === 'text');
  if (!textContent) {
    return jsonResponse(
      { success: false, error: 'Empty response from evaluation service' },
      502
    );
  }

  // Parse the JSON evaluation from Claude's response
  let evaluation: EvaluateThemeData;
  try {
    const jsonMatch = textContent.text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error('No JSON found in response');
    }
    evaluation = JSON.parse(jsonMatch[0]);
  } catch {
    console.error('Failed to parse evaluation:', textContent.text);
    return jsonResponse(
      { success: false, error: 'Failed to parse evaluation result' },
      502
    );
  }

  // Ensure scores are integers in 0-100 range
  evaluation.relevanceScore = clampScore(evaluation.relevanceScore);
  evaluation.vocabularyScore = clampScore(evaluation.vocabularyScore);
  evaluation.grammarScore = clampScore(evaluation.grammarScore);
  evaluation.expressionScore = clampScore(evaluation.expressionScore);

  // Calculate overallScore as weighted average
  evaluation.overallScore = Math.round(
    (evaluation.relevanceScore * 3 +
      evaluation.vocabularyScore * 2 +
      evaluation.grammarScore * 3 +
      evaluation.expressionScore * 2) /
      10
  );

  // Ensure arrays exist
  if (!Array.isArray(evaluation.usedKeywords)) {
    evaluation.usedKeywords = [];
  }
  if (!Array.isArray(evaluation.suggestedVocabulary)) {
    evaluation.suggestedVocabulary = [];
  }
  if (!Array.isArray(evaluation.detailedFeedback)) {
    evaluation.detailedFeedback = [];
  }

  const response: EvaluateThemeResponse = {
    success: true,
    data: evaluation,
  };

  return jsonResponse(response, 200);
}

function buildEvaluationPrompt(body: EvaluateThemeRequest): string {
  return `You are an expert Korean language evaluator. Evaluate the following Korean text that was spoken in response to a themed free-talk exercise.

Theme ID: ${body.themeId}
Theme Name: ${body.themeName}
Theme Description: ${body.themeDescription}
Expected Keywords: ${JSON.stringify(body.keywords)}

User's spoken text (recognized by speech-to-text):
"${body.recognizedText}"

Evaluate the text on the following criteria, each scored 0-100:

1. **relevanceScore**: How relevant is the response to the theme "${body.themeName}" (${body.themeDescription})? Does it address the topic?
2. **vocabularyScore**: How rich and appropriate is the vocabulary? Did the user use theme-related keywords?
3. **grammarScore**: How grammatically correct is the Korean? Check particles (조사), verb endings (어미), word order, etc.
4. **expressionScore**: How natural and diverse are the expressions? Consider sentence variety, length, and fluency.

Also provide:
- **feedback**: A brief overall feedback message in Japanese (1-2 sentences)
- **usedKeywords**: Which of the expected keywords [${body.keywords.join(', ')}] were actually used in the text (exact or stem matches)
- **suggestedVocabulary**: 3-5 additional Korean vocabulary words/phrases that would be useful for this theme
- **detailedFeedback**: An array of 2-4 feedback items, each with:
  - "type": one of "excellent", "good", or "tip"
  - "message": a specific feedback message in English

Respond with ONLY a JSON object (no markdown fences, no explanation) in this exact format:
{
  "relevanceScore": <number>,
  "vocabularyScore": <number>,
  "grammarScore": <number>,
  "expressionScore": <number>,
  "feedback": "<Japanese feedback string>",
  "usedKeywords": ["<keyword1>", ...],
  "suggestedVocabulary": ["<word1>", ...],
  "detailedFeedback": [
    {"type": "<excellent|good|tip>", "message": "<English feedback>"},
    ...
  ]
}`;
}

function clampScore(score: number): number {
  return Math.round(Math.min(100, Math.max(0, score ?? 0)));
}

function jsonResponse(data: EvaluateThemeResponse, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
