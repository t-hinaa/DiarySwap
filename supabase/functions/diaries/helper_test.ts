import { assertEquals,assertThrows } from "@std/assert";
import { validateDiaryInput } from "./helper.ts";

Deno.test("Diaries: 正しい入力なら正常にパースできること", () => {
    const validData = {
        content: "今日はいい天気",
        weather: "晴れ",
        seal_stamp: "gold"
    };

    const result = validateDiaryInput(validData);
    assertEquals(result.content, "今日はいい天気");
    assertEquals(result.weather, "晴れ");
    assertEquals(result.seal_stamp, "gold");
});

Deno.test("validateDiaryInput: 本文が空の場合エラーになること", () => {
    const invalidData = {
        content: "",
        weather: "晴れ",
        seal_stamp: "gold"
    };

    assertThrows(() => {
        validateDiaryInput(invalidData);
    });
});

Deno.test("validateDiaryInput: 天気が未選択の場合はエラーになること", () => {
    const invalidData = {
        content: "今日はいい天気",
        weather: "",
        seal_stamp: "gold"
    };

    assertThrows(() => {
        validateDiaryInput(invalidData);
    });
});

Deno.test("validateDiaryInput: シーリングスタンプが未選択の場合はエラーになること", () => {
    const invalidData = {
        content: "今日はいい天気",
        weather: "晴れ",
        seal_stamp: ""
    };

    assertThrows(() => {
        validateDiaryInput(invalidData);
    });
});