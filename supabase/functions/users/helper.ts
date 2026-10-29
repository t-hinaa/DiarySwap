import { z } from "zod";

export const userSchema = z.object({
    line_user_id: z.string().min(1, "LINEユーザーIDは必須です"),
    display_name: z.string().min(1, "表示名は必須です"),
    avatar_url: z.string().url("アバターのURLの形式がただしくありません").optional()
});

export function validateAndFormatUser(input: unknown) {
    const result = userSchema.safeParse(input);

    if (!result.success) {
        throw new Error("ユーザーのバリデーションエラー");
    }

    return {
        ...result.data,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
    };
}