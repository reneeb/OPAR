INSERT INTO opr_job_type (type_label) VALUES ('analyze');
INSERT INTO opr_job_type (type_label) VALUES ('delete');
INSERT INTO opr_job_type (type_label) VALUES ('comment');

INSERT INTO opr_oq_entity (oq_label, priority, module) VALUES ('Templates Checked', 1, 'TemplateCheck' );
INSERT INTO opr_oq_entity (oq_label, priority, module) VALUES ('System Calls Used', 1, 'SystemCall' );
INSERT INTO opr_oq_entity (oq_label, priority, module) VALUES ('Follows Coding Guidelines', 1, 'PerlCritic' );
INSERT INTO opr_oq_entity (oq_label, priority, module) VALUES ('Valid XML in Config Files', 1, 'BasicXMLCheck' );
INSERT INTO opr_oq_entity (oq_label, priority, module) VALUES ('Tidy Perl', 1, 'PerlTidy' );
INSERT INTO opr_oq_entity (oq_label, priority, module) VALUES ('Has Unittests', 1, 'UnitTests' );
INSERT INTO opr_oq_entity (oq_label, priority, module) VALUES ('Has Documentation', 1, 'Documentation' );
INSERT INTO opr_oq_entity (oq_label, priority, module) VALUES ('Lists All Dependencies', 1, 'Dependencies' );
INSERT INTO opr_oq_entity (oq_label, priority, module) VALUES ('Use Open Source License', 1, 'License' );

INSERT INTO opr_group (group_id, group_name) VALUES (1, 'admin');
INSERT INTO opr_group (group_id, group_name) VALUES (2, 'author');

INSERT INTO opr_user (user_id, user_name, user_password, mail) VALUES (1, 'reneeb', '', 'opar@perl-services.de');

INSERT INTO opr_group_user (group_id, user_id) VALUES (1,1);
INSERT INTO opr_group_user (group_id, user_id) VALUES (2,1);