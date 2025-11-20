-- Thought Recorder Database Schema
-- Run this SQL in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Categories Table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    color_hex TEXT NOT NULL,
    icon TEXT NOT NULL,
    ai_assigned BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on user_id for faster queries
CREATE INDEX idx_categories_user_id ON categories(user_id);

-- Thoughts Table
CREATE TABLE thoughts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    original_text TEXT NOT NULL,
    ai_summary TEXT,
    recording_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    tags TEXT[] DEFAULT '{}',
    has_reminder BOOLEAN DEFAULT false,
    reminder_id TEXT
);

-- Create indexes for better query performance
CREATE INDEX idx_thoughts_user_id ON thoughts(user_id);
CREATE INDEX idx_thoughts_category_id ON thoughts(category_id);
CREATE INDEX idx_thoughts_created_at ON thoughts(created_at DESC);
CREATE INDEX idx_thoughts_tags ON thoughts USING GIN(tags);

-- Full text search on thoughts
CREATE INDEX idx_thoughts_search ON thoughts USING GIN(
    to_tsvector('english', original_text || ' ' || COALESCE(ai_summary, ''))
);

-- Reminders Table
CREATE TABLE reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    thought_id UUID REFERENCES thoughts(id) ON DELETE CASCADE,
    android_reminder_id TEXT,
    reminder_time TIMESTAMP WITH TIME ZONE NOT NULL,
    title TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on thought_id
CREATE INDEX idx_reminders_thought_id ON reminders(thought_id);
CREATE INDEX idx_reminders_time ON reminders(reminder_time);

-- Storage bucket for audio recordings
-- Run this separately or in the Supabase Storage UI
INSERT INTO storage.buckets (id, name, public)
VALUES ('recordings', 'recordings', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policy for authenticated uploads
CREATE POLICY "Users can upload their own recordings"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'recordings');

CREATE POLICY "Users can view their own recordings"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'recordings');

-- Row Level Security (RLS) Policies
-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE thoughts ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

-- For demo purposes, allow all operations (you should implement proper auth)
CREATE POLICY "Allow all operations on categories"
ON categories FOR ALL
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow all operations on thoughts"
ON thoughts FOR ALL
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow all operations on reminders"
ON reminders FOR ALL
USING (true)
WITH CHECK (true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_thoughts_updated_at
    BEFORE UPDATE ON thoughts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Sample query functions (optional but helpful)

-- Function to search thoughts
CREATE OR REPLACE FUNCTION search_thoughts(
    search_query TEXT,
    user_id_param TEXT
)
RETURNS TABLE (
    id UUID,
    user_id TEXT,
    original_text TEXT,
    ai_summary TEXT,
    recording_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    category_id UUID,
    tags TEXT[],
    has_reminder BOOLEAN,
    reminder_id TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM thoughts t
    WHERE t.user_id = user_id_param
    AND (
        t.original_text ILIKE '%' || search_query || '%'
        OR t.ai_summary ILIKE '%' || search_query || '%'
        OR search_query = ANY(t.tags)
    )
    ORDER BY t.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get thoughts by category
CREATE OR REPLACE FUNCTION get_thoughts_by_category(
    category_id_param UUID,
    user_id_param TEXT
)
RETURNS TABLE (
    id UUID,
    user_id TEXT,
    original_text TEXT,
    ai_summary TEXT,
    recording_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    category_id UUID,
    tags TEXT[],
    has_reminder BOOLEAN,
    reminder_id TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM thoughts t
    WHERE t.user_id = user_id_param
    AND t.category_id = category_id_param
    ORDER BY t.created_at DESC;
END;
$$ LANGUAGE plpgsql;
