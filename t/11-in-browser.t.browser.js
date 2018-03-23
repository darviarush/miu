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
console.log('1..'+2);
console.log("= js-тесты в браузере");
console.log("== Введение");
console.log("== Параметры командной строки");
console.log("== Пример теста в браузере");
S$ = (window); R$ = "[object Window]"; assert$( S$ == R$, 1, S$, '=', R$, "window 		// [object Window]" );
S$ = (document); R$ = "[object HTMLDocument]"; assert$( S$ == R$, 2, S$, '=', R$, "document	// [object HTMLDocument]" );
