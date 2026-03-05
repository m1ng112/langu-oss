// Google Cloud Text-to-Speech API types

export interface TTSRequest {
  text: string;
  languageCode?: string; // default: ko-KR
  voiceName?: string; // e.g., ko-KR-Wavenet-A
  speakingRate?: number; // 0.25 to 4.0, default 1.0
}

export interface TTSResponse {
  success: boolean;
  data?: {
    audioContent: string; // base64 encoded MP3
    durationMs?: number;
  };
  error?: string;
  meta?: {
    requestId: string;
    voiceUsed: string;
    processedAt: string;
  };
}

export interface GoogleTTSRequestBody {
  input: {
    text: string;
  };
  voice: {
    languageCode: string;
    name?: string;
  };
  audioConfig: {
    audioEncoding: 'MP3' | 'LINEAR16' | 'OGG_OPUS';
    speakingRate?: number;
    pitch?: number;
  };
}

export interface GoogleTTSResponseBody {
  audioContent: string; // base64 encoded audio
}

// Korean voice options
export const KOREAN_VOICES = {
  // WaveNet (high quality)
  'ko-KR-Wavenet-A': { gender: 'female', type: 'wavenet' },
  'ko-KR-Wavenet-B': { gender: 'female', type: 'wavenet' },
  'ko-KR-Wavenet-C': { gender: 'male', type: 'wavenet' },
  'ko-KR-Wavenet-D': { gender: 'male', type: 'wavenet' },
  // Standard
  'ko-KR-Standard-A': { gender: 'female', type: 'standard' },
  'ko-KR-Standard-B': { gender: 'female', type: 'standard' },
  'ko-KR-Standard-C': { gender: 'male', type: 'standard' },
  'ko-KR-Standard-D': { gender: 'male', type: 'standard' },
} as const;

export type KoreanVoiceName = keyof typeof KOREAN_VOICES;

// Extend Env to include Google TTS key
export interface TTSEnv {
  GOOGLE_TTS_API_KEY: string;
}
