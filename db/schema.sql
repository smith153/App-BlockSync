
CREATE TABLE file (
    ufn         VARCHAR(64) NOT NULL,
    uhn         VARCHAR(64) NOT NULL,
    hostname    VARCHAR(255) NOT NULL,
    path        TEXT NOT NULL,
    filename    TEXT NOT NULL,
    crcsum      VARCHAR(64) NOT NULL,
    block_size  INTEGER NOT NULL
);

ALTER TABLE file ADD CONSTRAINT file_pkey PRIMARY KEY (ufn);

CREATE TABLE file_block (
    file    VARCHAR(64) NOT NULL,
    id      INTEGER NOT NULL,
    crcsum  VARCHAR(64)
);

ALTER TABLE file_block ADD CONSTRAINT file_block_pkey PRIMARY KEY (file);
ALTER TABLE file_block ADD CONSTRAINT file_block_fk FOREIGN KEY
    (file) REFERENCES file (ufn) ON DELETE CASCADE ON UPDATE CASCADE;


