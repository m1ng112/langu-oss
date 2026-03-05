# `POST /api/v1/evaluate-theme` エンドポイント実装依頼

## 概要

iOS側に「テーマ別フリートーク（Theme Response Evaluator）」機能を追加しました。ユーザーがテーマに沿って韓国語で自由に話し、その内容を評価する機能です。バックエンド側に新しいエンドポイントの実装をお願いします。

## エンドポイント

```
POST /api/v1/evaluate-theme
Content-Type: application/json
```

## リクエストボディ

```json
{
  "recognizedText": "저는 한국 음식을 좋아해요. 특히 김치찌개가 맛있어요.",
  "themeId": "selfIntro",
  "themeName": "자기소개",
  "themeDescription": "Introduce yourself in Korean - name, nationality, hobbies",
  "keywords": ["이름", "나라", "취미", "좋아하다", "저는"]
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `recognizedText` | string | Yes | Azure Speech SDKで認識されたユーザーの発話テキスト |
| `themeId` | string | Yes | テーマの識別子 |
| `themeName` | string | Yes | テーマの韓国語名 |
| `themeDescription` | string | Yes | テーマの説明（英語） |
| `keywords` | string[] | Yes | テーマに関連するキーワードリスト |

## レスポンス（成功時）

```json
{
  "success": true,
  "data": {
    "overallScore": 78,
    "relevanceScore": 85,
    "vocabularyScore": 72,
    "grammarScore": 68,
    "expressionScore": 80,
    "feedback": "テーマに沿った良い回答です。文法をもう少し意識してみましょう。",
    "usedKeywords": ["저는", "좋아하다"],
    "suggestedVocabulary": ["잘하다", "관심이 있다", "출신이에요"],
    "detailedFeedback": [
      {
        "type": "excellent",
        "message": "Your response is highly relevant to the theme."
      },
      {
        "type": "good",
        "message": "Good vocabulary usage for this topic."
      },
      {
        "type": "tip",
        "message": "Try using more varied sentence endings like ~ㄹ 수 있어요."
      }
    ]
  }
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `overallScore` | int (0-100) | 総合スコア（4つのスコアの加重平均でもOK） |
| `relevanceScore` | int (0-100) | テーマとの関連性 |
| `vocabularyScore` | int (0-100) | 語彙の豊かさ・適切さ |
| `grammarScore` | int (0-100) | 文法の正確さ |
| `expressionScore` | int (0-100) | 表現の自然さ・多様性 |
| `feedback` | string | 総合フィードバックメッセージ |
| `usedKeywords` | string[] | `keywords`のうち実際に使用されたもの |
| `suggestedVocabulary` | string[] | テーマに関連するおすすめ語彙 |
| `detailedFeedback` | object[] | 詳細フィードバック（任意） |
| `detailedFeedback[].type` | string | `"excellent"` / `"good"` / `"tip"` のいずれか |
| `detailedFeedback[].message` | string | フィードバックメッセージ（英語） |

## レスポンス（エラー時）

```json
{
  "success": false,
  "error": "recognizedText is required"
}
```

## 評価ロジックの提案

LLM（Claude / GPT等）を使って以下を評価するのが良さそうです：

1. **Relevance (関連性)**: `recognizedText` が `themeName` / `themeDescription` / `keywords` にどの程度関連しているか
2. **Vocabulary (語彙)**: テーマに適した語彙を使えているか、`keywords` のうちどれを使ったか
3. **Grammar (文法)**: 韓国語の文法として正しいか（助詞、語尾、語順など）
4. **Expression (表現)**: 表現の多様性、自然さ、文の長さ・複雑さ

`overallScore` は4つの平均、もしくは関連性に重みをつけた加重平均（例: `(relevance*3 + vocabulary*2 + grammar*3 + expression*2) / 10`）を推奨。

## iOS側の実装状況

- `ThemeEvaluationService.swift` でこのエンドポイントを呼び出し済み
- `detailedFeedback` が返らない場合はiOS側でスコアに基づくフォールバック生成あり
- `overallScore` が返らない場合は4スコアの平均をiOS側で算出

## 既存エンドポイントとの整合性

既存の `/api/v1/assess` と同じレスポンス形式（`{ success, data }` / `{ success, error }`）に合わせています。
