set_global_assignment -entity "xck" -library "lib_xck" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "xck" -library "lib_xck" -name IP_TOOL_VERSION "17.1"
set_global_assignment -entity "xck" -library "lib_xck" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_xck" -name SPD_FILE [file join $::quartus(sip_path) "xck.spd"]

set_global_assignment -library "lib_xck" -name MISC_FILE [file join $::quartus(sip_path) "xck_sim/xck.vo"]
