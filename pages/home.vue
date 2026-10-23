<template>
    <div class="min-h-[calc(100vh-73px)] bg-[#faf8F5] flex flex-col items-center justify-center px-4 py-8 overflow-hidden">

        <div class="w-full max-w-6xl flex flex-col md:flex-row items-center justify-center gap-6 lg:gap-10">
        
            <div class="w-full md:w-72 h-80 bg-white/70 backdrop-blur-md rounded-[60%_40%_30%_70%/60%_30%_70%_40%] p-6 flex flex-col items-center justify-center shadow-sm border border-stone-200/50 hover:-translate-y-1 hover:shadow-lg hover:scale-[1.02] transition duration-300 cursor-pointer">
                <div class="flex flex-col items-center justify-center my-auto">
                    <button class="bg-[#8B263E] text-white px-8 py-3.5 rounded-full font-medium text-sm shadow-md hover:bg-[#721f33] transition duration-200 flex items-center justify-center gap-2">
                        <span>📖</span>日記を読む
                    </button>
                </div>
            </div>

            <div class="w-full md:w-[460px] h-[420px] bg-white/80 backdrop-blur-md rounded-[30%_70%_50%_50%/50%_40%_60%_50%] p-8 flex flex-col justify-between shadow-xl border border-stone-200/60 relative hover:-translate-y-1 hover:shadow-2xl hover:scale-[1.02] transition duration-300">
                <div class="flex flex-col items-center justify-center my-auto">
                    <button class="bg-[#8B263E] text-white px-8 py-3.5 rounded-full font-medium text-sm shadow-md hover:bg-[#721f33] transition duration-200 flex items-center justify-center gap-2">
                        <span>✍️</span>日記を書く
                    </button>
                </div>
            </div>

            <div class="w-full md:w-72 h-80 bg-white/70 backdrop-blur-md rounded-[50%_50%_70%_30%/40%_60%_40%_60%] p-6 flex flex-col items-center justify-center shadow-sm border border-stone-200/50 hover:-translate-y-1 hover:shadow-lg hover:scale-[1.02] transition duration-300 cursor-pointer">
                <div class="text-center">
                    <h3 class="text-stone-800 font-medium text-sm">新しい交換日記を始める</h3>
                    <button class="bg-[#8B263E] text-white px-8 py-3.5 rounded-full font-medium text-sm shadow-md hover:bg-[#721f33] transition duration-200 flex items-center justify-center gap-2">
                        グループを作成
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>