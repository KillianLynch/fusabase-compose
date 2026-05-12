#!/bin/bash

MARKER="/opt/oracle/ords/.baas_installed"
BAAS_ALLOWED_ORIGINS="https://localhost:3000 https://localhost:8000 http://localhost:3000 http://localhost:8000"

install_baas_allowed_origins_guard() {
  echo "Installing Fusabase authorized origins guard."

  sql -s "sys/$ORACLE_PWD@localhost:1521/freepdb1 as sysdba" <<SQL
WHENEVER SQLERROR EXIT SQL.SQLCODE
CREATE OR REPLACE TRIGGER ords_metadata.baas_allowed_origins_biu
  BEFORE INSERT OR UPDATE OF value ON ords_metadata.ords_prop_values
  FOR EACH ROW
DECLARE
  l_key    ords_metadata.ords_prop_facts.key%TYPE;
  l_schema ords_metadata.ords_schemas.parsing_schema%TYPE;

  PROCEDURE append_origin(p_origin IN varchar2) IS
  BEGIN
    IF instr(' ' || nvl(:new.value, '') || ' ', ' ' || p_origin || ' ') = 0 THEN
      :new.value := trim(nvl(:new.value, '') || ' ' || p_origin);
    END IF;
  END;
BEGIN
  SELECT pf.key, s.parsing_schema
    INTO l_key, l_schema
    FROM ords_metadata.ords_prop_facts pf
    JOIN ords_metadata.ords_schemas s ON s.id = :new.schema_id
   WHERE pf.id = :new.prop_fact_id;

  IF l_key = 'dynamic.allowed.origins.baas' AND l_schema = 'TESTUSER' THEN
    append_origin('https://localhost:3000');
    append_origin('https://localhost:8000');
    append_origin('http://localhost:3000');
    append_origin('http://localhost:8000');
  END IF;
EXCEPTION
  WHEN no_data_found THEN
    NULL;
END;
/
SQL
}

configure_baas_allowed_origins() {
  echo "Configuring Fusabase authorized origins: $BAAS_ALLOWED_ORIGINS"

  sql -s fusabase_dba/baas@localhost:1521/freepdb1 <<SQL
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  l_key     CONSTANT varchar2(128) := 'dynamic.allowed.origins.baas';
  l_value   varchar2(4000);
  l_origins sys.odcivarchar2list := sys.odcivarchar2list(
    'https://localhost:3000',
    'https://localhost:8000',
    'http://localhost:3000',
    'http://localhost:8000'
  );
BEGIN
  BEGIN
    SELECT pv.value
      INTO l_value
      FROM ords_metadata.ords_prop_values pv
      JOIN ords_metadata.ords_prop_facts pf ON pf.id = pv.prop_fact_id
      JOIN ords_metadata.ords_schemas s ON s.id = pv.schema_id
     WHERE s.parsing_schema = 'TESTUSER'
       AND pf.key = l_key;
  EXCEPTION
    WHEN no_data_found THEN
      l_value := NULL;
  END;

  FOR i IN 1 .. l_origins.count LOOP
    IF instr(' ' || l_value || ' ', ' ' || l_origins(i) || ' ') = 0 THEN
      l_value := trim(l_value || ' ' || l_origins(i));
    END IF;
  END LOOP;

  ORDS_ADMIN.SET_PROPERTY(
    p_schema => 'TESTUSER',
    p_key    => l_key,
    p_value  => l_value
  );
END;
/
COMMIT;
SQL
}

if [ -f "$MARKER" ]; then
  if ! install_baas_allowed_origins_guard; then
    echo "Failed to install Fusabase authorized origins guard."
    exit 1
  fi
  if ! configure_baas_allowed_origins; then
    echo "Failed to configure Fusabase authorized origins."
    exit 1
  fi
  echo "Oracle Backend for Firebase (Fusabase) already installed, skipping."
  exit 0
fi

echo "Installing Oracle Backend for Firebase (Fusabase)..."

printf '1\n2\nS\nWelcome12345\nA\nSYS AS SYSDBA\n%s\n' "$ORACLE_PWD" | \
  /opt/oracle/ords/bin/ords fusabase install

if [ $? -ne 0 ]; then
  echo "Oracle Backend for Firebase (Fusabase) installation failed."
  exit 1
fi

echo "Granting baas_dba role to fusabase_dba..."

echo "GRANT baas_dba, dba TO fusabase_dba;" | sql -s "sys/$ORACLE_PWD@localhost:1521/freepdb1 as sysdba"

if [ $? -ne 0 ]; then
  echo "Failed to grant baas_dba role."
  exit 1
fi

echo "Enabling TESTUSER for Oracle Backend for Firebase (Fusabase)..."

echo "BEGIN
  OBAAS_ADMIN.OBAAS_ENABLE_SCHEMA('TESTUSER', 'BASE_PATH', 'testuser', FALSE);
END;
/
COMMIT;" | sql -s fusabase_dba/baas@localhost:1521/freepdb1

if [ $? -eq 0 ]; then
  if ! install_baas_allowed_origins_guard; then
    echo "Failed to install Fusabase authorized origins guard."
    exit 1
  fi
  if ! configure_baas_allowed_origins; then
    echo "Failed to configure Fusabase authorized origins."
    exit 1
  fi
  touch "$MARKER"
  echo "Oracle Backend for Firebase (Fusabase) setup complete."
else
  echo "Failed to enable TESTUSER for Oracle Backend for Firebase (Fusabase)."
  exit 1
fi
