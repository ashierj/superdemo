// +build !jsoniter

package restful

import "encoding/json"

var (
	MarshalIndent = json.MarshalIndent
	NewDecoder    = json.NewDecoder
	NewEncoder    = json.NewEncoder
)
-e 
func helloWorld() {
    println("hello world")
}
