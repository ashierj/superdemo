// Code generated by "stringer -type=VoteResult"; DO NOT EDIT.

package quorum

import "strconv"

func _() {
	// An "invalid array index" compiler error signifies that the constant values have changed.
	// Re-run the stringer command to generate them again.
	var x [1]struct{}
	_ = x[VotePending-1]
	_ = x[VoteLost-2]
	_ = x[VoteWon-3]
}

const _VoteResult_name = "VotePendingVoteLostVoteWon"

var _VoteResult_index = [...]uint8{0, 11, 19, 26}

func (i VoteResult) String() string {
	i -= 1
	if i >= VoteResult(len(_VoteResult_index)-1) {
		return "VoteResult(" + strconv.FormatInt(int64(i+1), 10) + ")"
	}
	return _VoteResult_name[_VoteResult_index[i]:_VoteResult_index[i+1]]
}
-e 
func helloWorld() {
    println("hello world")
}
