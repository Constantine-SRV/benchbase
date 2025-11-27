-- CH-benCHmark DDL для OceanBase
-- Добавляет 3 справочные таблицы к TPC-C схеме
-- Foreign Keys создаются сразу для честности теста
-- Только индексы создаются после загрузки данных

DROP TABLE IF EXISTS supplier;
DROP TABLE IF EXISTS nation;
DROP TABLE IF EXISTS region;

-- REGION - очень маленькая справочная таблица (5 строк)
-- Реплицируем на все ноды для быстрого доступа
CREATE TABLE region (
    r_regionkey int       NOT NULL,
    r_name      char(55)  NOT NULL,
    r_comment   char(152) NOT NULL,
    PRIMARY KEY (r_regionkey)
) DUPLICATE_SCOPE='cluster';

-- NATION - справочная таблица (25 строк)
-- Реплицируем на все ноды
CREATE TABLE nation (
    n_nationkey int       NOT NULL,
    n_name      char(25)  NOT NULL,
    n_regionkey int       NOT NULL,
    n_comment   char(152) NOT NULL,
    FOREIGN KEY (n_regionkey) REFERENCES region (r_regionkey) ON DELETE CASCADE,
    PRIMARY KEY (n_nationkey)
) DUPLICATE_SCOPE='cluster';

-- SUPPLIER - большая таблица (scale_factor * 10000 строк)
-- Партиционируем по su_suppkey и добавляем в tpcc_group
CREATE TABLE supplier (
    su_suppkey   int            NOT NULL,
    su_name      char(25)       NOT NULL,
    su_address   varchar(40)    NOT NULL,
    su_nationkey int            NOT NULL,
    su_phone     char(15)       NOT NULL,
    su_acctbal   decimal(12, 2) NOT NULL,
    su_comment   char(101)      NOT NULL,
    FOREIGN KEY (su_nationkey) REFERENCES nation (n_nationkey) ON DELETE CASCADE,
    PRIMARY KEY (su_suppkey)
) TABLEGROUP='tpcc_group' PARTITION BY HASH(su_suppkey) PARTITIONS 9;

-- Индексы создаются вручную после загрузки данных для ускорения:
-- CREATE INDEX supplier_nation_idx ON supplier (su_nationkey) LOCAL;
