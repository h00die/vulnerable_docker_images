#!/bin/bash
# Start ES, seed it once with fake-but-useful loot, then keep it foreground.
/opt/elasticsearch/bin/elasticsearch &
pid=$!

for i in $(seq 1 90); do
  curl -sf http://127.0.0.1:9200 >/dev/null 2>&1 && break
  sleep 1
done

if ! curl -sf http://127.0.0.1:9200/intranet >/dev/null 2>&1; then
  curl -s -XPUT http://127.0.0.1:9200/intranet/users/1 \
    -d '{"user":"jsmith","password":"password123","role":"dev"}' >/dev/null
  curl -s -XPUT http://127.0.0.1:9200/intranet/users/2 \
    -d '{"user":"agarcia","password":"123456","role":"support"}' >/dev/null
  curl -s -XPUT http://127.0.0.1:9200/intranet/users/3 \
    -d '{"user":"backup","password":"letmein","role":"service"}' >/dev/null
  curl -s -XPUT http://127.0.0.1:9200/intranet/config/1 \
    -d '{"key":"wp_db_password","value":"wordpress","note":"app01 wordpress"}' >/dev/null
fi

wait $pid
