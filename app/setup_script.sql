CREATE APPLICATION ROLE IF NOT EXISTS app_user;
CREATE APPLICATION ROLE IF NOT EXISTS app_admin;

CREATE SCHEMA IF NOT EXISTS core;
GRANT USAGE ON SCHEMA core TO APPLICATION ROLE app_user;

CREATE OR ALTER VERSIONED SCHEMA app_public;
GRANT USAGE ON SCHEMA app_public TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE core.grant_callback(priv array)
RETURNS STRING
LANGUAGE SQL
AS
$$ 
   CALL app_public.start_app(); 
$$;

GRANT USAGE ON PROCEDURE core.grant_callback(array) to APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE app_public.start_app()
   RETURNS string
   LANGUAGE sql
   AS
$$
BEGIN
   LET pool_name := (SELECT CURRENT_DATABASE()) || '_compute_pool';

   CREATE COMPUTE POOL IF NOT EXISTS IDENTIFIER(:pool_name)
      MIN_NODES = 1
      MAX_NODES = 1
      INSTANCE_FAMILY = CPU_X64_S
      AUTO_RESUME = true;

   CREATE SERVICE IF NOT EXISTS core.mongo_service
      IN COMPUTE POOL identifier(:pool_name)
      FROM spec='service/mongo.yaml';

   GRANT SERVICE ROLE core.mongo_service!ALL_ENDPOINTS_USAGE TO APPLICATION ROLE app_user;   

   RETURN 'Service successfully created';
END;
$$;

GRANT USAGE ON PROCEDURE app_public.start_app() TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE app_public.service_status()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS $$
   DECLARE
         service_status VARCHAR;
   BEGIN
         CALL SYSTEM$GET_SERVICE_STATUS('core.mongo_service') INTO :service_status;
         RETURN PARSE_JSON(:service_status)[0]['status']::VARCHAR;
   END;
$$;

GRANT USAGE ON PROCEDURE app_public.service_status() TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE app_public.showcontainers()
RETURNS TABLE()
LANGUAGE PYTHON
PACKAGES = ('snowflake-snowpark-python')
RUNTIME_VERSION = 3.9
HANDLER = 'main'
as
$$
def main(session):
    df= session.sql(f"""
    SHOW SERVICE CONTAINERS IN SERVICE core.mongo_service
    """)
    return df
$$;

GRANT USAGE ON PROCEDURE app_public.showcontainers() TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE app_public.service_logs(container_name varchar)
RETURNS TABLE()
LANGUAGE PYTHON
PACKAGES = ('snowflake-snowpark-python')
RUNTIME_VERSION = 3.9
HANDLER = 'main'
as
$$
def main(session, container_name):
    return session.sql(f"""
    CALL SYSTEM$GET_SERVICE_LOGS('core.mongo_service', 0, '{container_name}')
    """)
$$;
GRANT USAGE ON PROCEDURE app_public.service_logs(varchar) TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE app_public.getEndpoints()
RETURNS TABLE()
LANGUAGE PYTHON
PACKAGES = ('snowflake-snowpark-python')
RUNTIME_VERSION = 3.9
HANDLER = 'main'
as
$$
def main(session):
    return session.sql(f"""
    SHOW ENDPOINTS IN SERVICE core.mongo_service
    """)
$$;

GRANT USAGE ON PROCEDURE app_public.getEndpoints() TO APPLICATION ROLE app_user;

CREATE OR REPLACE PROCEDURE app_public.version_init()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
can_create_compute_pool BOOLEAN;
BEGIN

   SELECT SYSTEM$HOLD_PRIVILEGE_ON_ACCOUNT('CREATE COMPUTE POOL')
      INTO can_create_compute_pool;

   ALTER SERVICE IF EXISTS core.mongo_service
      FROM spec='service/mongo.yaml';
   IF (can_create_compute_pool) THEN
      SELECT SYSTEM$WAIT_FOR_SERVICES(120, 'core.mongo_service');
   END IF;
   RETURN 'DONE';
END;
$$;