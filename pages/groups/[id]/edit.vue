<script setup>
import { ref, onMounted, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';

const router = useRouter()
const route = useRoute()
const supabase = useSupabaseClient()

const diaryId = ref(null);

// フォーム用のリアクティブ変数
const isLoading = ref(true);
const content = ref('');
const weather = ref('');
const date = ref(new Date().toISOString().split('T')[0]);
const themeTitle = ref('');
const themePoints = ref([]);
const themeText = ref([]);
const isSubmitting = ref(false);

// データ取得
const fetchEditData = async () => {
    const groupId = route.params.id;
    // まだIDが取れていなければ処理を中断
    if (!groupId) return;

    try {
        isLoading.value = true
        console.log("データ取得開始, groupId:", groupId);

        const { data, error } = await supabase.rpc('get_group_diary_details', {
            p_group_id: groupId
        })
        if (error) throw error

        // 編集対象の投稿を取得
        const post = data.posts?.[0]
        if (post) {
            diaryId.value = post.id
            date.value = post.date
            weather.value = post.weather
            content.value = post.content
            // お題のタイトルと質問リストをセット
            themeTitle.value = post.theme_title || ''
            themePoints.value = post.theme_points || []

            // 回答（文字列で返ってくる場合を考慮してパース）
            let answers = post.theme_text
            while (typeof answers === 'string') {
                try {
                    answers = JSON.parse(answers)
                } catch (e) {
                    answers = []
                    break
                }
            }
            themeText.value = Array.isArray(answers) ? answers : []
        }
    } catch (err) {
        console.error('データの取得に失敗:', err)
    } finally {
        isLoading.value = false
    }
};
// URLのパラメータの変化を監視して、IDが決まった瞬間にデータを取得する
watch(
    () => route.params.id,
    (newId) => {
        if (newId) {
            fetchEditData();
        }
    },
    { immediate: true }
);

// 更新ボタン
const handleUpdate = async () => {
    try {
        isSubmitting.value = true

        const { error } = await supabase.rpc('update_diary_post', {
            p_diary_id: diaryId.value,
            p_content: content.value,
            p_theme_text: themeText.value, // 配列のまま渡す
            p_weather: weather.value,
            p_date: date.value
        })
    
        if (error) throw error

        alert('日記を更新しました！')
        router.push(`/groups/${route.params.id}`) // 詳細画面へ戻る

    } catch (err) {
        console.error('更新エラー:', err)
        alert('更新に失敗しました: ' + (err.message || err))
    } finally {
        isSubmitting.value = false
    }
}

// キャンセル時
const goBack = () => {
    router.back()
}
</script>

<template>
    <div class="min-h-[calc(100vh-73px)] bg-[#FAF8F5] flex flex-col items-center justify-start px-4 py-12 text-stone-800">

        <!-- 上部コントロール（戻るボタンなど） -->
        <div class="w-full max-w-5xl mb-4 flex items-center justify-between px-2">
            <button
                @click="goBack"
                class="inline-flex items-center gap-2 px-5 py-2 rounded-full bg-white border border-[#e2DAD0] text-[#5A1222] hover:bg-[#F4EFEA] shadow-sm transition text-xs font-bold tracking-wider font-serif"
            >
                <span>戻る</span>
            </button>
        </div>

        <!-- 外側の重厚なブック風コンテナ -->
        <div class="w-full max-w-5xl bg-gradient-to-b from-[#381017] to-[#1E080E] rounded-3xl shadow-[0_30px_70px_rgba(0,0,0,0.85)] p-6 md:p-10 relative border-4 border-[#5A1222]/60 ring-1 ring-black/50">

            <!-- ローディング中 -->
            <div v-if="isLoading" class="text-center py-24 text-stone-400 font-serif">
                データを読み込んでいます...
            </div>

            <!-- ノート -->
            <div v-else class="relative bg-[#FDFBF7] rounded-[20px] shadow-xl border border-stone-300/60 overflow-hidden p-8 md:p-12 font-serif">

                <h2 class="text-lg font-bold text-[#5A1222] mb-6 text-center border-b border-stone-200/80 pb-3">
                    日記の編集
                </h2>

                <div class="space-y-6">
                    <!-- 日付・天気 -->
                    <div class="flex flex-wrap gap-4 items-center justify-between bg-stone-50/80 p-4 rounded-2xl border border-stone-200/80">
                        <!-- 日付 -->
                        <div class="flex items-center gap-2">
                            <label class="text-xs font-bold text-stone-700">日付:</label>
                            <input 
                                type="date" 
                                v-model="date" 
                                class="bg-white border border-stone-300 rounded-lg px-3 py-1 text-xs text-stone-800 focus:outline-none focus:ring-2 focus:ring-[#5A1222]/30 font-sans"
                            />
                        </div>

                        <!-- 天気 -->
                        <div class="flex items-center gap-2">
                            <label class="text-xs font-bold text-stone-700">天気:</label>
                            <select 
                                v-model="weather"
                                class="bg-white border border-stone-300 rounded-lg px-3 py-1 text-xs text-stone-800 focus:outline-none focus:ring-2 focus:ring-[#5A1222]/30 font-sans"
                            >
                                <<option value="sunny">晴れ</option>
                                <option value="cloudy">くもり</option>
                                <option value="rainy">雨</option>
                                <option value="snowy">雪</option>
                            </select>
                        </div>
                    </div>

                    <!-- 本文 -->
                    <div class="space-y-2">
                        <label class="text-xs font-bold text-[#5A1222]">本文</label>
                        <textarea 
                            v-model="content" 
                            rows="6"
                            class="w-full bg-white border border-stone-300/80 rounded-2xl p-4 text-sm text-stone-800 leading-relaxed focus:outline-none focus:ring-2 focus:ring-[#5A1222]/30 resize-none shadow-inner"
                        ></textarea>
                    </div>

                    <!-- お題 -->
                    <div class="space-y-4 pt-2">
                        <div class="flex items-center justify-between">
                            <h3 class="text-xs font-bold text-[#8B263E] uppercase tracking-wider flex items-center gap-1">
                                <span>お題と回答の編集</span>
                            </h3>
                        <span 
                            v-if="themeTitle"
                            class="text-xs font-bold text-stone-600 bg-amber-100/70 px-3 py-1 rounded-full"
                        >
                            テーマ: {{ themeTitle }}
                        </span>
                    </div>

                    <div
                        v-for="(point, index) in themePoints"
                        :key="index"
                        class="bg-white p-4 rounded-xl shadow-sm border border-stone-200 text-xs transition relative flex flex-col justify-between space-y-2"
                    >
                        <!-- お題 -->
                        <div class="flex items-start gap-2">
                            <span class="text-[10px] font-bold text-[#5A1222] bg-[#F4EFEA] px-2 py-0.5 rounded border border-[#E2DAD0] shrink-0">
                                Q0{{ index + 1 }}
                            </span>
                            <span class="text-xs font-bold text-stone-800 leading-relaxed break-words">
                                {{ point }}
                            </span>
                        </div>

                        <!-- 回答入力欄 -->
                        <textarea
                            v-model="themeText[index]"
                            rows="2"
                            placeholder="ここに入力"
                            class="w-full bg-[#FAF8F5] border border-stone-200 rounded-lg p-2.5 text-xs text-stone-800 focus:outline-none focus:border-[#5A1222] shadow-inner resize-none leading-snug"
                        ></textarea>
                    </div>
                </div>

                    <!-- アクションボタン -->
                    <div class="text-center mt-3">
                        <p class="text-[11px] text-stone-400">
                            ※このアプリに削除機能はありません。内容を直したいときは、いつでもここから編集して上書きしてくださいね。
                        </p>
                    </div>
                    <div class="flex items-center justify-end gap-4 pt-6 border-t border-stone-200/80">
                        <button 
                            @click="goBack"
                            class="px-5 py-2.5 rounded-full text-xs font-bold text-stone-600 bg-white border border-stone-300 hover:bg-stone-50 transition shadow-sm"
                        >
                            キャンセル
                        </button>
                        <button 
                            @click="handleUpdate"
                            :disabled="isSubmitting"
                            class="px-6 py-2.5 rounded-full text-xs font-bold text-amber-100 bg-[#5A1222] hover:bg-[#430D19] shadow-md transition disabled:opacity-50"
                        >
                            {{ isSubmitting ? '保存中...' : '変更を保存する' }}
                        </button>
                    </div>
                </div>

            </div>
        </div>
    </div>
</template>