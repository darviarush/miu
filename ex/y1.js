var tape = require("tape")

tape("123", function(t) {
	t.plan(7)
	t.ok(true, "-1-")
	t.ok(false, "-2-")
	t.ok(false, "-3-")
	t.ok(false, "-4-")
	t.ok(true, "-5-")
	t.ok(true, "-6-")
	t.ok(true, "-7-")
});