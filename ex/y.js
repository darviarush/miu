var tape = require("tape")

tape("123", function(t) {
	t.plan(7)
	t.ok(true, "-1-")
	t.ok(true, "-2-")
	t.ok(true, "-3-")
	t.ok(true, "-4-")
	t.ok(true, "-5-")
	t.ok(true, "-6-")
	t.ok(true, "-7-")
});