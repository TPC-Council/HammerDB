import os
tmpdir = os.getenv('TMP')
outputfile = os.path.join(tmpdir, 'mssqls_tprocc' )
exec(open('./scripts/python/generic/generic_tprocc_result.py').read())
exit()
