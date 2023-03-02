import os
tmpdir = os.getenv('TMP')
outputfile = os.path.join(tmpdir, 'db2_tprocc' )
exec(open('./scripts/python/generic/generic_tprocc_result.py').read())
exit()
