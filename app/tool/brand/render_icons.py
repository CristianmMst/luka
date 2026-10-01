# /// script
# requires-python = ">=3.12"
# dependencies = ["resvg-py==0.5.0", "pillow>=11"]
# ///
"""Rasteriza los íconos de la app desde los SVG maestros de tool/brand/.

- app_icon.svg: el símbolo sobre el cuadro amarillo (fuente de verdad).
- app_icon_small.svg: el mismo sin la sombra, para 60 px o menos, donde
  la flecha y la sombra se funden.

Genera los PNG de iOS (opacos: la App Store rechaza el alfa), los legacy
de Android (esquinas redondeadas, rx 22) y el de 512 px de la ficha de
Play Store. El primer plano adaptativo de Android es un VectorDrawable
escrito a mano con esta misma geometría (drawable/ic_launcher_foreground.xml).

Uso (desde la raíz): just app-icons
"""

import io
import json
from pathlib import Path

import resvg_py
from PIL import Image

BRAND = Path(__file__).parent
APP = BRAND.parent.parent
IOS = APP / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
RES = APP / "android/app/src/main/res"
PLAY_STORE = APP / "android/app/src/main/ic_launcher-playstore.png"

SMALL_MAX_PX = 60
ANDROID_LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def render(px: int, *, rounded: bool = False) -> Image.Image:
    name = "app_icon_small.svg" if px <= SMALL_MAX_PX else "app_icon.svg"
    svg = (BRAND / name).read_text(encoding="utf-8")
    if rounded:
        svg = svg.replace('<rect width="100" height="100"', '<rect width="100" height="100" rx="22"', 1)
    png = resvg_py.svg_to_bytes(svg_string=svg, width=px, height=px)
    return Image.open(io.BytesIO(bytes(png)))


def main() -> None:
    contents = json.loads((IOS / "Contents.json").read_text(encoding="utf-8"))
    for image in contents["images"]:
        points = float(image["size"].split("x")[0])
        px = round(points * int(image["scale"].removesuffix("x")))
        render(px).convert("RGB").save(IOS / image["filename"], optimize=True)

    for density, px in ANDROID_LEGACY.items():
        render(px, rounded=True).save(RES / f"mipmap-{density}/ic_launcher.png", optimize=True)

    render(512).convert("RGB").save(PLAY_STORE, optimize=True)


if __name__ == "__main__":
    main()
