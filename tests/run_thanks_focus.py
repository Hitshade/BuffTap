import test_thanks_identity
import test_thanks_robust
import test_review_corrections
import test_thanks_late_caster
import test_profile_persistence
import test_profiles
from test_bufftap import tests, failures
import test_thanks_diagnostics
print('FINAL_TOTAL',len(tests))
print('FINAL_FAILED',len(failures))
assert not failures
