import os
tmpdir = os.getenv('TMP')
outputfile = os.path.join(tmpdir, 'maria_tproch' )
exec(open('./scripts/python/generic/generic_tproch_result.py').read())
exit()
