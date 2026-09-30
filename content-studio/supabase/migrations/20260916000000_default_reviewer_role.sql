-- Make new signups default to reviewer role
ALTER TABLE public.profiles ALTER COLUMN role SET DEFAULT 'reviewer';

-- Update the trigger to explicitly set reviewer
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
begin
  insert into public.profiles (id, display_name, role)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', new.email), 'reviewer');
  return new;
end;
$$;

-- Promote all existing uploaders to reviewer
UPDATE public.profiles SET role = 'reviewer' WHERE role = 'uploader';
