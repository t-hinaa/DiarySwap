import { assertEquals, assertThrows }  from "@std/assert";
import { validateGroupInput,getNextMember,GroupMember  } from "./helper.ts";


// グループ情報のバリデーションテスト
Deno.test("validateGroupInput: 正しいグループデータなら正常にパースできること", () => {
    const validate = {
        name: "ナイスデイ",
        invite_code: "abc1234",
        exchange_frequency: "2人",
        theme_package: "standard"
    };

    const result = validateGroupInput(validate);
    assertEquals(result.name, "ナイスデイ");
    assertEquals(result.invite_code, "abc1234");
    assertEquals(result.exchange_frequency, "2人");
    assertEquals(result.theme_package, "standard");
});

Deno.test("validateGroupInput: グループ名が空の場合はエラーになること", () => {
    const invalidData = {
        name: "",
        invite_code: "abc1234",
        exchange_frequency: "2人",
        theme_package: "standard"
    };

    assertThrows(() => {
        validateGroupInput(invalidData);
    });
});

Deno.test("validateGroupInput: グループ名が50文字以上の場合はエラーになること", () => {
    const invalidData = {
        name: "あ".repeat(51),
        invite_code: "abc1234",
        exchange_frequency: "2人",
        theme_package: "standard"
    };

    assertThrows(() => {
        validateGroupInput(invalidData);
    });
});

Deno.test("validateGroupInput: 招待コードが4文字未満の場合はエラーになること", () => {
    const invalidData = {
        name: "ナイスデイ",
        invite_code: "123",
        exchange_frequency: "2人",
        theme_package: "standard"
    };

    assertThrows(() => {
        validateGroupInput(invalidData);
    });
});
Deno.test("validateGroupInput: 交換頻度やお題パッケージが未選択の場合はエラーになること", () => {
    const invalidData = {
        name: "ナイスデイ",
        invite_code: "abc1234",
        exchange_frequency: "",
        theme_package: "standard"
    };

    assertThrows(() => {
        validateGroupInput(invalidData);
    });
});

// 順番についてのテスト
Deno.test("getNextMember: 順番(turn_order)通りに次のメンバーが選ばれ、人数を超えたらループすること", () => {
    const members: GroupMember[] = [
        { id: "m2", user_id: "user_B", turn_order: 2 },
        { id: "1", user_id: "user_A", turn_order: 1 }, //あえて順番をバラバラにすることによりテスト内でソートされるか確認する
        { id: "m3", user_id: "user_C", turn_order: 3 },
    ];

    // 1番目
    assertEquals(getNextMember(members, 0)?.user_id, "user_A");

    // 2番目
    assertEquals(getNextMember(members, 1)?.user_id, "user_B");

    // 3番目
    assertEquals(getNextMember(members, 2)?.user_id, "user_C");

    // 3人が終わったのでループして再び1人目に戻る
    assertEquals(getNextMember(members, 3)?.user_id, "user_A");

    // 2番目
    assertEquals(getNextMember(members, 4)?.user_id, "user_B");
});

Deno.test("getNextMember: メンバーが0人の場合はnullを返すこと", () => {
    const result = getNextMember([], 0);
    assertEquals(result, null);
});
