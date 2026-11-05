<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';

const route = useRoute()
const router = useRouter()
const supabase = useSupabaseClient()
const user = useSupabaseUser()

const inviteCode = route.params.code // URLから招待コードを取得 
const groupInfo = ref(null)
const isLoading = ref(true)
const errorMessage = ref('')

// ページを開いた時に招待コードに一致するグループを検索する
onMounted(async () => {
    
    try {
        const { data, error } = await supabase
            .rpc('get_group_by_invite_code', { p_invite_code: inviteCode })     //RPC関数を呼ぶコード
            .single()

        if (error || !data) {
            errorMessage.value = '無効な招待リンクか、すでに有効期限が切れています。'
        }else {
              groupInfo.value = data // グループが見つかった！
        }
    }catch (err) {
        console.error('グループ検索エラー:',err)
        errorMessage.value = 'グループの情報取得に失敗しました。'
    }finally {
        isLoading.value = false
    }
})

// LINEでログインして参加するボタンの処理
const loginAndJoin = () => {
    const LINE_CHANNEL_ID = "2012285519"
    const redirectUri = `${window.location.origin}/auth/callback`

    // LINEのstate機能にパスをそのまま含めてLINEに預ける
    const currentPath = window.location.pathname
    const stateValue = encodeURIComponent(currentPath)
    
    const lineAuthUrl = `https://access.line.me/oauth2/v2.1/authorize?response_type=code&client_id=${LINE_CHANNEL_ID}&redirect_uri=${encodeURIComponent(redirectUri)}&state=${stateValue}&scope=profile%20openid`
    window.location.href = lineAuthUrl
}

// グループに参加する ボタンを押した時の処理
const joinGroup = async () => {
    const { data: sessionData, error: sessionErr } = await supabase.auth.getSession()

    // ログインしていなかったら、一度ログインへ（ログイン後にこのページに戻る）
    if (sessionErr || !sessionData.session) {
        alert('参加するにはLINEログインが必要です。')
        loginAndJoin()
        return
    }

    const supabaseUserId = sessionData.session.user.id

    // グループ情報の読み込み
    if (!groupInfo.value || !groupInfo.value.id) {
        alert('グループ情報を読み込んでいます。少々お待ちください。')
        return
    }

    try{
        isLoading.value = true

        // RPC関数を呼ぶだけで、参加チェック・ターンオーダー計算・INSERTが完了になる
        const { data: assignedOrder, error: rpcError } = await supabase
            .rpc('join_group_with_turn_order', {
                p_group_id: groupInfo.value.id,
                p_user_id: supabaseUserId
            })

        if (rpcError) throw rpcError

        if (assignedOrder === -1) {
            alert('すでにこのグループに参加しています！')
        } else {
            alert(`グループに参加しました！（あなたの順番: ${assignedOrder}番目）`)
        }

        router.push(`/groups/${groupInfo.value.id}`)

    }catch (err) {
        console.error('グループ参加エラー:',err)
        alert('グループへの参加に失敗しました: ' + err.message)
    }finally {
        isLoading.value = false
    }
}
</script>

<template>
    <div class="min-h-screen bg-amber-50 flex items-center justify-center p-6">
        <div class="bg-white rounded-2xl p-8 max-w-md w-full shadow-lg text-center">

            <!-- ローディング中 -->
            <div v-if="isLoading">
                <p class="text-gray-600">読み込んでいます...</p>
            </div>

            <!-- エラー（無効なリンク）の場合 -->
            <div v-else-if="errorMessage" class="space-y-4">
                <h2 class="text-xl font-bold text-gray-800">リンクが見つかりません</h2>
                <p class="text-gray-600 text-sm">{{ errorMessage }}</p>
                <button
                    @click="router.push('/')"
                    class="w-full bg-gray-200 hover:bg-gray-300 font-bold py-3 rounded-lg transition"
                >
                    トップページへ戻る
                </button>
            </div>

            <!-- グループが見つかった場合（お迎え画面） -->
            <div v-else-if="groupInfo" class="space-y-6">
                <div>
                    <h2 class="text-xl font-bold text-gray-800 mb-2">交換日記へ招待されました！</h2>
                    <p class="text-gray-600 text-sm">
                        <span class="font-bold text-amber-700">「{{groupInfo.name}}」</span>のグループに参加して、日記を始めましょう。
                    </p>
                </div>

                <!-- ログインしている場合：参加ボタン -->
                <div v-if="user">
                    <button
                        @click="joinGroup"
                        :disabled="isLoading || !groupInfo"
                        class="w-full bg-amber-600 hover:bg-amber-700 text-white font-bold py-3 rounded-lg shadow transition"
                    >
                        グループに参加する
                    </button>
                </div>

                <!-- ログインしてない場合：LINEログインボタン -->
                <div v-else class="space-y-3">
                    <p class="text-xs text-gray-500">参加するにはLINEログインが必要です</p>
                    <button
                        @click="loginAndJoin"
                        class="w-full bg-[#06C755] hover:-[#05b34c] text-white font-bold py-3 rounded-lg shadow flex items-center justify-center gap-2transition"
                    >
                        <span>💬</span>
                        <span>LINEでログインして参加する</span>
                    </button>
                </div>
            </div>

        </div>
    </div>
</template>