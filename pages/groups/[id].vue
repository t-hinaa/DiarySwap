<template>
    <div class="p-8">
        <h1 class="text-2xl font-bold">グループ詳細・日記ページ</h1>
        <p class="text-gray-600 mt-2">グループID: {{ route.params.id }}</p>
    </div>
</template>

<script setup>
import { useRoute } from 'vue-router'
const route = useRoute()
</script>