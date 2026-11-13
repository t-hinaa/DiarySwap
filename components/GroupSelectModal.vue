<script setup>
defineProps({
    isOpen: {
        type: Boolean,
        required: true
    },
    groups: {
        type: Array,
        required: true
    }
})

const emit = defineEmits(['close', 'select'])

const handleSelect = (groupId) => {
    emit('select', groupId)
}

const handleClose = () => {
    emit('close')
}
</script>
<template>
    <Transition name="fade">
        <div
            v-if="isOpen"
            @click.self="handleClose"
            class="fixed inset-0 bg-stone-900/30 backdrop-blur-sm z-50 overflow-y-auto p-4 flex items-center justify-center min-h-full"
        >
            <div class="bg-[#FAF8F5]/95 backdrop-blur-md rounded-[36px] p-6 sm:p-8 max-w-md w-full shadow-2xl border border-stone-200/80 relative my-auto">

                <div class="text-center mb-4">
                    <h3 class="text-lg font-bold text-stone-800">どの交換日記を書きますか？</h3>
                    <p class="text-xs text-stone-500 mt-1">グループを選んでください</p>
                </div>

                <!-- グループ一覧リスト -->
                <div class="space-y-3 max-h-60 overflow-y-auto pr-1 mb-6 flex-1 min-h-0">
                    <button
                        v-for="group in groups"
                        :key="group.id"
                        @click="handleSelect(group.id)"
                        class="w-full text-left px-5 py-4 rounded-2xl bg-white/80 hover:bg-[#8B263E] text-stone-800 hover:text-white font-medium text-sm shadow-sm border border-stone-200/60 transition duration-200 flex items-center justify-between group"
                    >
                        <div class="truncate pr-2">
                            <span class="block truncate">{{ group.name }}</span>
                            <span 
                                class="text-[10px] mt-0.5 block"
                                :class="group.turn_order === group.current_turn_index ? 'text-emerald-600 group-hover:text-emerald-200' : 'text-stone-400 group-hover:text-stone-200'"
                            >
                                {{ group.turn_order === group.current_turn_index ? 'あなたのターンです' : '順番待ち中...' }}
                            </span>
                        </div>
                        <span class="text-sm px-2.5 py-1 rounded-full bg-[#FAF8F5] text-[#8B263E] group-hover:bg-white/20 group-hover:text-white transition shrink-0">
                            執筆する
                        </span>
                    </button>
                </div>

                <!-- 閉じる -->
                <div class="text-center">
                    <button
                        @click="handleClose"
                        class="text-stone-400 hover:text-stone-600 text-xs font-medium py-2 px-4 transition"
                    >
                        閉じる</button>
                </div>
            </div>
        </div>
    </Transition>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}
</style>