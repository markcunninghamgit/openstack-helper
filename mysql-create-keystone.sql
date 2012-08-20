CREATE DATABASE keystone;
GRANT ALL ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'keystone-password';
flush privileges;
delete from mysql.user where host = 'localhost' and user = '';
