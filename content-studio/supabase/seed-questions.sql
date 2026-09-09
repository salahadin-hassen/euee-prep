-- Run this in your Supabase SQL Editor to seed test questions.
-- Replace the project_id with an actual project UUID from your database.

-- Find a project to use:
-- SELECT id, title FROM projects LIMIT 5;

-- Then uncomment and set the project_id below:
/*
DO $$
DECLARE
  proj_id uuid := 'PASTE-YOUR-PROJECT-ID-HERE';
BEGIN
  INSERT INTO questions (project_id, order_index, question_text, choices, correct_answer, explanation, status)
  VALUES
    (proj_id, 0, 'What is the capital of Ghana?', '["Accra","Kumasi","Tamale","Cape Coast"]', 'Accra', 'Accra is the capital and largest city of Ghana.', 'unverified'),
    (proj_id, 1, 'Which river is the longest in West Africa?', '["Niger","Volta","Senegal","Comoé"]', 'Niger', 'The Niger River is approximately 4,180 km long, making it the longest in West Africa.', 'unverified'),
    (proj_id, 2, 'What is 7 × 8?', '["54","56","58","64"]', '56', '7 × 8 = 56.', 'unverified'),
    (proj_id, 3, 'Which mineral is Ghana the largest producer of in Africa?', '["Gold","Diamonds","Bauxite","Manganese"]', 'Gold', ' Ghana is Africa''s largest gold producer and among the top 10 globally.', 'unverified'),
    (proj_id, 4, 'What is the boiling point of water at sea level?', '["90°C","95°C","100°C","110°C"]', '100°C', 'Water boils at 100°C (212°F) at standard atmospheric pressure.', 'unverified');
END
$$;
*/
