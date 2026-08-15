-- 残保金测算记录表：CloudBase PostgreSQL 安全配置
-- 前端只使用匿名登录 JWT；严禁把 service_role API Key 放入网页。

CREATE TABLE IF NOT EXISTS public.calculation_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  user_id varchar(64) NOT NULL
    DEFAULT (current_setting('request.jwt.claims', true)::json->>'sub'),
  schema_version smallint NOT NULL DEFAULT 1,
  company_name varchar(80),
  contact varchar(80),
  inputs jsonb NOT NULL DEFAULT '{}'::jsonb,
  results jsonb NOT NULL DEFAULT '{}'::jsonb,
  policy_status varchar(120),
  reference_only boolean NOT NULL DEFAULT false,
  compliance_confirmed_count smallint NOT NULL DEFAULT 0,
  consent_version varchar(40) NOT NULL DEFAULT '2026-08-15-v1',
  source varchar(40) NOT NULL DEFAULT 'cloudbase_site',
  page_path text
);

CREATE INDEX IF NOT EXISTS idx_calculation_records_user_id
  ON public.calculation_records(user_id);
CREATE INDEX IF NOT EXISTS idx_calculation_records_created_at
  ON public.calculation_records(created_at DESC);

ALTER TABLE public.calculation_records ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.calculation_records FROM PUBLIC;
REVOKE ALL ON public.calculation_records FROM anon, authenticated;
GRANT SELECT, INSERT ON public.calculation_records TO anon, authenticated;
GRANT ALL ON public.calculation_records TO service_role;

DROP POLICY IF EXISTS calculation_records_select_own ON public.calculation_records;
DROP POLICY IF EXISTS calculation_records_insert_own ON public.calculation_records;

CREATE POLICY calculation_records_select_own
  ON public.calculation_records
  FOR SELECT TO anon, authenticated
  USING (
    user_id = (current_setting('request.jwt.claims', true)::json->>'sub')
  );

CREATE POLICY calculation_records_insert_own
  ON public.calculation_records
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    user_id = (current_setting('request.jwt.claims', true)::json->>'sub')
  );
