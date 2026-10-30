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

    // LINEログイン
    const loginWithLine = async () => {
        const { error } = await supabase.auth.signInWithOAuth({
            provider: 'line',
            options: {
                redirectTo: `${window.location.origin}/home`, //ログイン成功後に戻ってくる場所
            },
        })
        
        if (error) {
            console.error('LINEログインエラー:',error.message)
            alert('ログインに失敗しました')
        }
    }
</script>