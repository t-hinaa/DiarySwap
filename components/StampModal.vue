<script setup>
const props = defineProps({
    selectedWax: String,
    selectedCrest: String
})

const emit =defineEmits(['update:stamp', 'close', 'submit'])

const handleWaxChange = (waxId) => {
    emit('update:stamp', waxId, props.selectedCrest)
}

const handleCrestChange = (crestId) => {
    emit('update:stamp',props.selectedWax, crestId)
}

const waxOptions = [
    { id: 'bordeaux', name: 'ボルドー', class: 'bg-[#6B1D2F]' },
    { id: 'gold', name: 'ミモザイエロー', class: 'bg-[#C5A059]' },
    { id: 'purple', name: 'プラムワイン', class: 'bg-[#4A2E4B]' },
    { id: 'green', name: 'セージ', class: 'bg-[#2A4736]' },
    { id: 'white', name: 'パールホワイト', class: 'bg-[#EAE6DF]' }
]

const crestOptions = [
    { id: 'laurel', name: '月桂樹', icon: '🌿' },
    { id: 'key', name: '鍵', icon: '🗝️' },
    { id: 'heart', name: '親愛', icon: '❤️' },
    { id: 'letter', name: '書簡', icon: '✉️' }
]
</script>

<template>
    <div class="fixed inset-0 bg-black/60 backdrop-blur-sm flex justify-center items-center z-50 p-4">
        <div class="bg-[#FAF8F5] rounded-3xl p-8 max-w-md w-full shadow-2xl border border-[#E2DAD0] space-y-6 relative">

            <button @click="$emit('close')" type="button" class="absolute top-4 right-4 text-stone-400 hover:text-stone-700 text-sm">×</button>

            <div class="text-center space-y-1">
                <h3 class="text-lg font-bold text-[#5A1222]">シーリングワックス封印の儀</h3>
                <p class="text-xs text-stone-500">色と刻印を選び、このページに封をしましょう。</p>
            </div>

            <!-- 色の選択 -->
            <div class="space-y-2">
                <label class="text-xs font-bold text-stone-600 block">1. スタンプの色を選ぶ (WAX PALETTE)</label>
                <div class="flex justify-between gap-2">
                    <button
                        v-for="wax in waxOptions"
                        :key="wax.id"
                        @click="handleWaxChange(wax.id)"
                        type="button"
                        class="w-10 h-10 rounded-full transition-transform flex items-center justify-center border-2"
                        :class="[wax.class, selectedWax === wax.id ? 'border-[#5A1222] scale-110 shadow-md' : 'border-transparent opacity-80']"
                    ></button>
                </div>
            </div>

            <!-- 刻印を選ぶ -->
            <div class="space-y-2">
                <label class="text-xs font-bold text-stone-600 block">2. 刻印を選ぶ (BRASS CREST)</label>
                <div class="grid grid-cols-4 gap-2">
                    <button
                        v-for="crest in crestOptions"
                        :key="crest.id"
                        @click="handleCrestChange(crest.id)"
                        type="button"
                        class="p-3 rounded-xl border text-center transition flex flex-col items-center justify-center bg-white"
                        :class="selectedCrest === crest.id ? 'border-[#5A1222] bg-[#F4EFEA]' : 'border-[#E2DAD0] hover:bg-stone-50'"
                    >
                        <span class="text-xl mb-1">{{ crest.icon }}</span>
                        <span class="text-[10px]  font-medium text-stone-600">{{ crest.name }}</span>
                    </button>
                </div>
            </div>

            <button
                @click="$emit('submit')"
                type="button"
                class="w-full py-3.5 rounded-full bg-[#6B1D2F] hover:bg-[#5A1222] text-white text-xs font-bold tracking-wider transition shadow-lg flex items-center justify-center gap-2"
            >
                <span>シーリングワックスで封をする。</span>
            </button>
            <p class="text-[10px] text-center text-stone-400">※封をすると次の人にLINEで通知がいきます。</p>
        </div>
    </div>
</template>