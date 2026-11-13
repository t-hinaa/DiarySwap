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
    -- すでに同じ line_user_id が存在していれば更新
    ON CONFLICT (line_user_id) 
    DO UPDATE SET
        display_name = EXCLUDED.display_name,
        avatar_url = EXCLUDED.avatar_url;
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

-- グループのお題を返すRPC関数
drop function if exists get_group_theme(uuid);
create or replace function get_group_theme(p_group_id uuid)
returns table (
    id text,
    points text[]
)
language plpgsql
security definer
as $$
begin
    return query
    select 
        t.id,
        t.points::text[]
    from public.groups g
    join public.themes t on g.theme_package = t.id
    where g.id = p_group_id;
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
    theme_id TEXT  REFERENCES public.themes(id) ON DELETE SET NULL, --お題が削除されても日記は残る
    date DATE,
    weather TEXT,
    content TEXT,
    theme_text JSONB,
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


-- 日記投稿&交換順の自動計算RPC関数
CREATE OR REPLACE FUNCTION create_diary_post(
    p_group_id UUID,
    p_content TEXT,
    p_theme_text JSONB DEFAULT NULL,
    p_weather TEXT DEFAULT NULL,
    p_seal_stamp TEXT DEFAULT NULL,
    p_theme_id TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_diary_id UUID;
    v_user_id UUID;
    v_member_count INT;
    v_current_turn INT;
    v_next_turn INT;
    v_next_line_user_id TEXT;
    v_group_name TEXT;
    v_display_name TEXT;
    v_access_token TEXT := 'ここにLINEのチャネルアクセストークンを貼り付け';
    v_message TEXT;
BEGIN
    -- ログインチェック
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'ログインしていません。';
    END IF;

    -- メンバーチェック
    IF NOT EXISTS (
        SELECT 1 FROM public.group_members 
        WHERE group_id = p_group_id AND user_id = v_user_id
    ) THEN
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

-- net.http_post 機能（HTTP拡張機能）有効化
create extension if not exists pg_net with schema extensions;
    -- グループのメンバー数を取得
    SELECT count(*) INTO v_member_count 
    FROM public.group_members 
    WHERE group_id = p_group_id;

    -- 今のcurrent_turn_index とグループ名を取得
    SELECT COALESCE(current_turn_index, 1), name 
    INTO v_current_turn, v_group_name
    FROM public.groups 
    WHERE id = p_group_id;

    -- 1始まりで次のターンの番号を計算
    IF v_member_count > 0 THEN
        v_next_turn := ((v_current_turn) % v_member_count) + 1;
    ELSE
        v_next_turn := 1;
    END IF;

    -- 投稿数と「1始まりのターン」を更新
    UPDATE public.groups
    SET 
        current_count = COALESCE(current_count, 0) + 1,
        current_turn_index = v_next_turn,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_group_id;

    -- 【LINE通知】次のターンの人（turn_order が v_next_turn の人）のLINE IDを取得
    SELECT u.line_user_id INTO v_next_line_user_id
    FROM public.group_members gm
    JOIN public.users u ON gm.user_id = u.id
    WHERE gm.group_id = p_group_id
        AND gm.turn_order = v_next_turn;
    
    -- 投稿者の名前も取得（メッセージ用）
    SELECT display_name INTO v_display_name FROM public.users WHERE id = v_user_id;

    -- 次の人のLINE IDが存在し、かつ1人グループでなければ通知送信
    IF v_next_line_user_id IS NOT NULL AND v_member_count > 1 THEN
        v_message := format(
            E'📖 【%s】\n\n%sさんが日記を封印しました！\n次はあなたの番です！\n\n「%s...」',
            COALESCE(v_group_name, '交換日記'),
            COALESCE(v_display_name, 'メンバー'),
            substring(COALESCE(p_content, ''), 1, 25)
        );

        PERFORM net.http_post(
            url := 'https://api.line.me/v2/bot/message/push',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || v_access_token
            ),
            body := jsonb_build_object(
                'to', v_next_line_user_id,
                'messages', jsonb_build_array(
                    jsonb_build_object('type', 'text', 'text', v_message)
                )
            )
        );
    END IF;

    RETURN v_diary_id;
END;
$$;


-- 日記編集用のRPC関数
CREATE OR REPLACE FUNCTION update_diary_post(
    p_diary_id UUID,
    p_content TEXT,
    p_theme_text JSONB DEFAULT NULL,
    p_weather TEXT DEFAULT NULL,
    p_date Date DEFAULT NULL
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
        content = COALESCE(p_content, content),
        -- p_theme_text が渡されたらそのまま使い、NULLなら既存のままにする
        theme_text = COALESCE(p_theme_text, theme_text::jsonb),
        weather = COALESCE(p_weather, weather),
        date = COALESCE(p_date, date),
        updated_at = timezone('utc'::text, now())
    WHERE id = p_diary_id;

    -- 更新した日記のIDを返す
    RETURN p_diary_id;
END;
$$;
-- ログイン済みユーザーにのみ実行権限を与える
GRANT EXECUTE ON FUNCTION public.update_diary_post(UUID, TEXT, JSONB, TEXT, DATE) TO authenticated;

-- ==========================================
-- 参加している交換日記の情報をまとめて取得するためRPC関数（一覧画面用）
-- ==========================================

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
-- 交換日記の情報を全てまとめて取得するためRPC関数（詳細画面用）
-- ==========================================

create or replace function public.get_group_diary_details(p_group_id uuid)
returns json
language plpgsql
security definer
as $$
declare
    v_result json;
begin

    -- グループのメンバーかチェック
    IF NOT EXISTS (
        SELECT 1 FROM public.group_members 
        WHERE group_id = v_group_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'このグループのメンバーではありません。';
    END IF;

    select json_build_object(
        'group', (select row_to_json(g) from public.groups g where g.id = p_group_id),
        'posts', (
            coalesce(
                (
                    select json_agg(
                        json_build_object(
                            'id', d.id,
                            'content', d.content,
                            'date', d.date,
                            'weather', d.weather,
                            'author_name', coalesce(u.display_name, 'メンバー'),
                            'author_id', d.author_id,
                            'theme_title', t.title,
                            'theme_points', t.points,
                            'theme_text', d.theme_text,
                            'seal_stamp', d.seal_stamp 
                        )
                        order by d.created_at desc
                    )
                    from public.diaries d
                    left join public.users u on d.author_id = u.id
                    left join public.themes t on d.theme_id = t.id
                    where d.group_id = p_group_id
                ),
                '[]'::json
            )
        )
    ) into v_result;

    return v_result;
end;
$$;
-- ログイン済みユーザーにのみ実行権限を与える
GRANT EXECUTE ON FUNCTION public.get_group_diary_details(uuid) TO authenticated;