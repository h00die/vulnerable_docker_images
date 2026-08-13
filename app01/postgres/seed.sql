-- seeded on first boot by the postgres container's initdb hook
CREATE TABLE payroll (
  id     serial primary key,
  name   text,
  role   text,
  salary integer
);
INSERT INTO payroll (name, role, salary) VALUES
  ('J Smith',  'developer', 71000),
  ('A Garcia', 'support',   64000);

CREATE TABLE service_accounts (
  username text,
  password text,
  note     text
);
INSERT INTO service_accounts VALUES
  ('svc-backup',    'Backup2024!', 'files01 LDAP service account'),
  ('tomcat-deploy', 'admin123',    'app01 tomcat manager deploy user'),
  ('wp_admin',      'Summer2026!', 'web01 wordpress admin');
