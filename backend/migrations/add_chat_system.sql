-- ============================================================================
-- BorrowCircle - chat system migration
-- Adds:
--   1. a guarded `role` column on users (user / admin)
--   2. a `conversations` table (loan chats, item chats and admin chats)
--   3. a `messages` table
--   4. a trigger that keeps conversations.updated_at fresh
-- Every statement is idempotent: running this file twice is a no-op.
-- ============================================================================

-- 1. users.role -------------------------------------------------------------
-- If the column already exists (e.g. added by hand) ADD COLUMN IF NOT EXISTS
-- silently skips it, so this stays safe on databases that already have roles.
ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) NOT NULL DEFAULT 'user';

-- Defensive: keep the role value constrained (only added when missing).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'users_role_check'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_role_check
            CHECK (role IN ('user', 'admin'));
    END IF;
END $$;

UPDATE users SET role = 'user' WHERE role IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- 2. conversations -----------------------------------------------------------
-- scope is exactly one of:
--   loan_id  -> lender <-> borrower chat for one loan
--   item_id  -> enquiry chat about one item (before any loan exists)
--   both NULL-> admin / support chat (regular user <-> an admin)
CREATE TABLE IF NOT EXISTS conversations (
    id SERIAL PRIMARY KEY,
    loan_id INTEGER REFERENCES loans(id) ON DELETE SET NULL,
    item_id INTEGER REFERENCES items(id) ON DELETE SET NULL,
    participant1_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    participant2_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT conversations_participants_distinct
        CHECK (participant1_id <> participant2_id),
    CONSTRAINT conversations_scope_check CHECK (
        (loan_id IS NOT NULL AND item_id IS NULL) OR
        (loan_id IS NULL AND item_id IS NOT NULL) OR
        (loan_id IS NULL AND item_id IS NULL)
    )
);

-- Partial unique indexes: a plain UNIQUE(loan_id, participant1_id, participant2_id)
-- would NOT stop duplicates because NULL never equals NULL in PostgreSQL.
-- These only apply inside their own scope, so one pair can never produce
-- two conversations for the same loan / item / admin thread.
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_loan_unique
    ON conversations (loan_id, participant1_id, participant2_id)
    WHERE loan_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_item_unique
    ON conversations (item_id, participant1_id, participant2_id)
    WHERE item_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_admin_unique
    ON conversations (participant1_id, participant2_id)
    WHERE loan_id IS NULL AND item_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_conversations_loan ON conversations(loan_id);
CREATE INDEX IF NOT EXISTS idx_conversations_item ON conversations(item_id);
CREATE INDEX IF NOT EXISTS idx_conversations_participants
    ON conversations(participant1_id, participant2_id);

-- 3. messages ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    text TEXT NOT NULL CHECK (char_length(text) BETWEEN 1 AND 5000),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chat lists read newest-first inside one conversation; the partial index
-- keeps the "unread badge" queries cheap.
CREATE INDEX IF NOT EXISTS idx_messages_conversation
    ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_unread
    ON messages(conversation_id) WHERE is_read = FALSE;

-- 4. keep conversations.updated_at in sync ----------------------------------
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_conversation ON conversations;
CREATE TRIGGER trigger_update_conversation
    BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION update_conversation_timestamp();