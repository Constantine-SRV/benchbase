-- TPC-C DDL для OceanBase
-- Удаляем существующие объекты
DROP TABLE IF EXISTS bmsql_order_line;
DROP TABLE IF EXISTS bmsql_new_order;
DROP TABLE IF EXISTS bmsql_oorder;
DROP TABLE IF EXISTS bmsql_history;
DROP TABLE IF EXISTS bmsql_customer;
DROP TABLE IF EXISTS bmsql_stock;
DROP TABLE IF EXISTS bmsql_district;
DROP TABLE IF EXISTS bmsql_warehouse;
DROP TABLE IF EXISTS bmsql_item;
DROP TABLE IF EXISTS bmsql_config;
DROP TABLEGROUP IF EXISTS tpcc_group;

-- Создание конфигурационной таблицы (без партиционирования)
CREATE TABLE bmsql_config (
  cfg_name    VARCHAR(30) PRIMARY KEY,
  cfg_value   VARCHAR(50)
);

-- Создание tablegroup для colocation данных
CREATE TABLEGROUP tpcc_group PARTITION BY HASH PARTITIONS 9;

-- Таблица WAREHOUSE
CREATE TABLE bmsql_warehouse (
  w_id        INTEGER   NOT NULL,
  w_ytd       DECIMAL(12,2),
  w_tax       DECIMAL(4,4),
  w_name      VARCHAR(10),
  w_street_1  VARCHAR(20),
  w_street_2  VARCHAR(20),
  w_city      VARCHAR(20),
  w_state     CHAR(2),
  w_zip       CHAR(9),
  PRIMARY KEY(w_id)
) TABLEGROUP='tpcc_group' PARTITION BY HASH(w_id) PARTITIONS 9;

-- Таблица DISTRICT
CREATE TABLE bmsql_district (
  d_w_id       INTEGER       NOT NULL,
  d_id         INTEGER       NOT NULL,
  d_ytd        DECIMAL(12,2),
  d_tax        DECIMAL(4,4),
  d_next_o_id  INTEGER,
  d_name       VARCHAR(10),
  d_street_1   VARCHAR(20),
  d_street_2   VARCHAR(20),
  d_city       VARCHAR(20),
  d_state      CHAR(2),
  d_zip        CHAR(9),
  PRIMARY KEY (d_w_id, d_id)
) TABLEGROUP='tpcc_group' PARTITION BY HASH(d_w_id) PARTITIONS 9;

-- Таблица CUSTOMER
CREATE TABLE bmsql_customer (
  c_w_id         INTEGER        NOT NULL,
  c_d_id         INTEGER        NOT NULL,
  c_id           INTEGER        NOT NULL,
  c_discount     DECIMAL(4,4),
  c_credit       CHAR(2),
  c_last         VARCHAR(16),
  c_first        VARCHAR(16),
  c_credit_lim   DECIMAL(12,2),
  c_balance      DECIMAL(12,2),
  c_ytd_payment  DECIMAL(12,2),
  c_payment_cnt  INTEGER,
  c_delivery_cnt INTEGER,
  c_street_1     VARCHAR(20),
  c_street_2     VARCHAR(20),
  c_city         VARCHAR(20),
  c_state        CHAR(2),
  c_zip          CHAR(9),
  c_phone        CHAR(16),
  c_since        TIMESTAMP,
  c_middle       CHAR(2),
  c_data         VARCHAR(500),
  PRIMARY KEY (c_w_id, c_d_id, c_id)
) TABLEGROUP='tpcc_group' PARTITION BY HASH(c_w_id) PARTITIONS 9;

-- Таблица HISTORY
CREATE TABLE bmsql_history (
  hist_id  INTEGER,
  h_c_id   INTEGER,
  h_c_d_id INTEGER,
  h_c_w_id INTEGER,
  h_d_id   INTEGER,
  h_w_id   INTEGER,
  h_date   TIMESTAMP,
  h_amount DECIMAL(6,2),
  h_data   VARCHAR(24)
) TABLEGROUP='tpcc_group' PARTITION BY HASH(h_w_id) PARTITIONS 9;

-- Таблица NEW_ORDER
CREATE TABLE bmsql_new_order (
  no_w_id  INTEGER   NOT NULL,
  no_d_id  INTEGER   NOT NULL,
  no_o_id  INTEGER   NOT NULL,
  PRIMARY KEY (no_w_id, no_d_id, no_o_id)
) TABLEGROUP='tpcc_group' PARTITION BY HASH(no_w_id) PARTITIONS 9;

-- Таблица OORDER
CREATE TABLE bmsql_oorder (
  o_w_id       INTEGER      NOT NULL,
  o_d_id       INTEGER      NOT NULL,
  o_id         INTEGER      NOT NULL,
  o_c_id       INTEGER,
  o_carrier_id INTEGER,
  o_ol_cnt     INTEGER,
  o_all_local  INTEGER,
  o_entry_d    TIMESTAMP,
  PRIMARY KEY (o_w_id, o_d_id, o_id)
) TABLEGROUP='tpcc_group' PARTITION BY HASH(o_w_id) PARTITIONS 9;

-- Таблица ORDER_LINE
CREATE TABLE bmsql_order_line (
  ol_w_id         INTEGER   NOT NULL,
  ol_d_id         INTEGER   NOT NULL,
  ol_o_id         INTEGER   NOT NULL,
  ol_number       INTEGER   NOT NULL,
  ol_i_id         INTEGER   NOT NULL,
  ol_delivery_d   TIMESTAMP,
  ol_amount       DECIMAL(6,2),
  ol_supply_w_id  INTEGER,
  ol_quantity     INTEGER,
  ol_dist_info    CHAR(24),
  PRIMARY KEY (ol_w_id, ol_d_id, ol_o_id, ol_number)
) TABLEGROUP='tpcc_group' PARTITION BY HASH(ol_w_id) PARTITIONS 9;

-- Таблица ITEM (реплицируется на все ноды)
CREATE TABLE bmsql_item (
  i_id     INTEGER      NOT NULL,
  i_name   VARCHAR(24),
  i_price  DECIMAL(5,2),
  i_data   VARCHAR(50),
  i_im_id  INTEGER,
  PRIMARY KEY (i_id)
) DUPLICATE_SCOPE='cluster';

-- Таблица STOCK (с bloom filter для оптимизации)
CREATE TABLE bmsql_stock (
  s_w_id       INTEGER       NOT NULL,
  s_i_id       INTEGER       NOT NULL,
  s_quantity   INTEGER,
  s_ytd        INTEGER,
  s_order_cnt  INTEGER,
  s_remote_cnt INTEGER,
  s_data       VARCHAR(50),
  s_dist_01    CHAR(24),
  s_dist_02    CHAR(24),
  s_dist_03    CHAR(24),
  s_dist_04    CHAR(24),
  s_dist_05    CHAR(24),
  s_dist_06    CHAR(24),
  s_dist_07    CHAR(24),
  s_dist_08    CHAR(24),
  s_dist_09    CHAR(24),
  s_dist_10    CHAR(24),
  PRIMARY KEY (s_w_id, s_i_id)
) TABLEGROUP='tpcc_group' USE_BLOOM_FILTER=TRUE PARTITION BY HASH(s_w_id) PARTITIONS 9;

-- Индексы (создаются после загрузки данных вручную)
-- CREATE INDEX bmsql_customer_idx1 ON bmsql_customer (c_w_id, c_d_id, c_last, c_first) LOCAL;
-- CREATE INDEX bmsql_oorder_idx1 ON bmsql_oorder (o_w_id, o_d_id, o_carrier_id, o_id) LOCAL;
