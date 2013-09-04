DROP TABLE IF EXISTS `opr_user`;

CREATE TABLE `opr_user` (
  user_id INTEGER NOT NULL AUTO_INCREMENT,
  user_name VARCHAR(255) NOT NULL,
  user_password VARCHAR(255) NOT NULL,
  session_id VARCHAR(255) ,
  website VARCHAR(255) ,
  mail VARCHAR(255) NOT NULL,
  active TINYINT ,
  registered INTEGER ,
  realname VARCHAR(255),
  PRIMARY KEY(user_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_package`;

CREATE TABLE `opr_package` (
  package_id INTEGER NOT NULL AUTO_INCREMENT,
  name_id INTEGER NOT NULL,
  uploaded_by INTEGER NOT NULL,
  description TEXT ,
  version VARCHAR(255) ,
  framework VARCHAR(255) ,
  path VARCHAR(255) NOT NULL,
  is_in_index TINYINT ,
  website VARCHAR(255) ,
  bugtracker VARCHAR(255) ,
  upload_time INTEGER ,
  virtual_path VARCHAR(255) ,
  deletion_flag BIGINT ,
  documentation TEXT,
  PRIMARY KEY(package_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_package_author`;

CREATE TABLE `opr_package_author` (
  user_id INTEGER NOT NULL,
  name_id INTEGER NOT NULL,
  is_main_author TINYINT NOT NULL,
  PRIMARY KEY(user_id,name_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_package_dependencies`;

CREATE TABLE `opr_package_dependencies` (
  dependency_id INTEGER NOT NULL AUTO_INCREMENT,
  package_id INTEGER NOT NULL,
  dependency VARCHAR(255) NOT NULL,
  dependency_type ENUM('otrs','cpan') NOT NULL,
  dependency_version VARCHAR(255),
  PRIMARY KEY(dependency_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_oq_result`;

CREATE TABLE `opr_oq_result` (
  result_id INTEGER NOT NULL AUTO_INCREMENT,
  oq_id INTEGER NOT NULL,
  package_id INTEGER NOT NULL,
  oq_result TEXT ,
  filename VARCHAR(255),
  PRIMARY KEY(result_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_oq_entity`;

CREATE TABLE `opr_oq_entity` (
  oq_id INTEGER NOT NULL AUTO_INCREMENT,
  oq_label VARCHAR(255) NOT NULL,
  priority INTEGER NOT NULL,
  module VARCHAR(255) NOT NULL,
  PRIMARY KEY(oq_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_comments`;

CREATE TABLE `opr_comments` (
  comment_id INTEGER NOT NULL AUTO_INCREMENT,
  username VARCHAR(255) NOT NULL,
  packagename VARCHAR(255) NOT NULL,
  packageversion VARCHAR(255) NOT NULL,
  comments TEXT NOT NULL,
  rating INTEGER ,
  deletion_flag BIGINT ,
  headline VARCHAR(255) ,
  published BIGINT,
  PRIMARY KEY(comment_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_group`;

CREATE TABLE `opr_group` (
  group_id INTEGER NOT NULL AUTO_INCREMENT,
  group_name VARCHAR(255),
  PRIMARY KEY(group_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_group_user`;

CREATE TABLE `opr_group_user` (
  group_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  PRIMARY KEY(group_id,user_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `Session`;

CREATE TABLE `Session` (
  SessionID VARCHAR(255) NOT NULL,
  Start INTEGER ,
  Expire INTEGER,
  PRIMARY KEY(SessionID)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_job_queue`;

CREATE TABLE `opr_job_queue` (
  job_id INTEGER NOT NULL AUTO_INCREMENT,
  type_id INTEGER NOT NULL,
  package_id INTEGER ,
  created BIGINT ,
  job_state VARCHAR(255) ,
  changed BIGINT,
  PRIMARY KEY(job_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_job_type`;

CREATE TABLE `opr_job_type` (
  type_id INTEGER NOT NULL AUTO_INCREMENT,
  type_label VARCHAR(255),
  PRIMARY KEY(type_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_package_names`;

CREATE TABLE `opr_package_names` (
  name_id INTEGER NOT NULL AUTO_INCREMENT,
  package_name VARCHAR(255),
  PRIMARY KEY(name_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_formid`;

CREATE TABLE `opr_formid` (
  formid VARCHAR(255) NOT NULL,
  used TINYINT ,
  expire BIGINT,
  PRIMARY KEY(formid)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_temp_passwd`;

CREATE TABLE `opr_temp_passwd` (
  id INTEGER NOT NULL AUTO_INCREMENT,
  user_id INTEGER NOT NULL,
  token VARCHAR(255) ,
  created INTEGER,
  PRIMARY KEY(id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_feeds`;

CREATE TABLE `opr_feeds` (
  feed_id VARCHAR(255) NOT NULL,
  feed_config TEXT NOT NULL,
  PRIMARY KEY(feed_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_tags`;

CREATE TABLE `opr_tags` (
  tag_id INTEGER NOT NULL AUTO_INCREMENT,
  tag_name VARCHAR(255),
  PRIMARY KEY(tag_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_package_tags`;

CREATE TABLE `opr_package_tags` (
  name_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  PRIMARY KEY(name_id,tag_id)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_framework_versions`;

CREATE TABLE `opr_framework_versions` (
  framework VARCHAR(8) NOT NULL PRIMARY KEY
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_repo`;

CREATE TABLE `opr_repo` (
  repo_id VARCHAR(100) NOT NULL PRIMARY KEY,
  framework VARCHAR(8),
  email VARCHAR(255),
  index_file TEXT
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `opr_repo_package`;

CREATE TABLE `opr_repo_package` (
  repo_id VARCHAR(100) NOT NULL,
  name_id INTEGER NOT NULL,
  PRIMARY KEY( repo_id, name_id )
)ENGINE=InnoDB DEFAULT CHARSET=utf8;


