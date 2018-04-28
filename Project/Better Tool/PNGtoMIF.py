import os
import glob

from PIL import Image

print("Please put PNG source in ./in, then continue")
mode = int(input("Press 0 to convert every PNG in ./in folder, or press 1 to specify which file to convert: "))

files = []
if mode == 0:
    files = [os.path.basename(x) for x in glob.glob('./in/*.png')]
elif mode == 1:
    file = input("Please enter the name of the file as \"example.png\"")
    files.append(file)

for filename in files:

    im = Image.open("./in/" + filename)
    im = im.convert("RGBA")

    outImg = Image.new('RGB', im.size, color='white')
    outFile = open("./out/" + filename.replace(".png", "") + '.txt', 'w')
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            # pixel = im.getpixel((x,y))
            r, g, b, a = im.getpixel((x,y))
            # print("Pixel    : {0:08b} {1:08b} {2:08b}".format(r,g,b))
            r_out = (r >> 3)
            g_out = (g >> 3)
            b_out = (b >> 3)
            outImg.putpixel((x,y), (r_out << 3, g_out << 3, b_out << 3, a))
 
            result = r_out << 10 | g_out << 5 | b_out
            # print("Converted: {0:05b} {1:05b} {2:05b}".format(r_out,g_out,b_out))
            # print("Result   : {0:016b}".format(result))
            outFile.write("%04x\n" %(result))
    outFile.close()
    outImg.save("./debug/" + filename)