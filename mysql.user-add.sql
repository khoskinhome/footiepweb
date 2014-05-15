

CREATE USER 'ftypuser'@'localhost' IDENTIFIED BY 'changethispassword';


GRANT ALL PRIVILEGES ON ftypweb . * TO 'ftypuser'@'localhost';


FLUSH PRIVILEGES;
