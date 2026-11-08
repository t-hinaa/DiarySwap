-- ==========================================
-- usersテーブル
-- ==========================================

CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    line_user_id TEXT UNIQUE, 
    display_name TEXT,          -- デフォルトで Nullable（空欄OK）
    avatar_url TEXT,            -- デフォルトで Nullable（空欄OK）
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- テーブルのセキュリティ権限を絞る
REVOKE ALL ON users FROM anon;
GRANT SELECT, INSERT, UPDATE ON users TO authenticated;

-- RLSを有効化
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ユーザーテーブルのポリシー設定
DROP POLICY IF EXISTS "ユーザーは自分のプロフィールのみ閲覧可能" ON users;
CREATE POLICY "ユーザーは自分のプロフィールのみ閲覧可能"
ON users FOR SELECT
USING (auth.uid() = id);

DROP POLICY IF EXISTS "ユーザーは自分のプロフィールのみ作成可能" ON users;
CREATE POLICY "ユーザーは自分のプロフィールのみ作成可能"
ON users FOR INSERT
WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "ユーザーは自分のプロフィールのみ更新可能" ON users;
CREATE POLICY "ユーザーは自分のプロフィールのみ更新可能"
ON users FOR UPDATE
USING (auth.uid() = id);

-- ログイン時に自動で users テーブルに書き込む関数(自動トリガー関数)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.users (id, display_name, avatar_url,line_user_id)
    VALUES (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url',
    new.raw_user_meta_data->>'line_user_id'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- トリガーの登録
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ==========================================
-- groupsテーブル
-- ==========================================

CREATE TABLE IF NOT EXISTS public.groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    invite_code TEXT UNIQUE NOT NULL,
    exchange_frequency TEXT DEFAULT 'daily',
    theme_package TEXT DEFAULT 'earl_grey',
    current_turn_index INTEGER DEFAULT 1,
    current_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLSを有効化
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;

-- groups のポリシー
-- 作成（INSERT）はEdge Functionsが行うためポリシー不要

DROP POLICY IF EXISTS "メンバーのみグループ情報を閲覧可能" ON public.groups;
CREATE POLICY "メンバーのみグループ情報を閲覧可能"
ON public.groups 
FOR SELECT
TO authenticated
USING (
    id IN (
        SELECT group_id FROM public.group_members WHERE user_id = auth.uid()
    )
);

--  【RPC関数】招待コードからグループ情報を安全に取得（未ログイン可）
CREATE OR REPLACE FUNCTION public.get_group_by_invite_code(p_invite_code TEXT)
RETURNS TABLE (
    id UUID,
    name TEXT,
    exchange_frequency TEXT,
    theme_package TEXT
) 
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RETURN QUERY
    SELECT g.id, g.name, g.exchange_frequency, g.theme_package
    FROM public.groups g
    WHERE g.invite_code = p_invite_code;
END;
$$ LANGUAGE plpgsql;

-- 【ヘルパー関数】無限ループを防ぐためのメンバー判定関数
CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id UUID)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.group_members 
        WHERE group_id = p_group_id 
            AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql;


-- ==========================================
-- group_membersテーブル
-- ==========================================

CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    turn_order INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLSを有効化
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- group_membersのポリシー
DROP POLICY IF EXISTS "自分と、自分と同じグループのメンバーの情報のみ閲覧可能" ON public.group_members;
CREATE POLICY "自分と、自分と同じグループのメンバーの情報のみ閲覧可能"
ON public.group_members
FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()
    OR
    public.is_group_member(group_id)
);

DROP POLICY IF EXISTS "ログイン済みのユーザーが「自分自身のメンバー情報」を追加できる" ON public.group_members;
CREATE POLICY "ログイン済みのユーザーが「自分自身のメンバー情報」を追加できる"
ON public.group_members
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 参加のチェック＆交換順の自動計算RPC関数
CREATE OR REPLACE FUNCTION join_group_with_turn_order(p_group_id uuid, p_user_id uuid)
returns integer
language plpgsql
security definer
as $$
declare
    v_max_order integer;
    v_next_order integer;
    v_existing_count integer;
begin
    -- すでに参加しているかチェック
    select count(*) into v_existing_count
    from group_members
    where group_id = p_group_id and user_id = p_user_id;

    if v_existing_count > 0 then
        return -1; -- すでに参加済み
    end if;

    -- 現在の最大の turn_order を取得
    select coalesce(max(turn_order), 0) into v_max_order
    from group_members
    where group_id = p_group_id;

    v_next_order := v_max_order + 1;

    -- 新規メンバーとして挿入
    insert into group_members (group_id, user_id, turn_order)
    values (p_group_id, p_user_id, v_next_order);

    return v_next_order;
end;
$$;

-- 参加している交換日記の情報をまとめて取得するためのRPC関数
create or replace function get_my_diary_books()
returns table (
    group_id uuid,
    name text,
    exchange_frequency text,
    theme_package text,
    current_turn_index integer,
    current_count integer,
    turn_order integer
)
language plpgsql
security definer
as $$
begin
    return query
    select 
        g.id as group_id,
        g.name,
        g.exchange_frequency,
        g.theme_package,
        g.current_turn_index,
        g.current_count,
        gm.turn_order
    from public.group_members gm
    join public.groups g on gm.group_id = g.id
    where gm.user_id = auth.uid(); -- Supabaseの認証機能から現在のユーザーIDを取得
end;
$$;


-- ==========================================
-- themesテーブル
-- ==========================================

CREATE TABLE IF NOT EXISTS public.themes (
    id TEXT PRIMARY KEY,               -- 'earl_grey'などの文字列をそのままIDに
    title TEXT NOT NULL,               -- 'アールグレイ' などのテーマ名
    subtitle TEXT,
    points TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLSの有効化
ALTER TABLE public.themes ENABLE ROW LEVEL SECURITY;

-- ポリシー設定
CREATE POLICY "ログインしているユーザーであれば誰でもお題を閲覧できる"
ON public.themes 
FOR SELECT
USING (auth.uid() IS NOT NULL);


-- ==========================================
-- diariesテーブル
-- ==========================================

CREATE TABLE IF NOT EXISTS public.diaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    author_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    theme_id UUID  REFERENCES public.themes(id) ON DELETE SET NULL, --お題が削除されても日記は残る
    date DATE,
    weather TEXT,
    content TEXT,
    theme_text TEXT,
    seal_stamp TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLSの有効化
ALTER TABLE public.diaries ENABLE ROW LEVEL SECURITY;

-- ポリシー設定
DROP POLICY IF EXISTS "グループのメンバーであれば日記を閲覧できる" ON public.diaries;
CREATE POLICY "グループのメンバーであれば日記を閲覧できる"
ON public.diaries
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.group_members gm
        WHERE gm.group_id = diaries.group_id
        AND gm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "自分のIDで、所属するグループであれば日記を投稿できる" ON public.diaries;
CREATE POLICY "自分のIDで、所属するグループであれば日記を投稿できる"
ON public.diaries
FOR INSERT
WITH CHECK (
    auth.uid() = author_id
    AND EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = diaries.group_id
    AND gm.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "自分の日記のみ更新可能" ON public.diaries;
CREATE POLICY "自分の日記のみ更新可能"
ON public.diaries
FOR UPDATE
USING (
    -- 条件１：　自分がその日記を書いた本人であること
    auth.uid() = author_id
    -- 条件２：　その日記が属するグループのメンバーであること
    AND EXISTS (
        SELECT 1 FROM public.group_members gm
        WHERE gm.group_id = diaries.group_id
        AND gm.user_id = auth.uid()
    )
)

WITH CHECK (
    -- 更新後もauthor_idが変わっていないこと（日記のすり替え防止）
    auth.uid() = author_id
);


-- 日記投稿用のRPC関数
CREATE OR REPLACE FUNCTION create_diary_post(
    p_group_id UUID,
    p_content TEXT,
    p_theme_text TEXT DEFAULT NULL,
    p_weather TEXT DEFAULT NULL,
    p_seal_stamp TEXT DEFAULT NULL,
    p_theme_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_diary_id UUID;
    v_user_id UUID;
BEGIN
    -- 現在ログインしているユーザーのIDを取得
    v_user_id := auth.uid();
    if v_user_id is null then
        RAISE EXCEPTION 'ログインしていません。';
    END IF;

    -- ユーザーがそのグループのメンバーかチェック
    if not exists (
        SELECT 1 FROM public.group_members 
        WHERE group_id = p_group_id AND user_id = v_user_id
    ) then
        RAISE EXCEPTION 'このグループのメンバーではありません。';
    END IF;

    -- diariesテーブルに新しい日記を登録
    INSERT INTO public.diaries (
        group_id,
        author_id,
        theme_id,
        date,
        weather,
        content,
        theme_text,
        seal_stamp
    ) VALUES (
        p_group_id,
        v_user_id,
        p_theme_id,
        current_date,
        p_weather,
        p_content,
        p_theme_text,
        p_seal_stamp
    )
    RETURNING id INTO v_diary_id;

    -- 作成された日記のIDを返す
    RETURN v_diary_id;
END;
$$;

-- 日記更新用のRPC関数
CREATE OR REPLACE FUNCTION update_diary_post(
    p_diary_id UUID,
    p_content TEXT,
    p_theme_text TEXT DEFAULT NULL,
    p_weather TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_group_id UUID;
BEGIN
    -- 現在ログインしているユーザーのIDを取得
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'ログインしていません。';
    END IF;

    -- 自分が書いた日記か確認、その日記が属する group_id を取得
    SELECT group_id INTO v_group_id
    FROM public.diaries
    WHERE id = p_diary_id AND author_id = v_user_id;

    IF v_group_id IS NULL THEN
        RAISE EXCEPTION '編集権限がないか、該当する日記が見つかりません。';
    END IF;

    -- 現在もそのグループのメンバーかチェック
    IF NOT EXISTS (
        SELECT 1 FROM public.group_members 
        WHERE group_id = v_group_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'このグループのメンバーではありません。';
    END IF;

    -- データの更新実行
    UPDATE public.diaries
    SET 
        content = p_content,
        theme_text = COALESCE(p_theme_text, theme_text),
        weather = COALESCE(p_weather, weather),
        updated_at = timezone('utc'::text, now())
    WHERE id = p_diary_id;

    -- 更新した日記のIDを返す
    RETURN p_diary_id;
END;
$$;