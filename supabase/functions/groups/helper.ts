import { z } from "zod";

// groupテーブルについて
export const groupSchema = z.object({
    name: z.string().min(1, "グループ名は必須です").max(50, "グループ名は50文字以内で入力してください"),
    invite_code: z.string().min(4, "招待コードは4文字以上で入力してください"),
    exchange_frequency: z.string().min(1, "交換頻度を選択してください"),
    theme_package: z.string().min(1, "お題パッケージを選択してください"),
});

export type GroupInput = z.infer<typeof groupSchema>;

// member 型の定義
export interface GroupMember {
    id: string;
    user_id: string;
    turn_order: number;
}

// グループ作成・更新の入力データの検証
export function validateGroupInput(input: unknown): GroupInput {
    return groupSchema.parse(input);
}

// 順番について
export function getNextMember(members: GroupMember[], currentTurnIndex: number): GroupMember | null {
    if (members.length === 0) return null;

    const sorted = [...members].sort((a,b) => a.turn_order - b.turn_order);
    const index = currentTurnIndex % sorted.length;
    return sorted[index];
}

