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
      sha1 = hashlib.sha1()
      sha1.update(f.read())
      print sha1.hexdigest()
      
exit(0)