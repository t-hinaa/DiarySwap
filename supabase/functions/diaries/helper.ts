import { z } from "zod";

// diariesテーブルの入力チェック
export const diarySchema = z.object({
    content: z.string().min(1, "本文を入力してください。").max(20000, "本文は20000文字以内で入力してください。"),
    weather: z.string().min(1, "天気を選択してください。"),
    seal_stamp: z.string().min(1, "シーリングスタンプを選択してください"),
});

export type DiaryInput = z.infer<typeof diarySchema>;

// 日記投稿の入力データを検証
export function validateDiaryInput(input: unknown): DiaryInput {
    return diarySchema.parse(input);
}