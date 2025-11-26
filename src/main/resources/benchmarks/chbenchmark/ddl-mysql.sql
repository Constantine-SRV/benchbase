-- CH-benCHmark DDL для OceanBase
-- Добавляет 3 справочные таблицы к TPC-C схеме

DROP TABLE IF EXISTS supplier CASCADE;
DROP TABLE IF EXISTS nation CASCADE;
DROP TABLE IF EXISTS region CASCADE;

-- REGION - очень маленькая справочная таблица (5 строк)
-- Реплицируем на все ноды для быстрого доступа
CREATE TABLE region (
    r_regionkey INT       NOT NULL,
    r_name      CHAR(55)  NOT NULL,
    r_comment   CHAR(152) NOT NULL,
    PRIMARY KEY (r_regionkey)
) DUPLICATE_SCOPE='cluster';

-- NATION - справочная таблица (25 строк)
-- Реплицируем на все ноды
CREATE TABLE nation (
    n_nationkey INT       NOT NULL,
    n_name      CHAR(25)  NOT NULL,
    n_regionkey INT       NOT NULL,
    n_comment   CHAR(152) NOT NULL,
    PRIMARY KEY (n_nationkey)
) DUPLICATE_SCOPE='cluster';

-- SUPPLIER - большая таблица (scale_factor * 10000 строк)
-- Партиционируем по su_suppkey и добавляем в tpcc_group
CREATE TABLE supplier (
    su_suppkey   INT            NOT NULL,
    su_name      CHAR(25)       NOT NULL,
    su_address   VARCHAR(40)    NOT NULL,
    su_nationkey INT            NOT NULL,
    su_phone     CHAR(15)       NOT NULL,
    su_acctbal   DECIMAL(12, 2) NOT NULL,
    su_comment   CHAR(101)      NOT NULL,
    PRIMARY KEY (su_suppkey)
) TABLEGROUP='tpcc_group' PARTITION BY HASH(su_suppkey) PARTITIONS 9;

-- CREATE INDEX supplier_nation_idx ON supplier (su_nationkey) LOCAL;
