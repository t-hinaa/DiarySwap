<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from '#vue-router';

const router =useRouter()
const supabase = useSupabaseClient()

const diaryBooks = ref([])
const isLoading = ref(true)
const errorMessage = ref('')

// 参加している交換日記の一覧情報をSQL RPC経由で取得
const fetchMyDiaries = async () => {
    try {
        isLoading.value = true
        
        // RPC呼び出し
        const { data, error } = await supabase.rpc('get_my_diary_books')

        if (error) throw error

        diaryBooks.value = data || []
    } catch (err) {
        console.error('交換日記一覧の取得に失敗しました:', err)
        errorMessage.value = '交換日記の一覧を読み込めませんでした。'
    } finally {
        isLoading.value = false
    }
}

onMounted(() => {
    fetchMyDiaries()
})
</script>

<template>
    <div class="min-h-[calc(100vh-73px)] bg-[#FAF8F5] flex flex-col items-center justify-start px-4 py-12 text-stone-800">

        <div class="w-full max-w-6xl">
            <!-- ホームボタン -->
            <div class="w-full max-w-lg mb-4 flex justify-start">
                <button
                    @click="router.push('/home')"
                    class="inline-flex items-center gap-2 px-5 py-2 rounded-full bg-white border border-[#e2DAD0] text-[#5A1222] hover:bg-[#F4EFEA] shadow-sm transition text-xs font-bold tracking-wider"
                >
                    <span>ホーム</span>
                </button>
            </div>
                

            <!-- ヘッダータイトル -->
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-12 border-b border-stone-200/60 pb-6">
                <div>
                    <h1 class="text-3xl font-bold text-[#8B263E] tracking-wide font-self">あなたの交換日記の一覧</h1>
                    <p class="text-sm text-stone-500 mt-1">参加している交換日記の一覧です。表示をクリックして開けます。</p>
                </div>
            </div>

            <!-- エラー表示 -->
            <div v-if="errorMessages" class="bg-red-50 border border-red-50 text-red-700 px-4 py-3 rounded-xl mb-6 text-sm">
                {{ errorMessages }}
            </div>

            <!-- ローディング中 -->
            <div v-if="isLoading" class="text-center py-24 text-stone-400">
                日記を整理しています...
            </div>

            <!-- 日記が一冊もない場合 -->
            <div v-else-if="diaryBooks.length === 0" class="text-center py-24 bg-white rounded-2xl shadow-sm border border-stone-200/80">
                <p class="text-stone-600 font-medium mb-4">まだ参加している日記がありません</p>
            </div>

            <!-- 日記一覧 -->
            <div v-else class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-8">
                <div
                    v-for="book in diaryBooks"
                    :key="book.group_id"
                    @click="router.push(`/groups/${book.group_id}`)"
                    class="bg-white/80 backdrop-blur-md rounded-[30px] p-6 shadow-sm border border-stone-200/60 hover:-translate-y-1.5 hover:shadow-xl hover-scale-[1.02 transition duration-300 cursor-pointer flex flex-col justify-between h-72 relative overflow-hidden group"
                >
                    <!-- 背表紙 -->
                    <div class="absolute left-0 top-0 bottom-0 w-2.5 bg-[#8B263E] rounded-l-[30px]"></div>

                    <div class="pl-2">
                        <!-- 日記タイトル(グループ名) -->
                        <h2 class="text-lg font-bold text-stone-800 mt-4 line-clamp-2 group-hover:text-[#8B263E] transition font-serif leading-snug">
                            {{ book.name}}
                        </h2>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>