from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch, Rectangle


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "figures"
OUT.mkdir(parents=True, exist_ok=True)


COLORS = {
    "stage": "#DCEAF7",
    "stage_dark": "#2F6B9A",
    "memory": "#E7F3E7",
    "predictor": "#FCE8D5",
    "control": "#EEE5F7",
    "feedback": "#C94C4C",
    "text": "#1F2933",
    "line": "#40566D",
    "white": "#FFFFFF",
}


def save_figure(fig, name, caption, alt_text):
    base = OUT / name
    fig.savefig(base.with_suffix(".png"), dpi=600, facecolor="white")
    fig.savefig(base.with_suffix(".pdf"), facecolor="white")
    fig.savefig(base.with_suffix(".svg"), facecolor="white")
    plt.close(fig)
    return {
        "name": name,
        "caption": caption,
        "alt_text": alt_text,
        "files": [
            base.with_suffix(".png").relative_to(ROOT).as_posix(),
            base.with_suffix(".pdf").relative_to(ROOT).as_posix(),
            base.with_suffix(".svg").relative_to(ROOT).as_posix(),
        ],
    }


def add_box(ax, xy, width, height, title, body, facecolor, edgecolor=None):
    edgecolor = edgecolor or COLORS["line"]
    x, y = xy
    box = FancyBboxPatch(
        (x, y),
        width,
        height,
        boxstyle="round,pad=0.012,rounding_size=0.03",
        linewidth=1.2,
        edgecolor=edgecolor,
        facecolor=facecolor,
    )
    ax.add_patch(box)
    ax.text(
        x + width / 2,
        y + height - 0.10,
        title,
        ha="center",
        va="top",
        fontsize=10,
        fontweight="bold",
        color=COLORS["text"],
    )
    ax.text(
        x + width / 2,
        y + height / 2 - 0.02,
        body,
        ha="center",
        va="center",
        fontsize=8.2,
        linespacing=1.35,
        color=COLORS["text"],
    )
    return box


def add_arrow(ax, start, end, color=None, linestyle="-", mutation_scale=12, curve=0.0):
    color = color or COLORS["line"]
    connectionstyle = f"arc3,rad={curve}" if curve else "arc3"
    arrow = FancyArrowPatch(
        start,
        end,
        arrowstyle="-|>",
        mutation_scale=mutation_scale,
        linewidth=1.2,
        linestyle=linestyle,
        color=color,
        connectionstyle=connectionstyle,
    )
    ax.add_patch(arrow)
    return arrow


def figure_pipeline():
    fig, ax = plt.subplots(figsize=(13.2, 4.8), layout="constrained")
    ax.set_xlim(0, 13.2)
    ax.set_ylim(0, 4.8)
    ax.axis("off")
    ax.set_title(
        "Six-stage RV32I pipeline and main data movement",
        fontsize=14,
        fontweight="bold",
        color=COLORS["text"],
        pad=12,
    )

    stages = [
        ("IF", "PC, instruction\nmemory, predictor", COLORS["stage"]),
        ("ID", "decode, register\nfile, immediate", COLORS["stage"]),
        ("EX", "ALU, address,\nbranch target", COLORS["stage"]),
        ("MEM1", "data-memory\nrequest", COLORS["memory"]),
        ("MEM2", "read-data align,\nsign/zero extend", COLORS["memory"]),
        ("WB", "select result and\nwrite register", COLORS["control"]),
    ]
    x_positions = [0.25, 2.42, 4.59, 6.76, 8.93, 11.10]
    width, height, y = 1.75, 1.45, 2.15

    for i, (title, body, color) in enumerate(stages):
        add_box(ax, (x_positions[i], y), width, height, title, body, color)
        if i < len(stages) - 1:
            add_arrow(
                ax,
                (x_positions[i] + width, y + height / 2),
                (x_positions[i + 1], y + height / 2),
            )
            ax.text(
                (x_positions[i] + width + x_positions[i + 1]) / 2,
                y + height / 2 + 0.17,
                "pipeline reg.",
                ha="center",
                va="bottom",
                fontsize=7.2,
                color=COLORS["line"],
            )

    add_box(
        ax,
        (0.45, 0.35),
        3.0,
        0.95,
        "Hazard control",
        "forwarding + load-use stall\nwrong-path flush",
        COLORS["control"],
    )
    add_arrow(
        ax,
        (3.45, 0.85),
        (4.72, 2.15),
        color=COLORS["feedback"],
        linestyle="--",
        curve=-0.18,
    )
    add_arrow(
        ax,
        (3.45, 0.60),
        (1.00, 2.15),
        color=COLORS["feedback"],
        linestyle="--",
        curve=0.20,
    )
    ax.text(
        3.62,
        1.33,
        "control and data\nfeedback",
        fontsize=7.8,
        color=COLORS["feedback"],
        rotation=31,
        ha="center",
        va="center",
    )

    add_box(
        ax,
        (8.10, 0.35),
        4.45,
        0.95,
        "Architectural state",
        "register file write-back, memory update,\nPC redirect after resolved control transfer",
        COLORS["white"],
    )
    add_arrow(
        ax,
        (11.10 + width / 2, 2.15),
        (10.35, 1.30),
        color=COLORS["line"],
        linestyle="--",
        curve=0.15,
    )

    ax.text(
        0.25,
        1.78,
        "Each stage is separated by a registered interface. MEM1 and MEM2 make the memory path explicit.",
        fontsize=8.4,
        color=COLORS["text"],
        ha="left",
    )
    return fig


def figure_hybrid():
    fig, ax = plt.subplots(figsize=(12.8, 6.6), layout="constrained")
    ax.set_xlim(0, 12.8)
    ax.set_ylim(0, 6.6)
    ax.axis("off")
    ax.set_title(
        "Hybrid branch-prediction front end",
        fontsize=14,
        fontweight="bold",
        color=COLORS["text"],
        pad=12,
    )

    add_box(ax, (0.35, 4.62), 1.55, 0.95, "PC", "current fetch\naddress", COLORS["stage"])
    add_box(ax, (2.25, 5.05), 2.25, 1.00, "BTB", "target address\nand hit", COLORS["predictor"])
    add_box(ax, (2.25, 3.65), 2.25, 1.00, "PHT", "PC-indexed local\ndirection counter", COLORS["predictor"])
    add_box(ax, (5.05, 3.65), 2.25, 1.00, "Gshare", "PC index XOR\nglobal history", COLORS["predictor"])
    add_box(ax, (5.05, 5.05), 2.25, 1.00, "GHR", "global branch\nhistory", COLORS["control"])
    add_box(ax, (7.85, 4.35), 2.25, 1.00, "Selector", "choose PHT or\nGshare direction", COLORS["control"])
    add_box(ax, (7.85, 2.82), 2.25, 1.00, "RAS", "return target for\ncall/return", COLORS["predictor"])
    add_box(
        ax,
        (10.55, 4.05),
        1.85,
        1.35,
        "Next-PC\nselect",
        "taken + BTB hit:\npredicted target\notherwise PC+4",
        COLORS["stage"],
    )

    add_arrow(ax, (1.90, 5.10), (2.25, 5.52))
    add_arrow(ax, (1.90, 4.95), (2.25, 4.15))
    add_arrow(ax, (4.50, 4.15), (5.05, 4.15))
    add_arrow(ax, (6.18, 5.05), (6.18, 4.65))
    add_arrow(ax, (4.50, 4.15), (7.85, 4.72), curve=-0.12)
    add_arrow(ax, (7.30, 4.15), (7.85, 4.82), curve=0.12)
    add_arrow(ax, (10.10, 4.85), (10.55, 4.85))
    add_arrow(ax, (10.10, 3.32), (10.55, 4.40), curve=-0.10)
    add_arrow(ax, (10.55, 4.25), (1.90, 4.62), color=COLORS["feedback"], linestyle="--", curve=0.24)

    ax.text(
        6.6,
        3.03,
        "EX-stage resolution and update",
        fontsize=8.2,
        color=COLORS["feedback"],
        ha="center",
    )

    add_box(
        ax,
        (0.65, 1.05),
        3.0,
        1.00,
        "Resolved branch",
        "actual taken/not-taken,\nactual target, branch type",
        COLORS["white"],
    )
    add_box(
        ax,
        (4.25, 1.05),
        3.0,
        1.00,
        "Update state",
        "BTB, PHT, Gshare,\nSelector and RAS",
        COLORS["control"],
    )
    add_box(
        ax,
        (7.85, 1.05),
        3.55,
        1.00,
        "Recovery",
        "mispredict -> correct PC\nand pipeline flush",
        COLORS["white"],
    )
    add_arrow(ax, (3.65, 1.55), (4.25, 1.55), color=COLORS["feedback"])
    add_arrow(ax, (7.25, 1.55), (7.85, 1.55), color=COLORS["feedback"])

    ax.text(
        0.35,
        0.48,
        "The basic predictor structures are combined for a unified FPGA ablation study; no new predictor algorithm is claimed.",
        fontsize=8.3,
        color=COLORS["text"],
        ha="left",
    )
    return fig


def figure_experiment_flow():
    fig, ax = plt.subplots(figsize=(13.2, 5.4), layout="constrained")
    ax.set_xlim(0, 13.2)
    ax.set_ylim(0, 5.4)
    ax.axis("off")
    ax.set_title(
        "Experimental and verification workflow",
        fontsize=14,
        fontweight="bold",
        color=COLORS["text"],
        pad=12,
    )

    add_box(
        ax,
        (0.35, 3.55),
        2.25,
        1.05,
        "RTL design",
        "six-stage CPU\nsix predictor versions",
        COLORS["stage"],
    )
    add_box(
        ax,
        (3.15, 3.55),
        2.25,
        1.05,
        "Functional tests",
        "37 RV32I instructions\nmain + supplementary tests",
        COLORS["control"],
    )
    add_box(
        ax,
        (5.95, 3.55),
        2.25,
        1.05,
        "Trace differential",
        "75 valid commits/version\nreference-model comparison",
        COLORS["control"],
    )
    add_box(
        ax,
        (8.75, 3.55),
        2.25,
        1.05,
        "Performance",
        "cycle, CPI, IPC\nstall, flush, prediction",
        COLORS["predictor"],
    )
    add_box(
        ax,
        (11.55, 3.55),
        1.30,
        1.05,
        "Checks",
        "all tests\npass",
        COLORS["memory"],
    )
    for x in [2.60, 5.40, 8.20, 11.00]:
        add_arrow(ax, (x, 4.08), (x + 0.55, 4.08))

    add_box(
        ax,
        (1.35, 1.05),
        2.45,
        1.05,
        "Vivado implementation",
        "synthesis, place and route,\ntiming, power, bitstream",
        COLORS["memory"],
    )
    add_box(
        ax,
        (4.55, 1.05),
        2.45,
        1.05,
        "Resource and timing",
        "LUT, FF, BRAM,\nWNS/WHS, power",
        COLORS["predictor"],
    )
    add_box(
        ax,
        (7.75, 1.05),
        2.45,
        1.05,
        "Board smoke test",
        "A7-LITE 100T\n50 MHz LED observation",
        COLORS["memory"],
    )
    add_box(
        ax,
        (10.95, 1.05),
        1.75,
        1.05,
        "Paper data",
        "tables, figures,\nclaims",
        COLORS["control"],
    )

    add_arrow(ax, (1.48, 3.55), (2.10, 2.10), color=COLORS["line"], curve=0.12)
    add_arrow(ax, (2.58, 1.58), (4.55, 1.58))
    add_arrow(ax, (7.00, 1.58), (7.75, 1.58))
    add_arrow(ax, (10.20, 1.58), (10.95, 1.58))
    add_arrow(ax, (12.20, 3.55), (11.85, 2.10), color=COLORS["line"], curve=-0.12)

    ax.text(
        0.35,
        0.43,
        "The reported conclusions are bounded by the current custom benchmarks, Vivado power estimation and 50 MHz validation condition.",
        fontsize=8.4,
        color=COLORS["text"],
        ha="left",
    )
    return fig


def main():
    records = [
        save_figure(
            figure_pipeline(),
            "fig1_six_stage_pipeline",
            "Six-stage RV32I pipeline with IF, ID, EX, MEM1, MEM2 and WB stages.",
            "A horizontal six-stage pipeline. IF contains PC, instruction memory and prediction; ID decodes and reads registers; EX performs ALU and control-transfer calculations; MEM1 submits memory requests; MEM2 aligns and extends read data; WB writes results to the register file. Hazard control feeds forwarding, stalls and flushes back into the pipeline.",
        ),
        save_figure(
            figure_hybrid(),
            "fig2_hybrid_predictor",
            "Hybrid branch-prediction front end combining BTB, PHT, Gshare, Selector and RAS.",
            "The current PC queries BTB, PHT and Gshare. Gshare uses the global history register. Selector chooses the direction source, while RAS supplies return targets. Next-PC selection uses a predicted target only when the target and direction conditions are satisfied. EX-stage resolution updates predictor state and triggers recovery on a misprediction.",
        ),
        save_figure(
            figure_experiment_flow(),
            "fig3_experiment_workflow",
            "Functional, trace, implementation and board-level validation workflow.",
            "The workflow starts with the RTL CPU and six predictor versions, then runs 37-instruction functional tests, trace differential comparison, and performance statistics. Vivado implementation provides resource, timing, power and bitstream results. The A7-LITE 100T board provides smoke-test evidence, and all evidence is consolidated into paper tables, figures and claims.",
        ),
    ]

    manifest = OUT / "figure_manifest.md"
    lines = [
        "# Paper Figure Manifest",
        "",
        "Generated by `scripts/generate_paper_figures.py` using Matplotlib.",
        "",
    ]
    for index, record in enumerate(records, start=1):
        lines.extend(
            [
                f"## Figure {index}: `{record['name']}`",
                "",
                f"Caption: {record['caption']}",
                "",
                f"Alt text: {record['alt_text']}",
                "",
                "Files:",
            ]
        )
        lines.extend(f"- `{path}`" for path in record["files"])
        lines.append("")
    manifest.write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    main()


