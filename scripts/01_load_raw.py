"""Load the raw Kaggle CSV into SQLite as all-TEXT columns (no type guessing,
so Namibia's ISO code 'NA' is not turned into NULL), then run the SQL cleaning script."""
import csv, sqlite3, pathlib, shutil, tempfile
root = pathlib.Path(__file__).resolve().parent.parent
raw = root / "data/raw/security_incidents_2024_11_10_c.csv"
final_db = root / "data/clean/aid_worker_security.sqlite"
# build in a local temp folder (SQLite locking is unreliable on synced/network drives), copy at the end
db = pathlib.Path(tempfile.gettempdir()) / "aid_worker_security.sqlite"
db.unlink(missing_ok=True)
con = sqlite3.connect(db)
with open(raw, newline="", encoding="utf-8") as f:
    r = csv.reader(f); cols = next(r); rows = list(r)
con.execute("CREATE TABLE raw_incidents (" + ",".join(f'"{c}" TEXT' for c in cols) + ")")
con.executemany(f"INSERT INTO raw_incidents VALUES ({','.join('?'*len(cols))})", rows)
con.commit()
print("raw rows loaded:", con.execute("select count(*) from raw_incidents").fetchone()[0])
sql = (root / "scripts/02_clean_incidents.sql").read_text(encoding="utf-8")
con.executescript(sql); con.commit()
for t in ("fact_incidents", "dim_country", "dq_log"):
    print(t, con.execute(f"select count(*) from {t}").fetchone()[0])
# export clean tables for Power BI
for t in ("fact_incidents", "dim_country", "dq_log"):
    cur = con.execute(f"select * from {t}")
    with open(root / f"data/clean/{t}.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f); w.writerow([d[0] for d in cur.description]); w.writerows(cur)
con.close()
shutil.copy(db, final_db)
print("saved", final_db.name)
