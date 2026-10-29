import { assertEquals, assertThrows } from "@std/assert";
import { userSchema, validateAndFormatUser } from "./helper.ts";

// 正常系
Deno.test("正しいユーザーデータの場合、バリデーションを通過して正しく整形されること", () => {
    const inputData = {
        line_user_id: "U1234567890abcdef",
        display_name: "テストテスト",
        avatar_url: "https://example.com/avatar.png"
    };

    const result = validateAndFormatUser(inputData);

    // 期待通りかチェック
    assertEquals(result.line_user_id, "U1234567890abcdef");
    assertEquals(result.display_name, "テストテスト");
    assertEquals(typeof result.created_at, "string");
});

// 異常系
Deno.test("line_user_idやdisplay_nameが欠けている場合、エラーになること", () => {
    const invalidData = {
        display_name: "テストテスト"
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
