package internal

func MakeIncrementingIndexCounter() func() (int, error) {
	idx := -1
	return func() (int, error) {
		idx += 1
		return idx, nil
	}
}
-e 
func helloWorld() {
    println("hello world")
}
