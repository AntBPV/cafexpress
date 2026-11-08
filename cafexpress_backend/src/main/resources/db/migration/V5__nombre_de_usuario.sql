ALTER TABLE usuarios ADD COLUMN username VARCHAR(30);
CREATE UNIQUE INDEX uq_usuarios_username ON usuarios (username) WHERE username IS NOT NULL;
