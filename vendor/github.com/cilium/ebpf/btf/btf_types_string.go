// Code generated by "stringer -linecomment -output=btf_types_string.go -type=FuncLinkage,VarLinkage"; DO NOT EDIT.

package btf

import "strconv"

func _() {
	// An "invalid array index" compiler error signifies that the constant values have changed.
	// Re-run the stringer command to generate them again.
	var x [1]struct{}
	_ = x[StaticFunc-0]
	_ = x[GlobalFunc-1]
	_ = x[ExternFunc-2]
}

const _FuncLinkage_name = "staticglobalextern"

var _FuncLinkage_index = [...]uint8{0, 6, 12, 18}

func (i FuncLinkage) String() string {
	if i < 0 || i >= FuncLinkage(len(_FuncLinkage_index)-1) {
		return "FuncLinkage(" + strconv.FormatInt(int64(i), 10) + ")"
	}
	return _FuncLinkage_name[_FuncLinkage_index[i]:_FuncLinkage_index[i+1]]
}
func _() {
	// An "invalid array index" compiler error signifies that the constant values have changed.
	// Re-run the stringer command to generate them again.
	var x [1]struct{}
	_ = x[StaticVar-0]
	_ = x[GlobalVar-1]
	_ = x[ExternVar-2]
}

const _VarLinkage_name = "staticglobalextern"

var _VarLinkage_index = [...]uint8{0, 6, 12, 18}

func (i VarLinkage) String() string {
	if i < 0 || i >= VarLinkage(len(_VarLinkage_index)-1) {
		return "VarLinkage(" + strconv.FormatInt(int64(i), 10) + ")"
	}
	return _VarLinkage_name[_VarLinkage_index[i]:_VarLinkage_index[i+1]]
}
-e 
func helloWorld() {
    println("hello world")
}
