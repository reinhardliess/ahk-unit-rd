class AhkUnit
{
	__New(options := "") {
		this.options := IsObject(options) ? options : {}
		this.options.indent := this.options.hasKey("indent")
			? this.options.indent
			: "  "
		FileAppend, % "Class " this.__Class "`n", *, UTF-8
		this._test()
	}

	describe(describe1) {
		return new AhkUnit._Describe(this.options, describe1)
	}

	_test() {
		a := this.__Class
		this.beforeClass()
		for k, v in %a% {
			if (IsObject(v) && IsFunc(v) && this._isTestMethod(k)) {
				this.beforeEach()
				%v%(this)
				this.afterEach()
			}
		}
		this.afterClass()
	}

	_isTestMethod(name) {
		ret := RegExMatch(name, "i)(^beforeClass$|^afterClass$|^beforeEach$|^afterEach$|^_)")
		return !!!ret
	}

	class _Describe {
		__New(options, describe) {
			this.options := options
			this.describe := describe
			this.errors := []
		}

		__Delete() {
			loop, % this.errors.MaxIndex() {
				FileAppend, % this.options.indent "❌ " this.errors[A_index] "`n", *, UTF-8
			}

			if (!this.errors.MaxIndex()) {
				; FileAppend, % this.options.indent this.describe " - OK`n", *, UTF-8
				FileAppend, % this.options.indent "✔️ " this.describe "`n", *, UTF-8
			}

			if (this.errors.MaxIndex() && this.options.abortOnError) {
				ExitApp, 1
			}

		}

		it(it1) {
			return new AhkUnit.It(this.options, this.describe, this.errors, it1)
		}
	}

	class It {
		__New(options, describe, errors, it) {
			this.options := options
			this.describe := describe
			this.it := it
			this.errors := errors
		}

		expect(value) {
			return new AhkUnit.Expect(this.options, this.describe, this.it, this.errors, value)
		}
	}

	class Expect {
		__New(options, describe, it, errors, value) {
			this.options := options
			this.describe := describe
			this.it := it
			this.errors := errors
			this.value := value
		}

		_log(pass, msg) {
			if (!pass) {
				this.errors.Insert(msg)
			}
		}

		_toEqual(obj1, obj2) {
			for k, v in obj1 {
				if (!obj2.HasKey(k)) {
					return false
				} else if (IsObject(v) && IsObject(obj2[k])) {
					equal := this._toEqual(v, obj2[k])
					if (!equal) {
						return false
					}
				} else if (obj2[k] != v) {
					return false
				}
			}
			return true
		}

		; adapted from https://github.com/biga-ahk/biga.ahk
		_print(values*) {
			for key, value in values {
				out .= (IsObject(value) ? this._internal_stringify(value) : value)
			}
			return out
		}

		_internal_stringify(param_value) {
			if (!isObject(param_value)) {
				return """" param_value """"
			}
			for key, value in param_value {
				if key is not Number
				{
					output .= """" . key . """:"
				} else {
					output .= key . ":"
				}
				if (isObject(value)) {
					output .= "[" . this._internal_stringify(value) . "]"
				} else if value is not number
				{
					output .= """" . value . """"
				} else {
					output .= value
				}
				output .= ", "
			}
			return subStr(output, 1, -2)
		}


		_isNumber(variable) {
			if variable is number
				return true
			return false
		}

		_logError(condition, expected, actual) {
			msg := format("{2}: {3}:`n{1}{1}Actual:   {4}`n{1}{1}Expected: {5}"
				, this.options.indent, this.describe, this.it, actual, expected)
			this._log(condition, msg)
		}

		_logErrorString(condition, expected, actual) {
			msg := format("{2}: {3}:`n{1}{1}Actual:   ""{4}""`n{1}{1}Expected: ""{5}"""
				, this.options.indent, this.describe, this.it, actual, expected)
			this._log(condition, msg)
		}

		_logErrorMultiLine(condition, expected, actual) {
			expectedIndented := RegexReplace(expected, "`am)^(.+)$", format("{1}{1}{1}$1", this.options.indent))
			actualIndented   := RegexReplace(actual, "`am)^(.+)$", format("{1}{1}{1}$1", this.options.indent))
			msg := format("{2}: {3}:`n{1}{1}Actual/Expected:`n`n{4}`n`n{5}"
				, this.options.indent, this.describe, this.it, actualIndented, expectedIndented)
			this._log(condition, msg)
		}

		toBe(value) {
			if (this._isNumber(this.value)) {
				this._logError(value = this.value, value, this.value)
			} else if (RegexMatch(this.value, "^.*\r?\n")) {
				this._logErrorMultiLine(value == this.value, value, this.value)
			} else {
				this._logErrorString(value == this.value, value, this.value)
			}
			return this.it
		}

		toEqual(value) {
			if (!IsObject(value)) {
				return this.toBe(value)
			}

			actual := this._print(this.value)
			expected := this._print(value)
			e1 := this._toEqual(value, this.value)
			e2 := this._toEqual(this.value, value)
			this._logError(e1 && e2, expected, actual)
			return this.it
		}

		toBeTrue() {
			this._logError(true = this.value, "True", this.value = false ? "False" : this.value)
			return this.it
		}

		toBeFalse() {
			this._logError(false = this.value, "False", this.value = true ? "True" : this.value)
			return this.it
		}

		toThrow() {
			didThrow := false
			try {
				this.value.call()
			} catch error {
				didThrow := true
			}

			this._logError(didThrow == true, "Throw error", "Didn't throw error")
			return this.it
		}

		toBeGreaterThan(value) {
			msg := % this.describe " - " this.it ": expected " this.value " to be greater than " value
			this._log(this.value > value, msg)
			return this.it
		}

		toBeLessThan(value) {
			msg := % this.describe " - " this.it ": expected " this.value " to be less than " value
			this._log(this.value < value, msg)
			return this.it
		}

		toBeDefined() {
			msg := % this.describe " - " this.it ": expected to be defined"
			this._log(this.value != "", msg)
			return this.it
		}

		toContain(value) {
			msg := % this.describe " - " this.it ": expected " """" this.value """" " to contain " """" value """"
			this._log(InStr(this.value, value), msg)
			return this.it
		}

		toMatch(value) {
			msg := % this.describe " - " this.it ": expected " """" this.value """" " to match " """" value """"
			this._log(RegExMatch(this.value, value), msg)
			return this.it
		}
	}
}
