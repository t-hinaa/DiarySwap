<template>
    <div class="min-h-screen flex flex-col bg-[#FAF8F5] text-gray-800">
        <!-- ログイン後のみ表示するヘッダー -->
        <header
            v-if="route.path !== '/'"
            class="bg-[#FAF8F5]/90 backdrop-blur border-b border-stone-200/60 px-6 py-4 sticky top-0 z-50">
            <div class="max-w-7xl mx-auto flex justify-between items-center">
                <div class="flex items-center gap-3">
                    <div class="w-9 h-9 bg-[#8B263E] text-white rounded-full flex items-center justify-center font-bold text-sm shadow-sm">
                        📕
                    </div>
                    <NuxtLink to="/home" class="text-xl font-bold text-[#8B263E] tracking-wide hover:opacity-80 transition">
                        DiarySwap
                    </NuxtLink>
                </div>

                <nav class="hidden md:flex items-center bg-[#EFECE6] p-1.5 rounded-full border border-stone-200/50 text-sm shadow-inner">
                    <NuxtLink to="/home" class="px-5 py-2 rounded-full text-stone-600 font-medium hover:text-stone-900 transition duration-200">
                        ホーム
                    </NuxtLink>
                    <NuxtLink to="/read" class="px-5 py-2 rounded-full text-stone-600 font-medium hover:text-stone-900 transition duration-200">
                        日記を読む
                    </NuxtLink>
                    <NuxtLink to="/write" class="px-5 py-2 rounded-full text-stone-600 font-medium hover:text-stone-900 transition duration-200">
                        日記を書く
                    </NuxtLink>
                    <NuxtLink to="/create" class="px-5 py-2 rounded-full text-stone-600 font-medium hover:text-stone-900 transition duration-200">
                        日記を始める
                    </NuxtLink>
                </nav>

                <div class="flex items-center gap-4">
                    <button
                        @click="handleLogout"
                        class="text-xs px-3 py-1.5 rounded-lg border border-stone-300 text-stone-600 hover:bg-stone-200/60 transition duration-200 cursor-pointer"
                    >
                        ログアウト
                    </button>

                    <div class="flex items-center gap-2">
                        <div class="w-9 h-9 rounded-full bg-[#8E263E] text-white flex items-center justify-center text-xs font-bold shadow-sm overflow-hidden">
                            <span>🧸</span>
                        </div>
                    </div>
                </div>
            </div>
        </header>

        <main class="flex-grow">
            <slot />
        </main>
    </div>
</template>

<script setup>
const route = useRoute()

const handleLogout = () => {
    console.log('ログアウトします')
}
</script>