# Who Protects the Protectors? — Humanitarian Aid Worker Security Analysis

Security incidents against humanitarian aid workers, 1997–2024.

- **Dataset:** [Aid Worker Security Incidents 1997–2024](https://www.kaggle.com/) (Kaggle, CC0), sourced from the Aid Worker Security Database (AWSD). 4,153 incidents × 43 columns, spanning 94 countries/territories.
- **Tools:** SQL (SQLite) for cleaning and analysis, Python for loading and chart generation, Power BI for the dashboard.

## Headline findings

- **4,153** security incidents · **7,852** aid workers affected · **2,871** killed · **89%** were national staff
- **Violence is rising.** The last six years (2019–2024) hold 38% of all incidents. 2023 was the worst year on record, with 595 aid workers affected and 280 killed.
- **Local staff carry the risk.** National staff are 89% of everyone affected and 92% of everyone killed.
- **Six crises dominate.** Afghanistan, South Sudan, Sudan, Syria, Somalia and the Occupied Palestinian Territory account for 57% of all aid workers affected.
- **The road is the most dangerous place.** 37% of victims were attacked on the road and 36% in ambushes.
- **Weapon type decides survival odds.** Kidnapping affects the most people (2,294) but kills 9% of them; shootings kill 59%; explosive weapons kill 52%.
- **Reporting gaps remain.** The perpetrator is unknown for 48% of victims and the motive for 45% of incidents.

## Data cleaning (SQL)

The raw CSV was loaded into SQLite with every column stored as text on import — so values were never silently altered (e.g. Namibia's ISO code "NA" staying intact instead of becoming a blank). All cleaning logic lives in one script (`scripts/02_clean_incidents.sql`), and every step logs what it found and fixed to a data-quality table (`data/clean/dq_log.csv`) — nothing was dropped silently.

## Repository structure

```
data/raw/      original Kaggle download (untouched)
data/clean/    cleaned fact/dimension tables + the full data-quality log
scripts/       Python load script + SQL cleaning and analysis queries
report/        full write-up (Aid_Worker_Security_Report.docx) + chart figures
design/        design exploration notes and the options overview
powerbi/       two finished Power BI report variants (see below)
```

## Power BI dashboards

Two finished design directions, both built on the same cleaned model:

- **B — Night Ops:** a dark, high-contrast operational briefing style.
- **C — Field Journal:** a lighter, editorial report style.

Open either `.pbip` file in Power BI Desktop to explore.

## Full report

The complete write-up — methodology, every cleaning step, and the full set of findings — is in [`report/Aid_Worker_Security_Report.docx`](report/Aid_Worker_Security_Report.docx).

---
Prepared by Behaa Jumaa · November 2026
