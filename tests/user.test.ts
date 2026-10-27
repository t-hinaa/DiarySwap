import { describe, it, expect } from 'vitest'
import { z } from 'zod' //この行は削除して本物のスキーマをインポートする。

// 導入テストのため、本物のテストを行う際は削除する。
const userSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
})

describe('Zodユーザーモデルのテスト', () => {
  it('正しいデータなら成功する', () => {
    const data = { name: 'テスト太郎', email: 'test@example.com' }
    const result = userSchema.safeParse(data)
    expect(result.success).toBe(true)
  })

  it('不正なメールなら失敗する', () => {
    const data = { name: 'テスト太郎', email: 'invalid-email' }
    const result = userSchema.safeParse(data)
    expect(result.success).toBe(false)
  })
})