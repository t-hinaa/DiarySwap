<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';

const route = useRoute()
const router = useRouter()
const supabase = useSupabaseClient()

const groupId = route.params.id

const groupDetails = ref(null)
const diaryPosts = ref([])
const isLoading = ref(true)
const errorMessage = ref('')

const fetchGroupDetail = async () => {
    try {
        isLoading.value = true

        // グループ情報の取得
        const { data: groupData, error: groupError } = await supabase
            .from('groups')
            .select('*')
            .eq('id', groupId)
            .single()

        if (groupError) throw groupError
        groupDetails.value = groupData

        // 日記詳細の取得
        const { data: postsData, error: postsError } = await supabase
            .from('diaries')
            .select('*')
            .eq('group_id', groupId)
            .order('created_at', { ascending: false})

        if (postsError) throw postsError
        diaryPosts.value = postsData || []
    } catch (err) {
        console.error('詳細情報の取得に失敗しました:', err)
        errorMessage.value = '交換日記を開けませんでした。'
    } finally {
        isLoading.value = false
    }
}

onMounted(() => {
    fetchGroupDetail()
})
</script>

<template>
    <div class="min-h-[calc(100vh-73px)] bg-[#FAF8F5] flex flex-col items-center justify-start px-4 py-12 text-stone-800">

        <div class="w-full max-w-5xl">
            <!-- 戻るボタン -->
            <div class="w-full max-w-lg mb-4 flex justify-start">
                <button
                    @click="router.push('/list')"
                    class="inline-flex items-center gap-2 px-5 py-2 rounded-full bg-white border border-[#e2DAD0] text-[#5A1222] hover:bg-[#F4EFEA] shadow-sm transition text-xs font-bold tracking-wider"
                >
                    <span>一覧へ</span>
                </button>
            </div>

            <!-- エラー表示 -->
            <div v-if="errorMessage" class="bg-red-50 border border-red-50 text-red-700 px-4 py-3 rounded-xl mb-6 text-sm">
                {{ errorMessage }}
            </div>

            <!-- ローディング中 -->
            <div v-if="isLoading" class="text-center py-24 text-stone-400">
                交換日記を開いています...
            </div>

            <!-- ノート本体 -->
            <div v-else-if="groupDetails" class="relative bg-[#FDFBF7] rounded-[20px] shadow-xl border border-stone-300/60 overflow-hidden flex flex-col md:flex-row min-h-[700px]">

                <!-- しおり・綴じ目 -->
                <div class="hidden md:block absolute left-1/2 top-0 bottom-0 w-3 -translate-x-1/2 bg-gradient-to-r from-stone-300/50 via-[#8B263E] to-stone-300/50 z-10 shadow-inner"></div>

                <!-- 左：本文エリア -->
                <div class="w-full md:w-1/2 p-8 md:p-12 flex flex-col justify-between border-b md:border-b-0 md:border-r border-stone-200/80">
                    <div>
                        <!-- ヘッダー情報 -->
                        <div class="flex justify-between items-center text-xs text-stone-400 mb-6 border-b border-stone-200/50 pb-3 font-serif">
                            <span>{{ groupDetails.name }}</span>
                        </div>

                        <!-- 本文欄 -->
                        <div v-if="diaryPosts.length> 0">
                            <div class="mb-4">
                                <p class="text-stone-700 whitespace-pre-wrap leading-relaxed text-sm font-serif mt-6">
                                    {{ diaryPosts[0].content }}
                                </p>
                                <span class="text-[10px] font-semibold px-2.5 py-1 bg-amber-50 text-amber-800 rounded-full border border-amber-200">
                                    お題
                                </span>
                                <h2 class="text-xl font-bold text-stone-800 mt-2 font-serif">
                                    「{{ diaryPosts[0].theme_text || 'アールグレイ'}}」
                                </h2>
                            </div>
                        </div>

                        <div v-else class="text-center py-20 text-stone-400 text-sm">
                            まだページが書かれていません。
                        </div>
                    </div>

                    <!-- ページ番号 -->
                    <div class="pt-8 text-center text-xs text-stone-400 font-serif">
                        - 1 -
                    </div>
                </div>

                <!-- 右： -->
                <div class="w-full md:w-1/2 p-8 md:p-12 flex flex-col justify-between bg-[#FCFAF5]">
                    <div>
                        <div class="flex justify-between items-center text-xs text-stone-400 mb-6 border-b border-stone-200/50 pb-3 font-serif">
                            <span>みんなの感想・返信</span>
                            <span>💬 コメント</span>
                        </div>

                        <!-- コメントやタイムラインのプレースホルダー -->
                        <div class="space-y-4">
                            <div class="bg-white/70 p-4 rounded-2xl border border-stone-200/50 shadow-2xs">
                                <div class="flex justify-between text-[11px] text-stone-400 mb-1">
                                    <span class="font-bold text-stone-600">メンバー</span>
                                    <span>2日前</span>
                                </div>
                                <p class="text-xs text-stone-700">すてきなエピソードですね！次回の更新も楽しみにしてます✨</p>
                            </div>
                        </div>
                    </div>
                    <!-- ページ番号 -->
                    <div class="pt-8 text-center text-xs text-stone-400 font-serif">
                        - 2 -
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>