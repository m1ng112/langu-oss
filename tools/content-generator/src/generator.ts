/**
 * @module generator
 *
 * ContentGenerator uses the Anthropic SDK to call Claude and produce
 * structured language-learning content (units, stories, themes).
 *
 * The SDK automatically reads ANTHROPIC_API_KEY from the environment.
 */

import Anthropic from "@anthropic-ai/sdk";
import type {
  UnitsFile,
  StoriesFile,
  ThemesFile,
  UnitGenerationOptions,
  StoryGenerationOptions,
  ThemeGenerationOptions,
} from "./schemas.js";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const MODEL = "claude-sonnet-4-6" as const;
const MAX_TOKENS = 8192;

/**
 * Extract the first JSON object or array from a string that may contain
 * markdown fences or surrounding prose.
 */
function extractJson(raw: string): string {
  // Try to find a fenced code block first
  const fenced = raw.match(/```(?:json)?\s*\n?([\s\S]*?)```/);
  if (fenced?.[1]) {
    return fenced[1].trim();
  }

  // Fall back to the first top-level { ... } or [ ... ]
  const start = raw.search(/[{[]/);
  if (start === -1) {
    throw new Error("No JSON object found in model response");
  }

  let depth = 0;
  let inString = false;
  let escaped = false;

  for (let i = start; i < raw.length; i++) {
    const ch = raw[i];

    if (escaped) {
      escaped = false;
      continue;
    }
    if (ch === "\\") {
      if (inString) escaped = true;
      continue;
    }
    if (ch === '"') {
      inString = !inString;
      continue;
    }
    if (inString) continue;

    if (ch === "{" || ch === "[") {
      depth++;
    } else if (ch === "}" || ch === "]") {
      depth--;
    }

    if (depth === 0) {
      return raw.slice(start, i + 1);
    }
  }

  // If we never balanced, return from start to end and let JSON.parse fail
  // with a clear message.
  return raw.slice(start);
}

// ---------------------------------------------------------------------------
// ContentGenerator
// ---------------------------------------------------------------------------

export class ContentGenerator {
  private readonly client: Anthropic;

  constructor() {
    // The SDK reads ANTHROPIC_API_KEY from process.env automatically.
    this.client = new Anthropic();
  }

  // -----------------------------------------------------------------------
  // Units
  // -----------------------------------------------------------------------

  async generateUnits(opts: UnitGenerationOptions): Promise<UnitsFile> {
    const { nativeLanguage, targetLanguage, unitCount, lessonsPerUnit } = opts;

    const systemPrompt = `You are an expert ${targetLanguage} language teacher and curriculum designer who creates structured pronunciation-focused learning content. You have deep knowledge of ${targetLanguage} phonology, common learner difficulties (especially for ${nativeLanguage} speakers), and pedagogical sequencing.

Your output MUST be valid JSON and nothing else. Do not include any explanation outside the JSON.`;

    const userPrompt = `Generate a comprehensive set of ${unitCount} lesson units for ${nativeLanguage} speakers learning ${targetLanguage} pronunciation. Each unit should contain exactly ${lessonsPerUnit} lessons.

## Content Guidelines

### Unit Design
- Units should progress logically from fundamental sounds to more complex pronunciation patterns.
- Each unit should have a clear phonetic or thematic focus (e.g., basic vowels, consonant clusters, intonation, common greetings, numbers, food vocabulary).
- Mix phonetic-focused units with practical vocabulary units so learners stay engaged.
- Distribute difficulty levels across units: roughly 40% beginner, 35% intermediate, 25% advanced.

### Lesson Design
- Each lesson focuses on a single word or short phrase (1-4 syllables for beginner, up to 6-8 syllables for advanced).
- The "korean" field must contain natural, commonly-used ${targetLanguage} text.
- The "romanization" field MUST use the Revised Romanization of Korean system accurately:
  - ㅓ = "eo" (not "o" or "u")
  - ㅡ = "eu" (not "u")
  - ㅢ = "ui"
  - ㄱ at syllable-final = "k"
  - ㅂ at syllable-final = "p"
  - ㄷ at syllable-final = "t"
  - Handle consonant assimilation rules (e.g., 한국말 = "hangungmal" not "hangumal")
  - Handle tensification and nasalization in romanization.
- The "hint" field should give a specific, actionable pronunciation tip for ${nativeLanguage} speakers:
  - Compare sounds to familiar ${nativeLanguage} sounds where possible.
  - Describe tongue/lip position for difficult sounds.
  - Warn about common mistakes ${nativeLanguage} speakers make.
  - Keep hints concise (1-2 sentences).

### Emojis
- Each unit and lesson should have a relevant, distinct emoji.
- Use emojis that visually represent the topic (e.g., food, greetings, numbers).

## Output Schema

Return ONLY a JSON object matching this exact structure:

\`\`\`json
{
  "units": [
    {
      "id": 1,
      "emoji": "...",
      "title": "Unit title in ${nativeLanguage}",
      "description": "Brief description in ${nativeLanguage}",
      "difficulty": "beginner" | "intermediate" | "advanced",
      "lessons": [
        {
          "id": 1,
          "unitId": 1,
          "order": 1,
          "emoji": "...",
          "title": "Lesson title in ${nativeLanguage}",
          "korean": "${targetLanguage} text",
          "romanization": "accurate revised romanization",
          "translation": "${nativeLanguage} translation",
          "difficulty": "beginner" | "intermediate" | "advanced",
          "hint": "Pronunciation tip for ${nativeLanguage} speakers"
        }
      ]
    }
  ]
}
\`\`\`

Important:
- Lesson IDs must be globally unique across all units (1, 2, 3, ... sequentially).
- Unit IDs start at 1 and increment.
- "order" is 1-based within each unit.
- Ensure romanization is accurate according to the Revised Romanization system.
- Make hints genuinely useful, not generic.`;

    const response = await this.client.messages.create({
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: systemPrompt,
      messages: [{ role: "user", content: userPrompt }],
    });

    const text =
      response.content[0]?.type === "text" ? response.content[0].text : "";
    const parsed: unknown = JSON.parse(extractJson(text));
    return parsed as UnitsFile;
  }

  // -----------------------------------------------------------------------
  // Stories
  // -----------------------------------------------------------------------

  async generateStories(opts: StoryGenerationOptions): Promise<StoriesFile> {
    const { nativeLanguage, targetLanguage, storyCount } = opts;

    const systemPrompt = `You are an expert ${targetLanguage} language teacher who writes engaging short stories for pronunciation practice. You specialize in creating stories that are natural, culturally authentic, and carefully graded by difficulty level. You understand the phonetic challenges ${nativeLanguage} speakers face when learning ${targetLanguage}.

Your output MUST be valid JSON and nothing else. Do not include any explanation outside the JSON.`;

    const userPrompt = `Generate ${storyCount} short stories for ${nativeLanguage} speakers practicing ${targetLanguage} pronunciation.

## Content Guidelines

### Story Design
- Each story should be a self-contained mini-narrative (5-8 sentences).
- Stories should cover diverse, relatable topics: daily life, travel, food, school, work, seasons, hobbies, family, shopping, weather.
- Make stories culturally authentic with natural ${targetLanguage} phrasing (avoid translationese).
- Distribute difficulty: roughly 40% beginner, 35% intermediate, 25% advanced.
  - **Beginner**: Simple sentences, basic vocabulary, present tense, short sentences (3-8 words).
  - **Intermediate**: Compound sentences, past/future tenses, connectors, everyday idioms.
  - **Advanced**: Complex grammar, honorific speech levels, nuanced vocabulary, longer sentences.

### Sentence Quality
- Each sentence should be a natural, standalone ${targetLanguage} sentence.
- Avoid overly formal or textbook-like language; aim for how native speakers actually talk.
- The "romanization" MUST follow the Revised Romanization of Korean system precisely:
  - Apply all assimilation, tensification, and liaison rules.
  - ㅓ = "eo", ㅡ = "eu", ㅢ = "ui".
  - Final consonants: ㄱ="k", ㅂ="p", ㄷ="t", ㄹ="l".
  - Nasalization: ㄱ before ㄴ/ㅁ becomes "ng", ㅂ before ㄴ/ㅁ becomes "m".
- Translations should be natural ${nativeLanguage}, not word-for-word.

### Emojis
- Each story should have a single emoji that represents its theme.

## Output Schema

Return ONLY a JSON object matching this exact structure:

\`\`\`json
{
  "stories": [
    {
      "id": 1,
      "title": "Story title in ${nativeLanguage}",
      "titleKorean": "Story title in ${targetLanguage}",
      "emoji": "...",
      "difficulty": "beginner" | "intermediate" | "advanced",
      "sentences": [
        {
          "id": 1,
          "korean": "${targetLanguage} sentence",
          "romanization": "accurate revised romanization",
          "translation": "Natural ${nativeLanguage} translation"
        }
      ]
    }
  ]
}
\`\`\`

Important:
- Story IDs start at 1 and increment.
- Sentence IDs are 1-based within each story.
- Every story must have between 5 and 8 sentences.
- Romanization must be pronunciation-accurate (reflect actual spoken form, including liaison and assimilation).`;

    const response = await this.client.messages.create({
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: systemPrompt,
      messages: [{ role: "user", content: userPrompt }],
    });

    const text =
      response.content[0]?.type === "text" ? response.content[0].text : "";
    const parsed: unknown = JSON.parse(extractJson(text));
    return parsed as StoriesFile;
  }

  // -----------------------------------------------------------------------
  // Themes
  // -----------------------------------------------------------------------

  async generateThemes(opts: ThemeGenerationOptions): Promise<ThemesFile> {
    const { nativeLanguage, targetLanguage, themeCount } = opts;

    const systemPrompt = `You are an expert ${targetLanguage} conversation coach who designs engaging free-talk practice themes. You understand what topics motivate language learners and how to scaffold conversations at different proficiency levels. You have deep cultural knowledge of ${targetLanguage}-speaking countries.

Your output MUST be valid JSON and nothing else. Do not include any explanation outside the JSON.`;

    const userPrompt = `Generate ${themeCount} conversation themes for ${nativeLanguage} speakers practicing ${targetLanguage} in free-talk sessions.

## Content Guidelines

### Theme Design
- Themes should cover a wide range of practical and engaging topics: ordering food, asking directions, introducing yourself, talking about hobbies, describing weather, making plans, shopping, expressing opinions, telling stories about your day, travel experiences.
- Each theme should feel like a real conversational scenario a learner might encounter.
- Distribute difficulty: roughly 35% beginner, 35% intermediate, 30% advanced.
  - **Beginner** (minDurationSeconds: 30-60): Simple exchanges, basic vocabulary, formulaic phrases.
  - **Intermediate** (minDurationSeconds: 60-120): Extended conversation, expressing opinions, narrating events.
  - **Advanced** (minDurationSeconds: 120-180): Debate, nuanced expression, cultural topics, formal/informal register switching.

### Keywords
- Provide 5-8 vocabulary keywords (in ${targetLanguage}) that are central to the theme.
- Keywords should be high-frequency words a learner would actually need for this conversation.

### Example Sentences
- Provide 3-5 example ${targetLanguage} sentences a learner might use during this theme.
- Sentences should model good pronunciation patterns and natural phrasing.
- Include a mix of questions and statements.
- Sentences should be appropriate for the difficulty level.

### IDs
- Use kebab-case English IDs derived from the theme name (e.g., "ordering-food", "asking-directions").

### Emojis
- Each theme gets a single representative emoji.

## Output Schema

Return ONLY a JSON object matching this exact structure:

\`\`\`json
{
  "themes": [
    {
      "id": "theme-id-kebab-case",
      "emoji": "...",
      "name": "Theme name in ${nativeLanguage}",
      "koreanName": "Theme name in ${targetLanguage}",
      "description": "Brief description in ${nativeLanguage}",
      "keywords": ["${targetLanguage} keyword 1", "${targetLanguage} keyword 2", "..."],
      "difficulty": "beginner" | "intermediate" | "advanced",
      "minDurationSeconds": 30,
      "exampleSentences": [
        "${targetLanguage} example sentence 1",
        "${targetLanguage} example sentence 2"
      ]
    }
  ]
}
\`\`\`

Important:
- All keywords and exampleSentences must be in ${targetLanguage} (not ${nativeLanguage}).
- IDs must be unique kebab-case strings.
- minDurationSeconds should reflect realistic practice time for the difficulty level.
- Example sentences should be natural and conversationally appropriate.`;

    const response = await this.client.messages.create({
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: systemPrompt,
      messages: [{ role: "user", content: userPrompt }],
    });

    const text =
      response.content[0]?.type === "text" ? response.content[0].text : "";
    const parsed: unknown = JSON.parse(extractJson(text));
    return parsed as ThemesFile;
  }
}
