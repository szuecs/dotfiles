COPY myTab TO 'a_file.sql' WITH DELIMITER ';';
COPY myTable FROM 'a_file.sql' WITH DELIMITER ';' 
SELECT foo FROM TableName WHERE foo!='3';

UPDATE atable SET acol = 'val1' WHERE foo != 'bar';
DELETE FROM tab WHERE foo <> 'bar';
INSERT INTO atab (col1) VALUES (3) ;
