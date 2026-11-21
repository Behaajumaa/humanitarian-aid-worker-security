/* =====================================================================
   Project 07 - Humanitarian Aid Worker Security (AWSD 1997-2024)
   Data cleaning in SQL (SQLite dialect)
   Input : raw_incidents   (all columns TEXT, loaded by 01_load_raw.py)
   Output: stg_incidents -> fact_incidents, dim_country, dq_log
   ===================================================================== */

DROP TABLE IF EXISTS dq_log;
CREATE TABLE dq_log (step INTEGER, issue TEXT, rows_affected INTEGER, action TEXT);

/* ---------- 0. Profile what we start with ---------- */
INSERT INTO dq_log SELECT 0, 'Raw rows loaded', COUNT(*), 'Baseline' FROM raw_incidents;
INSERT INTO dq_log SELECT 0, 'Duplicate incident_id', COUNT(*) - COUNT(DISTINCT incident_id), 'None found - no action' FROM raw_incidents;

/* ---------- 1. Staging: trim whitespace / line breaks, blanks -> NULL ---------- */
DROP TABLE IF EXISTS stg_incidents;
CREATE TABLE stg_incidents AS
SELECT
  CAST(incident_id AS INTEGER)                                   AS incident_id,
  CAST(year  AS INTEGER)                                         AS year,
  CAST(NULLIF(TRIM(month),'') AS REAL)                           AS month,
  CAST(NULLIF(TRIM(day),'')   AS REAL)                           AS day,
  NULLIF(TRIM(date),'')                                          AS date,
  NULLIF(TRIM(country_code),'')                                  AS country_code,
  NULLIF(TRIM(country),'')                                       AS country,
  NULLIF(TRIM(region),'')                                        AS region,
  NULLIF(TRIM(district),'')                                      AS district,
  NULLIF(TRIM(city),'')                                          AS city,
  CAST(un AS INTEGER) AS un, CAST(ingo AS INTEGER) AS ingo,
  CAST(NULLIF(icrc,'') AS INTEGER)          AS icrc,
  CAST(NULLIF(nrcs_and_ifrc,'') AS INTEGER) AS nrcs_and_ifrc,
  CAST(NULLIF(nngo,'') AS INTEGER)          AS nngo,
  CAST(other AS INTEGER) AS other,
  CAST(nationals_killed AS INTEGER) AS nationals_killed,
  CAST(nationals_wounded AS INTEGER) AS nationals_wounded,
  CAST(nationals_kidnapped AS INTEGER) AS nationals_kidnapped,
  CAST(total_nationals AS INTEGER) AS total_nationals,
  CAST(internationals_killed AS INTEGER) AS internationals_killed,
  CAST(internationals_wounded AS INTEGER) AS internationals_wounded,
  CAST(internationals_kidnapped AS INTEGER) AS internationals_kidnapped,
  CAST(total_internationals AS INTEGER) AS total_internationals,
  CAST(total_killed AS INTEGER) AS total_killed,
  CAST(total_wounded AS INTEGER) AS total_wounded,
  CAST(total_kidnapped AS INTEGER) AS total_kidnapped,
  CAST(total_affected AS INTEGER) AS total_affected,
  CAST(gender_male AS INTEGER) AS gender_male,
  CAST(gender_female AS INTEGER) AS gender_female,
  CAST(gender_unknown AS INTEGER) AS gender_unknown,
  TRIM(means_of_attack, ' '||char(9)||char(10)||char(13))  AS means_of_attack,
  TRIM(attack_context,  ' '||char(9)||char(10)||char(13))  AS attack_context,
  TRIM(location,        ' '||char(9)||char(10)||char(13))  AS location,
  CAST(NULLIF(latitude,'')  AS REAL) AS latitude,
  CAST(NULLIF(longitude,'') AS REAL) AS longitude,
  NULLIF(TRIM(motive),'')      AS motive,
  TRIM(actor_type, ' '||char(9)||char(10)||char(13)) AS actor_type,
  NULLIF(TRIM(actor_name),'')  AS actor_name,
  TRIM(details, ' '||char(9)||char(10)||char(13))    AS details,
  NULLIF(TRIM(verified),'')    AS verified,
  TRIM(source, ' '||char(9)||char(10)||char(13))     AS source
FROM raw_incidents;

INSERT INTO dq_log SELECT 1, 'Text values with leading/trailing spaces or line breaks', COUNT(*),
  'Trimmed (means_of_attack, actor_type, source, details ...)'
FROM raw_incidents
WHERE means_of_attack <> TRIM(means_of_attack) OR actor_type <> TRIM(actor_type)
   OR source <> TRIM(source) OR details <> TRIM(details, ' '||char(10)||char(13));

/* ---------- 2. Standardise categorical spellings ---------- */
INSERT INTO dq_log SELECT 2, 'Inconsistent source labels (case / typo: "media", "Focal point", "Offiicial Report")',
  COUNT(*), 'Mapped to 5 standard labels' FROM stg_incidents
WHERE source NOT IN ('Official Report','Focal Point','Archived','Media','ACLED');
UPDATE stg_incidents SET source =
  CASE LOWER(source)
    WHEN 'official report'  THEN 'Official Report'
    WHEN 'offiicial report' THEN 'Official Report'
    WHEN 'focal point'      THEN 'Focal Point'
    WHEN 'media'            THEN 'Media'
    WHEN 'acled'            THEN 'ACLED'
    WHEN 'archived'         THEN 'Archived'
    ELSE source END;

INSERT INTO dq_log SELECT 2, 'verified = "Pen" (truncated) or blank', COUNT(*), '"Pen" -> Pending, blank -> Unknown'
FROM stg_incidents WHERE verified IS NULL OR verified = 'Pen';
UPDATE stg_incidents SET verified = CASE WHEN verified = 'Pen' THEN 'Pending' WHEN verified IS NULL THEN 'Unknown' ELSE verified END;

INSERT INTO dq_log SELECT 2, 'actor_type case variants ("Host State" vs "Host state", "State: unknown")', COUNT(*), 'Unified spelling'
FROM stg_incidents WHERE actor_type IN ('Host State','State: unknown');
UPDATE stg_incidents SET actor_type = CASE actor_type WHEN 'Host State' THEN 'Host state'
                                                      WHEN 'State: unknown' THEN 'State: Unknown' ELSE actor_type END;

INSERT INTO dq_log SELECT 2, 'Missing motive / actor_name', COUNT(*), 'Set to Unknown'
FROM stg_incidents WHERE motive IS NULL OR actor_name IS NULL;
UPDATE stg_incidents SET motive = COALESCE(motive,'Unknown'), actor_name = COALESCE(actor_name,'Unknown');

/* ---------- 3. Country names & codes ---------- */
INSERT INTO dq_log SELECT 3, 'Missing country (ICRC year-level records, no location)', COUNT(*), 'Country = "Unknown", code = "XX"'
FROM stg_incidents WHERE country IS NULL;
INSERT INTO dq_log SELECT 3, 'Missing ISO code for disputed areas (Chechnya, Kashmir)', COUNT(*), 'Code = "XX", country kept'
FROM stg_incidents WHERE country IS NOT NULL AND country_code IS NULL;
INSERT INTO dq_log SELECT 3, 'Outdated / formal country names (Syrian Arab Republic, Libyan Arab Jamahiriya, Swaziland ...)', COUNT(*), 'Renamed to current short names'
FROM stg_incidents WHERE country IN ('Syrian Arab Republic','Iran, Islamic Republic of','Libyan Arab Jamahiriya','Swaziland','Cote D''Ivoire','Occupied Palestinian Territories');

UPDATE stg_incidents SET
  country = CASE country
    WHEN 'Syrian Arab Republic'             THEN 'Syria'
    WHEN 'Iran, Islamic Republic of'        THEN 'Iran'
    WHEN 'Libyan Arab Jamahiriya'           THEN 'Libya'
    WHEN 'Swaziland'                        THEN 'Eswatini'
    WHEN 'Cote D''Ivoire'                   THEN 'Côte d''Ivoire'
    WHEN 'Occupied Palestinian Territories' THEN 'Occupied Palestinian Territory'
    ELSE COALESCE(country,'Unknown') END,
  country_code = COALESCE(country_code,'XX'),
  region   = COALESCE(region,'Unknown'),
  district = COALESCE(district,'Unknown'),
  city     = COALESCE(city,'Unknown');

/* ---------- 4. Organisation counts: NULL -> 0 ---------- */
INSERT INTO dq_log SELECT 4, 'NULL in icrc / nrcs_and_ifrc / nngo', COUNT(*), 'Set to 0 (row totals already match UN+INGO)'
FROM stg_incidents WHERE icrc IS NULL OR nrcs_and_ifrc IS NULL OR nngo IS NULL;
UPDATE stg_incidents SET icrc = COALESCE(icrc,0), nrcs_and_ifrc = COALESCE(nrcs_and_ifrc,0), nngo = COALESCE(nngo,0);

/* ---------- 5. Dates ---------- */
INSERT INTO dq_log SELECT 5, 'Incident date unknown (day and/or month missing)', COUNT(*), 'Kept; date_precision flag added, period_date = 1st of known month / Jan 1'
FROM stg_incidents WHERE date IS NULL;
INSERT INTO dq_log SELECT 5, 'Date year differs from year column', COUNT(*), 'None found'
FROM stg_incidents WHERE date IS NOT NULL AND CAST(substr(date,1,4) AS INTEGER) <> year;

/* ---------- 6. Arithmetic consistency checks ---------- */
INSERT INTO dq_log SELECT 6, 'nationals + internationals <> total_affected', COUNT(*), 'Check only'
FROM stg_incidents WHERE total_nationals + total_internationals <> total_affected;
INSERT INTO dq_log SELECT 6, 'killed + wounded + kidnapped <> total_affected', COUNT(*), 'Check only'
FROM stg_incidents WHERE total_killed + total_wounded + total_kidnapped <> total_affected;
INSERT INTO dq_log SELECT 6, 'gender split <> total_affected', COUNT(*), 'Flagged in dq_flag'
FROM stg_incidents WHERE gender_male + gender_female + gender_unknown <> total_affected;
INSERT INTO dq_log SELECT 6, 'organisation split <> total_affected', COUNT(*), 'Flagged in dq_flag'
FROM stg_incidents WHERE un+ingo+icrc+nrcs_and_ifrc+nngo+other <> total_affected;
INSERT INTO dq_log SELECT 6, 'Missing coordinates', COUNT(*), 'Kept; has_coordinates = 0 (excluded from map only)'
FROM stg_incidents WHERE latitude IS NULL;
INSERT INTO dq_log SELECT 6, 'Redundant column location_2 (WKT copy of lat/long)', COUNT(*), 'Dropped'
FROM stg_incidents;

/* ---------- 7. Country dimension with world region ---------- */
DROP TABLE IF EXISTS dim_country;
CREATE TABLE dim_country AS
SELECT DISTINCT country, country_code,
  CASE
    WHEN country IN ('Algeria','Egypt','Iran','Iraq','Israel','Jordan','Lebanon','Libya','Occupied Palestinian Territory',
                     'Saudi Arabia','Syria','Tunisia','Western Sahara','Yemen') THEN 'Middle East & North Africa'
    WHEN country IN ('Afghanistan','Bangladesh','India','Kashmir','Nepal','Pakistan','Sri Lanka','Kyrgyzstan','Tajikistan')
         THEN 'South & Central Asia'
    WHEN country IN ('Cambodia','Fiji','Indonesia','Myanmar','Papua New Guinea','Philippines','Thailand','Vietnam')
         THEN 'East Asia & Pacific'
    WHEN country IN ('Armenia','Azerbaijan','Chechnya','Georgia','Kosovo','Poland','Turkey','Ukraine')
         THEN 'Europe & Caucasus'
    WHEN country IN ('Argentina','Bolivia','Chile','Colombia','Dominican Republic','Ecuador','El Salvador','Guatemala','Guyana',
                     'Haiti','Honduras','Mexico','Nicaragua','Peru','Uruguay','Venezuela') THEN 'Americas'
    WHEN country = 'Unknown' THEN 'Unknown'
    ELSE 'Sub-Saharan Africa' END AS world_region
FROM stg_incidents;

/* ---------- 8. Final fact table ---------- */
DROP TABLE IF EXISTS fact_incidents;
CREATE TABLE fact_incidents AS
SELECT
  incident_id, year,
  CAST(month AS INTEGER) AS month, CAST(day AS INTEGER) AS day,
  date AS incident_date,
  CASE WHEN date IS NOT NULL THEN 'Exact day' WHEN month IS NOT NULL THEN 'Month only' ELSE 'Year only' END AS date_precision,
  printf('%04d-%02d-%02d', year, COALESCE(CAST(month AS INTEGER),1), COALESCE(CAST(day AS INTEGER),1)) AS period_date,
  country_code, country, region AS admin1, district, city,
  un, ingo, icrc, nrcs_and_ifrc, nngo, other,
  CASE WHEN un >= MAX(ingo,icrc,nrcs_and_ifrc,nngo,other) AND un > 0 THEN 'UN'
       WHEN ingo >= MAX(icrc,nrcs_and_ifrc,nngo,other) AND ingo > 0 THEN 'INGO'
       WHEN nngo >= MAX(icrc,nrcs_and_ifrc,other) AND nngo > 0 THEN 'National NGO'
       WHEN nrcs_and_ifrc >= MAX(icrc,other) AND nrcs_and_ifrc > 0 THEN 'Red Cross/Crescent (NS & IFRC)'
       WHEN icrc > 0 THEN 'ICRC' ELSE 'Other' END AS main_org_type,
  nationals_killed, nationals_wounded, nationals_kidnapped, total_nationals,
  internationals_killed, internationals_wounded, internationals_kidnapped, total_internationals,
  total_killed, total_wounded, total_kidnapped, total_affected,
  gender_male, gender_female, gender_unknown,
  means_of_attack,
  CASE WHEN means_of_attack IN ('Aerial bombardment','Shelling','Vehicle-born IED','Roadside IED','Body-borne IED',
                                'Landmine','Other Explosives','Complex attack') THEN 'Explosive weapons'
       WHEN means_of_attack IN ('Kidnapping','Kidnap-killing') THEN 'Kidnapping'
       WHEN means_of_attack = 'Shooting' THEN 'Shooting'
       WHEN means_of_attack IN ('Bodily assault','Rape/sexual assault') THEN 'Assault'
       ELSE 'Unknown' END AS attack_category,
  attack_context, location AS location_type,
  latitude, longitude, CASE WHEN latitude IS NULL THEN 0 ELSE 1 END AS has_coordinates,
  motive, actor_type,
  CASE WHEN actor_type LIKE 'Non-state armed group%' THEN 'Non-state armed group'
       WHEN actor_type IN ('Host state','State: Unknown','Police or paramilitary') THEN 'State actors'
       WHEN actor_type = 'Foreign or coalition forces' THEN 'Foreign/coalition forces'
       WHEN actor_type IN ('Criminal','Unaffiliated','Aid recipient','Staff member') THEN 'Other actors'
       ELSE 'Unknown' END AS actor_group,
  actor_name, verified, source,
  CASE WHEN year = 2024 THEN 1 ELSE 0 END AS is_partial_year,
  CASE WHEN gender_male+gender_female+gender_unknown <> total_affected THEN 'Gender split mismatch'
       WHEN un+ingo+icrc+nrcs_and_ifrc+nngo+other <> total_affected THEN 'Org split mismatch'
       ELSE 'OK' END AS dq_flag,
  details
FROM stg_incidents
ORDER BY year, period_date, incident_id;

INSERT INTO dq_log SELECT 9, 'Final rows in fact_incidents', COUNT(*), '100% of raw rows retained' FROM fact_incidents;
