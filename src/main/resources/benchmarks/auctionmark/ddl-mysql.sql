
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS item_attribute CASCADE;
DROP TABLE IF EXISTS item_image CASCADE;
DROP TABLE IF EXISTS item_comment CASCADE;
DROP TABLE IF EXISTS item_max_bid CASCADE;
DROP TABLE IF EXISTS useracct_item CASCADE;
DROP TABLE IF EXISTS item_purchase CASCADE;
DROP TABLE IF EXISTS item_bid CASCADE;
DROP TABLE IF EXISTS global_attribute_value CASCADE;
DROP TABLE IF EXISTS global_attribute_group CASCADE;
DROP TABLE IF EXISTS config_profile CASCADE;
DROP TABLE IF EXISTS useracct_feedback CASCADE;
DROP TABLE IF EXISTS useracct_watch CASCADE;
DROP TABLE IF EXISTS item CASCADE;
DROP TABLE IF EXISTS useracct_attributes CASCADE;
DROP TABLE IF EXISTS useracct CASCADE;
DROP TABLE IF EXISTS region CASCADE;
DROP TABLE IF EXISTS category CASCADE;

DROP TABLEGROUP IF EXISTS auctionmark_group;

-- ================================================================
-- TABLEGROUP с HASH партиционированием
-- ================================================================
CREATE TABLEGROUP auctionmark_group
  PARTITION BY HASH
  PARTITIONS 18;

-- ================================================================
-- CONFIG_PROFILE
-- ================================================================
CREATE TABLE config_profile (
  cfp_scale_factor        float NOT NULL,
  cfp_loader_start        timestamp DEFAULT CURRENT_TIMESTAMP,
  cfp_loader_stop         timestamp DEFAULT CURRENT_TIMESTAMP,
  cfp_user_item_histogram text NOT NULL
);

-- ================================================================
-- REGION (дублируем на все ноды)
-- ================================================================
CREATE TABLE region (
  r_id   bigint NOT NULL,
  r_name varchar(32),
  PRIMARY KEY (r_id)
) DUPLICATE_SCOPE='cluster';

-- ================================================================
-- USERACCT
-- ================================================================
CREATE TABLE useracct (
  u_id      varchar(128) NOT NULL,
  u_rating  bigint NOT NULL,
  u_balance float NOT NULL,
  u_comments integer DEFAULT 0,
  u_r_id    bigint NOT NULL,
  u_created timestamp DEFAULT CURRENT_TIMESTAMP,
  u_updated timestamp DEFAULT CURRENT_TIMESTAMP,
  u_sattr0  varchar(64),
  u_sattr1  varchar(64),
  u_sattr2  varchar(64),
  u_sattr3  varchar(64),
  u_sattr4  varchar(64),
  u_sattr5  varchar(64),
  u_sattr6  varchar(64),
  u_sattr7  varchar(64),
  u_iattr0  bigint DEFAULT NULL,
  u_iattr1  bigint DEFAULT NULL,
  u_iattr2  bigint DEFAULT NULL,
  u_iattr3  bigint DEFAULT NULL,
  u_iattr4  bigint DEFAULT NULL,
  u_iattr5  bigint DEFAULT NULL,
  u_iattr6  bigint DEFAULT NULL,
  u_iattr7  bigint DEFAULT NULL,
  FOREIGN KEY (u_r_id) REFERENCES region (r_id) ON DELETE CASCADE,
  PRIMARY KEY (u_id)
);

CREATE INDEX idx_useracct_region ON useracct (u_id, u_r_id);

-- ================================================================
-- USERACCT_ATTRIBUTES
-- ================================================================
CREATE TABLE useracct_attributes (
  ua_id    bigint NOT NULL,
  ua_u_id  varchar(128) NOT NULL,
  ua_name  varchar(32) NOT NULL,
  ua_value varchar(32) NOT NULL,
  u_created timestamp,
  FOREIGN KEY (ua_u_id) REFERENCES useracct (u_id) ON DELETE CASCADE,
  PRIMARY KEY (ua_id, ua_u_id)
);

-- ================================================================
-- CATEGORY (дублируем)
-- ================================================================
CREATE TABLE category (
  c_id        bigint NOT NULL,
  c_name      varchar(50),
  c_parent_id bigint,
  PRIMARY KEY (c_id),
  FOREIGN KEY (c_parent_id) REFERENCES category (c_id) ON DELETE CASCADE
) DUPLICATE_SCOPE='cluster';

CREATE INDEX idx_category_parent ON category (c_parent_id);

-- ================================================================
-- GLOBAL_ATTRIBUTE_GROUP (дублируем)
-- ================================================================
CREATE TABLE global_attribute_group (
  gag_id   varchar(128) NOT NULL,
  gag_c_id bigint NOT NULL,
  gag_name varchar(100) NOT NULL,
  FOREIGN KEY (gag_c_id) REFERENCES category (c_id) ON DELETE CASCADE,
  PRIMARY KEY (gag_id)
) DUPLICATE_SCOPE='cluster';

-- ================================================================
-- GLOBAL_ATTRIBUTE_VALUE (дублируем)
-- ================================================================
CREATE TABLE global_attribute_value (
  gav_id     varchar(128) NOT NULL,
  gav_gag_id varchar(128) NOT NULL,
  gav_name   varchar(100) NOT NULL,
  FOREIGN KEY (gav_gag_id) REFERENCES global_attribute_group (gag_id) ON DELETE CASCADE,
  PRIMARY KEY (gav_id, gav_gag_id)
) DUPLICATE_SCOPE='cluster';

-- ================================================================
-- ITEM - С ВЫЧИСЛЯЕМЫМ ХЕШЕМ
-- ================================================================
CREATE TABLE item (
  i_id              varchar(128) NOT NULL,
  i_u_id            varchar(128) NOT NULL,
  -- НОВОЕ: вычисляемый хеш для партиционирования
  i_id_hash         bigint AS (CRC32(i_id)) STORED,
  i_c_id            bigint NOT NULL,
  i_name            varchar(100),
  i_description     varchar(1024),
  i_user_attributes varchar(255) DEFAULT NULL,
  i_initial_price   float NOT NULL,
  i_current_price   float NOT NULL,
  i_num_bids        bigint,
  i_num_images      bigint,
  i_num_global_attrs bigint,
  i_num_comments    bigint,
  i_start_date      timestamp DEFAULT '1970-01-01 00:00:01',
  i_end_date        timestamp DEFAULT '1970-01-01 00:00:01',
  i_status          int DEFAULT 0,
  i_created         timestamp DEFAULT CURRENT_TIMESTAMP,
  i_updated         timestamp DEFAULT CURRENT_TIMESTAMP,
  i_iattr0          bigint DEFAULT NULL,
  i_iattr1          bigint DEFAULT NULL,
  i_iattr2          bigint DEFAULT NULL,
  i_iattr3          bigint DEFAULT NULL,
  i_iattr4          bigint DEFAULT NULL,
  i_iattr5          bigint DEFAULT NULL,
  i_iattr6          bigint DEFAULT NULL,
  i_iattr7          bigint DEFAULT NULL,
  FOREIGN KEY (i_u_id) REFERENCES useracct (u_id) ON DELETE CASCADE,
  FOREIGN KEY (i_c_id) REFERENCES category (c_id) ON DELETE CASCADE,
  PRIMARY KEY (i_id, i_u_id)
) TABLEGROUP='auctionmark_group'
  PARTITION BY HASH(i_id_hash)
  PARTITIONS 18;

CREATE INDEX idx_item_seller ON item (i_u_id);
CREATE INDEX idx_item_hash ON item (i_id_hash);

-- ================================================================
-- ITEM_ATTRIBUTE - с хешем
-- ================================================================
CREATE TABLE item_attribute (
  ia_id    varchar(128) NOT NULL,
  ia_i_id  varchar(128) NOT NULL,
  ia_u_id  varchar(128) NOT NULL,
  -- НОВОЕ: вычисляемый хеш
  ia_i_id_hash bigint AS (CRC32(ia_i_id)) STORED,
  ia_gav_id varchar(128) NOT NULL,
  ia_gag_id varchar(128) NOT NULL,
  ia_sattr0 varchar(64) DEFAULT NULL,
  FOREIGN KEY (ia_i_id, ia_u_id) REFERENCES item (i_id, i_u_id) ON DELETE CASCADE,
  FOREIGN KEY (ia_gav_id, ia_gag_id) REFERENCES global_attribute_value (gav_id, gav_gag_id),
  PRIMARY KEY (ia_i_id, ia_u_id, ia_id)
) TABLEGROUP='auctionmark_group'
  PARTITION BY HASH(ia_i_id_hash)
  PARTITIONS 18;

-- ================================================================
-- ITEM_IMAGE - с хешем
-- ================================================================
CREATE TABLE item_image (
  ii_id    varchar(128) NOT NULL,
  ii_i_id  varchar(128) NOT NULL,
  ii_u_id  varchar(128) NOT NULL,
  -- НОВОЕ: вычисляемый хеш
  ii_i_id_hash bigint AS (CRC32(ii_i_id)) STORED,
  ii_sattr0 varchar(128) NOT NULL,
  FOREIGN KEY (ii_i_id, ii_u_id) REFERENCES item (i_id, i_u_id) ON DELETE CASCADE,
  PRIMARY KEY (ii_i_id, ii_u_id, ii_id)
) TABLEGROUP='auctionmark_group'
  PARTITION BY HASH(ii_i_id_hash)
  PARTITIONS 18;

-- ================================================================
-- ITEM_COMMENT - с хешем
-- ================================================================
CREATE TABLE item_comment (
  ic_id       bigint NOT NULL,
  ic_i_id     varchar(128) NOT NULL,
  ic_u_id     varchar(128) NOT NULL,
  -- НОВОЕ: вычисляемый хеш
  ic_i_id_hash bigint AS (CRC32(ic_i_id)) STORED,
  ic_buyer_id varchar(128) NOT NULL,
  ic_question varchar(128) NOT NULL,
  ic_response varchar(128) DEFAULT NULL,
  ic_created  timestamp DEFAULT CURRENT_TIMESTAMP,
  ic_updated  timestamp DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ic_i_id, ic_u_id) REFERENCES item (i_id, i_u_id) ON DELETE CASCADE,
  FOREIGN KEY (ic_buyer_id) REFERENCES useracct (u_id) ON DELETE CASCADE,
  PRIMARY KEY (ic_i_id, ic_u_id, ic_id)
) TABLEGROUP='auctionmark_group'
  PARTITION BY HASH(ic_i_id_hash)
  PARTITIONS 18;

-- ================================================================
-- ITEM_BID - с хешем
-- ================================================================
CREATE TABLE item_bid (
  ib_id       bigint NOT NULL,
  ib_i_id     varchar(128) NOT NULL,
  ib_u_id     varchar(128) NOT NULL,
  -- НОВОЕ: вычисляемый хеш
  ib_i_id_hash bigint AS (CRC32(ib_i_id)) STORED,
  ib_buyer_id varchar(128) NOT NULL,
  ib_bid      float NOT NULL,
  ib_max_bid  float NOT NULL,
  ib_created  timestamp DEFAULT CURRENT_TIMESTAMP,
  ib_updated  timestamp DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ib_i_id, ib_u_id) REFERENCES item (i_id, i_u_id) ON DELETE CASCADE,
  FOREIGN KEY (ib_buyer_id) REFERENCES useracct (u_id) ON DELETE CASCADE,
  PRIMARY KEY (ib_i_id, ib_u_id, ib_id),
  UNIQUE KEY uk_item_bid_by_id (ib_id, ib_i_id, ib_u_id)
) TABLEGROUP='auctionmark_group'
  PARTITION BY HASH(ib_i_id_hash)
  PARTITIONS 18;

-- ================================================================
-- ITEM_MAX_BID - с хешем
-- ================================================================
CREATE TABLE item_max_bid (
  imb_i_id    varchar(128) NOT NULL,
  imb_u_id    varchar(128) NOT NULL,
  -- НОВОЕ: вычисляемый хеш
  imb_i_id_hash bigint AS (CRC32(imb_i_id)) STORED,
  imb_ib_id   bigint NOT NULL,
  imb_ib_i_id varchar(128) NOT NULL,
  imb_ib_u_id varchar(128) NOT NULL,
  imb_created timestamp DEFAULT CURRENT_TIMESTAMP,
  imb_updated timestamp DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (imb_i_id, imb_u_id) REFERENCES item (i_id, i_u_id) ON DELETE CASCADE,
  FOREIGN KEY (imb_ib_id, imb_ib_i_id, imb_ib_u_id)
    REFERENCES item_bid (ib_id, ib_i_id, ib_u_id) ON DELETE CASCADE,
  PRIMARY KEY (imb_i_id, imb_u_id)
) TABLEGROUP='auctionmark_group'
  PARTITION BY HASH(imb_i_id_hash)
  PARTITIONS 18;

-- ================================================================
-- ITEM_PURCHASE - с хешем
-- ================================================================
CREATE TABLE item_purchase (
  ip_id        bigint NOT NULL,
  ip_ib_id     bigint NOT NULL,
  ip_ib_i_id   varchar(128) NOT NULL,
  ip_ib_u_id   varchar(128) NOT NULL,
  -- НОВОЕ: вычисляемый хеш
  ip_ib_i_id_hash bigint AS (CRC32(ip_ib_i_id)) STORED,
  ip_date      timestamp DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ip_ib_id, ip_ib_i_id, ip_ib_u_id)
    REFERENCES item_bid (ib_id, ib_i_id, ib_u_id) ON DELETE CASCADE,
  PRIMARY KEY (ip_id, ip_ib_id, ip_ib_i_id, ip_ib_u_id)
) TABLEGROUP='auctionmark_group'
  PARTITION BY HASH(ip_ib_i_id_hash)
  PARTITIONS 18;

-- ================================================================
-- USERACCT_FEEDBACK - с хешем
-- ================================================================
CREATE TABLE useracct_feedback (
  uf_u_id    varchar(128) NOT NULL,
  uf_i_id    varchar(128) NOT NULL,
  uf_i_u_id  varchar(128) NOT NULL,
  -- НОВОЕ: вычисляемый хеш
  uf_i_id_hash bigint AS (CRC32(uf_i_id)) STORED,
  uf_from_id varchar(128) NOT NULL,
  uf_rating  tinyint NOT NULL,
  uf_date    timestamp DEFAULT CURRENT_TIMESTAMP,
  uf_sattr0  varchar(80) NOT NULL,
  FOREIGN KEY (uf_i_id, uf_i_u_id) REFERENCES item (i_id, i_u_id) ON DELETE CASCADE,
  FOREIGN KEY (uf_u_id) REFERENCES useracct (u_id) ON DELETE CASCADE,
  FOREIGN KEY (uf_from_id) REFERENCES useracct (u_id) ON DELETE CASCADE,
  PRIMARY KEY (uf_u_id, uf_i_id, uf_i_u_id, uf_from_id),
  CHECK (uf_u_id <> uf_from_id)
) TABLEGROUP='auctionmark_group'
  PARTITION BY HASH(uf_i_id_hash)
  PARTITIONS 18;

-- ================================================================
-- USERACCT_ITEM - с хешем
-- ================================================================
CREATE TABLE useracct_item (
  ui_u_id       varchar(128) NOT NULL,
  ui_i_id       varchar(128) NOT NULL,
  ui_i_u_id     varchar(128) NOT NULL,
  -- НОВОЕ: вычисляемый хеш
  ui_i_id_hash  bigint AS (CRC32(ui_i_id)) STORED,
  ui_ip_id      bigint,
  ui_ip_ib_id   bigint,
  ui_ip_ib_i_id varchar(128),
  ui_ip_ib_u_id varchar(128),
  ui_created    timestamp DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ui_u_id) REFERENCES useracct (u_id) ON DELETE CASCADE,
  FOREIGN KEY (ui_i_id, ui_i_u_id) REFERENCES item (i_id, i_u_id) ON DELETE CASCADE,
  FOREIGN KEY (ui_ip_id, ui_ip_ib_id, ui_ip_ib_i_id, ui_ip_ib_u_id)
    REFERENCES item_purchase (ip_id, ip_ib_id, ip_ib_i_id, ip_ib_u_id) ON DELETE CASCADE,
  PRIMARY KEY (ui_u_id, ui_i_id, ui_i_u_id)
) TABLEGROUP='auctionmark_group'
  PARTITION BY HASH(ui_i_id_hash)
  PARTITIONS 18;

-- ================================================================
-- USERACCT_WATCH - с хешем
-- ================================================================
CREATE TABLE useracct_watch (
  uw_u_id    varchar(128) NOT NULL,
  uw_i_id    varchar(128) NOT NULL,
  uw_i_u_id  varchar(128) NOT NULL,
  -- НОВОЕ: вычисляемый хеш
  uw_i_id_hash bigint AS (CRC32(uw_i_id)) STORED,
  uw_created timestamp DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (uw_i_id, uw_i_u_id) REFERENCES item (i_id, i_u_id) ON DELETE CASCADE,
  FOREIGN KEY (uw_u_id) REFERENCES useracct (u_id) ON DELETE CASCADE,
  PRIMARY KEY (uw_u_id, uw_i_id, uw_i_u_id)
) TABLEGROUP='auctionmark_group'
  PARTITION BY HASH(uw_i_id_hash)
  PARTITIONS 18;

SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
