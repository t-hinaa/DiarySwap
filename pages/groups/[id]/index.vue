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

// ページネーション
const currentPageIndex = ref(0);

// データ取得
const currentPost = computed(() => {
    if (!diaryPosts.value || diaryPosts.value.length === 0) return null;
    const post = diaryPosts.value[currentPageIndex.value] || diaryPosts.value[0];
    if (!post) return null;

    let answers = post.theme_text;

    // 文字列として届いている場合、配列になるまでJSON.parseする
    while (typeof answers === 'string') {
        try {
        answers = JSON.parse(answers);
        } catch (e) {
            answers = [];
            break;
        }
    }
    return {
        ...post,
        theme_text: Array.isArray(answers) ? answers : []
    };
});

// ページ数の計算（何セット分投稿があるか）
const totalPostsCount = computed(()=> diaryPosts.value.length || 1);

// 日付を綺麗に
const formatDate = (dateStr) => {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const dayOfWeek = daysArr[date.getDay()];
    return `${month}/${day}(${dayOfWeek}) ${hours}:${minutes}`;
}

const fetchGroupDetail = async () => {
    try {
        isLoading.value = true

        // グループ情報の取得
        const { data, error } = await supabase.rpc('get_group_diary_details', {
            p_group_id: groupId
        });

        if (error) throw error

        groupDetails.value = data.group;
        diaryPosts.value = data.posts || [];
    } catch (err) {
        console.error('詳細情報の取得に失敗しました:', err)
        errorMessage.value = '交換日記を開けませんでした。'
    } finally {
        isLoading.value = false
    }
}

onMounted(() => {
    fetchGroupDetail();
});

// 日記編集画面へ
const goToEdit = () => { 
    if (!groupId) {
        alert('対象のグループが見つかりません。')
        return
    }
    router.push(`/groups/${groupId}/edit`)
}
</script>

<template>
    <div class="min-h-[calc(100vh-73px)] bg-[#FAF8F5] flex flex-col items-center justify-start px-4 py-12 text-stone-800">

        <div class="w-full max-w-5xl mb-4 flex items-center justify-between px-2">
            <!-- 戻るボタン -->
            <button
                @click="router.push('/list')"
                class="inline-flex items-center gap-2 px-5 py-2 rounded-full bg-white border border-[#e2DAD0] text-[#5A1222] hover:bg-[#F4EFEA] shadow-sm transition text-xs font-bold tracking-wider"
            >
                <span>一覧へ</span>
            </button>
            <!-- 編集ボタン -->
            <button
                @click="router.push(`/groups/${groupId}/edit`)"
                class="ml-auto inline-flex items-center gap-2 px-5 py-2 rounded-full bg-white border border-[#e2DAD0] text-[#5A1222] hover:bg-[#F4EFEA] shadow-sm transition text-xs font-bold tracking-wider"
            >
                <span>編集画面へ</span>
            </button>
        </div>
        
        <!-- 日記 -->
        <div class="w-full max-w-5xl bg-gradient-to-b from-[#381017] to-[#1E080E] rounded-3xl shadow-[0_30px_70px_rgba(0,0,0,0.85)] p-6 md:p-10 relative border-4 border-[#5A1222]/60 ring-1 ring-black/50">

            <!-- エラー表示 -->
            <div v-if="errorMessage" class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl mb-6 text-sm">
                {{ errorMessage }}
            </div>

            <!-- ローディング中 -->
            <div v-if="isLoading" class="text-center py-24 text-stone-400">
                交換日記を開いています...
            </div>

            <!-- ノート本体 -->
            <div v-else-if="groupDetails" class="relative bg-[#FDFBF7] rounded-[20px] shadow-xl border border-stone-300/60 overflow-hidden flex flex-col md:flex-row min-h-[700px]">

                <!-- しおり・綴じ目 -->
                <div class="hidden md:block absolute left-1/2 top-0 bottom-0 w-4 -translate-x-1/2 bg-gradient-to-r from-stone-300/50 via-[#8B263E] to-stone-300/50 z-10 shadow-inner"></div>

                <!-- 左：本文エリア -->
                <div class="w-full md:w-1/2 p-8 md:p-12 flex flex-col justify-between border-b md:border-b-0 md:border-r border-stone-200/80 relative">
                    <div>
                        <!-- ヘッダー情報 -->
                        <div class="flex justify-between items-center text-xs text-stone-500 mb-6 border-b border-stone-200/50 pb-3 font-serif">
                            <span class="font-bold tracking-wide text-[#5A1222]">{{ groupDetails.name }}</span>
                            <div class="flex items-center gap-2">
                                <span>{{ currentPost?.date || '' }}</span>
                                <span class="bg-stone-100 px-2 py-0.5 rounded text-[11px] border border-stone-200">
                                    {{ currentPost?.weather || '晴れ' }}
                                </span>
                            </div>
                        </div>

                        <div class="mb-4 text-xs text-stone-600 font-serif">
                            今日の担当は <span class="font-bold text-[#5A1222]">{{ currentPost?.author_name || 'メンバー' }}</span> だよ！
                        </div>

                        <!-- 本文欄 -->
                        <div v-if="diaryPosts.length > 0">
                            <div class="mb-4">
                                <p class="text-stone-700 whitespace-pre-wrap leading-relaxed text-sm font-serif mt-2">
                                    {{ currentPost?.content }}
                                </p>
                            </div>
                        </div>

                        <div v-else class="text-center py-20 text-stone-400 text-sm">
                            まだページが書かれていません。
                        </div>
                    </div>

                    <!-- ページ番号 -->
                    <div class="pt-8 text-center text-xs text-stone-400 font-serif">
                        - {{ currentPageIndex * 2 + 1 }} -
                    </div>
                </div>

                <!-- 右：お題エリア -->
                <div class="w-full md:w-1/2 p-8 md:p-12 flex flex-col justify-between bg-[#FCFAF5] relative">
                    <div>
                        <div class="flex justify-between items-center text-xs text-stone-500 mb-6 border-b border-stone-200/50 pb-3 font-serif">
                            <span class="font-bold text-[#8B263E]">📌 お題と回答</span>
                            <span class="text-[11px] text-stone-400">テーマ: {{ currentPost?.theme_title || '' }}</span>
                        </div>

                        <!-- お題ごとのボックス一覧 -->
                        <div v-if="currentPost" class="space-y-4">
                            <div class="bg-amber-50/70 p-3 rounded-2xl border border-amber-200/60 shadow-2xs mb-3">
                                <h3 class="text-sm font-bold text-stone-800 font-serif">
                                    「{{ currentPost.theme_title || 'テーマ' }}」
                                </h3>
                            </div>

                            <!-- お題＆回答 -->
                            <div class="space-y-3" v-if="currentPost?.theme_points && currentPost.theme_points.length > 0">
                                <div 
                                    v-for="(point, idx) in currentPost.theme_points" 
                                    :key="idx"
                                    class="bg-white/90 p-4 rounded-2xl border border-amber-200/40 shadow-2xs space-y-2 font-serif"
                                >
                                    <!-- お題 -->
                                    <div class="flex items-start gap-2">
                                        <span class="w-5 h-5 rounded-full bg-amber-200 text-amber-900 text-[10px] flex items-center justify-center font-bold shrink-0 mt-0.5">
                                            {{ idx + 1 }}
                                        </span>
                                        <span class="text-xs font-bold text-stone-800">
                                            {{ point }}
                                        </span>
                                    </div>

                                    <!-- 回答 -->
                                    <div class="pl-7 pt-1 border-t border-stone-100">
                                        <p class="text-xs text-stone-600 leading-relaxed whitespace-pre-wrap">
                                            {{ currentPost.theme_text?.[idx] || '（未回答）' }}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div v-else class="text-center py-20 text-stone-400 text-sm font-serif">
                            お題情報がありません。
                        </div>
                    </div>

                    <!-- ページ番号 -->
                    <div class="pt-8 text-center text-xs text-stone-400 font-serif">
                        - {{ currentPageIndex * 2 + 2 }} -
                    </div>
                </div>
            </div>

            <!-- ページネーション -->
            <div v-if="diaryPosts.length > 1" class="flex justify-center items-center gap-4 mt-6">
                <button 
                    @click="currentPageIndex > 0 ? currentPageIndex-- : null"
                    :disabled="currentPageIndex === 0"
                    class="px-4 py-1.5 rounded-full bg-[#5A1222] text-amber-100 text-xs font-serif disabled:opacity-40 shadow"
                >
                    前のページ
                </button>
                <span class="text-xs text-stone-300 font-serif">
                    {{ currentPageIndex + 1 }} / {{ diaryPosts.length }} ページ
                </span>
                <button 
                    @click="currentPageIndex < diaryPosts.length - 1 ? currentPageIndex++ : null"
                    :disabled="currentPageIndex === diaryPosts.length - 1"
                    class="px-4 py-1.5 rounded-full bg-[#5A1222] text-amber-100 text-xs font-serif disabled:opacity-40 shadow"
                >
                    次のページ
                </button>
            </div>
        </div>
    </div>
</template>