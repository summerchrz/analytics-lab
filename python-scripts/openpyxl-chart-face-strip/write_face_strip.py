"""Demo: write chart face-strip cells only; never recreate the chart."""
from pathlib import Path

from openpyxl import Workbook, load_workbook
from openpyxl.chart import BarChart, Reference

OUT = Path(__file__).resolve().parent / "_demo_face_strip.xlsx"

# Published series seed (incomplete live feed would disagree — don't use it here)
SEED_LABELS = ["2019", "2020", "2021", "2022", "2023", "2024", "2025", "1H'2026"]
SEED_VALUES = [204.0, 254.1, 198.1, 169.8, 207.3, 269.4, 290.8, 262.4]


def bootstrap_template(path: Path) -> None:
    wb = Workbook()
    ws = wb.active
    ws.title = "Score"
    for i, (lab, val) in enumerate(zip(SEED_LABELS, SEED_VALUES), start=9):  # col I=9
        ws.cell(1, i, lab)
        ws.cell(2, i, val)

    chart = BarChart()
    chart.type = "col"
    chart.title = "Index by Period"
    data = Reference(ws, min_col=9, min_row=2, max_col=16, max_row=2)
    cats = Reference(ws, min_col=9, min_row=1, max_col=16, max_row=1)
    chart.add_data(data, from_rows=True, titles_from_data=False)
    chart.set_categories(cats)
    ws.add_chart(chart, "I4")
    wb.save(path)


def write_face_strip_only(path: Path, labels: list[str], values: list[float]) -> None:
    """Overwrite I1:P2 only. Leave charts alone."""
    wb = load_workbook(path)
    ws = wb["Score"]
    start_col = 9
    max_cols = 16
    for i in range(max_cols):
        ws.cell(1, start_col + i, None)
        ws.cell(2, start_col + i, None)
    for i, (lab, val) in enumerate(zip(labels, values)):
        ws.cell(1, start_col + i, lab)
        ws.cell(2, start_col + i, round(float(val), 4))
    n_charts = len(ws._charts)
    wb.save(path)
    print(f"Wrote {len(labels)} face points; chart count unchanged at {n_charts}")


if __name__ == "__main__":
    if not OUT.exists():
        bootstrap_template(OUT)
        print("Bootstrapped template + chart:", OUT.name)
    # Simulate a refresh with tiny jitter on the last point only
    vals = list(SEED_VALUES)
    vals[-1] = 262.4413
    write_face_strip_only(OUT, SEED_LABELS, vals)
