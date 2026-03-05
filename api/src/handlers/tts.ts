import type {
  TTSRequest,
  TTSResponse,
  TTSEnv,
  GoogleTTSRequestBody,
  GoogleTTSResponseBody,
  KoreanVoiceName,
  KOREAN_VOICES,
} from '../types/google';

const GOOGLE_TTS_ENDPOINT = 'https://texttospeech.googleapis.com/v1/text:synthesize';
const DEFAULT_VOICE = 'ko-KR-Wavenet-A';
const DEFAULT_LANGUAGE = 'ko-KR';

export async function handleTTS(
  request: Request,
  env: TTSEnv
): Promise<Response> {
  // Validate method
  if (request.method !== 'POST') {
    return jsonResponse({ success: false, error: 'Method not allowed' }, 405);
  }

  // Parse request body
  let body: TTSRequest;
  try {
    body = await request.json();
  } catch {
    return jsonResponse({ success: false, error: 'Invalid JSON body' }, 400);
  }

  // Validate required fields
  if (!body.text || body.text.trim().length === 0) {
    return jsonResponse(
      { success: false, error: 'Missing required field: text' },
      400
    );
  }

  // Validate text length (Google TTS limit is 5000 chars)
  if (body.text.length > 500) {
    return jsonResponse(
      { success: false, error: 'Text too long (max 500 characters)' },
      400
    );
  }

  // Validate speaking rate
  const speakingRate = body.speakingRate ?? 1.0;
  if (speakingRate < 0.25 || speakingRate > 4.0) {
    return jsonResponse(
      { success: false, error: 'Speaking rate must be between 0.25 and 4.0' },
      400
    );
  }

  // Build Google TTS request
  console.log(`Google TTS call: text="${body.text.substring(0, 50)}", rate=${speakingRate}`);
  const voiceName = body.voiceName || DEFAULT_VOICE;
  const languageCode = body.languageCode || DEFAULT_LANGUAGE;

  const googleRequest: GoogleTTSRequestBody = {
    input: {
      text: body.text,
    },
    voice: {
      languageCode: languageCode,
      name: voiceName,
    },
    audioConfig: {
      audioEncoding: 'MP3',
      speakingRate: speakingRate,
    },
  };

  // Call Google TTS API
  let googleResponse: globalThis.Response;
  try {
    googleResponse = await fetch(
      `${GOOGLE_TTS_ENDPOINT}?key=${env.GOOGLE_TTS_API_KEY}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(googleRequest),
      }
    );
  } catch (error) {
    console.error('Google TTS API error:', error);
    return jsonResponse(
      { success: false, error: 'Failed to connect to TTS service' },
      502
    );
  }

  if (!googleResponse.ok) {
    const errorBody = await googleResponse.text();
    console.error('Google TTS API error:', googleResponse.status, errorBody);
    return jsonResponse(
      { success: false, error: 'TTS service error' },
      502
    );
  }

  // Parse Google response
  let result: GoogleTTSResponseBody;
  try {
    result = await googleResponse.json();
  } catch {
    return jsonResponse(
      { success: false, error: 'Invalid response from TTS service' },
      502
    );
  }

  if (!result.audioContent) {
    return jsonResponse(
      { success: false, error: 'No audio content in response' },
      502
    );
  }

  // Build response
  const response: TTSResponse = {
    success: true,
    data: {
      audioContent: result.audioContent,
    },
    meta: {
      requestId: crypto.randomUUID(),
      voiceUsed: voiceName,
      processedAt: new Date().toISOString(),
    },
  };

  return jsonResponse(response, 200);
}

function jsonResponse(data: TTSResponse, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      // Cache successful responses for 24 hours
      ...(status === 200 && {
        'Cache-Control': 'public, max-age=86400',
      }),
    },
  });
}
