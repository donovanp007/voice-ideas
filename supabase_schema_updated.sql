-- Thought Recorder Database Schema - UPDATED VERSION
-- Run this SQL in your Supabase SQL Editor
-- This version includes: titles, pinning, archiving, and checklist support

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==================== CATEGORIES TABLE ====================
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    color_hex TEXT NOT NULL,
    icon TEXT NOT NULL,
    ai_assigned BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);

-- ==================== THOUGHTS TABLE (UPDATED) ====================
CREATE TABLE IF NOT EXISTS thoughts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,

    -- Content fields
    title TEXT,  -- NEW: User or AI-generated title
    original_text TEXT NOT NULL,
    ai_summary TEXT,
    recording_url TEXT,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Organization
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    tags TEXT[] DEFAULT '{}',

    -- Status flags (NEW)
    is_pinned BOOLEAN DEFAULT false,  -- NEW: Pin important thoughts
    is_archived BOOLEAN DEFAULT false,  -- NEW: Archive old thoughts
    is_checklist BOOLEAN DEFAULT false,  -- NEW: Is this a checklist/to-do?

    -- Reminders
    has_reminder BOOLEAN DEFAULT false,
    reminder_id TEXT
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_thoughts_user_id ON thoughts(user_id);
CREATE INDEX IF NOT EXISTS idx_thoughts_category_id ON thoughts(category_id);
CREATE INDEX IF NOT EXISTS idx_thoughts_created_at ON thoughts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_thoughts_tags ON thoughts USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_thoughts_is_pinned ON thoughts(is_pinned);  -- NEW
CREATE INDEX IF NOT EXISTS idx_thoughts_is_archived ON thoughts(is_archived);  -- NEW

-- Full text search on thoughts (updated to include title)
CREATE INDEX IF NOT EXISTS idx_thoughts_search ON thoughts USING GIN(
    to_tsvector('english',
        COALESCE(title, '') || ' ' ||
        original_text || ' ' ||
        COALESCE(ai_summary, '')
    )
);

-- ==================== CHECKLIST ITEMS TABLE (NEW) ====================
CREATE TABLE IF NOT EXISTS checklist_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    thought_id UUID NOT NULL REFERENCES thoughts(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    position INTEGER NOT NULL,  -- Order of items in the checklist
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for checklist items
CREATE INDEX IF NOT EXISTS idx_checklist_items_thought_id ON checklist_items(thought_id);
CREATE INDEX IF NOT EXISTS idx_checklist_items_position ON checklist_items(thought_id, position);

-- ==================== REMINDERS TABLE ====================
CREATE TABLE IF NOT EXISTS reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    thought_id UUID REFERENCES thoughts(id) ON DELETE CASCADE,
    android_reminder_id TEXT,
    reminder_time TIMESTAMP WITH TIME ZONE NOT NULL,
    title TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on thought_id
CREATE INDEX IF NOT EXISTS idx_reminders_thought_id ON reminders(thought_id);
CREATE INDEX IF NOT EXISTS idx_reminders_time ON reminders(reminder_time);

-- ==================== STORAGE BUCKET ====================
-- Storage bucket for audio recordings
-- Run this separately or in the Supabase Storage UI
INSERT INTO storage.buckets (id, name, public)
VALUES ('recordings', 'recordings', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policy for authenticated uploads
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'objects'
        AND policyname = 'Users can upload their own recordings'
    ) THEN
        CREATE POLICY "Users can upload their own recordings"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'recordings');
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'objects'
        AND policyname = 'Users can view their own recordings'
    ) THEN
        CREATE POLICY "Users can view their own recordings"
        ON storage.objects FOR SELECT
        TO authenticated
        USING (bucket_id = 'recordings');
    END IF;
END $$;

-- ==================== ROW LEVEL SECURITY (RLS) ====================
-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE thoughts ENABLE ROW LEVEL SECURITY;
ALTER TABLE checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

-- For demo purposes, allow all operations (you should implement proper auth)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'categories'
        AND policyname = 'Allow all operations on categories'
    ) THEN
        CREATE POLICY "Allow all operations on categories"
        ON categories FOR ALL
        USING (true)
        WITH CHECK (true);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'thoughts'
        AND policyname = 'Allow all operations on thoughts'
    ) THEN
        CREATE POLICY "Allow all operations on thoughts"
        ON thoughts FOR ALL
        USING (true)
        WITH CHECK (true);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'checklist_items'
        AND policyname = 'Allow all operations on checklist_items'
    ) THEN
        CREATE POLICY "Allow all operations on checklist_items"
        ON checklist_items FOR ALL
        USING (true)
        WITH CHECK (true);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'reminders'
        AND policyname = 'Allow all operations on reminders'
    ) THEN
        CREATE POLICY "Allow all operations on reminders"
        ON reminders FOR ALL
        USING (true)
        WITH CHECK (true);
    END IF;
END $$;

-- ==================== FUNCTIONS AND TRIGGERS ====================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_thoughts_updated_at ON thoughts;
CREATE TRIGGER update_thoughts_updated_at
    BEFORE UPDATE ON thoughts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update completed_at when checklist item is marked complete
CREATE OR REPLACE FUNCTION update_checklist_item_completed_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_completed = true AND OLD.is_completed = false THEN
        NEW.completed_at = NOW();
    ELSIF NEW.is_completed = false THEN
        NEW.completed_at = NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for checklist completion
DROP TRIGGER IF EXISTS update_checklist_completed_at ON checklist_items;
CREATE TRIGGER update_checklist_completed_at
    BEFORE UPDATE ON checklist_items
    FOR EACH ROW
    EXECUTE FUNCTION update_checklist_item_completed_at();

-- ==================== UTILITY FUNCTIONS ====================

-- Function to search thoughts (updated with title)
CREATE OR REPLACE FUNCTION search_thoughts(
    search_query TEXT,
    user_id_param TEXT,
    include_archived BOOLEAN DEFAULT false
)
RETURNS TABLE (
    id UUID,
    user_id TEXT,
    title TEXT,
    original_text TEXT,
    ai_summary TEXT,
    recording_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    category_id UUID,
    tags TEXT[],
    is_pinned BOOLEAN,
    is_archived BOOLEAN,
    is_checklist BOOLEAN,
    has_reminder BOOLEAN,
    reminder_id TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT t.*
    FROM thoughts t
    WHERE t.user_id = user_id_param
    AND (include_archived OR t.is_archived = false)
    AND (
        t.title ILIKE '%' || search_query || '%'
        OR t.original_text ILIKE '%' || search_query || '%'
        OR t.ai_summary ILIKE '%' || search_query || '%'
        OR search_query = ANY(t.tags)
    )
    ORDER BY t.is_pinned DESC, t.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get thoughts by category
CREATE OR REPLACE FUNCTION get_thoughts_by_category(
    category_id_param UUID,
    user_id_param TEXT,
    include_archived BOOLEAN DEFAULT false
)
RETURNS TABLE (
    id UUID,
    user_id TEXT,
    title TEXT,
    original_text TEXT,
    ai_summary TEXT,
    recording_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    category_id UUID,
    tags TEXT[],
    is_pinned BOOLEAN,
    is_archived BOOLEAN,
    is_checklist BOOLEAN,
    has_reminder BOOLEAN,
    reminder_id TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT t.*
    FROM thoughts t
    WHERE t.user_id = user_id_param
    AND t.category_id = category_id_param
    AND (include_archived OR t.is_archived = false)
    ORDER BY t.is_pinned DESC, t.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get checklist completion percentage
CREATE OR REPLACE FUNCTION get_checklist_completion(thought_id_param UUID)
RETURNS INTEGER AS $$
DECLARE
    total INTEGER;
    completed INTEGER;
BEGIN
    SELECT COUNT(*) INTO total
    FROM checklist_items
    WHERE thought_id = thought_id_param;

    IF total = 0 THEN
        RETURN 0;
    END IF;

    SELECT COUNT(*) INTO completed
    FROM checklist_items
    WHERE thought_id = thought_id_param
    AND is_completed = true;

    RETURN (completed * 100 / total);
END;
$$ LANGUAGE plpgsql;

-- ==================== MIGRATION FOR EXISTING DATA ====================
-- If you already have data, run these ALTER statements

-- Add new columns to existing thoughts table (safe to run multiple times)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'thoughts' AND column_name = 'title') THEN
        ALTER TABLE thoughts ADD COLUMN title TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'thoughts' AND column_name = 'is_pinned') THEN
        ALTER TABLE thoughts ADD COLUMN is_pinned BOOLEAN DEFAULT false;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'thoughts' AND column_name = 'is_archived') THEN
        ALTER TABLE thoughts ADD COLUMN is_archived BOOLEAN DEFAULT false;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'thoughts' AND column_name = 'is_checklist') THEN
        ALTER TABLE thoughts ADD COLUMN is_checklist BOOLEAN DEFAULT false;
    END IF;
END $$;

-- ==================== SAMPLE QUERIES ====================
-- Uncomment to test

-- Get all active (non-archived) thoughts
-- SELECT * FROM thoughts WHERE user_id = 'demo-user-id' AND is_archived = false ORDER BY is_pinned DESC, created_at DESC;

-- Get all pinned thoughts
-- SELECT * FROM thoughts WHERE user_id = 'demo-user-id' AND is_pinned = true;

-- Get checklists with completion percentage
-- SELECT t.*, get_checklist_completion(t.id) as completion_percentage
-- FROM thoughts t WHERE t.is_checklist = true;

-- Get checklist items for a thought
-- SELECT * FROM checklist_items WHERE thought_id = 'YOUR_THOUGHT_ID' ORDER BY position;
