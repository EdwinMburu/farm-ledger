from PIL import Image, ImageDraw
from pathlib import Path

root = Path(__file__).resolve().parent.parent
android_res = root / 'android' / 'app' / 'src' / 'main' / 'res'

sizes = {
    'mipmap-hdpi': 72,
    'mipmap-mdpi': 48,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

for folder, size in sizes.items():
    target_dir = android_res / folder
    target = target_dir / 'ic_launcher.png'
    img = Image.new('RGBA', (1024, 1024), (44, 106, 79, 255))
    draw = ImageDraw.Draw(img)

    # body
    draw.ellipse((180, 330, 840, 780), fill=(255, 255, 255, 255))

    # head
    draw.ellipse((610, 170, 905, 470), fill=(255, 255, 255, 255))

    # snout
    draw.ellipse((690, 290, 820, 390), fill=(220, 220, 220, 255))

    # nostrils
    draw.ellipse((725, 310, 760, 340), fill=(50, 50, 50, 255))
    draw.ellipse((780, 310, 815, 340), fill=(50, 50, 50, 255))

    # ears
    draw.ellipse((660, 100, 720, 175), fill=(255, 255, 255, 255))
    draw.ellipse((785, 100, 845, 175), fill=(255, 255, 255, 255))
    draw.ellipse((680, 120, 705, 160), fill=(190, 190, 190, 255))
    draw.ellipse((805, 120, 830, 160), fill=(190, 190, 190, 255))

    # horns / spots
    draw.ellipse((720, 210, 760, 250), fill=(0, 0, 0, 255))
    draw.ellipse((790, 210, 830, 250), fill=(0, 0, 0, 255))

    # legs
    draw.rounded_rectangle((280, 760, 335, 940), radius=25, fill=(255, 255, 255, 255))
    draw.rounded_rectangle((430, 760, 485, 940), radius=25, fill=(255, 255, 255, 255))
    draw.rounded_rectangle((575, 760, 630, 940), radius=25, fill=(255, 255, 255, 255))
    draw.rounded_rectangle((715, 760, 770, 940), radius=25, fill=(255, 255, 255, 255))

    # black spots
    for spot in [
        (250, 470, 350, 570),
        (350, 560, 430, 660),
        (560, 520, 660, 620),
        (640, 610, 730, 700),
        (430, 390, 500, 470),
    ]:
        draw.ellipse(spot, fill=(40, 40, 40, 255))

    # muzzle and eye
    draw.ellipse((720, 240, 760, 280), fill=(0, 0, 0, 255))
    draw.ellipse((820, 250, 845, 275), fill=(0, 0, 0, 255))

    # subtle soft highlight to keep it polished
    highlight = Image.new('RGBA', img.size, (0, 0, 0, 0))
    hdraw = ImageDraw.Draw(highlight)
    hdraw.ellipse((140, 150, 420, 450), fill=(255, 255, 255, 40))
    img = Image.alpha_composite(img, highlight)

    small = img.resize((size, size), Image.Resampling.LANCZOS)
    small.save(target)

print('Cow launcher icons generated for Android.')
