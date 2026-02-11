# PayrollEngine.Client.Scripting Actions
<br />

> Assembly `PayrollEngine.Client.Scripting, Version=0.9.0.0, Culture=neutral, PublicKeyToken=null`

> Date 2/11/2026 3:27 PM

<br />

---
### Age
| | |
|:-- |:-- |
| Description      | Get persons age      |
| Function type    | `Payroll`   |
| Categories       | `Date` |
| Parameters       | <ul><li>`birthDate` <i>The persons birth date</i> [`Date`]</li><li>`testDate` <i>Reference date (default: utc-now)</i> [`Date`]</li></ul> |

---
### ApplyRangeLookupValue
| | |
|:-- |:-- |
| Description      | Apply a range value to the lookup ranges considering the lookup range mode      |
| Function type    | `Payroll`   |
| Categories       | `Lookup` |
| Parameters       | <ul><li>`lookup` <i>The lookup name</i> [`String`]</li><li>`range` <i>The range value</i> [`Dec`]</li><li>`field` <i>The JSON value field name (optional)</i></li></ul> |

---
### Concat
| | |
|:-- |:-- |
| Description      | Concat multiple strings      |
| Function type    | `Payroll`   |
| Categories       | `String` |
| Parameters       | `values` <i>Value collection</i> [`String`]</ul> |

---
### Contains
| | |
|:-- |:-- |
| Description      | Test if value is from a specific value domain      |
| Function type    | `Payroll`   |
| Categories       | `String` |
| Parameters       | `values` <i>Value collection</i> [`Num`, `Date`, `String`]</ul> |

---
### GetCollectorValue
| | |
|:-- |:-- |
| Description      | Get collector value      |
| Function type    | `WageType`   |
| Categories       | `WageType` |
| Parameters       | `name` <i>The collector name</i> [`String`]</ul> |

---
### GetCycleCollectorValue
| | |
|:-- |:-- |
| Description      | Get collector year-to-date value      |
| Function type    | `Payrun`   |
| Categories       | `Collector` |
| Parameters       | `name` <i>The collector name</i> [`String`]</ul> |

---
### GetCycleWageTypeValue
| | |
|:-- |:-- |
| Description      | Get wage type year-to-date value by wage type name      |
| Function type    | `Payrun`   |
| Categories       | `WageType` |
| Parameters       | `name` <i>The wage type name</i> [`String`]</ul> |

---
### GetCycleWageTypeValue
| | |
|:-- |:-- |
| Description      | Get wage type year-to-date value by wage type number      |
| Function type    | `Payrun`   |
| Categories       | `WageType` |
| Parameters       | `number` <i>The wage type number</i> [`Dec`]</ul> |

---
### GetFieldValue
| | |
|:-- |:-- |
| Description      | Get case field value      |
| Function type    | `Payroll`   |
| Categories       | `Case` |
| Parameters       | `field` <i>The case field name</i> [`String`]</ul> |

---
### GetLookupValue
| | |
|:-- |:-- |
| Description      | Get lookup value by key and value field name      |
| Function type    | `Payroll`   |
| Categories       | `Lookup` |
| Parameters       | <ul><li>`lookup` <i>The lookup name</i> [`String`]</li><li>`key` <i>The lookup key</i></li><li>`rangeValue` <i>The lookup key or range value</i></li><li>`field` <i>The JSON value field name (optional)</i></li></ul> |

---
### GetLookupValue
| | |
|:-- |:-- |
| Description      | Get lookup value by key or range value      |
| Function type    | `Payroll`   |
| Categories       | `Lookup` |
| Parameters       | <ul><li>`lookup` <i>The lookup name</i> [`String`]</li><li>`keyOrRangeValue` <i>The lookup key or range value</i></li><li>`field` <i>The JSON value field name (optional)</i></li></ul> |

---
### GetPayrunResultValue
| | |
|:-- |:-- |
| Description      | Get payrun result value      |
| Function type    | `Payrun`   |
| Categories       | `Payrun` |
| Parameters       | `name` <i>The result name</i> [`String`]</ul> |

---
### GetRuntimeValue
| | |
|:-- |:-- |
| Description      | Get payrun runtime value      |
| Function type    | `Payrun`   |
| Categories       | `Runtime` |
| Parameters       | `key` <i>The value key</i> [`String`]</ul> |

---
### GetSourceFieldEnd
| | |
|:-- |:-- |
| Description      | Get the case relation source field end date      |
| Function type    | `CaseRelationBuild`   |
| Categories       | `RelationField` |
| Parameters       | `field` <i>The case field on the target case</i> [`String`]</ul> |

---
### GetSourceFieldStart
| | |
|:-- |:-- |
| Description      | Get the case relation source field start date      |
| Function type    | `CaseRelationBuild`   |
| Categories       | `RelationField` |
| Parameters       | `field` <i>The case field on the target case</i> [`String`]</ul> |

---
### GetSourceFieldValue
| | |
|:-- |:-- |
| Description      | Det the case relation source field value      |
| Function type    | `CaseRelationBuild`   |
| Categories       | `RelationField` |
| Parameters       | `field` <i>The case field on the source case</i> [`String`]</ul> |

---
### GetTargetFieldEnd
| | |
|:-- |:-- |
| Description      | Get the case relation target field end date      |
| Function type    | `CaseRelationBuild`   |
| Categories       | `RelationField` |
| Parameters       | `field` <i>The case field on the target case</i> [`String`]</ul> |

---
### GetTargetFieldStart
| | |
|:-- |:-- |
| Description      | Get the case relation target field start date      |
| Function type    | `CaseRelationBuild`   |
| Categories       | `RelationField` |
| Parameters       | `field` <i>The case field on the target case</i> [`String`]</ul> |

---
### GetTargetFieldValue
| | |
|:-- |:-- |
| Description      | Get the case relation target field value      |
| Function type    | `CaseRelationBuild`   |
| Categories       | `RelationField` |
| Parameters       | `field` <i>The case field on the target case</i> [`String`]</ul> |

---
### GetTimeSpan
| | |
|:-- |:-- |
| Description      | Get the timespan between two dates      |
| Function type    | `Payroll`   |
| Categories       | `Date` |
| Parameters       | <ul><li>`start` <i>The start date</i> [`Date`]</li><li>`end` <i>The end date</i> [`Date`]</li></ul> |

---
### GetWageTypeValueByName
| | |
|:-- |:-- |
| Description      | Get wage type value by name      |
| Function type    | `WageType`   |
| Categories       | `WageType` |
| Parameters       | `name` <i>The wage type name</i> [`String`]</ul> |

---
### GetWageTypeValueByNumber
| | |
|:-- |:-- |
| Description      | Get wage type value      |
| Function type    | `WageType`   |
| Categories       | `WageType` |
| Parameters       | `number` <i>Get wage type value by number</i> [`Dec`]</ul> |

---
### HasFieldValue
| | |
|:-- |:-- |
| Description      | Test for case field value      |
| Function type    | `Payroll`   |
| Categories       | `Case` |
| Parameters       | `field` <i>The case field name</i> [`String`]</ul> |

---
### HasLookupValue
| | |
|:-- |:-- |
| Description      | Test for lookup value by key and range value      |
| Function type    | `Payroll`   |
| Categories       | `Lookup` |
| Parameters       | <ul><li>`lookup` <i>The lookup name</i> [`String`]</li><li>`key` <i>The lookup key</i> [`String`]</li><li>`field` <i>The JSON value field name (optional)</i></li></ul> |

---
### HasLookupValue
| | |
|:-- |:-- |
| Description      | Test for lookup value by key      |
| Function type    | `Payroll`   |
| Categories       | `Lookup` |
| Parameters       | <ul><li>`lookup` <i>The lookup name</i> [`String`]</li><li>`keyOrRangeValue` <i>The lookup key or range value</i></li><li>`field` <i>The JSON value field name (optional)</i></li></ul> |

---
### HiddenField
| | |
|:-- |:-- |
| Description      | Hide all field inputs      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `Field` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### IIf
| | |
|:-- |:-- |
| Description      | Returns one of two parts, depending on the evaluation of an expression      |
| Function type    | `Payroll`   |
| Categories       | `System` |
| Parameters       | <ul><li>`expression` <i>Expression to evaluate</i></li><li>`onTrue` <i>Value or expression returned if expr is True</i></li><li>`onFalse` <i>Value or expression returned if expr is False</i></li></ul> |

---
### IfNull
| | |
|:-- |:-- |
| Description      | Returns the second value in case the first value is null      |
| Function type    | `Payroll`   |
| Categories       | `System` |
| Parameters       | <ul><li>`first` <i>Value to return if defined</i></li><li>`second` <i>Value to return if first value is undefined</i></li></ul> |

---
### IsNotNull
| | |
|:-- |:-- |
| Description      | Returns true whether the value is not Null      |
| Function type    | `Payroll`   |
| Categories       | `System` |
| Parameters       | `value` <i>Value to test</i></ul> |

---
### IsNull
| | |
|:-- |:-- |
| Description      | Returns true whether the value is Null      |
| Function type    | `Payroll`   |
| Categories       | `System` |
| Parameters       | `value` <i>Value to test</i></ul> |

---
### Log
| | |
|:-- |:-- |
| Description      | Log a message      |
| Function type    | `Payroll`   |
| Categories       | `System` |
| Parameters       | <ul><li>`message` <i>Message to log</i></li><li>`level` <i>Log level (default: Information)</i></li></ul> |

---
### Max
| | |
|:-- |:-- |
| Description      | Get the maximum value      |
| Function type    | `Payroll`   |
| Categories       | `Math` |
| Parameters       | <ul><li>`left` <i>The left compare value</i> [`Num`, `Date`, `TimeSpan`]</li><li>`right` <i>The right compare value</i> [`Num`, `Date`, `TimeSpan`]</li></ul> |

---
### Max
| | |
|:-- |:-- |
| Description      | Get the largest collection value      |
| Function type    | `Payroll`   |
| Categories       | `Math` |
| Parameters       | `values` <i>Value collection</i> [`Num`, `Date`, `TimeSpan`]</ul> |

---
### Min
| | |
|:-- |:-- |
| Description      | Get the minimum value      |
| Function type    | `Payroll`   |
| Categories       | `Math` |
| Parameters       | <ul><li>`left` <i>The left compare value</i> [`Num`, `Date`, `TimeSpan`]</li><li>`right` <i>The right compare value</i> [`Num`, `Date`, `TimeSpan`]</li></ul> |

---
### Min
| | |
|:-- |:-- |
| Description      | Get the smallest collection value      |
| Function type    | `Payroll`   |
| Categories       | `Math` |
| Parameters       | `values` <i>Value collection</i> [`Num`, `Date`, `TimeSpan`]</ul> |

---
### Range
| | |
|:-- |:-- |
| Description      | Ensure value is within a value range      |
| Function type    | `Payroll`   |
| Categories       | `Math` |
| Parameters       | <ul><li>`value` <i>The value to limit</i> [`Num`, `Date`, `TimeSpan`]</li><li>`min` <i>The minimum value</i> [`Num`, `Date`, `TimeSpan`]</li><li>`max` <i>The maximum value</i> [`Num`, `Date`, `TimeSpan`]</li></ul> |

---
### RemoveRuntimeValue
| | |
|:-- |:-- |
| Description      | Remove payrun runtime value      |
| Function type    | `Payrun`   |
| Categories       | `Runtime` |
| Parameters       | `key` <i>The value key</i> [`String`]</ul> |

---
### SameDay
| | |
|:-- |:-- |
| Description      | Test for same date day      |
| Function type    | `Payroll`   |
| Categories       | `Date` |
| Parameters       | <ul><li>`left` <i>The left date to compare</i> [`Date`]</li><li>`right` <i>The right date to compare</i> [`Date`]</li></ul> |

---
### SameMonth
| | |
|:-- |:-- |
| Description      | Test for same date month      |
| Function type    | `Payroll`   |
| Categories       | `Date` |
| Parameters       | <ul><li>`left` <i>The left date to compare</i> [`Date`]</li><li>`right` <i>The right date to compare</i> [`Date`]</li></ul> |

---
### SameYear
| | |
|:-- |:-- |
| Description      | Test for same date year      |
| Function type    | `Payroll`   |
| Categories       | `Date` |
| Parameters       | <ul><li>`left` <i>The left date to compare</i> [`Date`]</li><li>`right` <i>The right date to compare</i> [`Date`]</li></ul> |

---
### SetFieldAttachmentExtensions
| | |
|:-- |:-- |
| Description      | Set field attachments file extensions      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `Field` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`extensions` <i>The file extensions</i> [`String`]</li></ul> |

---
### SetFieldAttachmentMandatory
| | |
|:-- |:-- |
| Description      | Set field mandatory file attachments      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `Field` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldAttachmentNone
| | |
|:-- |:-- |
| Description      | Set field without file attachments      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `Field` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldAttachmentOptional
| | |
|:-- |:-- |
| Description      | Set field optional file attachments      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `Field` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldCheck
| | |
|:-- |:-- |
| Description      | Set field boolean as checkbox      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldCulture
| | |
|:-- |:-- |
| Description      | Set field value culture      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`culture` <i>The culture (https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/a9eac961-e77d-41a6-90a5-ce1a8b0cdb9c)</i> [`String`]</li></ul> |

---
### SetFieldEndFormat
| | |
|:-- |:-- |
| Description      | Set field end format      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldEnd` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`format` <i>The format (https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings)</i> [`String`]</li></ul> |

---
### SetFieldEndHelp
| | |
|:-- |:-- |
| Description      | Set field end help      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldEnd` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`help` <i>The field end help</i> [`String`]</li></ul> |

---
### SetFieldEndLabel
| | |
|:-- |:-- |
| Description      | Set field end label      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldEnd` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`label` <i>The field end label</i> [`String`]</li></ul> |

---
### SetFieldEndPickerOpenDay
| | |
|:-- |:-- |
| Description      | Set field end day date picker      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldEnd` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldEndPickerOpenMonth
| | |
|:-- |:-- |
| Description      | Set field end month date picker      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldEnd` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldEndPickerOpenYear
| | |
|:-- |:-- |
| Description      | Set field end year date picker      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldEnd` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldEndPickerTypeDateTime
| | |
|:-- |:-- |
| Description      | Set field end time picker      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldEnd` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldEndReadOnly
| | |
|:-- |:-- |
| Description      | Set field end read only      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldEnd` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldEndRequired
| | |
|:-- |:-- |
| Description      | Set field end required      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldEnd` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldFormat
| | |
|:-- |:-- |
| Description      | Set field value format      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`format` <i>The value format (https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings)</i> [`String`]</li></ul> |

---
### SetFieldLineCount
| | |
|:-- |:-- |
| Description      | Set field text line count      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`count` <i>The line count</i> [`Int`]</li></ul> |

---
### SetFieldMaxLength
| | |
|:-- |:-- |
| Description      | Set field maximum text length      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`length` <i>The length</i> [`Int`]</li></ul> |

---
### SetFieldMaxValue
| | |
|:-- |:-- |
| Description      | Set field maximum value      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`Num`]</li><li>`max` <i>The maximum value</i></li></ul> |

---
### SetFieldMinValue
| | |
|:-- |:-- |
| Description      | Set field minimum value      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`Num`]</li><li>`min` <i>The minimum value</i></li></ul> |

---
### SetFieldStartFormat
| | |
|:-- |:-- |
| Description      | Set field start format      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldStart` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`format` <i>The format (https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings)</i> [`String`]</li></ul> |

---
### SetFieldStartHelp
| | |
|:-- |:-- |
| Description      | Set field start help      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldStart` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`help` <i>The field start help</i> [`String`]</li></ul> |

---
### SetFieldStartLabel
| | |
|:-- |:-- |
| Description      | Set field start label      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldStart` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`label` <i>The field start label</i> [`String`]</li></ul> |

---
### SetFieldStartPickerOpenDay
| | |
|:-- |:-- |
| Description      | Set field start day date picker      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldStart` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldStartPickerOpenMonth
| | |
|:-- |:-- |
| Description      | Set field start month date picker      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldStart` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldStartPickerOpenYear
| | |
|:-- |:-- |
| Description      | Set field start year date picker      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldStart` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldStartPickerTypeDateTime
| | |
|:-- |:-- |
| Description      | Set field start picker date time      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldStart` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldStartReadOnly
| | |
|:-- |:-- |
| Description      | Set field start read only      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldStart` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldStartRequired
| | |
|:-- |:-- |
| Description      | Set field start required      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldStart` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldStepSize
| | |
|:-- |:-- |
| Description      | Set field numeric step size      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`Int`]</li><li>`size` <i>The step size</i></li></ul> |

---
### SetFieldValueAdornment
| | |
|:-- |:-- |
| Description      | Set field value adornment      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`adornment` <i>The adornment text</i> [`String`]</li></ul> |

---
### SetFieldValueHelp
| | |
|:-- |:-- |
| Description      | Set field value help      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`help` <i>The help text</i> [`String`]</li></ul> |

---
### SetFieldValueLabel
| | |
|:-- |:-- |
| Description      | Set field value label      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`label` <i>The label text</i> [`String`]</li></ul> |

---
### SetFieldValueMask
| | |
|:-- |:-- |
| Description      | Set field value mask      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | <ul><li>`field` <i>The target field</i> [`String`]</li><li>`mask` <i>The value mask (https://learn.microsoft.com/en-us/dotnet/api/system.windows.forms.maskedtextbox.mask)</i> [`String`]</li></ul> |

---
### SetFieldValuePickerOpenDay
| | |
|:-- |:-- |
| Description      | Set field value day date picker      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldValuePickerOpenMonth
| | |
|:-- |:-- |
| Description      | Set field value month date picker      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldValuePickerOpenYear
| | |
|:-- |:-- |
| Description      | Set field value year date picker      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldValueReadOnly
| | |
|:-- |:-- |
| Description      | Set field value read only      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetFieldValueRequired
| | |
|:-- |:-- |
| Description      | Set field value required      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `FieldValue` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### SetNamespace
| | |
|:-- |:-- |
| Description      | Set namespace to a name      |
| Function type    | `Payroll`   |
| Categories       | `System` |
| Parameters       | <ul><li>`name` <i>Name to be extended</i></li><li>`namespace` <i>Namespace to apply (default: regulation namespace)</i></li></ul> |

---
### SetPayrunResultValue
| | |
|:-- |:-- |
| Description      | Set payrun result value      |
| Function type    | `Payrun`   |
| Categories       | `Payrun` |
| Parameters       | <ul><li>`name` <i>The result name</i> [`String`]</li><li>`value` <i>The value to set</i></li><li>`type` <i>The value type (default: Money), [StringType]</i></li></ul> |

---
### SetRuntimeValue
| | |
|:-- |:-- |
| Description      | Set payrun runtime value      |
| Function type    | `Payrun`   |
| Categories       | `Runtime` |
| Parameters       | <ul><li>`key` <i>The value key</i> [`String`]</li><li>`value` <i>The value to set</i></li></ul> |

---
### SetTargetFieldEnd
| | |
|:-- |:-- |
| Description      | Set the case relation target field change end date      |
| Function type    | `CaseRelationBuild`   |
| Categories       | `RelationField` |
| Parameters       | <ul><li>`field` <i>The case field on the target case</i> [`String`]</li><li>`end` <i>The end date to set</i> [`Date`]</li></ul> |

---
### SetTargetFieldStart
| | |
|:-- |:-- |
| Description      | Set the case relation target field change start date      |
| Function type    | `CaseRelationBuild`   |
| Categories       | `RelationField` |
| Parameters       | <ul><li>`field` <i>The case field on the target case</i> [`String`]</li><li>`start` <i>The start date to set</i> [`Date`]</li></ul> |

---
### SetTargetFieldValue
| | |
|:-- |:-- |
| Description      | Set the case relation target field value      |
| Function type    | `CaseRelationBuild`   |
| Categories       | `RelationField` |
| Parameters       | <ul><li>`field` <i>The case field on the target case</i> [`String`]</li><li>`value` <i>The value to set</i></li></ul> |

---
### ShowFieldDescription
| | |
|:-- |:-- |
| Description      | Show field description      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `Field` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### VisibleField
| | |
|:-- |:-- |
| Description      | Show all field inputs      |
| Function type    | `CaseChange`   |
| Categories       | `FieldInput`, `Field` |
| Parameters       | `field` <i>The target field</i> [`String`]</ul> |

---
### Within
| | |
|:-- |:-- |
| Description      | Test value is within a value range      |
| Function type    | `Payroll`   |
| Categories       | `Math` |
| Parameters       | <ul><li>`value` <i>The value to test</i> [`Num`, `Date`, `TimeSpan`]</li><li>`min` <i>The minimum value</i> [`Num`, `Date`, `TimeSpan`]</li><li>`max` <i>The maximum value</i> [`Num`, `Date`, `TimeSpan`]</li></ul> |

---
### YearDiff
| | |
|:-- |:-- |
| Description      | Test for same date year      |
| Function type    | `Payroll`   |
| Categories       | `Date` |
| Parameters       | <ul><li>`start` <i>The start date</i> [`Date`]</li><li>`end` <i>The end date</i> [`Date`]</li></ul> |
