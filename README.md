# 🚌 Twin Cities Transit Reliability Pipeline

[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![BigQuery](https://img.shields.io/badge/Google_BigQuery-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white)](https://cloud.google.com/bigquery)
[![dbt](https://img.shields.io/badge/dbt-FF694B?style=for-the-badge&logo=dbt&logoColor=white)](https://www.getdbt.com/)
[![Dagster](https://img.shields.io/badge/Dagster-654FF0?style=for-the-badge&logo=dagster&logoColor=white)](https://dagster.io/)
[![SQL](https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=googlebigquery&logoColor=white)](https://cloud.google.com/bigquery/docs/reference/standard-sql)
[![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)

![Status](https://img.shields.io/badge/Status-Live_&_Collecting-success?style=flat-square)
![Pipeline](https://img.shields.io/badge/Orchestration-Automated_(2_min)-blue?style=flat-square)
![dbt Models](https://img.shields.io/badge/dbt_Models-3-blue?style=flat-square)
![Tests](https://img.shields.io/badge/dbt_Tests-13_Passing-brightgreen?style=flat-square)
![Data](https://img.shields.io/badge/Data-Live_Metro_Transit_API-orange?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

> An end-to-end **ELT data pipeline** that ingests **live** Twin Cities bus &
> train positions every 2 minutes, matches them against the published
> schedule, and measures how reliable each transit route actually is —
> orchestrated automatically and modeled in a cloud data warehouse.

---

## 📌 Why this project

Most portfolio pipelines run on static or synthetic CSV files. **This one
runs on real, live data** — and solves a genuinely non-trivial problem:
inferring *when a bus actually arrived at a stop* from nothing but raw
GPS coordinates streaming in over time. That required geospatial distance
math, careful stop-matching logic, window functions, and timezone-aware
time arithmetic — the same messy realities a real data engineering role
involves: live data, incremental loading, orchestration, and transformation
at scale.

---

## 🏗️ Architecture

```
   Metro Transit Realtime API ──┐
   (live vehicle positions)     │
                                 ├──► Python ──► BigQuery ──► dbt ──► Power BI
   Metro Transit GTFS ──────────┘   (Extract    (Cloud       (SQL     (BI /
   (published schedule, CSV)         + Load)     Warehouse)   Transform) dashboard)
                                          ▲
                              Dagster orchestrates the collector
                                    (scheduled every 2 minutes)
```

**Extract → Load → Transform (ELT):** raw data is landed untouched in the
warehouse first, then transformed in-place with SQL/dbt — the modern
industry-standard pattern.

<!-- Add your dashboard screenshot here once built:
![Dashboard](docs/dashboard.png)
-->

---

## 🧰 Tech stack

| Layer            | Technology                                   |
|------------------|----------------------------------------------|
| **Languages**    | Python, SQL                                  |
| **Ingestion**    | Python (`requests`, `pandas`, `pandas-gbq`)  |
| **Orchestration**| Dagster (scheduled asset, every 2 min)       |
| **Warehouse**    | Google BigQuery                              |
| **Transformation**| dbt (models + data quality tests)           |
| **BI / Dashboard**| Power BI                                     |
| **Version control**| Git & GitHub                               |
| **Auth / Cloud** | Google Cloud IAM, service accounts           |

---

## 🔄 How it works

This pipeline solves a genuinely hard problem: **the live data never says
"the bus arrived at stop X."** It only reports where each vehicle is
(latitude/longitude) at random moments. Turning that into "was this bus on
time?" required real engineering at every stage.

### 1. Extract + Load  (Python + Dagster)
A Python collector calls Metro Transit's live vehicle API every 2 minutes,
filters out non-reporting vehicles (a large share of raw records report
`0,0` coordinates — buses assigned but not yet transmitting GPS),
timestamps each pull, and **appends** the clean records to BigQuery.
**Dagster** runs this on a schedule, so real history accumulates
automatically. Two source types are handled: a **live JSON API** (vehicle
positions) and a **bulk file download** (the GTFS schedule as CSVs).

### 2. Transform  (dbt on BigQuery) — the hard part
The core challenge: reconstruct *arrivals* from raw GPS pings, then compare
them to the schedule. The dbt models do this in stages:

- **Geospatial distance math.** Each vehicle's live coordinates are turned
  into a geography point with `ST_GEOGPOINT(lon, lat)`, and `ST_DISTANCE`
  computes the true great-circle distance (in meters) from the bus to every
  stop on its route. This is the same haversine-style spherical distance
  calculation used in real location systems — done at scale in SQL.

- **Matching a bus to the *correct* stop.** A naive "nearest stop" is
  wrong: a bus can be physically closest to a stop it already passed, or to
  a stop on a different route entirely. The pipeline joins each vehicle to
  **only the stops its own trip is scheduled to serve** (via the schedule's
  `trip_id`), and uses **window functions** (`ROW_NUMBER() OVER (PARTITION
  BY ...)`) to rank stops by distance *per snapshot* — correctly isolating
  which stop each bus was actually at, at each moment in time.

- **Detecting arrival (closest approach).** Because GPS pings are sparse,
  arrival is estimated as the **moment of minimum distance** to each stop —
  found with a second window function that partitions by trip *and* stop and
  keeps the closest observation. Observations beyond a 150 m threshold are
  discarded as "never actually arrived," a deliberate data-quality decision.

- **Timezone-correct lateness.** Timestamps are localized (collector clock →
  Central Time) and the estimated arrival is differenced against the
  scheduled `arrival_time` to compute minutes late. Edge cases are handled
  explicitly: GTFS after-midnight times (e.g. `24:49:00`) are parsed safely
  with `SAFE.PARSE_TIME`, and noisy negative values are filtered to a
  realistic range.

- **Aggregation.** Cleaned, per-arrival lateness is rolled up into route,
  hourly, and daily reliability models — each covered by automated dbt tests.

### 3. Serve  (Power BI)
Dashboards visualize the route rankings and the time-of-day reliability curve.

---

## 📊 Data models (dbt)

| Model                 | Grain            | What it answers                          |
|-----------------------|------------------|------------------------------------------|
| `route_reliability`   | one row / route  | Which routes are most/least reliable?    |
| `hourly_reliability`  | one row / hour   | How does reliability change across the day? |
| `daily_reliability`   | one row / weekday| Are some days worse than others?         |

**Data quality:** 13 automated dbt tests (`not_null`, `unique`,
`accepted_values`) enforce integrity on every model.

---

## 🔎 Key findings

- **Evening rush hour is the worst.** Average lateness climbs through the
  afternoon and peaks around **7 PM (~4.6 min late)**, versus **~1 min**
  late in the early morning.
- **Rail is reliable.** METRO Blue Line averages **~3.3 min** late across
  ~1,000 measured arrivals; Green Line **~2.9 min**.
- **Local routes lag.** Several local bus routes are the least reliable in
  the sample.

<!-- Replace/expand with more numbers + charts as data accumulates -->

---

## ⚠️ Data quality & honest limitations

- Arrival times are **estimated** from GPS position snapshots
  (closest-approach), not exact arrival events.
- Analysis reflects the data collected so far; the pipeline is **live and
  growing**, so weekday/weekend patterns strengthen over time.
- Very-early values are filtered to a realistic range (−5 to 60 min) to
  remove measurement noise.
- After-midnight GTFS service times (24:00+) are currently excluded
  (a planned enhancement).

*Being explicit about limitations is intentional — trustworthy analysis
means knowing what the numbers can and can't say.*

---

## 📁 Repository structure

```
mn-transit-pipeline/
├── ingestion/          # Python collector (extract + load to BigQuery)
├── orchestration/      # Dagster project (scheduled every 2 min)
├── models/             # dbt models + data quality tests
│   ├── route_reliability.sql
│   ├── hourly_reliability.sql
│   ├── daily_reliability.sql
│   └── schema.yml
├── docs/               # dashboard screenshots
└── README.md
```

---

## 🚀 Running it

```bash
# 1. Set up the Python environment and install dependencies
# 2. Authenticate to Google Cloud
# 3. Start the collector (or launch Dagster to schedule it):
dg dev
# 4. Build and test the transformations:
dbt build   # runs models + tests
```

---

## 🔭 Roadmap

- [ ] Publish an auto-refreshing dashboard
- [ ] Add weather data to study weather's impact on reliability
- [ ] Proper handling of after-midnight (24:00+) service times
- [ ] A live "where is my bus" map view
- [ ] Expand weekday/weekend analysis as data accumulates

---

## 📫 Contact

Built as a data engineering portfolio project. Questions or opportunities —
feel free to open an issue or connect on LinkedIn.

## 📄 License

MIT
