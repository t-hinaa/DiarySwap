<script setup>
defineProps({
    theme: {
        type: Object,
        default: null
    }
})

const emit = defineEmits(['close', 'confirm'])
</script>

<template>
    <div v-if="theme" class="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4 z-50 animate-fadeIn">
        <div class="bg-white rounded-3xl p-6 md:p-8 max-w-md w-full shadow-2xl border border-[#EFECE6] relative space-y-4 font-serif">

            <!-- 閉じるボタン -->
            <button
                @click="emit('close')"
                class="absolute top-4 right-4 text-[#8C7B73] hover:text-[#3A2E2B] w-8 h-8 rounded-full bg-[#FAFAF8] border border-[#E2DAD0] flex items-center justify-center transition text-sm font-bold"
            >
                ×
            </button>
            <!-- モーダルヘッダー -->
            <div>
                <span class="text-[10px] uppercase tracking-wider font-semibold text-[#8C7B73] bg-[#F4EFEA] px-2 py-1 rounded">
                    お題パッケージ詳細
                </span>
                <h3 class="text-xl font-bold text-[#5A1222] mt-2">【 {{ theme.title }} 】</h3>
            </div>

            <!-- 詳細テキストボックス -->
            <div class="bg-[#FAFAF8] border border-[#E2DAD0] p-4 rounded-2xl text-xs text-[#6B5B53] leading-relaxed whitespace-pre-line max-h-48 overflow-y-auto space-y-2">
                <p class="font-bold text-[#3A2E2B]">{{ theme.subtitle }}</p>
                <ul class="space-y-1 pl-2">
                    <li v-for="(point,index) in theme.points" :key="index">
                        ・{{ point }}
                    </li>
                </ul>
            </div>

            <!-- アクションボタン -->
            <div class="space-y-2 pt-2">
                <button
                    @click="emit('confirm', theme.id)"
                    class="w-full bg-[#5A1222] hover:bg-[#430D19] text-[#FDFBF7] font-medium py-3 rounded-xl shadow-md transition text-sm"
                >
                    決定
                </button>
                <button
                    @click="emit('close')"
                    class="w-full bg-[#FAFAF8] hover:bg-[#F2ECE4] text-[#6B5B53] font-medium py-2.5 rounded-xl transition text-xs border border-[#E2DAD0]"
                >
                    閉じる
                </button>
            </div>
        </div>
    </div> 
</template>