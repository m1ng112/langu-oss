// Azure Speech API types

export interface PronunciationAssessmentConfig {
  ReferenceText: string;
  GradingSystem: 'HundredMark' | 'FivePoint';
  Granularity: 'Phoneme' | 'Word' | 'FullText';
  Dimension: 'Basic' | 'Comprehensive';
  EnableMiscue: boolean;
}

export interface AzureSpeechResult {
  RecognitionStatus: 'Success' | 'NoMatch' | 'InitialSilenceTimeout' | 'Error';
  DisplayText?: string;
  NBest?: AzureNBestResult[];
}

export interface AzureNBestResult {
  Confidence: number;
  Display: string;
  PronScore?: number;
  AccuracyScore?: number;
  FluencyScore?: number;
  CompletenessScore?: number;
  ProsodyScore?: number;
  Words?: AzureWordResult[];
}

export interface AzureWordResult {
  Word: string;
  Offset: number;
  Duration: number;
  AccuracyScore?: number;
  ErrorType?: string;
}

// API Request/Response types

export interface AssessRequest {
  audio: string; // base64 encoded WAV
  referenceText?: string; // Optional: if empty, transcription-only mode
  lessonId?: number;
}

export interface AssessResponse {
  success: boolean;
  data?: {
    pronunciationScore: number;
    accuracyScore: number;
    fluencyScore: number;
    completenessScore: number;
    prosodyScore: number;
    recognizedText?: string;
  };
  error?: string;
  meta?: {
    assessmentId: string;
    processedAt: string;
    mode?: 'transcription' | 'assessment';
  };
}

export interface Env {
  AZURE_SPEECH_KEY: string;
  AZURE_SPEECH_REGION: string;
  ANTHROPIC_API_KEY: string;
  RATE_LIMIT_PER_DAY: string;
}

// Theme evaluation types

export interface EvaluateThemeRequest {
  recognizedText: string;
  themeId: string;
  themeName: string;
  themeDescription: string;
  keywords: string[];
}

export interface DetailedFeedbackItem {
  type: 'excellent' | 'good' | 'tip';
  message: string;
}

export interface EvaluateThemeData {
  overallScore: number;
  relevanceScore: number;
  vocabularyScore: number;
  grammarScore: number;
  expressionScore: number;
  feedback: string;
  usedKeywords: string[];
  suggestedVocabulary: string[];
  detailedFeedback: DetailedFeedbackItem[];
}

export interface EvaluateThemeResponse {
  success: boolean;
  data?: EvaluateThemeData;
  error?: string;
}
