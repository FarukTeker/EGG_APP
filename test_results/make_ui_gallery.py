#!/usr/bin/env python3
"""Çıkarılan ekran görüntülerinden zaman damgalı bir HTML galeri sayfası üretir."""
import os, glob, re, html

DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ui_screenshots")
files = sorted(glob.glob(os.path.join(DIR, "scene_*.png")))

cards = []
for f in files:
    name = os.path.basename(f)
    m = re.match(r"scene_(\d+)_t([\d,]+)s\.png", name)
    idx, t = m.group(1), m.group(2).replace(",", ".")
    mins, secs = divmod(float(t), 60)
    cards.append(f"""
    <div class="card">
      <div class="meta">#{idx} &nbsp;·&nbsp; {int(mins):02d}:{secs:05.2f} (video içinde)</div>
      <img src="ui_screenshots/{html.escape(name)}" loading="lazy">
    </div>""")

page = f"""<!DOCTYPE html><html><head><meta charset="utf-8">
<title>EGG_APP — UI Ekran Görüntüleri</title>
<style>
  body {{ margin:0; background:#0d1117; color:#c9d1d9; font-family:-apple-system,Segoe UI,Roboto,sans-serif; }}
  h1 {{ padding:24px 28px 8px; font-size:22px; }}
  p.sub {{ padding:0 28px 20px; color:#8b949e; font-size:14px; }}
  .grid {{ display:grid; grid-template-columns:repeat(auto-fill,minmax(220px,1fr)); gap:18px; padding:0 28px 40px; }}
  .card {{ background:#161b22; border:1px solid #30363d; border-radius:12px; overflow:hidden; }}
  .card img {{ width:100%; display:block; }}
  .meta {{ padding:10px 12px; font-size:13px; color:#58a6ff; border-bottom:1px solid #30363d; }}
</style></head><body>
  <h1>EGG_APP — Ekran Kaydından Çıkarılan UI Ekran Görüntüleri</h1>
  <p class="sub">Kaynak: "Ekran Kaydı 2026-06-07 19.07.39.mov" (4:34) — otomatik sahne tespitiyle {len(files)} farklı ekran ayrıştırıldı.</p>
  <div class="grid">{"".join(cards)}</div>
</body></html>"""

out = os.path.join(os.path.dirname(DIR), "ui_screenshots_gallery.html")
with open(out, "w", encoding="utf-8") as f:
    f.write(page)
print(f"Galeri yazıldı → {out}  ({len(files)} görüntü)")
