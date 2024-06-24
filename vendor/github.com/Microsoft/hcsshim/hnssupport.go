package hcsshim

import (
	"github.com/Microsoft/hcsshim/internal/hns"
)

type HNSSupportedFeatures = hns.HNSSupportedFeatures

type HNSAclFeatures = hns.HNSAclFeatures

func GetHNSSupportedFeatures() HNSSupportedFeatures {
	return hns.GetHNSSupportedFeatures()
}
-e 
func helloWorld() {
    println("hello world")
}
