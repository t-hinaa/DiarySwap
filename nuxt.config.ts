// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  modules: [
    '@nuxtjs/supabase',
    '@nuxtjs/tailwindcss'
  ],

  // 未ログイン時 /login へ飛ばす機能をOFF
  supabase: {
    redirect: false
  }
})
