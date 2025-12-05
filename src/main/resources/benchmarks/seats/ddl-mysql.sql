SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;

-- Drop Tables (в правильном порядке, чтобы не ломать FK)
DROP TABLE IF EXISTS reservation;
DROP TABLE IF EXISTS frequent_flyer;
DROP TABLE IF EXISTS flight;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS airport_distance;
DROP TABLE IF EXISTS airline;
DROP TABLE IF EXISTS airport;
DROP TABLE IF EXISTS country;
DROP TABLE IF EXISTS config_histograms;
DROP TABLE IF EXISTS config_profile;

-- Удаляем tablegroup если существует
DROP TABLEGROUP IF EXISTS seats_group;

-- Создаём tablegroup для SEATS с 18 партициями (оптимально для 3-6-9 серверов)
-- ВАЖНО: используем PARTITION BY KEY (это тоже хэш-разбиение)
CREATE TABLEGROUP IF NOT EXISTS seats_group
  PARTITION BY KEY
  PARTITIONS 18;

-- =========================
-- CONFIG_PROFILE (конфигурация - не партиционируем)
-- =========================
CREATE TABLE config_profile (
  cfp_scale_factor          FLOAT        NOT NULL,
  cfp_aiport_max_customer   TEXT         NOT NULL,
  cfp_flight_start          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  cfp_flight_upcoming       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  cfp_flight_past_days      INT          NOT NULL,
  cfp_flight_future_days    INT          NOT NULL,
  cfp_flight_offset         INT,
  cfp_reservation_offset    INT,
  cfp_num_reservations      BIGINT       NOT NULL,
  cfp_code_ids_xrefs        TEXT         NOT NULL
);

-- =========================
-- CONFIG_HISTOGRAMS (справочник - не партиционируем)
-- =========================
CREATE TABLE config_histograms (
  cfh_name       VARCHAR(128)   NOT NULL,
  cfh_data       VARCHAR(10005) NOT NULL,
  cfh_is_airport TINYINT        DEFAULT 0,
  PRIMARY KEY (cfh_name)
);

-- =========================
-- COUNTRY (справочник - не партиционируем)
-- =========================
CREATE TABLE country (
  co_id     BIGINT       NOT NULL,
  co_name   VARCHAR(64)  NOT NULL,
  co_code_2 VARCHAR(2)   NOT NULL,
  co_code_3 VARCHAR(3)   NOT NULL,
  PRIMARY KEY (co_id)
);

-- =========================
-- AIRPORT (справочник - не партиционируем)
-- =========================
CREATE TABLE airport (
  ap_id         BIGINT       NOT NULL,
  ap_code       VARCHAR(3)   NOT NULL,
  ap_name       VARCHAR(128) NOT NULL,
  ap_city       VARCHAR(64)  NOT NULL,
  ap_postal_code VARCHAR(12),
  ap_co_id      BIGINT       NOT NULL,
  ap_longitude  FLOAT,
  ap_latitude   FLOAT,
  ap_gmt_offset FLOAT,
  ap_wac        BIGINT,
  ap_iattr00    BIGINT,
  ap_iattr01    BIGINT,
  ap_iattr02    BIGINT,
  ap_iattr03    BIGINT,
  ap_iattr04    BIGINT,
  ap_iattr05    BIGINT,
  ap_iattr06    BIGINT,
  ap_iattr07    BIGINT,
  ap_iattr08    BIGINT,
  ap_iattr09    BIGINT,
  ap_iattr10    BIGINT,
  ap_iattr11    BIGINT,
  ap_iattr12    BIGINT,
  ap_iattr13    BIGINT,
  ap_iattr14    BIGINT,
  ap_iattr15    BIGINT,
  PRIMARY KEY (ap_id),
  FOREIGN KEY (ap_co_id) REFERENCES country (co_id)
);

-- =========================
-- AIRPORT_DISTANCE (справочник - не партиционируем)
-- =========================
CREATE TABLE airport_distance (
  d_ap_id0  BIGINT NOT NULL,
  d_ap_id1  BIGINT NOT NULL,
  d_distance FLOAT NOT NULL,
  PRIMARY KEY (d_ap_id0, d_ap_id1),
  FOREIGN KEY (d_ap_id0) REFERENCES airport (ap_id),
  FOREIGN KEY (d_ap_id1) REFERENCES airport (ap_id)
);

-- =========================
-- AIRLINE (справочник - не партиционируем)
-- =========================
CREATE TABLE airline (
  al_id        BIGINT        NOT NULL,
  al_iata_code VARCHAR(3),
  al_icao_code VARCHAR(3),
  al_call_sign VARCHAR(32),
  al_name      VARCHAR(128)  NOT NULL,
  al_co_id     BIGINT        NOT NULL,
  al_iattr00   BIGINT,
  al_iattr01   BIGINT,
  al_iattr02   BIGINT,
  al_iattr03   BIGINT,
  al_iattr04   BIGINT,
  al_iattr05   BIGINT,
  al_iattr06   BIGINT,
  al_iattr07   BIGINT,
  al_iattr08   BIGINT,
  al_iattr09   BIGINT,
  al_iattr10   BIGINT,
  al_iattr11   BIGINT,
  al_iattr12   BIGINT,
  al_iattr13   BIGINT,
  al_iattr14   BIGINT,
  al_iattr15   BIGINT,
  PRIMARY KEY (al_id),
  FOREIGN KEY (al_co_id) REFERENCES country (co_id)
);

-- =========================
-- CUSTOMER (главная транзакционная таблица)
-- Партиционируем по c_id
-- ВАЖНО: UNIQUE constraint на c_id_str включает партиционный ключ c_id
-- =========================
CREATE TABLE customer (
  c_id        VARCHAR(128) NOT NULL,
  c_id_str    VARCHAR(64)  NOT NULL,
  c_base_ap_id BIGINT,
  c_balance   FLOAT        NOT NULL,

  c_sattr00   VARCHAR(32),
  c_sattr01   VARCHAR(8),
  c_sattr02   VARCHAR(8),
  c_sattr03   VARCHAR(8),
  c_sattr04   VARCHAR(8),
  c_sattr05   VARCHAR(8),
  c_sattr06   VARCHAR(8),
  c_sattr07   VARCHAR(8),
  c_sattr08   VARCHAR(8),
  c_sattr09   VARCHAR(8),
  c_sattr10   VARCHAR(8),
  c_sattr11   VARCHAR(8),
  c_sattr12   VARCHAR(8),
  c_sattr13   VARCHAR(8),
  c_sattr14   VARCHAR(8),
  c_sattr15   VARCHAR(8),
  c_sattr16   VARCHAR(8),
  c_sattr17   VARCHAR(8),
  c_sattr18   VARCHAR(8),
  c_sattr19   VARCHAR(8),

  c_iattr00   BIGINT,
  c_iattr01   BIGINT,
  c_iattr02   BIGINT,
  c_iattr03   BIGINT,
  c_iattr04   BIGINT,
  c_iattr05   BIGINT,
  c_iattr06   BIGINT,
  c_iattr07   BIGINT,
  c_iattr08   BIGINT,
  c_iattr09   BIGINT,
  c_iattr10   BIGINT,
  c_iattr11   BIGINT,
  c_iattr12   BIGINT,
  c_iattr13   BIGINT,
  c_iattr14   BIGINT,
  c_iattr15   BIGINT,
  c_iattr16   BIGINT,
  c_iattr17   BIGINT,
  c_iattr18   BIGINT,
  c_iattr19   BIGINT,

  PRIMARY KEY (c_id),
  UNIQUE KEY idx_c_id_str (c_id_str, c_id),
  FOREIGN KEY (c_base_ap_id) REFERENCES airport (ap_id)
)
TABLEGROUP = 'seats_group'
PARTITION BY KEY (c_id) PARTITIONS 18;

-- =========================
-- FREQUENT_FLYER
-- Партиционируем по ff_c_id (customer_id)
-- =========================
CREATE TABLE frequent_flyer (
  ff_c_id      VARCHAR(128) NOT NULL,
  ff_al_id     BIGINT       NOT NULL,
  ff_c_id_str  VARCHAR(64)  NOT NULL,

  ff_sattr00   VARCHAR(32),
  ff_sattr01   VARCHAR(32),
  ff_sattr02   VARCHAR(32),
  ff_sattr03   VARCHAR(32),

  ff_iattr00   BIGINT,
  ff_iattr01   BIGINT,
  ff_iattr02   BIGINT,
  ff_iattr03   BIGINT,
  ff_iattr04   BIGINT,
  ff_iattr05   BIGINT,
  ff_iattr06   BIGINT,
  ff_iattr07   BIGINT,
  ff_iattr08   BIGINT,
  ff_iattr09   BIGINT,
  ff_iattr10   BIGINT,
  ff_iattr11   BIGINT,
  ff_iattr12   BIGINT,
  ff_iattr13   BIGINT,
  ff_iattr14   BIGINT,
  ff_iattr15   BIGINT,

  PRIMARY KEY (ff_c_id, ff_al_id),
  FOREIGN KEY (ff_c_id) REFERENCES customer (c_id),
  FOREIGN KEY (ff_al_id) REFERENCES airline (al_id)
)
TABLEGROUP = 'seats_group'
PARTITION BY KEY (ff_c_id) PARTITIONS 18;

CREATE INDEX idx_ff_customer_id ON frequent_flyer (ff_c_id_str);

-- =========================
-- FLIGHT
-- Партиционируем по f_id для равномерного распределения рейсов
-- =========================
CREATE TABLE flight (
  f_id            VARCHAR(128) NOT NULL,
  f_al_id         BIGINT       NOT NULL,
  f_depart_ap_id  BIGINT       NOT NULL,
  f_depart_time   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  f_arrive_ap_id  BIGINT       NOT NULL,
  f_arrive_time   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  f_status        BIGINT       NOT NULL,
  f_base_price    FLOAT        NOT NULL,
  f_seats_total   BIGINT       NOT NULL,
  f_seats_left    BIGINT       NOT NULL,

  f_iattr00       BIGINT,
  f_iattr01       BIGINT,
  f_iattr02       BIGINT,
  f_iattr03       BIGINT,
  f_iattr04       BIGINT,
  f_iattr05       BIGINT,
  f_iattr06       BIGINT,
  f_iattr07       BIGINT,
  f_iattr08       BIGINT,
  f_iattr09       BIGINT,
  f_iattr10       BIGINT,
  f_iattr11       BIGINT,
  f_iattr12       BIGINT,
  f_iattr13       BIGINT,
  f_iattr14       BIGINT,
  f_iattr15       BIGINT,
  f_iattr16       BIGINT,
  f_iattr17       BIGINT,
  f_iattr18       BIGINT,
  f_iattr19       BIGINT,
  f_iattr20       BIGINT,
  f_iattr21       BIGINT,
  f_iattr22       BIGINT,
  f_iattr23       BIGINT,
  f_iattr24       BIGINT,
  f_iattr25       BIGINT,
  f_iattr26       BIGINT,
  f_iattr27       BIGINT,
  f_iattr28       BIGINT,
  f_iattr29       BIGINT,

  PRIMARY KEY (f_id),
  FOREIGN KEY (f_al_id)        REFERENCES airline (al_id),
  FOREIGN KEY (f_depart_ap_id) REFERENCES airport (ap_id),
  FOREIGN KEY (f_arrive_ap_id) REFERENCES airport (ap_id)
)
TABLEGROUP = 'seats_group'
PARTITION BY KEY (f_id) PARTITIONS 18;

CREATE INDEX f_depart_time_idx ON flight (f_depart_time);

-- =========================
-- RESERVATION
-- КРИТИЧНО: партиционируем по r_f_id (flight_id)
-- чтобы UNIQUE (r_f_id, r_seat) гарантированно был локальным
-- =========================
CREATE TABLE reservation (
  r_id      BIGINT       NOT NULL,
  r_c_id    VARCHAR(128) NOT NULL,
  r_f_id    VARCHAR(128) NOT NULL,
  r_seat    BIGINT       NOT NULL,
  r_price   FLOAT        NOT NULL,

  r_iattr00 BIGINT,
  r_iattr01 BIGINT,
  r_iattr02 BIGINT,
  r_iattr03 BIGINT,
  r_iattr04 BIGINT,
  r_iattr05 BIGINT,
  r_iattr06 BIGINT,
  r_iattr07 BIGINT,
  r_iattr08 BIGINT,

  PRIMARY KEY (r_id, r_c_id, r_f_id),
  UNIQUE KEY idx_flight_seat (r_f_id, r_seat),
  FOREIGN KEY (r_c_id) REFERENCES customer (c_id),
  FOREIGN KEY (r_f_id) REFERENCES flight (f_id)
)
TABLEGROUP = 'seats_group'
PARTITION BY KEY (r_f_id) PARTITIONS 18;

SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
