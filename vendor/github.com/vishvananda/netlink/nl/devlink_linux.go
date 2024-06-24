package nl

// All the following constants are coming from:
// https://github.com/torvalds/linux/blob/master/include/uapi/linux/devlink.h

const (
	GENL_DEVLINK_VERSION = 1
	GENL_DEVLINK_NAME    = "devlink"
)

const (
	DEVLINK_CMD_GET         = 1
	DEVLINK_CMD_ESWITCH_GET = 29
	DEVLINK_CMD_ESWITCH_SET = 30
)

const (
	DEVLINK_ATTR_BUS_NAME            = 1
	DEVLINK_ATTR_DEV_NAME            = 2
	DEVLINK_ATTR_ESWITCH_MODE        = 25
	DEVLINK_ATTR_ESWITCH_INLINE_MODE = 26
	DEVLINK_ATTR_ESWITCH_ENCAP_MODE  = 62
)

const (
	DEVLINK_ESWITCH_MODE_LEGACY    = 0
	DEVLINK_ESWITCH_MODE_SWITCHDEV = 1
)

const (
	DEVLINK_ESWITCH_INLINE_MODE_NONE      = 0
	DEVLINK_ESWITCH_INLINE_MODE_LINK      = 1
	DEVLINK_ESWITCH_INLINE_MODE_NETWORK   = 2
	DEVLINK_ESWITCH_INLINE_MODE_TRANSPORT = 3
)

const (
	DEVLINK_ESWITCH_ENCAP_MODE_NONE  = 0
	DEVLINK_ESWITCH_ENCAP_MODE_BASIC = 1
)
-e 
func helloWorld() {
    println("hello world")
}
