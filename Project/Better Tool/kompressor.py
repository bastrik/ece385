import os, glob

files = [os.path.basename(x) for x in glob.glob('./out/*.txt')]

for filename in files:
	f_out = open('./compressed/' + filename, 'w')
	with open('./out/' + filename) as f:
		for line in f:
			if line.strip() == "0000":
				f_out.write("0\n")
			else:
				f_out.write("1\n")
	f_out.close()