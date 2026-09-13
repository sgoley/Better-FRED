#!/bin/bash
set -e

SRC="docs/screenshots"
AS_IPHONE="docs/screenshots/appstore/iphone"
AS_IPAD="docs/screenshots/appstore/ipad"
WEB="docs/assets/screenshots"

mkdir -p "$AS_IPHONE" "$AS_IPAD" "$WEB"

echo "Processing iPhone Screenshots..."
# 1. Dashboard
sips -s format jpeg -s formatOptions 98 "$SRC/Simulator Screenshot - iPhone 17 Pro - 2026-09-13 at 15.15.28.png" --out "$AS_IPHONE/01_dashboard.jpg"
sips -z 2868 1320 "$AS_IPHONE/01_dashboard.jpg" --out "$AS_IPHONE/01_dashboard_6.9inch.jpg"
sips -s format png "$AS_IPHONE/01_dashboard_6.9inch.jpg" --out "$AS_IPHONE/01_dashboard_6.9inch.png"
cp "$AS_IPHONE/01_dashboard.jpg" "$WEB/screen-dashboard.jpg"

# 2. Explore
sips -s format jpeg -s formatOptions 98 "$SRC/Simulator Screenshot - iPhone 17 Pro - 2026-09-13 at 15.15.34.png" --out "$AS_IPHONE/02_explore.jpg"
sips -z 2868 1320 "$AS_IPHONE/02_explore.jpg" --out "$AS_IPHONE/02_explore_6.9inch.jpg"
sips -s format png "$AS_IPHONE/02_explore_6.9inch.jpg" --out "$AS_IPHONE/02_explore_6.9inch.png"
cp "$AS_IPHONE/02_explore.jpg" "$WEB/screen-explore.jpg"

# 3. Chart Detail
sips -s format jpeg -s formatOptions 98 "$SRC/Simulator Screenshot - iPhone 17 Pro - 2026-09-13 at 15.15.43.png" --out "$AS_IPHONE/03_chart_detail.jpg"
sips -z 2868 1320 "$AS_IPHONE/03_chart_detail.jpg" --out "$AS_IPHONE/03_chart_detail_6.9inch.jpg"
sips -s format png "$AS_IPHONE/03_chart_detail_6.9inch.jpg" --out "$AS_IPHONE/03_chart_detail_6.9inch.png"
cp "$AS_IPHONE/03_chart_detail.jpg" "$WEB/screen-chart.jpg"

# 4. Settings BYOK
sips -s format jpeg -s formatOptions 98 "$SRC/Simulator Screenshot - iPhone 17 Pro - 2026-09-13 at 15.15.55.png" --out "$AS_IPHONE/04_settings.jpg"
sips -z 2868 1320 "$AS_IPHONE/04_settings.jpg" --out "$AS_IPHONE/04_settings_6.9inch.jpg"
sips -s format png "$AS_IPHONE/04_settings_6.9inch.jpg" --out "$AS_IPHONE/04_settings_6.9inch.png"
cp "$AS_IPHONE/04_settings.jpg" "$WEB/screen-settings.jpg"

echo "Processing iPad Screenshots..."
# 1. iPad Dashboard (Portrait 2048 x 2732)
sips -s format jpeg -s formatOptions 98 "$SRC/Simulator Screenshot - iPad (A16) - 2026-09-13 at 15.11.45.png" --out "$AS_IPAD/01_ipad_dashboard.jpg"
sips -z 2732 2048 "$AS_IPAD/01_ipad_dashboard.jpg" --out "$AS_IPAD/01_ipad_dashboard_13inch.jpg"
sips -s format png "$AS_IPAD/01_ipad_dashboard_13inch.jpg" --out "$AS_IPAD/01_ipad_dashboard_13inch.png"
cp "$AS_IPAD/01_ipad_dashboard.jpg" "$WEB/screen-ipad-dashboard.jpg"

# 2. iPad Chart Fullscreen (Landscape 2732 x 2048)
sips -s format jpeg -s formatOptions 98 "$SRC/Simulator Screenshot - iPad (A16) - 2026-09-13 at 15.14.12.png" --out "$AS_IPAD/02_ipad_chart_landscape.jpg"
sips -z 2048 2732 "$AS_IPAD/02_ipad_chart_landscape.jpg" --out "$AS_IPAD/02_ipad_chart_landscape_13inch.jpg"
sips -s format png "$AS_IPAD/02_ipad_chart_landscape_13inch.jpg" --out "$AS_IPAD/02_ipad_chart_landscape_13inch.png"
cp "$AS_IPAD/02_ipad_chart_landscape.jpg" "$WEB/screen-ipad-chart.jpg"

# 3. iPad Settings (Landscape 2732 x 2048)
sips -s format jpeg -s formatOptions 98 "$SRC/Simulator Screenshot - iPad (A16) - 2026-09-13 at 15.13.33.png" --out "$AS_IPAD/03_ipad_settings_landscape.jpg"
sips -z 2048 2732 "$AS_IPAD/03_ipad_settings_landscape.jpg" --out "$AS_IPAD/03_ipad_settings_landscape_13inch.jpg"
sips -s format png "$AS_IPAD/03_ipad_settings_landscape_13inch.jpg" --out "$AS_IPAD/03_ipad_settings_landscape_13inch.png"

# 4. iPad Explore (Landscape 2732 x 2048)
sips -s format jpeg -s formatOptions 98 "$SRC/Simulator Screenshot - iPad (A16) - 2026-09-13 at 15.12.18.png" --out "$AS_IPAD/04_ipad_explore_landscape.jpg"
sips -z 2048 2732 "$AS_IPAD/04_ipad_explore_landscape.jpg" --out "$AS_IPAD/04_ipad_explore_landscape_13inch.jpg"
sips -s format png "$AS_IPAD/04_ipad_explore_landscape_13inch.jpg" --out "$AS_IPAD/04_ipad_explore_landscape_13inch.png"

echo "Checking alpha on all processed files..."
sips -g hasAlpha "$AS_IPHONE"/*.png "$AS_IPAD"/*.png
echo "All done!"
