<template>
    <div
        class="relative min-h-dvh bg-[#FAF8F5] text-[#1E080E] font-serif flex flex-col justify-between px-6 py-6 sm:px-10 overflow-x-clip"
    >

        <div
            class="bookmark-ribbon fixed top-0 right-[16%] sm:right-[23%]  w-3.5 sm:w-4 h-24 sm:h-28 bg-gradient-to-b from-[#8B263E] via-[#6E1A2E] to-[#430D19] z-20 pointer-events-none"
            aria-hidden="true"
        />

        <div class="h-10 sm:h-14" aria-hidden=true />

        <main class="w-full max-w-md mx-auto flex flex-col items-center text-center my-auto py-4">
            <div class="relative mb-9 flex items-center justify-center">

                <div
                    aria-hidden="true"
                    class="w-[265px] sm:w-[320px] aspect-square translate-x-2.5 translate-y-3 bg-[#381017]/15 rounded-[50%_50%_70%_30%/40%_60%_40%_60%] blur-[4px]"
                />

                <div class="absolute inset-0 w-[265px] sm:w-[320px] aspect-square overflow-hidden border border-[#381017]/25 bg-[#FAF8F5] rounded-[50%_50%_70%_30%/40%_60%_40%_60%] shadow-[0_16px_36px_rgba(30,8,14,0.14),inset_0_0_0_1px_rgba(250,248,245,0.6)]">
                    <img
                        src="/images/top.jpg"
                        alt="日記イメージ"
                        class="w-full h-full object-cover object-bottom block"
                    />
                </div>
            </div>

            <h1 class="text-[2.6rem] sm:text-[3.35rem] leading-[1.08] font-normal tracking-[0.04em] text-[#381017] mb-3">
                DiarySwap
            </h1>

            <p class="text-xs sm:text-[13px] tracking-[0.18em] text-[#73635B] mb-11">
                あ、交換日記しよ
            </p>

            <div class="flex flex-col items-center gap-4 w-full">
                <button
                    ref="lineBtnRef"
                    type="button"
                    :style="{ transform: lineBtnTransform }"
                    class="font-sans bg-gradient-to-b from-[#962B45] to-[#7A1E34] hover:from-[#6B172B] hover:to-[#4D0F1E] active:from-[#4D0F1E] active:to-[#381017] text-[#FAF8F5] text-xs sm:text-sm font-medium tracking-[0.08em] px-8 py-3.5 rounded-full border border-[#381017]/30 shadow-[inset_0_1px_0_rgba(250,248,245,0.28),0_12px_24px_rgba(30,8,14,0.22)] transition-colors duration-200 cursor-pointer will-change-transform"
                    @click="loginWithLine"
                >
                    LINEでログインして始める
                </button>

                <!-- ゲストユーザー -->
                <button
                    v-if="showGuestLogin"
                    type="button"
                    class="font-sans text-xs sm:text-sm tracking-wider text-[#73635B] hover:text-[#1E080E] underline underline-offset-4 transition-colors duration-200 cursor-pointer"
                    @click="handleGuestLogin"
                >
                    ゲストユーザーはこちら
                </button>
            </div>
        </main>

        <!-- 利用規約・プライバシーポリシー -->
        <footer class="w-full max-w-4xl mx-auto flex flex-col items-center gap-1.5 pt-10">
            <nav
                v-if="showLegalLinks"
                aria-label="利用規約・プライバシーポリシー"
                class="font-sans flex flex-wrap items-center justify-center gap-x-5 gap-y-1 text-xs tracking-[0.06em] text-[#73635B]"
            >
                <NuxtLink
                    to="/terms"
                    class="hover:text-[#381017] underline underline-offset-4 transition-colors duration-200"
                >
                    利用規約
                </NuxtLink>
                <NuxtLink
                    to="/privacy"
                    class="hover:text-[#381017] underline underline-offset-4 transition-colors duration-200"
                >
                    プライバシーポリシー
                </NuxtLink>
            </nav>

            <span class="text-[10px] tracking-[0.22em] text-[#8C7B73] pt-2">
                © DiarySwap
            </span>
        </footer>
    </div>
</template>

<script setup>
const supabase = useSupabaseClient()

// 設定
const LINE_CHANNEL_ID = "2012285519"

// 使う時にtrueに
const showGuestLogin = ref (true); // ゲストログイン
const showLegalLinks = ref (true); // 利用規約・プライバシーポリシ-
    
// LINEログイン
const loginWithLine = () => {
    const redirectUri = `${window.location.origin}/auth/callback`

    // window.location.pathnameの中にstateを入れる
    const targetPath = (window.location.pathname === '/' || window.location.pathname === '') 
        ? '/home' 
        : window.location.pathname
    const stateValue = encodeURIComponent(targetPath)

    const lineAuthUrl = `https://access.line.me/oauth2/v2.1/authorize?response_type=code&client_id=${LINE_CHANNEL_ID}&redirect_uri=${encodeURIComponent(redirectUri)}&state=${stateValue}&scope=profile%20openid`
    window.location.href = lineAuthUrl
}

// ゲストログイン
const handleGuestLogin = () => {
    console.log("ゲストログイン(準備中)");
};

// アニメーションのインポート
const { elRef: lineBtnRef, transformStyle: lineBtnTransform } = useJello({
    stiffness: 0.12,
    damping: 0.8,
    enterScaleX: 1.04,
    enterScalY: 0.96,
    rotStrength: 2
});
</script>

<style scoped>
/* 栞リボンの先端をV字に切り抜き＋ドロップシャドウ */
.bookmark-ribbon {
    clip-path: polygon(0 0, 100% 0, 100% 100%, 50% 82%, 0 100%);
    filter: drop-shadow(0 6px 10px rgba(30, 8, 14, 0.22));
}
</style>