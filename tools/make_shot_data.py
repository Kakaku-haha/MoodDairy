"""Build a SharedPreferences payload with illustrative entries for store screenshots."""

import json
import os
from xml.sax.saxutils import escape, quoteattr

DAY = [
    # (month, day, score, note, tags, type, hour, minute)
    (10, 11, 3, "和朋友去吃了顿很久没吃的火锅，聊到店里快打烊。", ["朋友", "美食"], "daily", 21, 20),
    (10, 12, 4, "路边的桂花开了，风一吹，整条街都是甜的。", ["天气", "独处"], "moment", 20, 40),
    (10, 12, 2, "下午把拖了两天的报表做完，心里松了一块。", ["工作"], "daily", 22, 10),
    (10, 13, 1, "普通的一天，晚饭后散步了半小时。", ["运动", "天气"], "daily", 21, 5),
    (10, 14, -1, "开会被否定了几次，回家只想躺着。还是给自己煮了碗面。", ["工作", "美食"], "daily", 22, 30),
    (10, 15, 2, "把房间整理了一遍，扔掉了三袋不用的东西。", ["独处"], "daily", 21, 15),
    (10, 16, 4, "方案一次通过，晚上和同事在楼下喝了杯热可可。", ["工作", "朋友"], "daily", 20, 50),
    (10, 18, 3, "陪妈妈逛了半天菜市场，回家做了两道新菜。", ["家人", "美食"], "daily", 22, 5),
    (10, 19, 2, "午休时在楼下晒了十分钟太阳。", ["天气", "工作"], "moment", 13, 35),
    (10, 19, 2, "周一比想象中顺利，晚上早点睡了。", ["工作", "睡眠"], "daily", 23, 0),
    (10, 20, 2, "把拖了很久的体检预约上了，算是了却一桩心事。", ["健康"], "daily", 21, 40),
    (10, 21, 0, "平平的一天，没什么特别想说的。", [], "daily", 22, 15),
    (10, 22, 3, "重新开始跑步，三公里，出了一身汗。", ["运动", "健康"], "daily", 21, 25),
    (10, 23, 4, "收到朋友寄来的书，扉页写了两行字。", ["朋友", "学习"], "daily", 20, 55),
    (10, 24, 2, "早饭的红薯烤得刚好，甜得冒热气。", ["美食"], "moment", 9, 20),
    (10, 24, 3, "午休出去走了走，天上的云很软。", ["天气", "独处"], "moment", 13, 10),
]


def build_entries():
    entries = []
    for i, (m, d, score, note, tags, kind, hh, mm) in enumerate(DAY):
        entries.append(
            {
                "id": f"{kind}-{2026}{m:02d}{d:02d}{hh:02d}{mm:02d}-{i:02d}",
                "score": score,
                "type": kind,
                "createdAt": f"2026-{m:02d}-{d:02d}T{hh:02d}:{mm:02d}:00.000",
                "note": note,
                "tags": tags,
            }
        )
    entries.sort(key=lambda e: e["createdAt"])
    return entries


def build_xml():
    entries_json = json.dumps(build_entries(), ensure_ascii=False, separators=(",", ":"))
    return (
        "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n"
        "<map>\n"
        f"    <string name={quoteattr('flutter.warmtrace.entries.v1')}>{escape(entries_json)}</string>\n"
        f"    <string name={quoteattr('flutter.warmtrace.done_tasks.v1')}>[]</string>\n"
        "</map>\n"
    )


if __name__ == "__main__":
    out = r"D:\ProGram\MoodDairy\tools\FlutterSharedPreferences.xml"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(build_xml())
    print("wrote", out, os.path.getsize(out), "bytes")
