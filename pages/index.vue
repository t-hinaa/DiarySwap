<template>
    <div class="max-w-xl mx-auto text-center py-12">
        <h1 class="text-3xl font-bold mb-4 text-gray-900">DiarySwap</h1>
        <p class="text-gray-600 mb-8">あ、交換日記しよ</p>

        <div>
            <button
                @click="loginWithLine"
                class="px-6 py-3 bg-[#06C755] hover:bg-[#05b34c] text-white font-bold rounded-lg shadow-md transition duration-200 cursor-pointer flex items-center justify-center gap-3 mx-auto"
            >
                <span class="text-xl">💬</span>
                <span>LINEでログインして始める</span>
            </button>
        </div>
    </div>
</template>

<script setup>
const supabase = useSupabaseClient()

// 設定
const LINE_CHANNEL_ID = "2012285519"
const SUPABASE_URL = `https://bmwibppijrcgbhvodylz.supabase.co`
    
// LINEログイン
const loginWithLine = () => {
    const redirectUri = window.location.origin
    const lineAuthUrl = `https://access.line.me/oauth2/v2.1/authorize?response_type=code&client_id=${LINE_CHANNEL_ID}&redirect_uri=${encodeURIComponent(redirectUri)}&state=12345&scope=profile%20openid`

    window.location.href = lineAuthUrl
}

// LINEログイン後に戻ってきた時のコード受け取り処理
onMounted(async () => {
    const urlParams = new URLSearchParams(window.location.search)
    const code = urlParams.get('code')

    if (code) {
        try {
            const response = await fetch(`https://bmwibppijrcgbhvodylz.supabase.co/functions/v1/quick-responder`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    code: code,
                    redirect_uri: window.location.origin,
                }),
            })

            const result = await response.json()

            if (!response.ok) {
                throw new Error(result.error || 'ログインに失敗しました') 
            }

            // URLを削除してから/homeへ
            window.history.replaceState({}, document.title, window.location.pathname)
            navigateTo('/home')

        } catch (err) {
            console.error('認証エラー:', err)
            alert(`ログインに失敗しました: ${err.message}`)
        }
    }
})    
</script>