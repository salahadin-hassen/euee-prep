-- Enable pgcrypto for digest() used by import_manual_questions.
-- Idempotent: safe to apply regardless of current state.

create extension if not exists pgcrypto;
