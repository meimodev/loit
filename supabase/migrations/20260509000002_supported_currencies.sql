-- ================================================================
-- supported_currencies: registry of fiat currencies the app supports.
-- ================================================================
-- Canonical source for: snapshot key set, currency picker UI,
-- fx-rate-refresh symbols list. Loaded once at app start by client.
-- ================================================================

CREATE TABLE supported_currencies (
  code          text PRIMARY KEY,
  name          text NOT NULL,
  symbol        text NOT NULL,
  display_order int  NOT NULL UNIQUE
);

ALTER TABLE supported_currencies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "supported_currencies_select_all" ON supported_currencies
  FOR SELECT TO authenticated USING (true);

INSERT INTO supported_currencies (code, name, symbol, display_order) VALUES
  ('INR', 'Indian Rupee',          '₹',     1),
  ('CNY', 'Chinese Yuan',          '¥',     2),
  ('USD', 'US Dollar',             '$',     3),
  ('EUR', 'Euro',                  '€',     4),
  ('IDR', 'Indonesian Rupiah',     'Rp',    5),
  ('PKR', 'Pakistani Rupee',       '₨',     6),
  ('NGN', 'Nigerian Naira',        '₦',     7),
  ('BRL', 'Brazilian Real',        'R$',    8),
  ('BDT', 'Bangladeshi Taka',      '৳',     9),
  ('RUB', 'Russian Ruble',         '₽',     10),
  ('ETB', 'Ethiopian Birr',        'Br',    11),
  ('MXN', 'Mexican Peso',          '$',     12),
  ('JPY', 'Japanese Yen',          '¥',     13),
  ('PHP', 'Philippine Peso',       '₱',     14),
  ('EGP', 'Egyptian Pound',        '£',     15),
  ('CDF', 'Congolese Franc',       'FC',    16),
  ('VND', 'Vietnamese Dong',       '₫',     17),
  ('IRR', 'Iranian Rial',          '﷼',    18),
  ('TRY', 'Turkish Lira',          '₺',     19),
  ('THB', 'Thai Baht',             '฿',     20),
  ('TZS', 'Tanzanian Shilling',    'TSh',   21),
  ('GBP', 'British Pound',         '£',     22),
  ('ZAR', 'South African Rand',    'R',     23),
  ('KES', 'Kenyan Shilling',       'KSh',   24),
  ('COP', 'Colombian Peso',        '$',     25),
  ('KRW', 'South Korean Won',      '₩',     26),
  ('DZD', 'Algerian Dinar',        'د.ج',   27),
  ('IQD', 'Iraqi Dinar',           'ع.د',   28),
  ('ARS', 'Argentine Peso',        '$',     29),
  ('CAD', 'Canadian Dollar',       '$',     30),
  ('PLN', 'Polish Zloty',          'zł',    31),
  ('MAD', 'Moroccan Dirham',       'د.م.',  32),
  ('UAH', 'Ukrainian Hryvnia',     '₴',     33),
  ('MYR', 'Malaysian Ringgit',     'RM',    34),
  ('SAR', 'Saudi Riyal',           '﷼',    35),
  ('PEN', 'Peruvian Sol',          'S/.',   36),
  ('AUD', 'Australian Dollar',     '$',     37),
  ('TWD', 'New Taiwan Dollar',     'NT$',   38),
  ('KZT', 'Kazakhstani Tenge',     '₸',     39),
  ('CLP', 'Chilean Peso',          '$',     40),
  ('RON', 'Romanian Leu',          'lei',   41),
  ('KHR', 'Cambodian Riel',        '៛',     42),
  ('AED', 'UAE Dirham',            'د.إ',   43),
  ('SEK', 'Swedish Krona',         'kr',    44),
  ('CZK', 'Czech Koruna',          'Kč',    45),
  ('ILS', 'Israeli Shekel',        '₪',     46),
  ('HUF', 'Hungarian Forint',      'Ft',    47),
  ('BYN', 'Belarusian Ruble',      'Br',    48),
  ('CHF', 'Swiss Franc',           'CHf',   49),
  ('LAK', 'Lao Kip',               '₭',     50),
  ('HKD', 'Hong Kong Dollar',      'HK$',   51),
  ('BGN', 'Bulgarian Lev',         'лв',    52),
  ('RSD', 'Serbian Dinar',         'дин',   53),
  ('SGD', 'Singapore Dollar',      '$',     54),
  ('DKK', 'Danish Krone',          'kr',    55),
  ('NOK', 'Norwegian Krone',       'kr',    56),
  ('NZD', 'New Zealand Dollar',    '$',     57),
  ('KWD', 'Kuwaiti Dinar',         'KD',    58),
  ('MDL', 'Moldovan Leu',          'L',     59),
  ('BAM', 'Bosnia-Herzegovina Mark','KM',   60),
  ('ALL', 'Albanian Lek',          'L',     61),
  ('MKD', 'Macedonian Denar',      'ден',   62),
  ('ISK', 'Icelandic Krona',       'kr',    63);
