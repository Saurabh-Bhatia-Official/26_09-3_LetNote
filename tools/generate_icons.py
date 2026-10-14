import os
import shutil
from collections import deque
import numpy as np
from PIL import Image

def main():
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    source_candidates = [
        r'C:\Users\ssbha\.gemini\antigravity-ide\brain\d893710b-a09a-44c1-b1a6-e9aed8e883e0\.user_uploaded\media_1791969276109.png',
        os.path.join(root_dir, 'assets', 'images', 'logo.png')
    ]
    
    src_file = None
    for cand in source_candidates:
        if os.path.exists(cand):
            src_file = cand
            break
            
    if not src_file:
        raise FileNotFoundError("Source logo image not found.")
        
    print(f"Loading source logo from: {src_file}")
    
    # 1. Ensure assets/images directory
    assets_img_dir = os.path.join(root_dir, 'assets', 'images')
    os.makedirs(assets_img_dir, exist_ok=True)
    
    # Copy master original logo
    dest_master = os.path.join(assets_img_dir, 'logo.png')
    if os.path.abspath(src_file) != os.path.abspath(dest_master):
        shutil.copyfile(src_file, dest_master)
    print(f"Saved: {dest_master}")
    
    # Load image in RGBA
    img = Image.open(src_file).convert('RGBA')
    arr = np.array(img, dtype=np.float32)
    h, w = arr.shape[:2]
    
    # 2. Generate transparent version of full logo
    # Flood-fill from borders to detect exterior background
    is_bg_seed = (arr[:, :, 0] > 240) & (arr[:, :, 1] > 240) & (arr[:, :, 2] > 240)
    visited = np.zeros((h, w), dtype=bool)
    
    q = deque()
    for x in range(w):
        if is_bg_seed[0, x]: q.append((0, x)); visited[0, x] = True
        if is_bg_seed[h-1, x]: q.append((h-1, x)); visited[h-1, x] = True
    for y in range(h):
        if is_bg_seed[y, 0]: q.append((y, 0)); visited[y, 0] = True
        if is_bg_seed[y, w-1]: q.append((y, w-1)); visited[y, w-1] = True
        
    while q:
        y, x = q.popleft()
        for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w:
                if not visited[ny, nx] and is_bg_seed[ny, nx]:
                    visited[ny, nx] = True
                    q.append((ny, nx))
                    
    # Include interior enclosed holes in typography (Y > 620: loops of 'e', 'o', etc.)
    text_counters = (~visited) & is_bg_seed
    text_counters[:620, :] = False
    
    transparent_mask = visited | text_counters
    
    # Alpha mask with smooth antialiasing along edges
    alpha = np.ones((h, w), dtype=np.float32) * 255.0
    alpha[transparent_mask] = 0.0
    
    edge_pixels = np.zeros((h, w), dtype=bool)
    for dy, dx in [(-1,0), (1,0), (0,-1), (0,1), (-1,-1), (-1,1), (1,-1), (1,1)]:
        rolled = np.roll(np.roll(transparent_mask, dy, axis=0), dx, axis=1)
        edge_pixels |= (rolled & (~transparent_mask))
        
    max_diff = np.max(255.0 - arr[:, :, :3], axis=2)
    for y, x in zip(*np.where(edge_pixels)):
        d = max_diff[y, x]
        if d < 120:
            a = np.clip(d / 120.0 * 255.0, 0, 255)
            alpha[y, x] = min(alpha[y, x], a)
            
    out_arr = arr.copy()
    out_arr[:, :, 3] = alpha
    logo_transparent = Image.fromarray(out_arr.astype(np.uint8))
    
    dest_trans = os.path.join(assets_img_dir, 'logo_transparent.png')
    logo_transparent.save(dest_trans)
    print(f"Saved: {dest_trans}")
    
    # 3. Extract the standalone Notebook + Pen icon mark
    # Bounding box of the mark is [X: 305 to 757, Y: 200 to 582]
    icon_crop = logo_transparent.crop((305, 200, 757, 582))
    
    # Place in a square 1024x1024 canvas with proper safe-zone padding (~16% padding)
    icon_trans_1024 = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    target_w = 760
    target_h = int(round(icon_crop.height * (target_w / icon_crop.width)))
    resized_mark = icon_crop.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    pos_x = (1024 - target_w) // 2
    pos_y = (1024 - target_h) // 2
    icon_trans_1024.paste(resized_mark, (pos_x, pos_y), resized_mark)
    
    dest_icon_trans = os.path.join(assets_img_dir, 'logo_icon_transparent.png')
    icon_trans_1024.save(dest_icon_trans)
    print(f"Saved: {dest_icon_trans}")
    
    # Icon with clean white background
    icon_white_1024 = Image.new('RGBA', (1024, 1024), (255, 255, 255, 255))
    icon_white_1024.paste(icon_trans_1024, (0, 0), icon_trans_1024)
    dest_icon_white = os.path.join(assets_img_dir, 'logo_icon.png')
    icon_white_1024.save(dest_icon_white)
    print(f"Saved: {dest_icon_white}")
    
    # Master App Icon
    dest_app_icon = os.path.join(assets_img_dir, 'app_icon.png')
    icon_white_1024.save(dest_app_icon)
    print(f"Saved: {dest_app_icon}")
    
    # 4. Generate Android Launcher Icons
    android_res = os.path.join(root_dir, 'android', 'app', 'src', 'main', 'res')
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    for folder, size in android_sizes.items():
        folder_path = os.path.join(android_res, folder)
        os.makedirs(folder_path, exist_ok=True)
        # Use clean white background icon for launcher
        out_ico = icon_white_1024.resize((size, size), Image.Resampling.LANCZOS)
        out_path = os.path.join(folder_path, 'ic_launcher.png')
        out_ico.save(out_path)
        print(f"Saved Android {folder}/ic_launcher.png ({size}x{size})")
        
    # 5. Generate iOS App Icons
    ios_iconset = os.path.join(root_dir, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    os.makedirs(ios_iconset, exist_ok=True)
    ios_files = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
    }
    for fname, sz in ios_files.items():
        out_path = os.path.join(ios_iconset, fname)
        out_img = icon_white_1024.resize((sz, sz), Image.Resampling.LANCZOS)
        out_img.save(out_path)
        print(f"Saved iOS {fname} ({sz}x{sz})")
        
    # iOS LaunchImage
    ios_launch = os.path.join(root_dir, 'ios', 'Runner', 'Assets.xcassets', 'LaunchImage.imageset')
    if os.path.exists(ios_launch):
        icon_trans_1024.resize((128, 128), Image.Resampling.LANCZOS).save(os.path.join(ios_launch, 'LaunchImage.png'))
        icon_trans_1024.resize((256, 256), Image.Resampling.LANCZOS).save(os.path.join(ios_launch, 'LaunchImage@2x.png'))
        icon_trans_1024.resize((384, 384), Image.Resampling.LANCZOS).save(os.path.join(ios_launch, 'LaunchImage@3x.png'))
        print("Updated iOS LaunchImage.imageset")
        
    # 6. Generate macOS App Icons
    macos_iconset = os.path.join(root_dir, 'macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    os.makedirs(macos_iconset, exist_ok=True)
    macos_files = {
        'app_icon_16.png': 16,
        'app_icon_32.png': 32,
        'app_icon_64.png': 64,
        'app_icon_128.png': 128,
        'app_icon_256.png': 256,
        'app_icon_512.png': 512,
        'app_icon_1024.png': 1024,
    }
    for fname, sz in macos_files.items():
        out_path = os.path.join(macos_iconset, fname)
        out_img = icon_white_1024.resize((sz, sz), Image.Resampling.LANCZOS)
        out_img.save(out_path)
        print(f"Saved macOS {fname} ({sz}x{sz})")
        
    # 7. Generate Windows Icon (.ico)
    windows_icon_path = os.path.join(root_dir, 'windows', 'runner', 'resources', 'app_icon.ico')
    os.makedirs(os.path.dirname(windows_icon_path), exist_ok=True)
    # Windows icon uses transparent background mark so it renders seamlessly on any taskbar
    icon_trans_1024.save(windows_icon_path, format='ICO', sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print(f"Saved Windows app_icon.ico: {windows_icon_path}")
    
    # 8. Generate Web Icons
    web_dir = os.path.join(root_dir, 'web')
    web_icons_dir = os.path.join(web_dir, 'icons')
    os.makedirs(web_icons_dir, exist_ok=True)
    
    # favicon: 32x32 transparent
    fav_path = os.path.join(web_dir, 'favicon.png')
    icon_trans_1024.resize((32, 32), Image.Resampling.LANCZOS).save(fav_path)
    print(f"Saved Web favicon: {fav_path}")
    
    # Icon-192.png & Icon-512.png
    icon_white_1024.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-192.png'))
    icon_white_1024.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-512.png'))
    
    # Maskable icons (with ~20% safe zone padding)
    icon_white_1024.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-maskable-192.png'))
    icon_white_1024.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-maskable-512.png'))
    print("Saved Web icons in web/icons/")
    
    print("\nAll icons and brand assets generated successfully!")

if __name__ == '__main__':
    main()
