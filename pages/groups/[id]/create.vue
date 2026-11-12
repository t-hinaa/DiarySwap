<script setup>
import { reactive, ref, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { watch } from 'vue';
import StampModal from '~/components/StampModal.vue';

const router = useRouter()
const route = useRoute()
const supabase = useSupabaseClient()

// 日付 (YYYY-MM-DD)
const today = new Date().toISOString().split('T')[0]

// WAXとCRESTを合体させて更新する関数
const updateSealStamp = (color, crest) => {
    form.seal_stamp = `${color}_${crest}`
}

const form = reactive({
    theme_id: null,
    date: today,
    content: '',
    weather: 'sunny',
    theme_text: ['', '', '', ''],
    seal_stamp:'bordeaux_laurel'
})

const themes = ref([])
const isLoading = ref(false)
const isStampModalOpen = ref(false)
const isStamping = ref(false)

// グループのDBからお題パックのIDを取得
const fetchThemes = async (groupId) => {
    if(!groupId || groupId ==='undefined' ) return

    try {
        const { data, error } = await supabase.rpc('get_group_theme', {
            p_group_id: groupId
        })

        if (error) throw error

        if (data && data.length > 0) {
            // ４つの配列に整える
            const theme = data[0]
            form.theme_id = theme.id
            themes.value = (theme.points || []).map(point => ({ title: point }))
        } 
    } catch (err) {
        console.error('お題の取得に失敗しました', err.message)
    }
}

// route.params.id が変化した（または読み込まれた）タイミングで自動で実行
watch(
    () => route.params.id,
    (newId) => {
        fetchThemes(newId)
    },
    { immediate: true } //ページを開いた初回も即座に実行
)

const openStampModal = () => {
    //　文字数チェック
    if (!form.content.trim()) {
        alert('本文を入力してください。')
        return
    }

    // 文字数上限チェック
    const MAX_LENGTH = 1000
    if (form.content.length > MAX_LENGTH) {
        alert(`本文は ${MAX_LENGTH} 文字以内で入力してください。（現在 ${form.content.length}文字）`)
        return
    }

    // お題への回答チェック
    const hasTheme_text = form.theme_text.some(text => text.trim() !== '')
    if (form.theme_text.length > 0 && !hasTheme_text) {
        alert('お題について１つ以上回答を入力してください')
        return
    }
    isStampModalOpen.value = true
}

// 封印＆DBに保存
const executeSealing = async () => {
    try {
        isLoading.value = true
        isStampModalOpen.value = false
        isStamping.value = true

        // RPC関数
        const { error } = await supabase.rpc('create_diary_post', {
            p_group_id: route.params.id,
            p_content: form.content,
            p_theme_text: form.theme_text,
            p_weather: form.weather,
            p_seal_stamp: form.seal_stamp,
            p_theme_id: form.theme_id
        })

        if (error) throw error
            
        setTimeout(() => {
            router.push(`/groups/${route.params.id}`)
        },2500)

    } catch (err) {
        alert('封印に失敗しました:' + err.message)
        isStamping.value = false
    } finally {
        isLoading.value = false
    }
}
</script>

<template>
    <div class="min-h-[calc(100vh-73px)] bg-[#FAF8F5] text-stone-800 px-4 py-12 flex flex-col items-center relative overflow-hidden">

        <div class="w-full max-5xl mb-4 flex items-center">
            <!-- 戻るボタン -->
            <button
                @click="router.push('/home')"
                class="inline-flex items-center gap-2 px-5 py-2 rounded-full bg-white border border-[#e2DAD0] text-[#5A1222] hover:bg-[#F4EFEA] shadow-sm transition text-xs font-bold tracking-wider"
            >
            <span>ホーム</span>
            </button>
        </div>

        <!-- メイン執筆画面 -->
        <div class="w-full max-w-5xl bg-gradient-to-b from-[#381017 ]bg-[#1E080E] rounded-3xl shadow-[0_30px_70px_rgba(0,0,0,0.85)] p-6 md:p-10 relative border-4 border-[#5A1222]/60 ring-1 ring-black/50">

            <!-- ノートの中身 -->
            <div class="bg-[#FAF8F5] rounded-2xl shadow-inner p-8 md;p-12 space-y-8 relative border border-[#E2DAD0]">
            
                <!-- 栞 -->
                <div class="hidden md:block absolute left-1/2 top-0 bottom-0 w-3 -translate-x-1/2 bg-gradient-to-r from-stone-300/50 via-[#8B263E] to-stone-300/50 z-10 shadow-inner"></div>

                <!-- ヘッダー情報 -->
                <div class="flex flex-wrap justify-between items-center border-b border-[#E2DAD0] pb-4 gap-4">
                    <div class="flex items-center gap-2">
                        <!-- 日付 -->
                        <span class="text-xs font-bold tracking-widest text-[#5A1222] bg-[#F4EFEA] px-3 py-1.5 rounded-full">
                            執筆日
                        </span>
                        <input
                            v-model="form.date"
                            type="date"
                            class="text-xs font-medium bg-white border border-[#E2DAD0] rounded-lg px-3 py-1.5 text-stone-700 focus:outline-none focus:border-[#5A1222]"
                        />
                    </div>
                    <!-- 天気 -->
                    <select v-model="form.weather" class="text-xs bg-transparent border border-[#E2DAD0] rounded-md px-2 py-1 text-stone-600 focus:outline-none">
                        <option value="sunny">晴れ</option>
                        <option value="cloudy">くもり</option>
                        <option value="rainy">雨</option>
                        <option value="snowy">雪</option>
                    </select>
                </div>

                <!-- 左右レイアウト -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-10">

                    <!-- 左：フリースペース -->
                    <div class="space-y-4 flex flex-col">
                        <label class="text-xs font-bold text-stone-500 tracking-wider">本文スペース</label>
                            <textarea
                            v-model="form.content"
                            rows="12"
                            placeholder="最近の出来事を自由に綴ってください"
                            class="w-full flex-1 min-h-[360px] border border-[#E2DAD0] rounded-2xl p-5 text-sm focus:outline-none focus:border-[#5A1222] bg-white/80 shadow-inner resize-none leading-relaxed"
                        ></textarea>
                        <!-- 文字数カウンター -->
                        <div class="text-right text-xs text-stone-400 mt-1">
                            {{ form.content.length }} / 1000文字
                        </div>
                    </div>

                    <!-- 右：お題スペース -->
                    <div class="space-y-4 flex flex-col">
                        <label class="block text-xs font-bold text-stone-500 tracking-wider">聞かせて！みんなのこと！</label>

                        <div class="grid grid-cols-1 gap-3 flex-1">
                            <div
                                v-for="(theme,index) in themes"
                                :key="theme.id || index"
                                class="bg-white p-3.5 rounded-xl shadow-sm border border-stone-200 text-xs transition relative flex flex-col justify-between"
                            >

                                <div class="flex items-center justify-between mb-1.5">
                                    <span class="text-[10px] font-bold text-[#5A1222] bg-[#F4EFEA] px-2 py-0.5 rounded border border-[#E2DAD0]">
                                        THEME 0{{ index + 1 }}
                                    </span>
                                    <span class="text-[11px] font-medium text-stone-600 leading-relaxed break-words">
                                        {{ theme.title }}
                                    </span>
                                </div>

                                <textarea
                                    type="text"
                                    v-model="form.theme_text[index]"
                                    placeholder="ここに入力"
                                    class="w-full bg-[#FAF8F5] border border-stone-200 rounded-lg px-2.5 text-xs text-stone-800 focus:outline-none focus:border-[#5A1222] shadow-inner resize-none leading-snug"
                                ></textarea>
                        </div>
                    </div>
                </div>
            </div>

            <!-- スタンプ押すボタン（LINE通知も） -->
            <div class="pt-6 border-t border-[#E2DAD0] flex justify-end">
                <button
                    @click="openStampModal"
                    class="inline-flex items-center gap-2 px-8 py-3.5 rounded-full bg-[#5A1222] text-white text-xs font-bold tracking-widest hover:bg-[#430D19] transition shadow-lg"
                >
                    <span>執筆完了！スタンプを押す</span>
                </button>
            </div>
        </div>
    </div>

        <!-- モーダル呼び出し -->
        <StampModal
            v-if="isStampModalOpen"
            :selected-wax="form.seal_stamp.split('_')[0]"
            :selected-crest="form.seal_stamp.split('_')[1]"
            @close="isStampModalOpen = false"
            @update:stamp="updateSealStamp" 
            @submit="executeSealing"
        />

        <div v-if="isStamping" class="fixed inset-0 bg-black/80 backdrop-blur-md flex flex-col justify-center items-center z-50 text-white space-y-4">
            <div class="text-6xl animate-bounce">🧞‍♀️✨</div>
            <p class="text-sm font-bold tracking-widest">封をしています...</p>
        </div>

    </div>
</template>