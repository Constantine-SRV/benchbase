-- Drop Exisiting Tables

IF OBJECT_ID('[followers]') IS NOT NULL DROP table [dbo].[followers];
IF OBJECT_ID('[follows]') IS NOT NULL DROP table [dbo].[follows];
IF OBJECT_ID('[tweets]') IS NOT NULL DROP table [dbo].[tweets];
IF OBJECT_ID('[added_tweets]') IS NOT NULL DROP table [dbo].[added_tweets];
IF OBJECT_ID('[user_profiles]') IS NOT NULL DROP table [dbo].[user_profiles];

-- Create Tables with PAGE compression
CREATE TABLE [dbo].[user_profiles] (
  uid int NOT NULL,
  name varchar(255) DEFAULT NULL,
  email varchar(255) DEFAULT NULL,
  partitionid int DEFAULT NULL,
  partitionid2 tinyint DEFAULT NULL,
  followers int DEFAULT NULL,
  PRIMARY KEY (uid) WITH (DATA_COMPRESSION = PAGE)
) WITH (DATA_COMPRESSION = PAGE);

CREATE TABLE [dbo].[followers] (
  f1 int NOT NULL REFERENCES [user_profiles] (uid),
  f2 int NOT NULL REFERENCES [user_profiles] (uid),
  PRIMARY KEY (f1,f2) WITH (DATA_COMPRESSION = PAGE)
) WITH (DATA_COMPRESSION = PAGE);

CREATE TABLE [dbo].[follows] (
  f1 int NOT NULL REFERENCES [user_profiles] (uid),
  f2 int NOT NULL REFERENCES [user_profiles] (uid),
  PRIMARY KEY (f1,f2) WITH (DATA_COMPRESSION = PAGE)
) WITH (DATA_COMPRESSION = PAGE);

-- TODO: id AUTO_INCREMENT
CREATE TABLE [dbo].[tweets] (
  id bigint NOT NULL,
  uid int NOT NULL REFERENCES [user_profiles] (uid),
  text char(140) NOT NULL,
  createdate datetime DEFAULT NULL,
  PRIMARY KEY (id) WITH (DATA_COMPRESSION = PAGE)
) WITH (DATA_COMPRESSION = PAGE);

CREATE TABLE [dbo].[added_tweets] (
  id bigint NOT NULL identity(1,1),
  uid int NOT NULL REFERENCES [user_profiles] (uid),
  text char(140) NOT NULL,
  createdate datetime DEFAULT NULL,
  PRIMARY KEY (id) WITH (DATA_COMPRESSION = PAGE)
) WITH (DATA_COMPRESSION = PAGE);


-- Create Indexes with PAGE compression
CREATE INDEX IDX_USER_FOLLOWERS ON [dbo].[user_profiles] (followers) WITH (DATA_COMPRESSION = PAGE);
CREATE INDEX IDX_USER_PARTITION ON [dbo].[user_profiles] (partitionid) WITH (DATA_COMPRESSION = PAGE);
CREATE INDEX IDX_TWEETS_UID ON [dbo].[tweets] (uid) WITH (DATA_COMPRESSION = PAGE);
CREATE INDEX IDX_ADDED_TWEETS_UID ON [dbo].[added_tweets] (uid) WITH (DATA_COMPRESSION = PAGE);
