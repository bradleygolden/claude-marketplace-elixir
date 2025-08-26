# Loop Control

## Current State
- **Status**: ACTIVE - Working on debugging tidewave detection issue
- **Loop**: CONTINUE - More work needed to complete port customization feature

## Early Stopping Conditions
Stop the loop when:
- ✅ All tests pass (including the new port customization test)
- ✅ Port customization feature is fully working
- ✅ No regressions in existing functionality
- ❌ Blocked on external dependencies or requirements
- ❌ Stuck in same debug cycle for >5 iterations

## Success Criteria
- [ ] Port customization test `test/mix/tasks/claude.install_test.exs:1828` passes
- [ ] All existing tests continue to pass
- [ ] Phoenix plugin properly supports `:port` option
- [ ] Installer preserves plugin port configurations
- [ ] Documentation updated with port option

## Current Issues to Resolve
1. **tidewave_already_configured? detection bug** - highest priority
2. **installer overriding plugin config** - related to #1

## Loop Iteration Guidelines
Each loop iteration should:
1. Focus on one specific debugging step
2. Make incremental progress 
3. Commit changes after each successful fix
4. Update status.md with findings
5. If stuck >3 iterations on same issue, try different approach

## Emergency Stop
If encountering infinite loops or getting stuck, use early stopping and document the blocking issue for human review.