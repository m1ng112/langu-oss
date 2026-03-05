import { handleAssess } from './handlers/assess';
import { handleEvaluateTheme } from './handlers/evaluate-theme';
import { handleTTS } from './handlers/tts';
import type { Env } from './types/azure';
import type { TTSEnv } from './types/google';

export default {
  async fetch(request: Request, env: Env & TTSEnv, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    // Route requests
    switch (url.pathname) {
      case '/api/v1/assess':
        return handleAssess(request, env);

      case '/api/v1/evaluate-theme':
        return handleEvaluateTheme(request, env);

      case '/api/v1/tts':
        return handleTTS(request, env);

      case '/api/v1/health':
        return new Response(
          JSON.stringify({
            status: 'ok',
            version: '1.0.0',
            timestamp: new Date().toISOString(),
          }),
          {
            headers: { 'Content-Type': 'application/json' },
          }
        );

      default:
        return new Response(
          JSON.stringify({ error: 'Not found' }),
          {
            status: 404,
            headers: { 'Content-Type': 'application/json' },
          }
        );
    }
  },
};
