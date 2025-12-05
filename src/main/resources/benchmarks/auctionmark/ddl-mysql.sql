SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS test_bid CASCADE;
DROP TABLE IF EXISTS test_item CASCADE;
DROP TABLEGROUP IF EXISTS test_key_group;

-- ================================================================
-- ТЕСТ 1: Создание TABLEGROUP с KEY
-- ================================================================
CREATE TABLEGROUP test_key_group
  PARTITION BY KEY
  PARTITIONS 6;

-- ================================================================
-- ТЕСТ 2: Таблица item с KEY партиционированием
-- ================================================================
CREATE TABLE test_item (
  i_id VARCHAR(128) NOT NULL,
  i_u_id VARCHAR(128) NOT NULL,
  i_name VARCHAR(100),
  PRIMARY KEY (i_id, i_u_id)
) TABLEGROUP='test_key_group'
  PARTITION BY KEY(i_id)
  PARTITIONS 6;

-- ================================================================
-- ТЕСТ 3: Таблица bid с FOREIGN KEY и KEY партиционированием
-- ================================================================
CREATE TABLE test_bid (
  b_id BIGINT NOT NULL,
  b_i_id VARCHAR(128) NOT NULL,
  b_u_id VARCHAR(128) NOT NULL,
  b_amount FLOAT,
  FOREIGN KEY (b_i_id, b_u_id) REFERENCES test_item(i_id, i_u_id),
  PRIMARY KEY (b_i_id, b_u_id, b_id)
) TABLEGROUP='test_key_group'
  PARTITION BY KEY(b_i_id)
  PARTITIONS 6;

SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;

-- ================================================================
-- ПРОВЕРКИ
-- ================================================================

-- Проверка 1: Таблицы созданы
SHOW TABLES LIKE 'test_%';

-- Проверка 2: Структура
SHOW CREATE TABLE test_item;
SHOW CREATE TABLE test_bid;

-- Проверка 3: Партиции
SELECT 
  table_name, 
  partition_name,
  partition_method
FROM information_schema.PARTITIONS
WHERE table_schema = DATABASE()
  AND table_name IN ('test_item', 'test_bid')
ORDER BY table_name, partition_ordinal_position;

-- Проверка 4: Колокация партиций
SELECT 
  table_name,
  partition_id,
  svr_ip,
  svr_port
FROM oceanbase.DBA_OB_TABLE_LOCATIONS
WHERE table_name IN ('TEST_ITEM', 'TEST_BID')
ORDER BY partition_id, table_name;

-- Проверка 5: Тест INSERT
INSERT INTO test_item (i_id, i_u_id, i_name) VALUES
  ('item-001', 'user-1', 'Test Item 1'),
  ('item-002', 'user-1', 'Test Item 2'),
  ('item-003', 'user-2', 'Test Item 3');

INSERT INTO test_bid (b_id, b_i_id, b_u_id, b_amount) VALUES
  (1, 'item-001', 'user-1', 100.0),
  (2, 'item-001', 'user-1', 150.0),
  (3, 'item-002', 'user-1', 200.0);

-- Проверка 6: Распределение по партициям
SELECT 
  i_id,
  COUNT(*) as item_count
FROM test_item
GROUP BY i_id;

SELECT 
  b_i_id,
  COUNT(*) as bid_count
FROM test_bid
GROUP BY b_i_id;

-- Проверка 7: JOIN работает
SELECT 
  i.i_id,
  i.i_name,
  COUNT(b.b_id) as bids
FROM test_item i
LEFT JOIN test_bid b ON i.i_id = b.b_i_id AND i.i_u_id = b.b_u_id
GROUP BY i.i_id, i.i_name;

