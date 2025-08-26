# Todo Queue

## High Priority
1. **[ACTIVE]** Debug tidewave detection logic issue
   - The installer should detect plugin's `tidewave: [port: "${PORT:-8080}"]` config
   - But it's adding `mcp_servers: [:tidewave]` instead
   - Test failing: `test/mix/tasks/claude.install_test.exs:1828`

2. **Fix installer port preservation**
   - Ensure installer preserves plugin's port configuration
   - Don't override with simple `:tidewave` atom

3. **Verify all tests pass**
   - Run full test suite after fixes
   - Ensure no regressions

## Medium Priority
4. **Update documentation**
   - Add examples of port customization to README
   - Document the new `:port` option properly

## Low Priority
5. **Consider additional enhancements**
   - Maybe add validation for port numbers
   - Consider other Tidewave configuration options

## Completed
- ✅ Add port option to Phoenix plugin config function
- ✅ Add port customization tests to Phoenix plugin
- ✅ Fix nested memories bug with plugin processing
- ✅ Fix non-Phoenix project test expectations
- ✅ Add integration test for port customization

## Blocked/Deferred
- None currently