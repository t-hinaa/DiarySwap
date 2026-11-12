<script setup>
import { reactive, ref  } from 'vue';
import { useRouter,useRoute } from 'vue-router';

const router = useRouter()
const route = useRoute()
const supabase = useSupabaseClient()
const themes = ref([])
const isLoading = ref(false)
const createdInviteUrl = ref('') // 生成された招待リンク

const createdGroupId = ref('')

// フォームの入力データ
const form = reactive({
    name: '',
    exchange_frequency: 'daily',  // 交換頻度
    theme_package: 'earl_grey',   // お題
})

// モーダルで表示するお題データの管理
const selectedThemeForModal = ref(null)
const hoveredTheme = ref(null)

// DBからお題一覧を取得
const fetchThemes = async () => {
    try {
        isLoading.value = true

        const { data, error } = await supabase
            .from('themes')
            .select('*')     //全て取得

        if (error) throw error

        themes.value = data || []
        console.log('取得したテーマ一覧:', themes.value)
    } catch (err) {
        console.error('テーマの取得に失敗しました:', err.message)
    } finally {
        isLoading.value = false
    }
}
onMounted(() => {
    fetchThemes()
})

// モーダル内で決定ボタンを押した時の処理
const confirmTheme = (themeId) => {
    form.theme_package = themeId
    selectedThemeForModal.value = null //モーダルを閉じる
    const chosen = themes.value.find(t =>t.id === themeId)
    alert(`「${chosen.title}」に決定しました！`)
}


// グループ作成
const createGroup = async () => {
    try {
        if (!form.name.trim()) {
            alert('グループ名を入力してください。')
            return
        }

        isLoading.value = true

        // アクセストークンを確実に取得する
        const { data: sessionData, error: sessionError } = await supabase.auth.getSession()
        const session = sessionData?.session
        const accessToken = session?.access_token

        console.log('【デバッグ】取得したアクセストークン:', accessToken)

        // アクセストークンが取得できていない場合は処理をストップ
        if (!accessToken) {
            alert('ログイン情報（トークン）が取得できませんでした。一度ログインし直してください。')
            return
        }

        // supabaseのgroupsテーブルに挿入
        const { data: responseData, error: funcError } = await supabase.functions.invoke('create-group', {
            method: 'POST',
            body: {
                name: form.name,
                exchange_frequency: form.exchange_frequency,
                theme_package: form.theme_package
            },
            headers: {
                Authorization: `Bearer ${accessToken}`
            }
        })

        if (funcError) throw funcError

        // グループデータと招待コードを取り出す
        const groupData = responseData.group
        const groupId = groupData.id
        const invite_code = groupData.invite_code

        // 取得したIDを変数として保持
        createdGroupId.value = groupId

        // 招待リンクを作成
        const origin = window.location.origin
        createdInviteUrl.value = `${origin}/invite/${invite_code}`
    }   catch (err) {
        console.error('グループ作成エラー:', err)
        alert('グループの作成に失敗しました: ' + err.message)
    }   finally {
        isLoading.value = false
    }
}
// 招待リンクをコピーする
const copyInviteUrl = async () => {
    try {
        if (navigator && navigator.clipboard && navigator.clipboard.writeText) {
            await navigator.clipboard.writeText(createdInviteUrl.value)
            alert('招待リンクをコピーしました！')
            return
        }

        // HTTP環境や古いブラウザ向けのフォールバック
        const textArea = document.createElement('textarea')
        textArea.value = createdInviteUrl.value
        textArea.style.position = 'fixed'
        textArea.style.top = '0'
        textArea.style.left = '0'
        textArea.style.opacity = '0'
        document.body.appendChild(textArea)
        textArea.focus()
        textArea.select()
        document.execCommand('copy')
        document.body.removeChild(textArea)
        alert('招待リンクをコピーしました！')
    } catch (err) {
        console.error('コピー失敗:', err)
        alert('コピーに失敗しました。リンクを長押しして手動でコピーしてください。')
    }
}

// LINEで招待リンクをシェアする関数
const shareOnLine = () => {
    window.open(`https://social-plugins.line.me/lineit/share?url=${encodeURIComponent(createdInviteUrl.value)}`, '_blank')
}

// 日記執筆画面へ
const goToCreate = () => {
    if (!createdGroupId.value) {
        alert('まだグループが作成されていません。')
        return
    }
    // 保存しておいたIDを使って遷移する
    router.push(`/groups/${createdGroupId.value}/create`)
}
</script>

<template>
    <div class="min-h-screen bg-[#FDFBF7] text-[#2C221E] p-6 flex flex-col items-center justify-center font-serif">
        
        <!-- ホームボタン -->
        <div class="w-full max-w-lg mb-4 flex justify-start">
            <button
                @click="router.push('/home')"
                class="inline-flex items-center gap-2 px-5 py-2 rounded-full bg-white border border-[#e2DAD0] text-[#5A1222] hover:bg-[#F4EFEA] shadow-sm transition text-xs font-bold tracking-wider"
            >
                <span>ホーム</span>
            </button>
        </div>
        
        
        <div class="bg-white rounded-3xl p-8 md:p-10 max-w-lg w-full shadow-xl border border-[#EFECE6] relative overflow-hidden">
            <div class="text-center mb-8">
                <h2 class="text-2xl font-bold tracking-wide text-[#3a2E2B]">グループ設定</h2>
                <p class="text-xs text-[#8c7B73] mt-1">お気に入りのルールで交換日記を始めましょう</p>
            </div>

            <div v-if="!createdInviteUrl" class="space-y-6">

                <!-- グループ名 -->
                <div>
                    <label class="block text-xs font-semibold tracking -wider test-[#6B5B53] uppercase mb-2">グループ名</label>
                    <input
                        v-model="form.name"
                        type="text"
                        placeholder="例：おしゃべりクラブ"
                        class="w-full bg-[#FAFAF8] border border-[#E2DAD0] rounded-xl px-4 py-3 text-sm text-[#3A2E2B] placeholder-[#B5A9A0] focus:ring-2 focus:ring-[#5A1222] focus:border-transparent focus:outline-none transition"
                    />
                </div>

                <!-- 交換頻度 -->
                <div>
                    <label class="block test-xs font-semibold tracking-wider text-[#6B5B53] uppercase mb-2">交換頻度</label>
                    <div class="relative">
                        <select
                            v-model="form.exchange_frequency"
                            class="w-full bg-[#FAFAF8] border border-[#E2DAD0] rounded-xl px-4 py-3 text-sm text-[#3A2E2B] appearance-none focus:ring-2 focus:ring-[#5A1222] focus:border-transparent focus:outline-none transition cursor-pointer"
                        >
                            <option value="daily">毎日</option>
                            <option value="3_days">3日ごと</option>
                            <option value="weekly">1週間ごと</option>
                            <option value="2_weeks">2週間ごと</option>
                            <option value="monthly">1ヶ月ごと</option>
                        </select>
                        <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-[#8C7B73]">
                            ▼
                        </div>
                        <p class="text-xs text-[#8c7B73] mt-1">※日記を交換する順番は、自動的に設定されます。</p>
                    </div>
                </div>

                <!-- お題選択 -->
                <div>
                    <div class="flex items-center justify-between mb-2">
                        <label class="block text-xs font-semibold tracking-wider text-[#6B5B53] uppercase mb-2">お題選択</label>
                        <span class="text-[10px] text-[#8C7B73]">クリックして詳細を確認・選択</span>
                    </div>
                    <div class="grid grid-cols-2 md:grid-cols-4 gap-2 relative">
                        <button
                            v-for="theme in themes"
                            :key ="theme.id"
                            type="button"
                            @click="selectedThemeForModal = theme"
                            @mouseenter="hoveredTheme = theme"
                            @mouseleave="hoveredTheme = null"
                            :class="form.theme_package === theme.id ? 'border-[#5A1222] bg-[#F4EFEA] text-[#5A1222]' : 'border-[#E2DAD0] bg-[#FAFAF8] text-[#6B5B53]'"
                            class="border rounded-xl p-3 text-xs font-medium transition text-center relative"
                        >
                            {{ theme.title }}
                            <!-- 選択中のお題 -->
                            <span v-if="form.theme_package === theme.id" class="absolute -top-1.5 -right-1.5 bg-[#5A1222] text-[#D4AF37] text-[9px] px-1.5 py-0.5 rounded-full font-bold shadow-sm">
                                選択中
                            </span>
                        </button>
                    </div>
                </div>

                <!-- 作成ボタン -->
                <button
                    @click="createGroup"
                    :disabled="isLoading"
                    class="w-full bg-[#5A1222] hover:bg-[#430D19] text-[#FDFBF7] font-medium py-3.5 rounded-xl shadow-md transition-all duration-200 disabled:opacity-50 tracking-wider text-sm mt-6 flex items-center justify-center gap-2"
                >
                    <span>{{ isLoading ? '作成中...' :'グループを決定。日記作成へ' }}</span>
                </button>
            </div>

            <!-- グループ作成後：招待リンクを表示する画面 -->
            <div v-else class="space-y-6 text-center animate-fadeIn">
                <div class="bg-[#F4EFEA] text-[#5A1222] p-5 rounded-2xl border border-[#E6DFD5]">
                    <p class="font-bold text-base mb-1">グループが完成しました</p>
                    <p class="text-xs text-[#73635B] leading-relaxed">以下の招待リンクを共有して、交換日記に招待しましょう。</p>
                </div>

                <!-- 招待URLのコピーボックス -->
                <div class="bg-[#FAFAF8] p-3.5 rounded-xl flex items-center justify-between text-xs text-[#6B5B53] border border-[#E2DAD0]">
                    <span class="truncate mr-3 font-mono select-all">{{ createdInviteUrl }}</span>
                    <button
                        @click="copyInviteUrl"
                        class="bg-white border border-[#DCD5CD] px-3 py-1.5 rounded-lg shadow-sm hover:bg-[#F5F2EC] text-[#3A2E2B] font-medium transition shrink-0"
                    >
                        コピー
                    </button>
                </div>

                <!-- LINEシェアボタン -->
                <button
                    @click="shareOnLine"
                    class="w-full bg-[#06C755] hover:bg-[#05b34c] text-white font-medium py-3.5 rounded-xl shadow-md flex items-center justify-center gap-2 transition text-sm"
                >
                    <span class="text-lg">💬</span>
                    <span>LINEで送る</span>
                </button>

                <button
                    @click="goToCreate"
                    class="w-full bg-[#EFECE6] hover:bg-[#E4DFD5] text-[#5A1222] font-medium py-3 rounded-xl transition text-sm"
                >
                    日記画面へ進む
                </button>
            </div>
        </div>

        <!-- お題詳細確認のモーダル -->
        <div v-if="selectedThemeForModal" class="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4 z-50 animate-fadeIn">
            <div class="bg-white rounded-3xl p-6 md:p-8 max-w-md w-full shadow-2xl border border-[#EFECE6] relative space-y-4 font-serif">

                <!-- 閉じるボタン -->
                <button
                    @click="selectedThemeForModal = null"
                    class="absolute top-4 right-4 text-[#8C7B73] hover:text-[#3A2E2B] w-8 h-8 rounded-full bg-[#FAFAF8] border border-[#E2DAD0] flex items-center justify-center transition text-sm font-bold"
                >
                    ×
                </button>
                <!-- モーダルヘッダー -->
                <div>
                    <span class="text-[10px] uppercase tracking-wider font-semibold text-[#8C7B73] bg-[#F4EFEA] px-2 py-1 rounded">
                        お題パッケージ詳細
                    </span>
                    <h3 class="text-xl font-bold text-[#5A1222] mt-2">【 {{ selectedThemeForModal.title }} 】</h3>
                </div>

                <!-- 詳細テキストボックス -->
                <div class="bg-[#FAFAF8] border border-[#E2DAD0] p-4 rounded-2xl text-xs text-[#6B5B53] leading-relaxed whitespace-pre-line max-h-48 overflow-y-auto space-y-2">
                    <p class="font-bold text-[#3A2E2B]">{{ selectedThemeForModal.subtitle }}</p>
                    <ul class="space-y-1 pl-2">
                        <li v-for="(point,index) in selectedThemeForModal.points" :key="index">
                            ・{{ point }}
                        </li>
                    </ul>
                </div>

                <!-- アクションボタン -->
                <div class="space-y-2 pt-2">
                    <button
                        @click="confirmTheme(selectedThemeForModal.id)"
                        class="w-full bg-[#5A1222] hover:bg-[#430D19] text-[#FDFBF7] font-medium py-3 rounded-xl shadow-md transition text-sm"
                    >
                        決定
                    </button>
                    <button
                        @click="selectedThemeForModal = null"
                        class="w-full bg-[#FAFAF8] hover:bg-[#F2ECE4] text-[#6B5B53] font-medium py-2.5 rounded-xl transition text-xs border border-[#E2DAD0]"
                    >
                        閉じる
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>