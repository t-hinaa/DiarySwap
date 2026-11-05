<template>
    <div class="flex items-center justify-center min-h-screen">
        <p class="text-gray-600">ログイン処理中...</p>
    </div>
</template>

<script setup>
import { onMounted } from 'vue'

const supabase = useSupabaseClient()

onMounted(async () => {
    const urlParams = new URLSearchParams(window.location.search)
    const code = urlParams.get('code')

    if (code) {
        try {
            const redirectUri = `${window.location.origin}/auth/callback`

            const response = await fetch(`https://bmwibppijrcgbhvodylz.supabase.co/functions/v1/quick-responder`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    code: code,
                    redirect_uri: redirectUri,
                }),
            })

            const result = await response.json()

            if (!response.ok) {
                throw new Error(result.error || 'ログインに失敗しました') 
            }

            // Supabaseのセッション（ログイン状態）を確立する
            const { error: verifyErr } = await supabase.auth.verifyOtp({
                token_hash: result.hashedToken,
                type: 'magiclink',
            })

            if (verifyErr) throw verifyErr

            // state から「本来戻るべきページのパス」を取り出す（なければ /home）
            const stateParam = new URLSearchParams(window.location.search).get('state')
            let originalPath = decodeURIComponent(stateParam || '/home')
            if (!originalPath.startsWith('/')) {
                originalPath = '/home'
            }

            // 元のページへ移動
            navigateTo(originalPath)

        } catch (err) {
            console.error('認証エラー:', err)
            alert(`ログインに失敗しました: ${err.message}`)
            navigateTo('/home')
        }
    } else {
        // codeがないのにこのページに来てしまった場合はホームへ逃がす
        navigateTo('/home')
    }
})
</script>