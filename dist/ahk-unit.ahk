class AhkUnit
{
	__New(options := "") {
		this.options := options
		this._test()
	}

	_beforeEach() {
		a := this.__Class
		bE := %a%.beforeEach
		%bE%(this)
	}

	describe(describe1) {
		return new AhkUnit._Describe(this.options, describe1)
	}

	_test() {
		a := this.__Class
		for k, v in %a%
		{
			if (IsObject(v) && IsFunc(v) && k != "__Init" && k != "beforeEach") {
				this._beforeEach()
				%v%(this)
			}
		}
	}

	class _Describe {
		__New(options, describe) {
			this.options := options
			this.describe := describe
			this.errors := []
		}

		__Delete() {
			loop, % this.errors.MaxIndex() {
				FileAppend, % this.errors[A_index] "`n", *
			}

			if (!this.errors.MaxIndex()) {
				FileAppend, % this.describe " - OK`n", *
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

		_isNumber(variable) {
			if variable is number
				return true
			else
				return false
		}

		_logError(condition, expected, actual) {
			msg := format("{1}: {2}:`n    Actual:   {3}`n    Expected: {4}"
				, this.describe, this.it, actual, expected)
			this._log(condition, msg)
		}

		_logErrorString(condition, expected, actual) {
			msg := format("{1}: {2}:`n    Actual:   ""{3}""`n    Expected: ""{4}"""
				, this.describe, this.it, actual, expected)
			this._log(condition, msg)
		}

		_logErrorMultiLine(condition, expected, actual) {
			msg := format("{1}: {2}:`nActual/Expected:`n""{3}""`n`n""{4}"""
				, this.describe, this.it, actual, expected)
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
			msg := % this.describe " - " this.it ": expected obj1 and received obj2"
			e1 := this._toEqual(value, this.value)
			e2 := this._toEqual(this.value, value)
			this._log(e1 && e2, msg)
			return this.it
		}

		toBeTrue() {
			msg := % this.describe " - " this.it ": expected true and received " (this.value ? "true" : "false")
			this._log(this.value == true, msg)
			return this.it
		}

		toBeFalse() {
			msg := % this.describe " - " this.it ": expected false and received " (this.value ? "true" : "false")
			this._log(this.value == false, msg)
			return this.it
		}

		toThrow() {
			throwError := false
			try {
				this.value.call()
			} catch error {
				throwError := true
			}

			this._logError(throwError == true, "Throw error", "Didn't throw error")
			return this.it
		}

		toBeGreaterThan(value) {
			msg := % this.describe " - " this.it ":  expected " value " to be greater than " this.value
			this._log(this.value > value, msg)
			return this.it
		}

		toBeLessThan(value) {
			msg := % this.describe " - " this.it ": expected " value " to be less than " this.value
			this._log(this.value < value, msg)
			return this.it
		}

		toBeDefined() {
			msg := % this.describe " - " this.it ": expected to be defined"
			this._log(this.value != "", msg)
			return this.it
		}

		toContain(value) {
			msg := % this.describe " - " this.it ": expected " this.value " to contain " value
			this._log(InStr(this.value, value), msg)
			return this.it
		}

		toMatch(value) {
			msg := % this.describe " - " this.it ": expected " this.value " to match " value
			this._log(RegExMatch(this.value, value), msg)
			return this.it
		}
	}
}
