// seeded on first boot by the mongo container's initdb hook
db = db.getSiblingDB('intranet');
db.users.insert([
  { user: 'jsmith',  password: 'password123', role: 'dev' },
  { user: 'agarcia', password: '123456',      role: 'support' },
  { user: 'backup',  password: 'letmein',     role: 'service' }
]);
db.config.insert([
  { key: 'wp_db_password', value: 'wordpress', note: 'app01 wordpress mysql' },
  { key: 'tomcat_manager', value: 'admin123',  note: 'app01 tomcat /manager' }
]);
