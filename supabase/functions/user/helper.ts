import { z } from "zod";

export const userSchema = z.object({
    lineUserId: z.string().min(1, "LINEユーザーIDは必須です"),
    displayName: z.string().min(1, "表示名は必須です"),
    avatarUrl: z.string().url("アバターのURLの形式がただしくありません").optional()
});

export function validateAndFormatUser(input: unknown) {
    const result = userSchema.safeParse(input);

    if (!result.success) {
        throw new Error("ユーザーのバリデーションエラー");
    }

    return {
        ...result.data,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
    };
}