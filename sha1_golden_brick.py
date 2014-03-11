import hashlib
import sys

if (len(sys.argv) != 2):
   print sys.argv[0]+":", "error: must specify an input file"
   exit(1)

try:
    f = open(sys.argv[1])
except IOError:
    print sys.argv[0]+":", "error: file", sys.argv[1], "does not exist"
    exit(1)
else:
   with f:
      contents = f.read()
      print hashlib.sha1(contents).hexdigest()
      
exit(0)