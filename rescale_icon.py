from PIL import Image
import os

def create_pro_icon():
    source_path = 'assets/launcher icon/transparent repairmybike launcher.png'
    output_path = 'assets/launcher icon/professional_launcher.png'
    
    # 1. Open source
    img = Image.open(source_path).convert("RGBA")
    
    # 2. Create target square canvas (professional standard: 1024x1024)
    target_size = 1024
    canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    
    # 3. Calculate scaling
    # Professional icons typically occupy ~60-70% of the canvas width/height
    # to fit comfortably in the circular/squircle mask "safe zone"
    max_dimension = target_size * 0.65  # 665 px
    
    source_w, source_h = img.size
    aspect = source_w / source_h
    
    if source_w > source_h:
        new_w = int(max_dimension)
        new_h = int(max_dimension / aspect)
    else:
        new_h = int(max_dimension)
        new_w = int(max_dimension * aspect)
        
    img_resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    # 4. Paste centered
    offset = ((target_size - new_w) // 2, (target_size - new_h) // 2)
    canvas.paste(img_resized, offset, img_resized)
    
    # 5. Save
    canvas.save(output_path)
    print(f"Professional icon created at: {output_path}")

if __name__ == "__main__":
    create_pro_icon()
