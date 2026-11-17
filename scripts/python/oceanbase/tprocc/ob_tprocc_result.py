# Run with hammerdbcli py auto from the HammerDB root.
import sys

try:
    from scripts.python.oceanbase.common import main
    main('TPROC-C', 'result')
except Exception:
    import traceback
    traceback.print_exc()
    sys.exit(1)
sys.exit(0)
