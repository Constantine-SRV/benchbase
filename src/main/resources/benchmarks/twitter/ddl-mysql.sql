SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;

-- Удаляем таблицы (сначала дочерние, потом родительская)
DROP TABLE IF EXISTS followers CASCADE;
DROP TABLE IF EXISTS follows CASCADE;
DROP TABLE IF EXISTS tweets CASCADE;
DROP TABLE IF EXISTS added_tweets CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Удаляем tablegroup после всех таблиц
DROP TABLEGROUP IF EXISTS twitter_group;

-- Создаём tablegroup для twitter с 18 партициями (оптимально для 6 серверов)
CREATE TABLEGROUP twitter_group
  PARTITION BY HASH
  PARTITIONS 18;

-- =========================
-- user_profiles
-- =========================
CREATE TABLE user_profiles (
    uid          INT NOT NULL,
    name         VARCHAR(255)  DEFAULT NULL,
    email        VARCHAR(255)  DEFAULT NULL,
    partitionid  INT           DEFAULT NULL,
    partitionid2 TINYINT       DEFAULT NULL,
    followers    INT           DEFAULT NULL,
    PRIMARY KEY (uid)
)
TABLEGROUP = 'twitter_group'
PARTITION BY HASH (uid) PARTITIONS 18;

CREATE INDEX idx_user_followers ON user_profiles (followers);
CREATE INDEX idx_user_partition ON user_profiles (partitionid);

-- =========================
-- followers
-- =========================
CREATE TABLE followers (
    f1 INT NOT NULL,
    f2 INT NOT NULL,
    FOREIGN KEY (f1) REFERENCES user_profiles (uid) ON DELETE CASCADE,
    FOREIGN KEY (f2) REFERENCES user_profiles (uid) ON DELETE CASCADE,
    PRIMARY KEY (f1, f2)
)
TABLEGROUP = 'twitter_group'
PARTITION BY HASH (f1) PARTITIONS 18;

-- =========================
-- follows
-- =========================
CREATE TABLE follows (
    f1 INT NOT NULL,
    f2 INT NOT NULL,
    FOREIGN KEY (f1) REFERENCES user_profiles (uid) ON DELETE CASCADE,
    FOREIGN KEY (f2) REFERENCES user_profiles (uid) ON DELETE CASCADE,
    PRIMARY KEY (f1, f2)
)
TABLEGROUP = 'twitter_group'
PARTITION BY HASH (f1) PARTITIONS 18;

-- =========================
-- tweets
-- =========================
-- ВАЖНО: PK расширен до (id, uid), чтобы колонка партиционирования входила в PK
CREATE TABLE tweets (
    id         BIGINT NOT NULL,
    uid        INT    NOT NULL,
    text       CHAR(140)  NOT NULL,
    createdate DATETIME   DEFAULT NULL,
    FOREIGN KEY (uid) REFERENCES user_profiles (uid) ON DELETE CASCADE,
    PRIMARY KEY (id, uid)
)
TABLEGROUP = 'twitter_group'
PARTITION BY HASH (uid) PARTITIONS 18;

CREATE INDEX idx_tweets_uid ON tweets (uid);

-- =========================
-- added_tweets
-- =========================
CREATE TABLE added_tweets (
    id         BIGINT NOT NULL AUTO_INCREMENT,
    uid        INT    NOT NULL,
    text       CHAR(140)  NOT NULL,
    createdate DATETIME   DEFAULT NULL,
    FOREIGN KEY (uid) REFERENCES user_profiles (uid) ON DELETE CASCADE,
    PRIMARY KEY (id, uid)
)
TABLEGROUP = 'twitter_group'
PARTITION BY HASH (uid) PARTITIONS 18;

CREATE INDEX idx_added_tweets_uid ON added_tweets (uid);

SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
