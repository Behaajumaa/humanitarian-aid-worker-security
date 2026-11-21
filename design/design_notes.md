# P07 Aid Worker Security — Dashboard design v1 ("Field Briefing")

Canvas: 1280 x 720 (Power BI 16:9). Style taken from datatraining.io: light grey canvas, white cards with soft shadows, one dark navy hero card, bold Sora headlines, Geist body, Geist Mono "/01" eyebrow labels, violet accent.

## Palette — "Violet Signal"
| Role | Hex |
|---|---|
| Canvas | #ECEEF3 |
| Ink (headlines, numbers) | #0B101F |
| Dark card | #0F1426 |
| Body text | #363B43 |
| Primary accent / affected | #5B2BDA |
| Secondary / kidnapped | #9B7BFF |
| Killed line (dark card) / National NGO | #47D7AD |
| Wounded / Red Cross | #FF9800 |
| Killed (bars, fatality chips) | #E5484D |

## Layout (different from JUSSOR + P01/P02 pages)
- No top nav bar, no icon sidebar, no filter side panel.
- Left editorial column: headline, 4 stacked numbered KPIs, compact filter card.
- Right bento: dark trend card + map card on top; How / Who / Top countries below.
- New visual types for the portfolio: waffle chart, outcome-stacked bars with fatality chips, lollipop ranking, dot-density map.

## Power BI visuals
| Area | Visual | Fields |
|---|---|---|
| /01–/04 | Card (new) x4 | Incidents, Affected, Killed, % National staff |
| /05 | Column + line (combo), field-parameter toggle Affected/Incidents | year · Affected, Killed |
| /06 | Azure/ArcGIS map bubbles + bar | latitude, longitude, total_affected · world_region |
| /07 | Stacked bar + card | attack_category · killed/wounded/kidnapped; fatality rate |
| /08 | Waffle (Deneb or 100-square matrix) + 100% stacked bar | nationals vs internationals; org columns |
| /09 | Table with data bars / lollipop (Deneb) | country, Affected, Fatality rate |
| Filters | Slicers | year, world_region, attack_category, staff type, main_org_type |
