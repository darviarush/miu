// сгенерировано miu

function deepEqual$(a, b, path_a, path_b) {
	function ret(a, b, path_a, path_b) {
		return [(path_a? path_a+'='+a: a), (path_b? path_b+'='+b: b)]
	}
	
	function keys(a) {
		var r = []
		for(i in a) if(a.hasOwnProperty(i)) r.push(i)
		return r.sort()
	}

	function jpath(p, l, x) { return p? p+x+l: l }
	
	if(path_a == null) path_a = ''
	if(path_b == null) path_b = ''
	
	var r
	if(a instanceof Array && b instanceof Array) {
		if(a.length !== b.length) return ret(a.length, b.length, path_a+'.length', path_b+'.length')
		for(var i=0, n=a.length; i<n; i++) {
			if(r = deepEqual$(a[i], b[i], path_a+'['+i+']', path_b+'['+i+']')) return r
		}
		return false
	}
	if(typeof a === 'object' && typeof b === 'object') {
		var ka = keys(a), kb = keys(b)
		if(ka.length !== kb.length) return ret(a, b, path_a+'.keys().length', path_b+'.keys().length')
		for(var i=0, n=ka.length; i<n; i++) {
			var k1 = ka[i], k2 = kb[i]
			if(k1 != k2) return ret(k1, k2, path_a+'.key('+i+')', path_b+'.key('+i+')')
			if(r = deepEqual$(a[k1], b[k2], path_a+'.'+k1, path_b+'.'+k2)) return r
		}
		return false
	}
	if(a == b) return false
	return ret(a, b, path_a, path_b)
}
	
function assert$(ok, num, got, op, expected, msg) {
	if(ok) {
		console.log('ok '+num+' - '+msg)
	} else {
		console.log('not ok '+num+' - '+msg)
		console.log('#  Failed test: '+msg)
		console.log('#    got:      '+got)
		console.log('#    operator: '+op)
		console.log('#    expected: '+expected)
	
		var s = new Error().stack.replace(/\n/g, '\n#        ')
		console.log('#      trace: '+s)
	}
}

var S$, R$, E$;
console.log('1..'+21);
console.log("= miu - js");
console.log("== Быстрый старт");
var abs;
S$ = (abs = 16); R$ = "16"; assert$( S$ == R$, 1, S$, '=', R$, "abs = 16;	// 16" );

S$ = (1+5); R$ = "6"; assert$( S$ == R$, 2, S$, '=', R$, "1+5 // 6" );
S$ = deepEqual$((1+5), (1+5)); assert$( !S$, 3, S$ && S$[0], '~~', S$ && S$[1], "1+5 //# 1+5" );
S$ = (" 26\n"); R$ = " 26\n"; assert$( S$ == R$, 4, S$, '=', R$, "\" 26\\n\" //  26\\n" );
S$ = deepEqual$(({a: [2], b: 3, c: 4}), ({a: [2], b: 3, c: 4})); assert$( !S$, 5, S$ && S$[0], '~~', S$ && S$[1], "{a: [2], b: 3, c: 4} //# {a: [2], b: 3, c: 4}" );


// ну а это просто комментарий, так как перед ним ничего нет!

S$ = (Math.pow(2, 3)); R$ = "10"; assert$( S$ < R$, 6, S$, "<", R$, "Math.pow(2, 3) //< 10" );
S$ = (8); R$ = "3"; assert$( S$ != R$, 7, S$, "!=", R$, "8 //!= 3" );
S$ = ("8"); R$ = "8"; assert$( S$ == R$, 8, S$, "==", R$, "\"8\" //== 8" );
S$ = ("test"); R$ = /es.$/; assert$( R$.test(S$), 9, S$, '~', R$, "\"test\" //~ es.$" );
S$ = ({}); R$ = /^\[object Object\]$/; assert$( R$.test(S$), 10, S$, '~', R$, "{} //~ ^\[object Object\]$" );
S$ = ({}); R$ = /^\[Object/; assert$( !R$.test(S$), 11, S$, '~', R$, "{} //!~ ^\[Object" );
S$ = ({}); R$ = (/^\[Object/i); assert$( R$.test(S$), 12, S$, '~', R$, "{} //#~ /^\[Object/i" );
S$ = String((123456)); R$ = String("123"); assert$( S$.substring(0, R$.length) == R$, 13, S$, 'startswith', R$, "123456 //startswith 123" );
S$ = String((123456)); R$ = String("456"); assert$( S$.substring(S$.length-R$.length) == R$, 14, S$, 'endswith', R$, "123456 //endswith 456" );

E$ = null; try { throw new Error("myexception") } catch(e) { E$ = e.message } S$ = String((E$)); R$ = String("myexception"); assert$( S$.substring(0, R$.length) == R$, 15, S$, 'startswith', R$, "throw new Error(\"myexception\") //@ startswith myexception" );
E$ = null; try { throw new Error("myexception") } catch(e) { E$ = e } S$ = (E$); R$ = (/чего\?/); assert$( !R$.test(S$), 16, S$, '~', R$, "throw new Error(\"myexception\") //#@ !~ /чего\?/" );
E$ = null; try { throw new Error("myexception") } catch(e) { E$ = e.message } S$ = (E$); R$ = /чего\?/; assert$( !R$.test(S$), 17, S$, '~', R$, "throw new Error(\"myexception\") //@ !~ чего\?" );


try {
	throw new Error("abc");
} catch(e) {
S$ = (e.message); R$ = "abc"; assert$( S$ == R$, 18, S$, '=', R$, "	e.message;			// abc" );
S$ = (e+""); R$ = "Error: abc"; assert$( S$ == R$, 19, S$, '=', R$, "	e+\"\";				// Error: abc" );
S$ = deepEqual$((e), (new Error("abc"))); assert$( !S$, 20, S$ && S$[0], '~~', S$ && S$[1], "	e					//# new Error(\"abc\")" );
}

console.log("=== Асинхронный тест");
setTimeout(function() {
S$ = (5); R$ = "5"; assert$( S$ == R$, 21, S$, '=', R$, "	5 // 5" );
}, 100);
