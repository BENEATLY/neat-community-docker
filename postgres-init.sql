-- Author:     Thomas D'haenens
-- License:    GPL-3.0
-- Link:       https://github.com/BENEATLY/neat-community-docker/
-- Contact:    https://neatly.be/

ALTER USER postgres WITH PASSWORD 'neat';
CREATE USER neat WITH PASSWORD 'neat';
CREATE DATABASE neat;
CREATE DATABASE neatdb;
GRANT ALL PRIVILEGES ON DATABASE neatdb TO neat;
ALTER USER neat CREATEDB;
ALTER DATABASE neatdb OWNER TO neat;
ALTER ROLE neat SUPERUSER;
