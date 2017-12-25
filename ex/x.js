var assert = require("chai").assert

describe("123", function() {
	it("345", function() {
		assert.ok(false, "---ok");
	});

	it("345-2", function() {
		assert.ok(false, "---ok");
	});

	it("345-3", function() {
		assert.ok(true, "---ok");
	});
});