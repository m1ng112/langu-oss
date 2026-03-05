import type {
  AssessRequest,
  AssessResponse,
  AzureSpeechResult,
  Env,
  PronunciationAssessmentConfig,
} from '../types/azure';

export async function handleAssess(
  request: Request,
  env: Env
): Promise<Response> {
  // Validate method
  if (request.method !== 'POST') {
    return jsonResponse({ success: false, error: 'Method not allowed' }, 405);
  }

  // Parse request body
  let body: AssessRequest;
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ success: false, error: 'Invalid JSON body' }, 400);
  }

  // Validate required fields
  if (!body.audio) {
    return jsonResponse(
      { success: false, error: 'Missing required field: audio' },
      400
    );
  }

  // Determine mode: pronunciation assessment (with referenceText) or transcription only
  const transcriptionOnly = !body.referenceText;

  // Validate audio size (max 5MB base64 ~ 3.75MB raw)
  if (body.audio.length > 5 * 1024 * 1024) {
    return jsonResponse({ success: false, error: 'Audio file too large (max 5MB)' }, 400);
  }

  // Decode base64 audio
  let audioBuffer: Uint8Array;
  try {
    const binaryString = atob(body.audio);
    audioBuffer = Uint8Array.from(binaryString, (c) => c.charCodeAt(0));
  } catch {
    return jsonResponse({ success: false, error: 'Invalid base64 audio data' }, 400);
  }

  // Build request headers
  const headers: Record<string, string> = {
    'Ocp-Apim-Subscription-Key': env.AZURE_SPEECH_KEY,
    'Content-Type': 'audio/wav',
  };

  // Add pronunciation assessment config only if referenceText is provided
  if (!transcriptionOnly) {
    const pronConfig: PronunciationAssessmentConfig = {
      ReferenceText: body.referenceText,
      GradingSystem: 'HundredMark',
      Granularity: 'Phoneme',
      Dimension: 'Comprehensive',
      EnableMiscue: true,
    };
    const configBytes = new TextEncoder().encode(JSON.stringify(pronConfig));
    headers['Pronunciation-Assessment'] = btoa(String.fromCharCode(...configBytes));
  }

  // Call Azure Speech API
  const azureUrl = `https://${env.AZURE_SPEECH_REGION}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=ko-KR&format=detailed`;

  let azureResponse: globalThis.Response;
  try {
    azureResponse = await fetch(azureUrl, {
      method: 'POST',
      headers,
      body: audioBuffer,
    });
  } catch (error) {
    console.error('Azure API error:', error);
    return jsonResponse(
      { success: false, error: 'Failed to connect to speech service' },
      502
    );
  }

  if (!azureResponse.ok) {
    console.error('Azure API error status:', azureResponse.status);
    return jsonResponse(
      { success: false, error: 'Speech service error' },
      502
    );
  }

  // Parse Azure response
  let result: AzureSpeechResult;
  try {
    result = await azureResponse.json();
  } catch {
    return jsonResponse(
      { success: false, error: 'Invalid response from speech service' },
      502
    );
  }

  // Check recognition status
  if (result.RecognitionStatus !== 'Success') {
    return jsonResponse(
      {
        success: false,
        error: `Recognition failed: ${result.RecognitionStatus}`,
      },
      400
    );
  }

  // Extract results
  if (!result.NBest || result.NBest.length === 0) {
    return jsonResponse(
      { success: false, error: 'No speech recognized' },
      400
    );
  }

  const best = result.NBest[0];

  // Build response based on mode
  const response: AssessResponse = {
    success: true,
    data: transcriptionOnly
      ? {
          // Transcription-only mode: just return recognized text
          pronunciationScore: 0,
          accuracyScore: 0,
          fluencyScore: 0,
          completenessScore: 0,
          prosodyScore: 0,
          recognizedText: best.Display,
        }
      : {
          // Full pronunciation assessment mode
          pronunciationScore: Math.round(best.PronScore ?? 0),
          accuracyScore: Math.round(best.AccuracyScore ?? 0),
          fluencyScore: Math.round(best.FluencyScore ?? 0),
          completenessScore: Math.round(best.CompletenessScore ?? 0),
          prosodyScore: Math.round(best.ProsodyScore ?? 0),
          recognizedText: best.Display,
        },
    meta: {
      assessmentId: crypto.randomUUID(),
      processedAt: new Date().toISOString(),
      mode: transcriptionOnly ? 'transcription' : 'assessment',
    },
  };

  return jsonResponse(response, 200);
}

function jsonResponse(data: AssessResponse, status: number): Response {
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
