

import { assertEquals, assertThrows } from "@std/assert";
import { userSchema, validateAndFormatUser } from "./helper.ts";

// 正常系
Deno.test("正しいユーザーデータの場合、バリデーションを通過して正しく整形されること", () => {
    const inputData = {
        lineUserId: "U1234567890abcdef",
        displayName: "テストテスト",
        avatarUrl: "https://example.com/avatar.png"
    };

    const result = validateAndFormatUser(inputData);

    // 期待通りかチェック
    assertEquals(result.lineUserId, "U1234567890abcdef");
    assertEquals(result.displayName, "テストテスト");
    assertEquals(typeof result.createdAt, "string");
});

// 異常系
Deno.test("lineUseIdやdisplayNameが欠けている場合、エラーになること", () => {
    const invalidData = {
        displayName: "テストテスト"
    };

    // エラーが発生するかテスト
    assertThrows(
        () => {
            validateAndFormatUser(invalidData);
        },
        Error,
        "ユーザーのバリデーションエラー"
    );
});
