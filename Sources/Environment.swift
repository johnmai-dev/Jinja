//
//  Environment.swift
//
//
//  Created by John Mai on 2024/3/23.
//

import Foundation
import OrderedCollections

class Environment {
    var parent: Environment?

    var variables: [String: any RuntimeValue] = [
        "namespace": FunctionValue(value: { args, _ in
            if args.isEmpty {
                return ObjectValue(value: [:])
            }
            guard args.count == 1, let objectArg = args[0] as? ObjectValue else {
                throw JinjaError.runtime("`namespace` expects either zero arguments or a single object argument")
            }
            return objectArg
        })
    ]

    lazy var tests: [String: (any RuntimeValue...) throws -> Bool] = [
        "odd": { args in
            if let arg = args.first as? NumericValue, let intValue = arg.value as? Int {
                return intValue % 2 != 0
            } else {
                throw JinjaError.runtime("Cannot apply test 'odd' to type: \(type(of: args.first))")
            }
        },
        "even": { args in
            if let arg = args.first as? NumericValue, let intValue = arg.value as? Int {
                return intValue % 2 == 0
            } else {
                throw JinjaError.runtime("Cannot apply test 'even' to type: \(type(of: args.first))")
            }
        },
        "divisibleby": { args in
            guard let value = args[0] as? NumericValue,
                let num = args[1] as? NumericValue,
                let intValue = value.value as? Int,
                let intNum = num.value as? Int
            else {
                throw JinjaError.runtime("divisibleby test requires two integers")
            }
            return intValue % intNum == 0
        },
        "defined": { args in
            return !(args[0] is UndefinedValue)
        },
        "undefined": { args in
            return args[0] is UndefinedValue
        },
        "filter": { [weak self] (args: any RuntimeValue...) throws -> Bool in
            guard let name = args[0] as? StringValue else {
                throw JinjaError.runtime("filter test requires a string")
            }
            return self?.filters.keys.contains(name.value) ?? false
        },
        "test": { [weak self] (args: any RuntimeValue...) throws -> Bool in
            guard let name = args[0] as? StringValue else {
                throw JinjaError.runtime("test test requires a string")
            }
            return self?.tests.keys.contains(name.value) ?? false
        },
        "none": { args in
            return args[0] is NullValue
        },
        "boolean": { args in
            return args[0] is BooleanValue
        },
        "false": { args in
            if let arg = args[0] as? BooleanValue {
                return !arg.value
            }
            return false
        },
        "true": { args in
            if let arg = args[0] as? BooleanValue {
                return arg.value
            }
            return false
        },
        "integer": { args in
            if let arg = args[0] as? NumericValue {
                return arg.value is Int
            }
            return false
        },
        "float": { args in
            if let numericValue = args[0] as? NumericValue {
                return numericValue.value is Double
            }
            return false
        },
        "lower": { args in
            if let arg = args[0] as? StringValue {
                return arg.value == arg.value.lowercased()
            }
            return false
        },
        "upper": { args in
            if let arg = args[0] as? StringValue {
                return arg.value == arg.value.uppercased()
            }
            return false
        },
        "string": { args in
            return args[0] is StringValue
        },
        "mapping": { args in
            return args[0] is ObjectValue
        },
        "number": { args in
            return args[0] is NumericValue
        },
        "sequence": { args in
            let value = args[0]
            if value is ArrayValue || value is StringValue {
                return true
            }
            return false
        },
        "iterable": { args in
            return args[0] is ArrayValue || args[0] is StringValue || args[0] is ObjectValue
        },
        "callable": { args in
            return args[0] is FunctionValue
        },
        // TODO: Implement "sameas"
        // TODO: Implement "escaped"
        "in": { args in
            guard let seq = args[1] as? ArrayValue else {
                throw JinjaError.runtime("in test requires a sequence")
            }
            return seq.value.contains { item in
                self.doEqualTo([args[0], item])
            }
        },
        "==": { args in self.doEqualTo(args) },
        "eq": { args in self.doEqualTo(args) },
        "equalto": { args in self.doEqualTo(args) },
        "!=": { args in
            guard args.count == 2 else {
                throw JinjaError.runtime("!= test requires two arguments")
            }
            return !self.doEqualTo(args)
        },
        "ne": { args in
            guard args.count == 2 else {
                throw JinjaError.runtime("ne test requires two arguments")
            }
            return !self.doEqualTo(args)
        },
        ">": { args in
            guard args.count == 2 else {
                throw JinjaError.runtime("> test requires two arguments")
            }
            return try self.doGreaterThan(args)
        },
        "gt": { args in
            guard args.count == 2 else {
                throw JinjaError.runtime("gt test requires two arguments")
            }
            return try self.doGreaterThan(args)
        },
        "greaterthan": { args in
            guard args.count == 2 else {
                throw JinjaError.runtime("greaterthan test requires two arguments")
            }
            return try self.doGreaterThan(args)
        },
        ">=": { args in
            guard args.count == 2 else {
                throw JinjaError.runtime(">= test requires two arguments")
            }
            return try self.doGreaterThanOrEqual(args)
        },
        "ge": { args in
            guard args.count == 2 else {
                throw JinjaError.runtime("ge test requires two arguments")
            }
            return try self.doGreaterThanOrEqual(args)
        },
        "<": { args in
            guard args.count == 2 else {
                throw JinjaError.runtime("< test requires two arguments")
            }
            return try self.doLessThan(args)
        },
        "lt": { args in
            guard args.count == 2 else {
                throw JinjaError.runtime("lt test requires two arguments")
            }
            return try self.doLessThan(args)
        },
        "lessthan": { args in
            guard args.count == 2 else {
                throw JinjaError.runtime("lessthan test requires two arguments")
            }
            return try self.doLessThan(args)
        },
        "<=": { args in
            guard args.count == 2 else {
                throw JinjaError.runtime("<= test requires two arguments")
            }
            return try self.doLessThanOrEqual(args)
        },
        "le": { args in
            guard args.count == 2 else {
                throw JinjaError.runtime("le test requires two arguments")
            }
            return try self.doLessThanOrEqual(args)
        },
    ]

    lazy var filters: [String: ([any RuntimeValue], Environment) throws -> any RuntimeValue] = [
        "abs": { args, env in
            guard let numericValue = args[0] as? NumericValue else {
                throw JinjaError.runtime("abs filter requires a number")
            }
            if let intValue = numericValue.value as? Int {
                return NumericValue(value: abs(intValue))
            } else if let doubleValue = numericValue.value as? Double {
                return NumericValue(value: abs(doubleValue))
            } else {
                throw JinjaError.runtime("Unsupported numeric type for abs filter")
            }
        },
        "attr": { args, env in
            guard let name = args[1] as? StringValue else {
                throw JinjaError.runtime("attr filter requires an object and attribute name")
            }
            let obj = args[0]
            if let objValue = obj as? ObjectValue {
                return objValue.value[name.value] ?? UndefinedValue()
            }
            return UndefinedValue()
        },
        "batch": { args, env in
            guard let arrayValue = args[0] as? ArrayValue,
                let linecount = args[1] as? NumericValue,
                let count = linecount.value as? Int
            else {
                throw JinjaError.runtime("batch filter requires an array and line count")
            }
            let fillWith = args.count > 2 ? args[2] : nil
            var result: [[any RuntimeValue]] = []
            var temp: [any RuntimeValue] = []
            for item in arrayValue.value {
                if temp.count == count {
                    result.append(temp)
                    temp = []
                }
                temp.append(item)
            }
            if !temp.isEmpty {
                if let fill = fillWith, temp.count < count {
                    temp += Array(repeating: fill, count: count - temp.count)
                }
                result.append(temp)
            }
            return ArrayValue(value: result.map { ArrayValue(value: $0) })
        },
        "capitalize": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("capitalize filter requires a string")
            }
            return StringValue(value: stringValue.value.capitalized)
        },
        "center": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("center filter requires a string")
            }
            let width = (args.count > 1 && args[1] is NumericValue) ? (args[1] as! NumericValue).value as! Int : 80
            let padding = max(0, width - stringValue.value.count)
            let leftPadding = padding / 2
            let rightPadding = padding - leftPadding
            return StringValue(
                value: String(repeating: " ", count: leftPadding) + stringValue.value
                    + String(repeating: " ", count: rightPadding)
            )
        },
        "count": { args, env in
            let value = args[0]
            if let arrayValue = value as? ArrayValue {
                return NumericValue(value: arrayValue.value.count)
            } else if let stringValue = value as? StringValue {
                return NumericValue(value: stringValue.value.count)
            } else if let objectValue = value as? ObjectValue {
                return NumericValue(value: objectValue.value.count)
            }
            throw JinjaError.runtime("Cannot count value of type \(type(of: value))")
        },
        "d": { args, env in try self.doDefault(args, env) },
        "default": { args, env in try self.doDefault(args, env) },
        "dictsort": { args, env in
            guard let dict = args[0] as? ObjectValue else {
                throw JinjaError.runtime("dictsort filter requires a dictionary")
            }
            let caseSensitive = args.count > 1 ? (args[1] as? BooleanValue)?.value ?? false : false
            let by = args.count > 2 ? (args[2] as? StringValue)?.value ?? "key" : "key"
            let reverse = args.count > 3 ? (args[3] as? BooleanValue)?.value ?? false : false
            let sortedDict = try dict.storage.sorted { (item1, item2) in
                let a: Any, b: Any
                if by == "key" {
                    a = item1.key
                    b = item2.key
                } else if by == "value" {
                    a = item1.value
                    b = item2.value
                } else {
                    throw JinjaError.runtime("Invalid 'by' argument for dictsort filter")
                }
                let result: Bool
                if let aString = a as? String, let bString = b as? String {
                    result = caseSensitive ? aString < bString : aString.lowercased() < bString.lowercased()
                } else if let aNumeric = a as? NumericValue, let bNumeric = b as? NumericValue {
                    if let aInt = aNumeric.value as? Int, let bInt = bNumeric.value as? Int {
                        result = aInt < bInt
                    } else if let aDouble = aNumeric.value as? Double, let bDouble = bNumeric.value as? Double {
                        result = aDouble < bDouble
                    } else {
                        throw JinjaError.runtime("Cannot compare values in dictsort filter")
                    }
                } else {
                    throw JinjaError.runtime("Cannot compare values in dictsort filter")
                }
                return reverse ? !result : result
            }
            return ArrayValue(
                value: sortedDict.map { (key, value) in
                    return ArrayValue(value: [StringValue(value: key), value])
                }
            )
        },
        "e": { args, env in try self.doEscape(args, env) },
        "escape": { args, env in try self.doEscape(args, env) },
        "filesizeformat": { args, env in
            guard let value = args[0] as? NumericValue, let size = value.value as? Double else {
                throw JinjaError.runtime("filesizeformat filter requires a numeric value")
            }
            let binary = args.count > 1 ? (args[1] as? BooleanValue)?.value ?? false : false
            let units =
                binary
                ? [" KiB", " MiB", " GiB", " TiB", " PiB", " EiB", " ZiB", " YiB"]
                : [" kB", " MB", " GB", " TB", " PB", " EB", " ZB", " YB"]
            let base: Double = binary ? 1024.0 : 1000.0
            if size < 1.0 {
                return StringValue(value: "\(Int(size)) Byte")  // Fixed: Wrap String in StringValue
            }
            let i = Int(floor(log(size) / log(base)))
            let unit = units[min(i, units.count - 1)]
            let num = size / pow(base, Double(i))
            return StringValue(value: String(format: "%.1f%@", num, unit))  // Fixed: Wrap String in StringValue
        },
        "first": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("first filter requires an array")
            }
            return arrayValue.value.first ?? UndefinedValue()
        },
        "float": { args, env in
            guard let value = args[0] as? NumericValue else {
                return NumericValue(value: 0.0)
            }
            if let doubleValue = value.value as? Double {
                return NumericValue(value: doubleValue)
            } else if let intValue = value.value as? Int {
                return NumericValue(value: Double(intValue))
            } else {
                return NumericValue(value: 0.0)
            }
        },
        "forceescape": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("forceescape filter requires a string")
            }
            return StringValue(
                value: stringValue.value.replacingOccurrences(of: "&", with: "&amp;")
                    .replacingOccurrences(of: "<", with: "&lt;")
                    .replacingOccurrences(of: ">", with: "&gt;")
                    .replacingOccurrences(of: "\"", with: "&quot;")
                    .replacingOccurrences(of: "'", with: "&#39;")
            )
        },
        "format": { args, env in
            guard let formatString = args[0] as? StringValue else {
                throw JinjaError.runtime("format filter requires a format string")
            }
            let values = args.dropFirst().map { $0 as? StringValue }
            let formattedString = String(format: formatString.value, arguments: values.map { $0?.value ?? "" })
            return StringValue(value: formattedString)
        },
        "groupby": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("groupby filter requires an array")
            }
            guard let attribute = args[1] as? StringValue else {
                throw JinjaError.runtime("groupby filter requires an attribute name")
            }
            let caseSensitive = args.count > 2 ? (args[2] as? BooleanValue)?.value ?? false : false
            var groups: [String: [any RuntimeValue]] = [:]
            for item in arrayValue.value {
                guard let objectValue = item as? ObjectValue,
                    let groupKey = objectValue.value[attribute.value] as? StringValue
                else {
                    continue
                }
                let key = caseSensitive ? groupKey.value : groupKey.value.lowercased()
                groups[key, default: []].append(item)
            }
            return ArrayValue(
                value: groups.map { (key, value) in
                    return ObjectValue(value: ["grouper": StringValue(value: key), "list": ArrayValue(value: value)])
                }
            )
        },
        "indent": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("indent filter requires a string")
            }
            let width = (args.count > 1 && args[1] is NumericValue) ? (args[1] as! NumericValue).value as! Int : 4
            let indent = String(repeating: " ", count: width)
            let first = args.count > 2 ? (args[2] as? BooleanValue)?.value ?? false : false
            let blank = args.count > 3 ? (args[3] as? BooleanValue)?.value ?? false : false
            var lines = stringValue.value.split(separator: "\n", omittingEmptySubsequences: false)
            for i in lines.indices {
                if (first || i > 0) && (blank || !lines[i].isEmpty) {
                    lines[i] = Substring(indent + lines[i])
                }
            }
            return StringValue(value: lines.joined(separator: "\n"))
        },
        "int": { args, env in
            guard let value = args[0] as? NumericValue else {
                return NumericValue(value: 0)
            }
            if let intValue = value.value as? Int {
                return NumericValue(value: intValue)
            } else if let doubleValue = value.value as? Double {
                return NumericValue(value: Int(doubleValue))
            } else {
                return NumericValue(value: 0)
            }
        },
        "items": { args, env in
            guard let iterable = args.first else {
                throw JinjaError.runtime("items filter requires an iterable")
            }
            if let arrayValue = iterable as? ArrayValue {
                return ArrayValue(
                    value: arrayValue.value.map {
                        ArrayValue(value: [$0])
                    }
                )
            } else if let objectValue = iterable as? ObjectValue {
                return ArrayValue(
                    value: objectValue.storage.map { (key, value) in
                        ArrayValue(value: [StringValue(value: key), value])
                    }
                )
            } else {
                throw JinjaError.runtime("items filter can only be applied to arrays and objects")
            }
        },
        "join": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("join filter requires an array")
            }
            let separator = (args.count > 1 && args[1] is StringValue) ? (args[1] as! StringValue).value : ""
            let stringValues = arrayValue.value.compactMap { $0 as? StringValue }
            return StringValue(value: stringValues.map { $0.value }.joined(separator: separator))
        },
        "last": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("last filter requires an array")
            }
            return arrayValue.value.last ?? UndefinedValue()
        },
        "length": { args, env in
            guard let arg = args.first else {
                throw JinjaError.runtime("length filter expects one argument")
            }

            if let arrayValue = arg as? ArrayValue {
                return NumericValue(value: arrayValue.value.count)
            } else if let stringValue = arg as? StringValue {
                return NumericValue(value: stringValue.value.count)
            } else if let objectValue = arg as? ObjectValue {
                return NumericValue(value: objectValue.value.count)
            } else {
                throw JinjaError.runtime("Cannot get length of type: \(type(of: arg))")
            }
        },
        "list": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("list filter requires an array")
            }
            return arrayValue
        },
        "lower": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("lower filter requires a string")
            }
            return StringValue(value: stringValue.value.lowercased())
        },
        "map": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("map filter requires an array")
            }
            // If no attribute is provided, return the array as is
            if args.count == 1 {
                return arrayValue
            }
            // Handle attribute mapping
            if let attribute = args[1] as? StringValue {
                let values = arrayValue.value.compactMap { item -> (any RuntimeValue)? in
                    if let objectValue = item as? ObjectValue {
                        return objectValue.value[attribute.value]
                    }
                    return nil
                }
                return ArrayValue(value: values)
            }
            // Handle function mapping
            if let function = args[1] as? FunctionValue {
                let values = try arrayValue.value.map { item in
                    try function.value([item], env)
                }
                return ArrayValue(value: values)
            }
            throw JinjaError.runtime("map filter requires either an attribute name or a function")
        },
        "min": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("min filter requires an array")
            }
            if arrayValue.value.isEmpty {
                return UndefinedValue()
            }
            if let numericValues = arrayValue.value as? [NumericValue] {
                let numbers = numericValues.compactMap { $0.value as? Double }
                if numbers.count != numericValues.count {
                    throw JinjaError.runtime("min filter requires all array elements to be numbers")
                }
                return NumericValue(value: numbers.min() ?? 0)
            } else if let stringValues = arrayValue.value as? [StringValue] {
                return StringValue(value: stringValues.map { $0.value }.min() ?? "")
            } else {
                throw JinjaError.runtime("min filter requires an array of numbers or strings")
            }
        },
        "max": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("max filter requires an array")
            }
            if arrayValue.value.isEmpty {
                return UndefinedValue()
            }
            if let numericValues = arrayValue.value as? [NumericValue] {
                let numbers = numericValues.compactMap { $0.value as? Double }
                if numbers.count != numericValues.count {
                    throw JinjaError.runtime("max filter requires all array elements to be numbers")
                }
                return NumericValue(value: numbers.max() ?? 0)
            } else if let stringValues = arrayValue.value as? [StringValue] {
                return StringValue(value: stringValues.map { $0.value }.max() ?? "")
            } else {
                throw JinjaError.runtime("max filter requires an array of numbers or strings")
            }
        },
        "pprint": { args, env in
            guard let value = args.first else {
                throw JinjaError.runtime("pprint filter expects one argument")
            }
            return StringValue(value: String(describing: value))
        },
        "random": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("random filter requires an array")
            }
            if let randomIndex = arrayValue.value.indices.randomElement() {
                return arrayValue.value[randomIndex]
            } else {
                return UndefinedValue()
            }
        },
        "reject": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("reject filter requires an array")
            }
            guard let testName = args[1] as? StringValue else {
                throw JinjaError.runtime("reject filter requires a test name")
            }
            guard let test = env.tests[testName.value] else {
                throw JinjaError.runtime("Unknown test '\(testName.value)'")
            }
            var result: [any RuntimeValue] = []
            for item in arrayValue.value {
                // Correctly pass arguments to the test function
                if try !test(item) {  // Negate the result for 'reject'
                    result.append(item)
                }
            }
            return ArrayValue(value: result)
        },
        "rejectattr": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("rejectattr filter requires an array")
            }
            guard let attribute = args[1] as? StringValue else {
                throw JinjaError.runtime("rejectattr filter requires an attribute name")
            }
            var result: [any RuntimeValue] = []
            for item in arrayValue.value {
                guard let objectValue = item as? ObjectValue,
                    let attrValue = objectValue.value[attribute.value]
                else {
                    continue
                }
                if args.count == 2 {
                    if !attrValue.bool() {
                        result.append(item)
                    }
                } else {
                    let testName = (args[2] as? StringValue)?.value ?? "defined"
                    guard let test = env.tests[testName] else {
                        throw JinjaError.runtime("Unknown test '\(testName)'")
                    }
                    // Correctly pass arguments to the test function
                    if try !test(attrValue) {  // Note the negation (!) for rejectattr
                        result.append(item)
                    }
                }
            }
            return ArrayValue(value: result)
        },
        "replace": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("replace filter requires a string")
            }
            guard let oldValue = args[1] as? StringValue else {
                throw JinjaError.runtime("replace filter requires an old value string")
            }
            guard let newValue = args[2] as? StringValue else {
                throw JinjaError.runtime("replace filter requires a new value string")
            }
            let count = (args.count > 3 && args[3] is NumericValue) ? (args[3] as! NumericValue).value as! Int : Int.max
            return StringValue(
                value: stringValue.value.replacingOccurrences(
                    of: oldValue.value,
                    with: newValue.value,
                    options: [],
                    range: nil
                )
            )
        },
        "reverse": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("reverse filter requires an array")
            }
            return ArrayValue(value: arrayValue.value.reversed())
        },
        "round": { args, env in
            guard let value = args[0] as? NumericValue, let number = value.value as? Double else {
                throw JinjaError.runtime("round filter requires a number")
            }
            let precision = (args.count > 1 && args[1] is NumericValue) ? (args[1] as! NumericValue).value as! Int : 0
            let method = (args.count > 2 && args[2] is StringValue) ? (args[2] as! StringValue).value : "common"
            let factor = pow(10, Double(precision))
            let roundedNumber: Double
            if method == "common" {
                roundedNumber = round(number * factor) / factor
            } else if method == "ceil" {
                roundedNumber = ceil(number * factor) / factor
            } else if method == "floor" {
                roundedNumber = floor(number * factor) / factor
            } else {
                throw JinjaError.runtime("Invalid method for round filter")
            }
            return NumericValue(value: roundedNumber)
        },
        "safe": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("safe filter requires a string")
            }
            return stringValue  // In this minimal example, we don't handle marking strings as safe
        },
        "select": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("select filter requires an array")
            }
            guard let testName = args[1] as? StringValue else {
                throw JinjaError.runtime("select filter requires a test name")
            }
            guard let test = env.tests[testName.value] else {
                throw JinjaError.runtime("Unknown test '\(testName.value)'")
            }
            var result: [any RuntimeValue] = []
            for item in arrayValue.value {
                if try test(item) {
                    result.append(item)
                }
            }
            return ArrayValue(value: result)
        },
        "selectattr": { args, env in
            guard let array = args[0] as? ArrayValue else {
                throw JinjaError.runtime("selectattr filter requires an array")
            }
            guard let attribute = args[1] as? StringValue else {
                throw JinjaError.runtime("selectattr filter requires an attribute name")
            }
            guard args.count > 2 else {
                throw JinjaError.runtime("selectattr filter requires a test")
            }
            var result: [any RuntimeValue] = []
            for item in array.value {
                if let obj = item as? ObjectValue,
                    let attrValue = obj.value[attribute.value]
                {
                    if args[2] is StringValue && args[2].bool() {
                        // Simple boolean test
                        if attrValue.bool() {
                            result.append(item)
                        }
                    } else if args.count > 3 {
                        // Test with comparison value
                        if let testName = (args[2] as? StringValue)?.value {
                            let testValue = args[3]
                            if testName == "equalto" {
                                // Handle equality test
                                if let strAttr = attrValue as? StringValue,
                                    let strTest = testValue as? StringValue
                                {
                                    if strAttr.value == strTest.value {
                                        result.append(item)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return ArrayValue(value: result)
        },
        "slice": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("slice filter requires an array")
            }
            guard let slices = args[1] as? NumericValue, let numSlices = slices.value as? Int else {
                throw JinjaError.runtime("slice filter requires a number of slices")
            }
            let fillWith = args.count > 2 ? args[2] : nil
            let itemsPerSlice = arrayValue.value.count / numSlices
            let slicesWithExtra = arrayValue.value.count % numSlices
            var result: [[any RuntimeValue]] = []
            var startIndex = 0
            for i in 0 ..< numSlices {
                let count = itemsPerSlice + (i < slicesWithExtra ? 1 : 0)
                var slice = Array(arrayValue.value[startIndex ..< startIndex + count])
                if let fillWithValue = fillWith, i >= slicesWithExtra, slice.count < itemsPerSlice {
                    slice.append(fillWithValue)
                }
                result.append(slice)
                startIndex += count
            }
            return ArrayValue(value: result.map { ArrayValue(value: $0) })
        },
        "sort": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("sort filter requires an array")
            }
            let reverse = args.count > 1 ? (args[1] as? BooleanValue)?.value ?? false : false
            let caseSensitive = args.count > 2 ? (args[2] as? BooleanValue)?.value ?? false : false
            let attribute = args.count > 3 ? (args[3] as? StringValue)?.value : nil
            let sortedArray = try arrayValue.value.sorted { (a, b) in
                let aValue: Any
                let bValue: Any
                if let attribute = attribute {
                    guard let aObject = a as? ObjectValue, let bObject = b as? ObjectValue else {
                        throw JinjaError.runtime("sort filter with attribute requires an array of objects")
                    }
                    guard let aAttr = aObject.value[attribute], let bAttr = bObject.value[attribute] else {
                        throw JinjaError.runtime("sort filter could not get attribute from both objects")
                    }
                    aValue = aAttr
                    bValue = bAttr
                } else {
                    aValue = a
                    bValue = b
                }
                let result: Bool
                if let aString = aValue as? StringValue, let bString = bValue as? StringValue {
                    result =
                        caseSensitive
                        ? aString.value < bString.value : aString.value.lowercased() < bString.value.lowercased()
                } else if let aNumeric = aValue as? NumericValue, let bNumeric = bValue as? NumericValue {
                    if let aInt = aNumeric.value as? Int, let bInt = bNumeric.value as? Int {
                        result = aInt < bInt
                    } else if let aDouble = aNumeric.value as? Double, let bDouble = bNumeric.value as? Double {
                        result = aDouble < bDouble
                    } else {
                        throw JinjaError.runtime("Cannot compare values in sort filter")
                    }
                } else {
                    throw JinjaError.runtime("Cannot compare values in sort filter")
                }
                return reverse ? !result : result
            }
            return ArrayValue(value: sortedArray)
        },
        "string": { args, env in
            guard let arg = args.first else {
                throw JinjaError.runtime("string filter expects one argument")
            }
            // In Jinja2 in Python, the `string` filter calls Python's `str` function on dicts, which which uses single quotes for strings. Here we're using double quotes in `tojson`, which is probably better for LLMs anyway, but this will result in differences with output from Jinja2.
            return try StringValue(value: stringify(arg, whitespaceControl: true))
        },
        "striptags": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("striptags filter requires a string")
            }
            // A very basic implementation to remove HTML tags
            let tagPattern = #"<[^>]+>"#
            let noTagsString = stringValue.value.replacingOccurrences(
                of: tagPattern,
                with: "",
                options: .regularExpression
            )
            return StringValue(value: noTagsString)
        },
        "sum": { args, env in
            guard let arrayValue = args[0] as? ArrayValue else {
                throw JinjaError.runtime("sum filter requires an array")
            }
            let attribute = (args.count > 1 && args[1] is StringValue) ? (args[1] as! StringValue).value : nil
            let start = (args.count > 2 && args[2] is NumericValue) ? (args[2] as! NumericValue).value as! Double : 0.0

            var sum: Double = start
            for item in arrayValue.value {
                if let attribute = attribute, let objectValue = item as? ObjectValue,
                    let attrValue = objectValue.value[attribute] as? NumericValue
                {
                    if let intValue = attrValue.value as? Int {
                        sum += Double(intValue)
                    } else if let doubleValue = attrValue.value as? Double {
                        sum += doubleValue
                    }
                } else if let numericValue = item as? NumericValue {
                    if let intValue = numericValue.value as? Int {
                        sum += Double(intValue)
                    } else if let doubleValue = numericValue.value as? Double {
                        sum += doubleValue
                    }
                }
            }
            return NumericValue(value: sum)
        },
        "title": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("title filter requires a string")
            }
            return StringValue(value: stringValue.value.capitalized)
        },
        "trim": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("trim filter requires a string")
            }
            return StringValue(value: stringValue.value.trimmingCharacters(in: .whitespacesAndNewlines))
        },
        "truncate": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("truncate filter requires a string")
            }
            let length = (args.count > 1 && args[1] is NumericValue) ? (args[1] as! NumericValue).value as! Int : 255
            let killwords = (args.count > 2 && args[2] is BooleanValue) ? (args[2] as! BooleanValue).value : false
            let end = (args.count > 3 && args[3] is StringValue) ? (args[3] as! StringValue).value : "..."
            if stringValue.value.count <= length {
                return stringValue
            }
            if killwords {
                return StringValue(value: String(stringValue.value.prefix(length - end.count)) + end)
            } else {
                let truncated = String(stringValue.value.prefix(length - end.count))
                if let lastSpace = truncated.lastIndex(of: " ") {
                    return StringValue(value: String(truncated[..<lastSpace]) + end)
                } else {
                    return StringValue(value: truncated + end)
                }
            }
        },
        "unique": { args, env in
            // Handle different iterable types
            func getIterableItems(_ value: any RuntimeValue) throws -> [any RuntimeValue] {
                switch value {
                case let arrayValue as ArrayValue:
                    return arrayValue.value
                case let stringValue as StringValue:
                    return stringValue.value.map { StringValue(value: String($0)) }
                case let objectValue as ObjectValue:
                    return objectValue.storage.map { key, value in
                        ArrayValue(value: [StringValue(value: key), value])
                    }
                default:
                    throw JinjaError.runtime("Value must be iterable (array, string, or object)")
                }
            }
            // Get the input iterable
            guard let input = args.first else {
                throw JinjaError.runtime("unique filter requires an iterable")
            }
            let caseSensitive = args.count > 1 ? (args[1] as? BooleanValue)?.value ?? false : false
            let attribute = args.count > 2 ? args[2] : nil
            // Enhanced getter function to handle both string and integer attributes
            func getter(_ item: any RuntimeValue) throws -> String {
                if let attribute = attribute {
                    // Handle string attribute
                    if let strAttr = attribute as? StringValue,
                        let objectValue = item as? ObjectValue,
                        let attrValue = objectValue.value[strAttr.value]
                    {
                        return caseSensitive ? try stringify(attrValue) : try stringify(attrValue).lowercased()
                    }
                    // Handle integer attribute
                    else if let numAttr = attribute as? NumericValue,
                        let index = numAttr.value as? Int
                    {
                        if let arrayValue = item as? ArrayValue {
                            guard index >= 0 && index < arrayValue.value.count else {
                                throw JinjaError.runtime("Index \(index) out of range")
                            }
                            let value = arrayValue.value[index]
                            return caseSensitive ? try stringify(value) : try stringify(value).lowercased()
                        } else if let stringValue = item as? StringValue {
                            guard index >= 0 && index < stringValue.value.count else {
                                throw JinjaError.runtime("Index \(index) out of range")
                            }
                            let value = StringValue(
                                value: String(
                                    stringValue.value[
                                        stringValue.value.index(stringValue.value.startIndex, offsetBy: index)
                                    ]
                                )
                            )
                            return caseSensitive ? try stringify(value) : try stringify(value).lowercased()
                        }
                    }
                    throw JinjaError.runtime("Cannot get attribute '\(try stringify(attribute))' from item")
                }
                return caseSensitive ? try stringify(item) : try stringify(item).lowercased()
            }
            var seen: [String: Bool] = [:]
            var result: [any RuntimeValue] = []
            // Process all items from the iterable
            let items = try getIterableItems(input)
            for item in items {
                let key = try getter(item)
                if seen[key] == nil {
                    seen[key] = true
                    result.append(item)
                }
            }
            return ArrayValue(value: result)
        },
        "upper": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("upper filter requires a string")
            }
            return StringValue(value: stringValue.value.uppercased())
        },
        "urlencode": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("urlencode filter requires a string")
            }

            let encodedString = stringValue.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return StringValue(value: encodedString)
        },
        "urlize": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("urlize filter requires a string")
            }
            let trimUrlLimit =
                (args.count > 1 && args[1] is NumericValue) ? (args[1] as! NumericValue).value as? Int : nil
            let nofollow = (args.count > 2 && args[2] is BooleanValue) ? (args[2] as! BooleanValue).value : false
            let target = (args.count > 3 && args[3] is StringValue) ? (args[3] as! StringValue).value : nil
            let urlPattern =
                #"(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})"#
            var urlizedString = stringValue.value
            if let regex = try? NSRegularExpression(pattern: urlPattern, options: []) {
                let nsRange = NSRange(
                    stringValue.value.startIndex ..< stringValue.value.endIndex,
                    in: stringValue.value
                )
                let matches = regex.matches(in: stringValue.value, options: [], range: nsRange)

                for match in matches.reversed() {
                    let urlRange = Range(match.range, in: stringValue.value)!
                    let url = String(stringValue.value[urlRange])
                    var trimmedUrl = url
                    if let limit = trimUrlLimit, url.count > limit {
                        trimmedUrl = String(url.prefix(limit)) + "..."
                    }
                    var link = "<a href=\"\(url)\""
                    if nofollow {
                        link += " rel=\"nofollow\""
                    }
                    if let target = target {
                        link += " target=\"\(target)\""
                    }
                    link += ">\(trimmedUrl)</a>"
                    urlizedString.replaceSubrange(urlRange, with: link)
                }
            }

            return StringValue(value: urlizedString)
        },
        "wordcount": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("wordcount filter requires a string")
            }
            let words = stringValue.value.split(separator: " ")
            return NumericValue(value: words.count)
        },
        "wordwrap": { args, env in
            guard let stringValue = args[0] as? StringValue else {
                throw JinjaError.runtime("wordwrap filter requires a string")
            }
            let width = (args.count > 1 && args[1] is NumericValue) ? (args[1] as! NumericValue).value as! Int : 79
            let breakLongWords = (args.count > 2 && args[2] is BooleanValue) ? (args[2] as! BooleanValue).value : true
            let wrapString = (args.count > 3 && args[3] is StringValue) ? (args[3] as! StringValue).value : "\n"
            var result = ""
            var currentLineLength = 0
            for word in stringValue.value.split(separator: " ", omittingEmptySubsequences: false) {
                if currentLineLength + word.count > width {
                    if currentLineLength > 0 {
                        result += wrapString
                        currentLineLength = 0
                    }
                    if word.count > width && breakLongWords {
                        while word.count > width {
                            result += word.prefix(width) + wrapString
                            let index = word.index(word.startIndex, offsetBy: width)
                            let remainder = word[index...]
                            currentLineLength = remainder.count
                        }
                    }
                }
                if !result.isEmpty {
                    result += " "
                    currentLineLength += 1
                }
                result += word
                currentLineLength += word.count
            }
            return StringValue(value: result)
        },
        "xmlattr": { args, env in
            guard let dict = args[0] as? ObjectValue else {
                throw JinjaError.runtime("xmlattr filter requires a dictionary")
            }
            let autospace = args.count > 1 ? (args[1] as? BooleanValue)?.value ?? true : true
            var result = ""
            for (key, value) in dict.storage {
                if !(value is UndefinedValue) && !(value is NullValue) {
                    if autospace {
                        result += " "
                    }
                    if let stringValue = value as? StringValue {
                        result +=
                            "\(key)=\"\(stringValue.value.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;"))\""
                    } else {
                        result += "\(key)=\"\(value)\""
                    }
                }
            }
            return StringValue(value: result)
        },
        "tojson": { args, env in
            guard let firstArg = args.first else {
                throw JinjaError.runtime("tojson filter expects at least one argument")
            }
            var indent: Int? = nil
            if args.count > 1, let kwargs = args.last as? ObjectValue,
                let indentArg = kwargs.value["indent"] as? NumericValue,
                let indentInt = indentArg.value as? Int
            {
                indent = indentInt
            }
            return try StringValue(value: toJSON(firstArg, indent: indent, whitespaceControl: false))
        },
    ]

    init(parent: Environment? = nil) {
        self.parent = parent
    }

    //    func isFunction<T>(_ value: Any, functionType: T.Type) -> Bool {
    //        return value is T
    //    }

    private func convertToRuntimeValues(input: Any?) throws -> any RuntimeValue {
        // Handle already converted RuntimeValue
        if let runtimeValue = input as? any RuntimeValue {
            return runtimeValue
        }
        // Handle nil values
        if input == nil {
            return NullValue()
        }
        if case Optional<Any>.none = input {
            return NullValue()
        }
        // Helper function to handle any OrderedDictionary type
        func convertOrderedDictionary<T>(_ dict: OrderedDictionary<String, T>) throws -> ObjectValue {
            var object: [String: any RuntimeValue] = [:]
            var keyOrder: [String] = []

            for (key, value) in dict {
                // Crucial: Convert Optional<T> to T, using NullValue if nil
                let convertedValue = (value as Any?) ?? NullValue()
                object[key] = try self.convertToRuntimeValues(input: convertedValue)
                keyOrder.append(key)
            }
            return ObjectValue(value: object, keyOrder: keyOrder)
        }
        // Handle other values
        switch input {
        case let value as Bool:
            return BooleanValue(value: value)
        case let value as Int:
            return NumericValue(value: value)
        case let value as Double:
            return NumericValue(value: value)
        case let value as Float:
            return NumericValue(value: value)
        case let value as String:
            return StringValue(value: value)
        case let data as Data:
            guard let string = String(data: data, encoding: .utf8) else {
                throw JinjaError.runtime("Failed to convert data to string")
            }
            return StringValue(value: string)
        case let fn as (String) throws -> Void:
            return FunctionValue { args, _ in
                guard let stringArg = args[0] as? StringValue else {
                    throw JinjaError.runtime("Argument must be a StringValue")
                }
                try fn(stringArg.value)
                return NullValue()
            }
        case let fn as (Bool) throws -> Void:
            return FunctionValue { args, _ in
                guard let boolArg = args[0] as? BooleanValue else {
                    throw JinjaError.runtime("Argument must be a BooleanValue")
                }
                try fn(boolArg.value)
                return NullValue()
            }
        case let fn as (Int, Int?, Int) -> [Int]:
            return FunctionValue { args, _ in
                guard args.count > 0, let arg0 = args[0] as? NumericValue, let int0 = arg0.value as? Int else {
                    throw JinjaError.runtime("First argument must be an Int")
                }
                var int1: Int? = nil
                if args.count > 1 {
                    if let numericValue = args[1] as? NumericValue, let tempInt1 = numericValue.value as? Int {
                        int1 = tempInt1
                    } else if !(args[1] is NullValue) {  // Accept NullValue for optional second argument
                        throw JinjaError.runtime("Second argument must be an Int or nil")
                    }
                }
                var int2: Int = 1
                if args.count > 2 {
                    if let numericValue = args[2] as? NumericValue, let tempInt2 = numericValue.value as? Int {
                        int2 = tempInt2
                    } else {
                        throw JinjaError.runtime("Third argument must be an Int")
                    }
                }
                let result = fn(int0, int1, int2)
                return ArrayValue(value: result.map { NumericValue(value: $0) })
            }
        case let values as [Any?]:
            let items = try values.map { try self.convertToRuntimeValues(input: $0) }
            return ArrayValue(value: items)
        case let orderedDict as OrderedDictionary<String, String>:
            return try convertOrderedDictionary(orderedDict)
        case let orderedDict as OrderedDictionary<String, OrderedDictionary<String, Any>>:
            return try convertOrderedDictionary(orderedDict)
        case let orderedDict as OrderedDictionary<String, OrderedDictionary<String, String>>:
            return try convertOrderedDictionary(orderedDict)
        case let orderedDict as OrderedDictionary<String, Any?>:
            return try convertOrderedDictionary(orderedDict)
        case let orderedDict as OrderedDictionary<String, Any>:
            return try convertOrderedDictionary(orderedDict)
        case let dictionary as [String: Any?]:
            var object: [String: any RuntimeValue] = [:]
            var keyOrder: [String] = []
            for (key, value) in dictionary {
                object[key] = try self.convertToRuntimeValues(input: value)
                keyOrder.append(key)
            }
            return ObjectValue(value: object, keyOrder: keyOrder)
        default:
            throw JinjaError.runtime(
                "Cannot convert to runtime value: \(String(describing: input)) type:\(type(of: input))"
            )
        }
    }

    @discardableResult
    func set(name: String, value: Any) throws -> any RuntimeValue {
        let runtimeValue = try self.convertToRuntimeValues(input: value)
        return try self.declareVariable(name: name, value: runtimeValue)
    }

    private func declareVariable(name: String, value: any RuntimeValue) throws -> any RuntimeValue {
        if self.variables.keys.contains(name) {
            throw JinjaError.syntax("Variable already declared: \(name)")
        }

        self.variables[name] = value
        return value
    }

    @discardableResult
    func setVariable(name: String, value: any RuntimeValue) throws -> any RuntimeValue {
        self.variables[name] = value
        return value
    }

    private func resolve(name: String) throws -> Environment {
        if self.variables.keys.contains(name) {
            return self
        }

        if let parent = self.parent {
            return try parent.resolve(name: name)
        }

        throw JinjaError.runtime("Unknown variable: \(name)")
    }

    func lookupVariable(name: String) -> any RuntimeValue {
        do {
            return try self.resolve(name: name).variables[name] ?? UndefinedValue()
        } catch {
            return UndefinedValue()
        }
    }

    // Filters

    private func doDefault(_ args: [any RuntimeValue], _ env: Environment) throws -> any RuntimeValue {
        let value = args[0]
        let defaultValue = args.count > 1 ? args[1] : StringValue(value: "")
        let boolean = args.count > 2 ? (args[2] as? BooleanValue)?.value ?? false : false
        if value is UndefinedValue || (boolean && !value.bool()) {
            return defaultValue
        }
        return value
    }

    private func doEscape(_ args: [any RuntimeValue], _ env: Environment) throws -> any RuntimeValue {
        guard let stringValue = args[0] as? StringValue else {
            throw JinjaError.runtime("escape filter requires a string")
        }
        return StringValue(
            value: stringValue.value.replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
        )
    }

    private func doEqualTo(_ args: [any RuntimeValue]) -> Bool {
        if args.count == 2 {
            if let left = args[0] as? StringValue, let right = args[1] as? StringValue {
                return left.value == right.value
            } else if let left = args[0] as? NumericValue, let right = args[1] as? NumericValue,
                let leftInt = left.value as? Int, let rightInt = right.value as? Int
            {
                return leftInt == rightInt
            } else if let left = args[0] as? BooleanValue, let right = args[1] as? BooleanValue {
                return left.value == right.value
            } else {
                return false
            }
        } else {
            return false
        }
    }

    // Tests

    private func doGreaterThan(_ args: [any RuntimeValue]) throws -> Bool {
        if let left = args[0] as? StringValue, let right = args[1] as? StringValue {
            return left.value > right.value
        } else if let left = args[0] as? NumericValue, let right = args[1] as? NumericValue {
            if let leftInt = left.value as? Int, let rightInt = right.value as? Int {
                return leftInt > rightInt
            } else if let leftDouble = left.value as? Double, let rightDouble = right.value as? Double {
                return leftDouble > rightDouble
            } else if let leftInt = left.value as? Int, let rightDouble = right.value as? Double {
                return Double(leftInt) > rightDouble
            } else if let leftDouble = left.value as? Double, let rightInt = right.value as? Int {
                return leftDouble > Double(rightInt)
            }
        }
        throw JinjaError.runtime("Cannot compare values of different types")
    }

    private func doGreaterThanOrEqual(_ args: [any RuntimeValue]) throws -> Bool {
        return try doGreaterThan(args) || doEqualTo(args)
    }

    private func doLessThan(_ args: [any RuntimeValue]) throws -> Bool {
        if let left = args[0] as? StringValue, let right = args[1] as? StringValue {
            return left.value < right.value
        } else if let left = args[0] as? NumericValue, let right = args[1] as? NumericValue {
            if let leftInt = left.value as? Int, let rightInt = right.value as? Int {
                return leftInt < rightInt
            } else if let leftDouble = left.value as? Double, let rightDouble = right.value as? Double {
                return leftDouble < rightDouble
            } else if let leftInt = left.value as? Int, let rightDouble = right.value as? Double {
                return Double(leftInt) < rightDouble
            } else if let leftDouble = left.value as? Double, let rightInt = right.value as? Int {
                return leftDouble < Double(rightInt)
            }
        }
        throw JinjaError.runtime("Cannot compare values of different types")
    }

    private func doLessThanOrEqual(_ args: [any RuntimeValue]) throws -> Bool {
        return try doLessThan(args) || doEqualTo(args)
    }
}
