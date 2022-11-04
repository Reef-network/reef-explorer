-- Dropping v2 views and functions
DROP VIEW IF EXISTS verified_pool_info;
DROP VIEW IF EXISTS pool_info;

DROP VIEW IF EXISTS volume_raw_min;
DROP VIEW IF EXISTS volume_raw_hour;
DROP VIEW IF EXISTS volume_raw_day;
DROP VIEW IF EXISTS volume_raw_week;
DROP FUNCTION IF EXISTS volume_window_raw;
DROP FUNCTION IF EXISTS volume_prepare_raw;

DROP VIEW IF EXISTS reserved_raw_min;
DROP VIEW IF EXISTS reserved_raw_hour;
DROP VIEW IF EXISTS reserved_raw_day;
DROP VIEW IF EXISTS reserved_raw_week;
DROP FUNCTION IF EXISTS reserved_window_raw;
DROP FUNCTION IF EXISTS reserved_prepare_raw;

DROP VIEW IF EXISTS token_price_min;
DROP VIEW IF EXISTS token_price_hour;
DROP VIEW IF EXISTS token_price_day;
DROP VIEW IF EXISTS token_price_week;
DROP FUNCTION IF EXISTS token_price_window;
DROP FUNCTION IF EXISTS token_price_prepare;

DROP VIEW IF EXISTS fee_min;
DROP VIEW IF EXISTS fee_hour;
DROP VIEW IF EXISTS fee_day;
DROP VIEW IF EXISTS fee_week;
DROP FUNCTION IF EXISTS fee_window;
DROP FUNCTION IF EXISTS fee_prepare;
DROP VIEW IF EXISTS fee;

DROP VIEW IF EXISTS fee_raw_min;
DROP VIEW IF EXISTS fee_raw_hour;
DROP VIEW IF EXISTS fee_raw_day;
DROP VIEW IF EXISTS fee_raw_week;
DROP FUNCTION IF EXISTS fee_window_raw;
DROP FUNCTION IF EXISTS fee_prepare_raw;
DROP VIEW IF EXISTS fee_raw;

DROP VIEW IF EXISTS candlestick_min;
DROP VIEW IF EXISTS candlestick_hour;
DROP VIEW IF EXISTS candlestick_day;
DROP VIEW IF EXISTS candlestick_week;
DROP FUNCTION IF EXISTS candlestick_window;
DROP FUNCTION IF EXISTS candlestick_prepare;

DROP VIEW IF EXISTS volume_change_min;
DROP VIEW IF EXISTS volume_change_hour;
DROP VIEW IF EXISTS volume_change_day;
DROP VIEW IF EXISTS volume_change_week;
DROP VIEW IF EXISTS volume_change;

DROP VIEW IF EXISTS volume_min;
DROP VIEW IF EXISTS volume_hour;
DROP VIEW IF EXISTS volume_day;
DROP VIEW IF EXISTS volume_week;
DROP FUNCTION IF EXISTS volume_window;
DROP FUNCTION IF EXISTS volume_prepare;
DROP VIEW IF EXISTS volume;

DROP VIEW IF EXISTS reserved_min;
DROP VIEW IF EXISTS reserved_hour;
DROP VIEW IF EXISTS reserved_day;
DROP VIEW IF EXISTS reserved_week;
DROP FUNCTION IF EXISTS reserved_window;
DROP FUNCTION IF EXISTS reserved_prepare;
DROP VIEW IF EXISTS reserved;

-- Token price tables
CREATE TABLE IF NOT EXISTS token_price_min(
  id SERIAL PRIMARY KEY,
  token_address CHAR(42) NOT NULL,
  price NUMERIC NOT NULL,
  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (token_address) REFERENCES contract (address) ON DELETE NO ACTION,
  CONSTRAINT unique_token_price_min_timeframe UNIQUE (token_address, timeframe)
);
CREATE INDEX IF NOT EXISTS token_price_min_token_address ON token_price_min (token_address);
CREATE INDEX IF NOT EXISTS token_price_min_timeframe ON token_price_min (timeframe);

CREATE TABLE IF NOT EXISTS token_price_hour(
  id SERIAL PRIMARY KEY,
  token_address CHAR(42) NOT NULL,
  price NUMERIC NOT NULL,
  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (token_address) REFERENCES contract (address) ON DELETE NO ACTION,
  CONSTRAINT unique_token_price_hour_timeframe UNIQUE (token_address, timeframe)
);
CREATE INDEX IF NOT EXISTS token_price_hour_token_address ON token_price_hour (token_address);
CREATE INDEX IF NOT EXISTS token_price_hour_timeframe ON token_price_hour (timeframe);

CREATE TABLE IF NOT EXISTS token_price_day(
  id SERIAL PRIMARY KEY,
  token_address CHAR(42) NOT NULL,
  price NUMERIC NOT NULL,
  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (token_address) REFERENCES contract (address) ON DELETE NO ACTION,
  CONSTRAINT unique_token_price_day_timeframe UNIQUE (token_address, timeframe)
);
CREATE INDEX IF NOT EXISTS token_price_day_token_address ON token_price_day (token_address);
CREATE INDEX IF NOT EXISTS token_price_day_timeframe ON token_price_day (timeframe);

CREATE TABLE IF NOT EXISTS token_price_week(
  id SERIAL PRIMARY KEY,
  token_address CHAR(42) NOT NULL,
  price NUMERIC NOT NULL,
  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (token_address) REFERENCES contract (address) ON DELETE NO ACTION,
  CONSTRAINT unique_token_price_week_timeframe UNIQUE (token_address, timeframe)
);
CREATE INDEX IF NOT EXISTS token_price_week_token_address ON token_price_week (token_address);
CREATE INDEX IF NOT EXISTS token_price_week_timeframe ON token_price_week (timeframe);

CREATE OR REPLACE FUNCTION token_price_insert()
  RETURNS TRIGGER AS $$
  BEGIN
    -- Insert minute token price
    INSERT INTO token_price_min
      (token_address, price, timeframe)
    VALUES
      (NEW.token_address, NEW.price, date_trunc('minute', NEW.timestamp))
    ON CONFLICT (token_address, timeframe) DO UPDATE
      SET price = NEW.price;

    -- Insert hourly token price
    INSERT INTO token_price_hour
      (token_address, price, timeframe)
    VALUES
      (NEW.token_address, NEW.price, date_trunc('hour', NEW.timestamp))
    ON CONFLICT (token_address, timeframe) DO UPDATE
      SET price = NEW.price;

    -- Insert daily token price
    INSERT INTO token_price_day
      (token_address, price, timeframe)
    VALUES
      (NEW.token_address, NEW.price, date_trunc('day', NEW.timestamp))
    ON CONFLICT (token_address, timeframe) DO UPDATE
      SET price = NEW.price;

    -- Insert weekly token price
    INSERT INTO token_price_week
      (token_address, price, timeframe)
    VALUES
      (NEW.token_address, NEW.price, date_trunc('week', NEW.timestamp))
    ON CONFLICT (token_address, timeframe) DO UPDATE
      SET price = NEW.price;

    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

-- Trigger token price insert procedure for each new row in token_price table
CREATE TRIGGER token_price_insert_trigger
  AFTER INSERT ON token_price
  FOR EACH ROW EXECUTE PROCEDURE token_price_insert();

-- Volume raw tables
CREATE TABLE IF NOT EXISTS volume_raw_min(
  id SERIAL PRIMARY KEY,
  pool_id BIGINT NOT NULL,
  volume_1 NUMERIC NOT NULL,
  volume_2 NUMERIC NOT NULL,
  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool (id) ON DELETE CASCADE,
  CONSTRAINT unique_volume_raw_min_timeframe UNIQUE (pool_id, timeframe)
);
CREATE INDEX IF NOT EXISTS volume_raw_min_pool_id ON volume_raw_min (pool_id);
CREATE INDEX IF NOT EXISTS volume_raw_min_timeframe ON volume_raw_min (timeframe);

CREATE TABLE IF NOT EXISTS volume_raw_hour(
  id SERIAL PRIMARY KEY,
  pool_id BIGINT NOT NULL,
  volume_1 NUMERIC NOT NULL,
  volume_2 NUMERIC NOT NULL,
  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool (id) ON DELETE CASCADE,
  CONSTRAINT unique_volume_raw_hour_timeframe UNIQUE (pool_id, timeframe)
);
CREATE INDEX IF NOT EXISTS volume_raw_hour_pool_id ON volume_raw_hour (pool_id);
CREATE INDEX IF NOT EXISTS volume_raw_hour_timeframe ON volume_raw_hour (timeframe);

CREATE TABLE IF NOT EXISTS volume_raw_day(
  id SERIAL PRIMARY KEY,
  pool_id BIGINT NOT NULL,
  volume_1 NUMERIC NOT NULL,
  volume_2 NUMERIC NOT NULL,
  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool (id) ON DELETE CASCADE,
  CONSTRAINT unique_volume_raw_day_timeframe UNIQUE (pool_id, timeframe)
);
CREATE INDEX IF NOT EXISTS volume_raw_day_pool_id ON volume_raw_day (pool_id);
CREATE INDEX IF NOT EXISTS volume_raw_day_timeframe ON volume_raw_day (timeframe);

CREATE TABLE IF NOT EXISTS volume_raw_week(
  id SERIAL PRIMARY KEY,
  pool_id BIGINT NOT NULL,
  volume_1 NUMERIC NOT NULL,
  volume_2 NUMERIC NOT NULL,
  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool (id) ON DELETE CASCADE,
  CONSTRAINT unique_volume_raw_week_timeframe UNIQUE (pool_id, timeframe)
);
CREATE INDEX IF NOT EXISTS volume_raw_week_pool_id ON volume_raw_week (pool_id);
CREATE INDEX IF NOT EXISTS volume_raw_week_timeframe ON volume_raw_week (timeframe);

CREATE OR REPLACE FUNCTION volume_raw_insert()
  RETURNS TRIGGER AS $$
  BEGIN
    -- Insert minute volume
    INSERT INTO volume_raw_min
      (pool_id, volume_1, volume_2, timeframe)
    VALUES
      (NEW.pool_id, NEW.volume_1, NEW.volume_2, date_trunc('minute', NEW.timestamp))
    ON CONFLICT (pool_id, timeframe) DO UPDATE SET 
      volume_1 = NEW.volume_1 + volume_raw_min.volume_1, 
      volume_2 = NEW.volume_2 + volume_raw_min.volume_2;

    -- Insert hourly volume
    INSERT INTO volume_raw_hour
      (pool_id, volume_1, volume_2, timeframe)
    VALUES
      (NEW.pool_id, NEW.volume_1, NEW.volume_2, date_trunc('hour', NEW.timestamp))
    ON CONFLICT (pool_id, timeframe) DO UPDATE SET
      volume_1 = NEW.volume_1 + volume_raw_hour.volume_1,
      volume_2 = NEW.volume_2 + volume_raw_hour.volume_2;

    -- Insert daily volume
    INSERT INTO volume_raw_day
      (pool_id, volume_1, volume_2, timeframe)
    VALUES
      (NEW.pool_id, NEW.volume_1, NEW.volume_2, date_trunc('day', NEW.timestamp))
    ON CONFLICT (pool_id, timeframe) DO UPDATE SET
      volume_1 = NEW.volume_1 + volume_raw_day.volume_1,
      volume_2 = NEW.volume_2 + volume_raw_day.volume_2;

    -- Insert weekly volume
    INSERT INTO volume_raw_week
      (pool_id, volume_1, volume_2, timeframe)
    VALUES
      (NEW.pool_id, NEW.volume_1, NEW.volume_2, date_trunc('week', NEW.timestamp))
    ON CONFLICT (pool_id, timeframe) DO UPDATE SET
      volume_1 = NEW.volume_1 + volume_raw_week.volume_1,
      volume_2 = NEW.volume_2 + volume_raw_week.volume_2;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

-- Trigger volume raw insert procedure for each new row in volume_raw table
CREATE TRIGGER volume_raw_insert_trigger
  AFTER INSERT ON volume_raw
  FOR EACH ROW EXECUTE PROCEDURE volume_raw_insert();

-- Reserved raw tables
CREATE TABLE IF NOT EXISTS reserved_raw_min(
  id SERIAL PRIMARY KEY,
  pool_id BIGINT NOT NULL,
  reserved_1 NUMERIC NOT NULL,
  reserved_2 NUMERIC NOT NULL,
  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool (id) ON DELETE CASCADE,
  CONSTRAINT unique_reserved_raw_min_timeframe UNIQUE (pool_id, timeframe)
);
CREATE INDEX IF NOT EXISTS reserved_raw_min_pool_id ON reserved_raw_min (pool_id);
CREATE INDEX IF NOT EXISTS reserved_raw_min_timeframe ON reserved_raw_min (timeframe);

CREATE TABLE IF NOT EXISTS reserved_raw_hour(
  id SERIAL PRIMARY KEY,
  pool_id BIGINT NOT NULL,
  reserved_1 NUMERIC NOT NULL,
  reserved_2 NUMERIC NOT NULL,
  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool (id) ON DELETE CASCADE,
  CONSTRAINT unique_reserved_raw_hour_timeframe UNIQUE (pool_id, timeframe)
);
CREATE INDEX IF NOT EXISTS reserved_raw_hour_pool_id ON reserved_raw_hour (pool_id);
CREATE INDEX IF NOT EXISTS reserved_raw_hour_timeframe ON reserved_raw_hour (timeframe);

CREATE TABLE IF NOT EXISTS reserved_raw_day(
  id SERIAL PRIMARY KEY,
  pool_id BIGINT NOT NULL,
  reserved_1 NUMERIC NOT NULL,
  reserved_2 NUMERIC NOT NULL,
  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool (id) ON DELETE CASCADE,
  CONSTRAINT unique_reserved_raw_day_timeframe UNIQUE (pool_id, timeframe)
);
CREATE INDEX IF NOT EXISTS reserved_raw_day_pool_id ON reserved_raw_day (pool_id);
CREATE INDEX IF NOT EXISTS reserved_raw_day_timeframe ON reserved_raw_day (timeframe);

CREATE TABLE IF NOT EXISTS reserved_raw_week(
  id SERIAL PRIMARY KEY,
  pool_id BIGINT NOT NULL,
  reserved_1 NUMERIC NOT NULL,
  reserved_2 NUMERIC NOT NULL,
  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool (id) ON DELETE CASCADE,
  CONSTRAINT unique_reserved_raw_week_timeframe UNIQUE (pool_id, timeframe)
);
CREATE INDEX IF NOT EXISTS reserved_raw_week_pool_id ON reserved_raw_week (pool_id);
CREATE INDEX IF NOT EXISTS reserved_raw_week_timeframe ON reserved_raw_week (timeframe);

CREATE OR REPLACE FUNCTION reserved_raw_insert()
  RETURNS TRIGGER AS $$
  BEGIN
    -- Insert minute reserved
    INSERT INTO reserved_raw_min
      (pool_id, reserved_1, reserved_2, timeframe)
    VALUES
      (NEW.pool_id, NEW.reserved_1, NEW.reserved_2, date_trunc('minute', NEW.timestamp))
    ON CONFLICT (pool_id, timeframe) DO UPDATE SET 
      reserved_1 = NEW.reserved_1, 
      reserved_2 = NEW.reserved_2;

    -- Insert hourly reserved
    INSERT INTO reserved_raw_hour
      (pool_id, reserved_1, reserved_2, timeframe)
    VALUES
      (NEW.pool_id, NEW.reserved_1, NEW.reserved_2, date_trunc('hour', NEW.timestamp))
    ON CONFLICT (pool_id, timeframe) DO UPDATE SET
      reserved_1 = NEW.reserved_1,
      reserved_2 = NEW.reserved_2;

    -- Insert daily reserved
    INSERT INTO reserved_raw_day
      (pool_id, reserved_1, reserved_2, timeframe)
    VALUES
      (NEW.pool_id, NEW.reserved_1, NEW.reserved_2, date_trunc('day', NEW.timestamp))
    ON CONFLICT (pool_id, timeframe) DO UPDATE SET
      reserved_1 = NEW.reserved_1,
      reserved_2 = NEW.reserved_2;

    -- Insert weekly reserved
    INSERT INTO reserved_raw_week
      (pool_id, reserved_1, reserved_2, timeframe)
    VALUES
      (NEW.pool_id, NEW.reserved_1, NEW.reserved_2, date_trunc('week', NEW.timestamp))
    ON CONFLICT (pool_id, timeframe) DO UPDATE SET
      reserved_1 = NEW.reserved_1,
      reserved_2 = NEW.reserved_2;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

-- Trigger reserved raw insert procedure for each new row in reserved_raw table
CREATE TRIGGER reserved_raw_insert_trigger
  AFTER INSERT ON reserved_raw
  FOR EACH ROW EXECUTE PROCEDURE reserved_raw_insert();

-- Candlestick table
CREATE TABLE IF NOT EXISTS candlestick_min(
  id SERIAL PRIMARY KEY,

  pool_id BIGINT NOT NULL,
  token_address CHAR(42) NOT NULL,

  open NUMERIC NOT NULL,
  high NUMERIC NOT NULL,
  low NUMERIC NOT NULL,
  close NUMERIC NOT NULL,

  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool (id) ON DELETE CASCADE,
  FOREIGN KEY (token_address) REFERENCES contract (address) ON DELETE NO ACTION,
  CONSTRAINT unique_candlestick_min UNIQUE (pool_id, token_address, timeframe)
);
CREATE INDEX IF NOT EXISTS candlestick_min_pool_id ON candlestick_min (pool_id);
CREATE INDEX IF NOT EXISTS candlestick_min_timeframe ON candlestick_min (timeframe);
CREATE INDEX IF NOT EXISTS candlestick_min_token_address ON candlestick_min (token_address);

CREATE TABLE IF NOT EXISTS candlestick_hour(
  id SERIAL PRIMARY KEY,

  pool_id BIGINT NOT NULL,
  token_address CHAR(42) NOT NULL,

  open NUMERIC NOT NULL,
  high NUMERIC NOT NULL,
  low NUMERIC NOT NULL,
  close NUMERIC NOT NULL,

  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool (id) ON DELETE CASCADE,
  FOREIGN KEY (token_address) REFERENCES contract (address) ON DELETE NO ACTION,
  CONSTRAINT unique_candlestick_hour UNIQUE (pool_id, token_address, timeframe)
);
CREATE INDEX IF NOT EXISTS candlestick_hour_pool_id ON candlestick_hour (pool_id);
CREATE INDEX IF NOT EXISTS candlestick_hour_timeframe ON candlestick_hour (timeframe);
CREATE INDEX IF NOT EXISTS candlestick_hour_token_address ON candlestick_hour (token_address);

CREATE TABLE IF NOT EXISTS candlestick_day(
  id SERIAL PRIMARY KEY,

  pool_id BIGINT NOT NULL,
  token_address CHAR(42) NOT NULL,

  open NUMERIC NOT NULL,
  high NUMERIC NOT NULL,
  low NUMERIC NOT NULL,
  close NUMERIC NOT NULL,

  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool (id) ON DELETE CASCADE,
  FOREIGN KEY (token_address) REFERENCES contract (address) ON DELETE NO ACTION,
  CONSTRAINT unique_candlestick_day UNIQUE (pool_id, token_address, timeframe)
);
CREATE INDEX IF NOT EXISTS candlestick_day_pool_id ON candlestick_day (pool_id);
CREATE INDEX IF NOT EXISTS candlestick_day_timeframe ON candlestick_day (timeframe);
CREATE INDEX IF NOT EXISTS candlestick_day_token_address ON candlestick_day (token_address);

CREATE TABLE IF NOT EXISTS candlestick_week(
  id SERIAL PRIMARY KEY,

  pool_id BIGINT NOT NULL,
  token_address CHAR(42) NOT NULL,

  open NUMERIC NOT NULL,
  high NUMERIC NOT NULL,
  low NUMERIC NOT NULL,
  close NUMERIC NOT NULL,

  timeframe TIMESTAMPTZ NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool (id) ON DELETE CASCADE,
  FOREIGN KEY (token_address) REFERENCES contract (address) ON DELETE NO ACTION,
  CONSTRAINT unique_candlestick_week UNIQUE (pool_id, token_address, timeframe)
);
CREATE INDEX IF NOT EXISTS candlestick_week_pool_id ON candlestick_week (pool_id);
CREATE INDEX IF NOT EXISTS candlestick_week_timeframe ON candlestick_week (timeframe);
CREATE INDEX IF NOT EXISTS candlestick_week_token_address ON candlestick_week (token_address);

-- Candlestick insert procedure
CREATE OR REPLACE FUNCTION candlestick_insert() RETURNS TRIGGER AS $$
  BEGIN
    -- Insert minute candlestick
    INSERT INTO candlestick_min
      (pool_id, token_address, open, high, low, close, timeframe)
    VALUES
      (NEW.pool_id, NEW.token_address, NEW.open, NEW.high, NEW.low, NEW.close, date_trunc('minute', NEW.timestamp))
    ON CONFLICT (pool_id, token_address, timeframe) DO UPDATE SET
      high = GREATEST(NEW.high, candlestick_min.high),
      low = LEAST(NEW.low, candlestick_min.low),
      close = NEW.close;

    -- Insert hourly candlestick
    INSERT INTO candlestick_hour
      (pool_id, token_address, open, high, low, close, timeframe)
    VALUES
      (NEW.pool_id, NEW.token_address, NEW.open, NEW.high, NEW.low, NEW.close, date_trunc('hour', NEW.timestamp))
    ON CONFLICT (pool_id, token_address, timeframe) DO UPDATE SET
      high = GREATEST(NEW.high, candlestick_hour.high),
      low = LEAST(NEW.low, candlestick_hour.low),
      close = NEW.close;

    -- Insert daily candlestick
    INSERT INTO candlestick_day
      (pool_id, token_address, open, high, low, close, timeframe)
    VALUES
      (NEW.pool_id, NEW.token_address, NEW.open, NEW.high, NEW.low, NEW.close, date_trunc('day', NEW.timestamp))
    ON CONFLICT (pool_id, token_address, timeframe) DO UPDATE SET
      high = GREATEST(NEW.high, candlestick_day.high),
      low = LEAST(NEW.low, candlestick_day.low),
      close = NEW.close;

    -- Insert weekly candlestick
    INSERT INTO candlestick_week
      (pool_id, token_address, open, high, low, close, timeframe)
    VALUES
      (NEW.pool_id, NEW.token_address, NEW.open, NEW.high, NEW.low, NEW.close, date_trunc('week', NEW.timestamp))
    ON CONFLICT (pool_id, token_address, timeframe) DO UPDATE SET
      high = GREATEST(NEW.high, candlestick_week.high),
      low = LEAST(NEW.low, candlestick_week.low),
      close = NEW.close;

    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

-- Candlestick trigger
CREATE TRIGGER candlestick_trigger 
  AFTER INSERT ON candlestick 
  FOR EACH ROW EXECUTE PROCEDURE candlestick_insert();


-- Fee raw views
CREATE OR REPLACE FUNCTION fee_raw_prepare(_tbl regclass)
  RETURNS TABLE (
    pool_id BIGINT,
    fee_1 NUMERIC,
    fee_2 NUMERIC,
    timeframe TIMESTAMPTZ
  ) AS $$
  BEGIN
    RETURN QUERY
      EXECUTE format('SELECT pool_id, volume_1 * 0.003 AS fee_1, volume_2 * 0.003 AS fee_2, timeframe FROM %s', _tbl);
  END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE VIEW fee_raw AS 
  SELECT
    pool_id,
    block_id,
    volume_1 * 0.003 AS fee_1,
    volume_2 * 0.003 AS fee_2,
    timestamp
  FROM volume_raw;

CREATE OR REPLACE VIEW fee_raw_min AS 
  SELECT * FROM fee_raw_prepare('volume_raw_min');
CREATE OR REPLACE VIEW fee_raw_hour AS
  SELECT * FROM fee_raw_prepare('volume_raw_hour');
CREATE OR REPLACE VIEW fee_raw_day AS
  SELECT * FROM fee_raw_prepare('volume_raw_day');
CREATE OR REPLACE VIEW fee_raw_week AS
  SELECT * FROM fee_raw_prepare('volume_raw_week');

-- Pricing module
-- Function accepts table name from which values are taken with _col argument and multiplied with token price
-- _timeframe argument is used to select timeframe of the table. I.E. min, hour, day, week
CREATE OR REPLACE FUNCTION pricing_module(_tbl text, _timeframe text)
  RETURNS TABLE (
    pool_id BIGINT,
    timeframe TIMESTAMPTZ,
    value NUMERIC
  ) AS $$
  BEGIN
    RETURN QUERY
      EXECUTE format('SELECT v.pool_id, v.timeframe, v.%1$s_1 * t1.price + v.%1$s_2 * t2.price AS value FROM %1$s_raw_%2$s AS v JOIN pool AS p ON p.id = v.pool_id JOIN token_price_%2$s AS t1 ON p.token_1 = t1.token_address AND v.timeframe = t1.timeframe JOIN token_price_%2$s AS t2 ON p.token_2 = t2.token_address AND v.timeframe = t2.timeframe', _tbl, _timeframe);
  END; $$
LANGUAGE plpgsql;

-- The same as above only this function is resolving base values I.E. with block id
CREATE OR REPLACE FUNCTION pricing_base(_tbl text)
  RETURNS TABLE (
    block_id INT,
    pool_id BIGINT,
    timeframe TIMESTAMPTZ,
    value NUMERIC
  ) AS $$
  BEGIN
    RETURN QUERY
     EXECUTE format('SELECT v.block_id, v.pool_id, v.timestamp, v.%1$s_1 * t1.price + v.%1$s_2 * t2.price AS value FROM %1$s_raw AS v JOIN pool AS p ON p.id = v.pool_id JOIN token_price AS t1 ON p.token_1 = t1.token_address AND v.block_id = t1.block_id JOIN token_price AS t2 ON p.token_2 = t2.token_address AND v.block_id = t2.block_id', _tbl);
  END; $$
LANGUAGE plpgsql;


-- Volume views
CREATE OR REPLACE VIEW volume AS 
  SELECT block_id, pool_id, timeframe, value as volume
  FROM pricing_base('volume');

CREATE OR REPLACE VIEW volume_min AS
  SELECT pool_id, timeframe, value AS volume 
  FROM pricing_module('volume', 'min');

CREATE OR REPLACE VIEW volume_hour AS
  SELECT pool_id, timeframe, value AS volume 
  FROM pricing_module('volume', 'hour');

CREATE OR REPLACE VIEW volume_day AS
  SELECT pool_id, timeframe, value AS volume 
  FROM pricing_module('volume', 'day');

CREATE OR REPLACE VIEW volume_week AS
  SELECT pool_id, timeframe, value AS volume 
  FROM pricing_module('volume', 'week');

-- Reserves views
CREATE OR REPLACE VIEW reserved AS 
  SELECT block_id, pool_id, timeframe, value as reserved
  FROM pricing_base('reserved');

CREATE OR REPLACE VIEW reserved_min AS
  SELECT pool_id, timeframe, value AS reserved 
  FROM pricing_module('reserved', 'min');

CREATE OR REPLACE VIEW reserved_hour AS
  SELECT pool_id, timeframe, value AS reserved 
  FROM pricing_module('reserved', 'hour');

CREATE OR REPLACE VIEW reserved_day AS
  SELECT pool_id, timeframe, value AS reserved 
  FROM pricing_module('reserved', 'day');

CREATE OR REPLACE VIEW reserved_week AS
  SELECT pool_id, timeframe, value AS reserved 
  FROM pricing_module('reserved', 'week');

--  Fee views
CREATE OR REPLACE VIEW fee AS 
  SELECT block_id, pool_id, timeframe, value as fee
  FROM pricing_base('fee');

CREATE OR REPLACE VIEW fee_min AS
  SELECT pool_id, timeframe, value AS fee 
  FROM pricing_module('fee', 'min');

CREATE OR REPLACE VIEW fee_hour AS
  SELECT pool_id, timeframe, value AS fee 
  FROM pricing_module('fee', 'hour');

CREATE OR REPLACE VIEW fee_day AS
  SELECT pool_id, timeframe, value AS fee 
  FROM pricing_module('fee', 'day');

CREATE OR REPLACE VIEW fee_week AS
  SELECT pool_id, timeframe, value AS fee 
  FROM pricing_module('fee', 'week');

-- Volume change views
CREATE OR REPLACE VIEW volume_change AS
  SELECT
    v.pool_id,
    v.block_id,
    v.timeframe,
    change(v.volume, LAG(v.volume) OVER (PARTITION BY v.pool_id ORDER BY v.timeframe)) AS volume_change
  FROM volume AS v;

CREATE OR REPLACE VIEW volume_change_min AS
  SELECT
    v.pool_id,
    v.timeframe,
    change(v.volume, LAG(v.volume) OVER (PARTITION BY v.pool_id ORDER BY v.timeframe)) AS volume_change
  FROM volume_min AS v;

CREATE OR REPLACE VIEW volume_change_hour AS
  SELECT
    v.pool_id,
    v.timeframe,
    change(v.volume, LAG(v.volume) OVER (PARTITION BY v.pool_id ORDER BY v.timeframe)) AS volume_change
  FROM volume_hour AS v;

CREATE OR REPLACE VIEW volume_change_day AS
  SELECT
    v.pool_id,
    v.timeframe,
    change(v.volume, LAG(v.volume) OVER (PARTITION BY v.pool_id ORDER BY v.timeframe)) AS volume_change
  FROM volume_day AS v;

CREATE OR REPLACE VIEW volume_change_week AS
  SELECT
    v.pool_id,
    v.timeframe,
    change(v.volume, LAG(v.volume) OVER (PARTITION BY v.pool_id ORDER BY v.timeframe)) AS volume_change
  FROM volume_week AS v;

-- Pool last info
 CREATE TABLE pool_last_info (
  pool_id BIGINT PRIMARY KEY,
  
  fee NUMERIC NOT NULL,
  volume NUMERIC NOT NULL,
  reserved NUMERIC NOT NULL,
  volume_change NUMERIC NOT NULL,

  FOREIGN KEY (pool_id) REFERENCES pool(id) ON DELETE CASCADE
);

-- Every time new pool is created we need to insert it's info into pool_last_info
-- All values are set to 0
CREATE OR REPLACE FUNCTION create_pool_last_info() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO pool_last_info 
    (pool_id, fee, volume, reserved, volume_change)
  VALUES 
    (NEW.id, 0, 0, 0, 0);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_pool_last_info_trigger
  AFTER INSERT ON pool
  FOR EACH ROW
  EXECUTE PROCEDURE create_pool_last_info();

-- Trigger for updating pool_last_info based on the new volume
CREATE OR REPLACE FUNCTION update_pool_last_info_volume() RETURNS TRIGGER AS $$
DECLARE
  block_id BIGINT;
  pool_pointer BIGINT;
  current_volume NUMERIC;
  prev_volume NUMERIC;
BEGIN
  SELECT MAX(id) INTO block_id FROM block WHERE finalized = true;
  SELECT last_value INTO pool_pointer FROM pool_event_sequence;

  -- Only updating pool_last_info when pool_pointer is aligned with last finalized block id
  IF block_id = pool_pointer THEN
    -- Selecting last 24 pool volume
    SELECT 
      SUM(volume) INTO current_volume 
    FROM volume 
    WHERE 
      pool_id = NEW.pool_id AND 
      timeframe >= NOW() - INTERVAL '1 day';

    -- Selecting previous 24 pool volume
    SELECT 
      SUM(volume) INTO prev_volume 
    FROM volume 
    WHERE 
      pool_id = NEW.pool_id AND 
      timeframe >= NOW() - INTERVAL '2 day' AND
      timeframe < NOW() - INTERVAL '1 day';

    -- Updating volume and fee
    UPDATE pool_last_info
    SET 
      volume = current_volume,
      fee = current_volume * 0.003,
      volume_change = change(current_volume, prev_volume)
    WHERE pool_id = NEW.pool_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_pool_last_info_volume_trigger
  AFTER INSERT ON volume_raw
  FOR EACH ROW
  EXECUTE PROCEDURE update_pool_last_info_volume();

-- Trigger for updating pool_last_info based on the new reserved
CREATE OR REPLACE FUNCTION update_pool_last_info_reserved() RETURNS TRIGGER AS $$
DECLARE
  block_id BIGINT;
  pool_pointer BIGINT;
  current_reserved NUMERIC;
BEGIN
  SELECT MAX(id) INTO block_id FROM block WHERE finalized = true;
  SELECT last_value INTO pool_pointer FROM pool_event_sequence;

  -- Only updating pool_last_info when pool_pointer is aligned with last finalized block id
  IF block_id = pool_pointer THEN
    -- Selecting last pool reserved
    SELECT reserved INTO current_reserved 
    FROM reserved 
    WHERE pool_id = NEW.pool_id
    ORDER BY timeframe DESC 
    LIMIT 1;
    -- Updating reserved
    UPDATE pool_last_info
    SET reserved = current_reserved
    WHERE pool_id = NEW.pool_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_pool_last_info_reserved_trigger
  AFTER INSERT ON reserved_raw
  FOR EACH ROW
  EXECUTE PROCEDURE update_pool_last_info_reserved();
