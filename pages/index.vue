<template>
    <div class="max-w-xl mx-auto text-center py-12">
        <h1 class="text-3xl font-bold mb-4 text-gray-900">DiarySwap</h1>
        <p class="text-gray-600 mb-8">あ、交換日記しよ</p>

        <div>
            <!-- あとでLINEログイン、@click="goToHome"を導入 -->
            <button 
                class="px-6 py-3 bg-[#06C755] hover:bg-[#05b34c] text-white font-bold rounded-lg shadow-md transition duration-200 cursor-pointer"
            >
                LINEでログインして始める
            </button>
        </div>
    </div>
</template>

<script setup>
    const router = useRouter()

    const goToHome = () => {
        //　ログインした感じで
        router.push('/home')
    }
</script>