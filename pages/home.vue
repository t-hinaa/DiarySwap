<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter()
const supabase = useSupabaseClient()

const isSubmitting = ref(false)
const showModal = ref(false)
const myGroups = ref([])

// 日記一覧画面
const goToList = () => {
    router.push('/list/')
}

// 日記作成画面　（ユーザーの所属グループを判定して飛ぶ）
const goToCreate = async () => {
    if (isSubmitting.value) return;

    try {
        isSubmitting.value = true;
        const user = (await supabase.auth.getUser()).data.user;
        
        if (!user) {
            alert('ログインが必要です。');
            router.push('/login');
            return;
        }

        /// 自分が所属するグループ一覧・自分の turn_order・グループの current_turn_indexを取得
        const { data, error } = await supabase
            .from('group_members')
            .select(`
                turn_order,
                groups (
                    id,
                    name,
                    current_turn_index
                )
            `)
            .eq('user_id', user.id);

        if (error) throw error;

        // データを使いやすい形に整形
        const groups = data.map(item => {
            // item.groups が配列の場合とオブジェクトの場合の両方に対応
            const g = Array.isArray(item.groups) ? item.groups[0] : item.groups;
            if (!g) return null;
            
            return {
                id: g.id,
                name: g.name,
                turn_order: item.turn_order,
                current_turn_index: g.current_turn_index
            };
        }).filter(Boolean);

        // 0件の場合
        if (groups.length === 0) {
            alert('まだ参加しているグループがありません。「グループを作成」から新しい交換日記を始めましょう！');
            return;
        }

        // 1件だけならそのまま直行
        if (groups.length === 1) {
            const targetGroup = groups[0];
            // 【ターン制限チェック】自分の順番と現在のターンが一致するか
            if (targetGroup.turn_order !== targetGroup.current_turn_index) {
                alert(`「${targetGroup.name}」は、今はほかのメンバーのターンです！順番を待ちましょう🫟`);
                return;
            }
            router.push(`/groups/${targetGroup.id}/create`);
            return;
        }

        // 2件以上あるならモーダルを開く
        myGroups.value = groups;
        showModal.value = true;

    } catch (err) {
        console.error('グループ情報の取得に失敗:', err);
        alert('グループ情報の取得に失敗しました。通信環境を確認してもう一度お試しください。');
    } finally {
        isSubmitting.value = false;
    }
}
// モーダルでグループが選択されたとき
const handleGroupSelect = (selectedGroup) => {
    showModal.value = false;

    // 1. 選択されたのがオブジェクトかID（文字列）かにかかわらず、IDを取り出す
    const groupId = typeof selectedGroup === 'object' ? selectedGroup?.id : selectedGroup;

    if (!groupId) {
        alert('グループIDが見つかりませんでした。');
        return;
    }

    // myGroups の中から該当するグループのデータを見つける
    const targetGroup = myGroups.value.find(g => g.id === groupId);

    if (!targetGroup) {
        alert('グループ情報が見つかりませんでした。');
        return;
    }

    // 【ターン制限チェック】
    if (targetGroup.turn_order !== targetGroup.current_turn_index) {
        alert(`「${targetGroup.name}」は、今はほかのメンバーのターンです！順番を待ちましょう🫟`);
        return;
    }

    router.push(`/groups/${targetGroup.id}/create`);
}

//グループ作成画面
const goToGroupCreate = () => {
    router.push('/groups/create')
}

</script>

<template>
    <div class="min-h-[calc(100vh-73px)] bg-[#faf8F5] flex flex-col items-center justify-center px-4 py-8 overflow-hidden relative">

        <div class="w-full max-w-6xl flex flex-col md:flex-row items-center justify-center gap-6 lg:gap-10">
        
            <div class="w-full md:w-72 h-80 bg-white/70 backdrop-blur-md rounded-[60%_40%_30%_70%/60%_30%_70%_40%] p-6 flex flex-col items-center justify-center shadow-sm border border-stone-200/50 hover:-translate-y-1 hover:shadow-lg hover:scale-[1.02] transition duration-300 cursor-pointer">
                <div class="flex flex-col items-center justify-center my-auto">
                    <button 
                        @click="goToList"
                        class="bg-[#8B263E] text-white px-8 py-3.5 rounded-full font-medium text-sm shadow-md hover:bg-[#721f33] transition duration-200 flex items-center justify-center gap-2"
                    >
                        <span>📖</span>日記を読む
                    </button>
                </div>
            </div>

            <div class="w-full md:w-[460px] h-[420px] bg-white/80 backdrop-blur-md rounded-[30%_70%_50%_50%/50%_40%_60%_50%] p-8 flex flex-col justify-between shadow-xl border border-stone-200/60 relative hover:-translate-y-1 hover:shadow-2xl hover:scale-[1.02] transition duration-300">
                <div class="flex flex-col items-center justify-center my-auto">
                    <button
                        @click="goToCreate"
                        :disabled="isSubmitting"
                        class="bg-[#8B263E] text-white px-8 py-3.5 rounded-full font-medium text-sm shadow-md hover:bg-[#721f33] transition duration-200 flex items-center justify-center gap-2 disabled:opacity-60"
                    >
                        <span>✍️</span>{{ isSubmitting ? '確認中...' : '日記を書く' }}
                    </button>
                </div>
            </div>

            <div class="w-full md:w-72 h-80 bg-white/70 backdrop-blur-md rounded-[50%_50%_70%_30%/40%_60%_40%_60%] p-6 flex flex-col items-center justify-center shadow-sm border border-stone-200/50 hover:-translate-y-1 hover:shadow-lg hover:scale-[1.02] transition duration-300 cursor-pointer">
                <div class="text-center">
                    <h3 class="text-stone-800 font-medium text-sm">新しい交換日記を始める</h3>
                    <button 
                        @click="goToGroupCreate"
                        class="bg-[#8B263E] text-white px-8 py-3.5 rounded-full font-medium text-sm shadow-md hover:bg-[#721f33] transition duration-200 flex items-center justify-center gap-2"
                    >
                        グループを作成
                    </button>
                </div>
            </div>
        </div>

        <!-- グループ選択モーダル -->
        <GroupSelectModal
            :is-open="showModal"
            :groups="myGroups"
            @close="showModal = false"
            @select="handleGroupSelect"
        />
    </div>
</template>