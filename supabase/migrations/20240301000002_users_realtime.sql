-- Add public.users to the supabase_realtime publication so client-side
-- streams (FeatureGate) react to tier upgrades immediately. Without this,
-- a successful checkout flips users.tier server-side but no UI screen
-- learns until the user signs out/in.
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
