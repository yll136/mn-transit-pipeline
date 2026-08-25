import dagster as dg
import pandas as pd
import pandas_gbq
import requests
from datetime import datetime

@dg.asset
def bus_positions():
    response = requests.get("https://svc.metrotransit.org/nextrip/vehicles")
    data = response.json()

    good_buses = []
    for bus in data:
        if bus["latitude"] != 0 and bus["location_time"] != 0:
            good_buses.append(bus)

    df = pd.DataFrame(good_buses)
    df["collected_at"] = datetime.now()

    pandas_gbq.to_gbq(df, "transit.bus_positions", project_id="project-2eb301e4-cadc-49d8-9bb", if_exists="append")

bus_job = dg.define_asset_job("bus_job", selection="bus_positions")

bus_schedule = dg.ScheduleDefinition(
    job=bus_job,
    cron_schedule="*/2 * * * *"
)