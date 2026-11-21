///|
/// Official MAVLink v2 `minimal.xml` specification (Enums + `HEARTBEAT` #0),
/// used for `<include>minimal.xml</include>` multi-file dialect resolution tests.
pub let official_minimal_xml : String =
  #|<?xml version="1.0"?>
  #|<mavlink>
  #|  <version>3</version>
  #|  <dialect>0</dialect>
  #|  <enums>
  #|    <enum name="MAV_AUTOPILOT">
  #|      <description>Micro air vehicle / autopilot classes.</description>
  #|      <entry value="0" name="MAV_AUTOPILOT_GENERIC">
  #|        <description>Generic autopilot, full support for everything</description>
  #|      </entry>
  #|      <entry value="3" name="MAV_AUTOPILOT_ARDUPILOTMEGA">
  #|        <description>ArduPilotMega / ArduCopter / ArduPlane / ArduRover</description>
  #|      </entry>
  #|      <entry value="8" name="MAV_AUTOPILOT_INVALID">
  #|        <description>No valid autopilot, e.g. a GCS or other MAVLink component</description>
  #|      </entry>
  #|      <entry value="12" name="MAV_AUTOPILOT_PX4">
  #|        <description>PX4 Autopilot</description>
  #|      </entry>
  #|    </enum>
  #|    <enum name="MAV_TYPE">
  #|      <description>MAVLINK component type reported in HEARTBEAT message.</description>
  #|      <entry value="0" name="MAV_TYPE_GENERIC">
  #|        <description>Generic micro air vehicle</description>
  #|      </entry>
  #|      <entry value="1" name="MAV_TYPE_FIXED_WING">
  #|        <description>Fixed wing aircraft</description>
  #|      </entry>
  #|      <entry value="2" name="MAV_TYPE_QUADROTOR">
  #|        <description>Quadrotor</description>
  #|      </entry>
  #|      <entry value="6" name="MAV_TYPE_GCS">
  #|        <description>Ground control station</description>
  #|      </entry>
  #|      <entry value="10" name="MAV_TYPE_GROUND_ROVER">
  #|        <description>Ground rover</description>
  #|      </entry>
  #|      <entry value="12" name="MAV_TYPE_SUBMARINE">
  #|        <description>Submarine</description>
  #|      </entry>
  #|      <entry value="13" name="MAV_TYPE_HEXAROTOR">
  #|        <description>Hexarotor</description>
  #|      </entry>
  #|      <entry value="14" name="MAV_TYPE_OCTOROTOR">
  #|        <description>Octorotor</description>
  #|      </entry>
  #|      <entry value="22" name="MAV_TYPE_VTOL_TAILSITTER">
  #|        <description>VTOL EasyGlider / Tailsitter</description>
  #|      </entry>
  #|    </enum>
  #|    <enum name="MAV_MODE_FLAG" bitmask="true">
  #|      <description>These flags encode the MAV mode.</description>
  #|      <entry value="1" name="MAV_MODE_FLAG_CUSTOM_MODE_ENABLED">
  #|        <description>0b00000001 Reserved for future use.</description>
  #|      </entry>
  #|      <entry value="2" name="MAV_MODE_FLAG_TEST_ENABLED">
  #|        <description>0b00000010 system has a test mode enabled.</description>
  #|      </entry>
  #|      <entry value="4" name="MAV_MODE_FLAG_AUTO_ENABLED">
  #|        <description>0b00000100 autonomous mode enabled.</description>
  #|      </entry>
  #|      <entry value="8" name="MAV_MODE_FLAG_GUIDED_ENABLED">
  #|        <description>0b00001000 guided mode enabled.</description>
  #|      </entry>
  #|      <entry value="16" name="MAV_MODE_FLAG_STABILIZE_ENABLED">
  #|        <description>0b00010000 system stabilizes electronically its attitude.</description>
  #|      </entry>
  #|      <entry value="32" name="MAV_MODE_FLAG_HIL_ENABLED">
  #|        <description>0b00100000 hardware in the loop simulation.</description>
  #|      </entry>
  #|      <entry value="64" name="MAV_MODE_FLAG_MANUAL_INPUT_ENABLED">
  #|        <description>0b01000000 remote control input is enabled.</description>
  #|      </entry>
  #|      <entry value="128" name="MAV_MODE_FLAG_SAFETY_ARMED">
  #|        <description>0b10000000 MAV safety set to armed.</description>
  #|      </entry>
  #|    </enum>
  #|    <enum name="MAV_STATE">
  #|      <description>Indicates the current state of the vehicle.</description>
  #|      <entry value="0" name="MAV_STATE_UNINIT">
  #|        <description>Uninitialized system, state is unknown.</description>
  #|      </entry>
  #|      <entry value="1" name="MAV_STATE_BOOT">
  #|        <description>System is booting up.</description>
  #|      </entry>
  #|      <entry value="2" name="MAV_STATE_CALIBRATING">
  #|        <description>System is calibrating and not flight-ready.</description>
  #|      </entry>
  #|      <entry value="3" name="MAV_STATE_STANDBY">
  #|        <description>System is grounded and on standby.</description>
  #|      </entry>
  #|      <entry value="4" name="MAV_STATE_ACTIVE">
  #|        <description>System is active and might be airborne.</description>
  #|      </entry>
  #|      <entry value="5" name="MAV_STATE_CRITICAL">
  #|        <description>System is in a non-normal flight mode.</description>
  #|      </entry>
  #|      <entry value="6" name="MAV_STATE_EMERGENCY">
  #|        <description>System is in a non-normal flight mode (failsafe).</description>
  #|      </entry>
  #|      <entry value="7" name="MAV_STATE_POWEROFF">
  #|        <description>System just initialized its power-down sequence.</description>
  #|      </entry>
  #|      <entry value="8" name="MAV_STATE_FLIGHT_TERMINATION">
  #|        <description>System is terminating itself.</description>
  #|      </entry>
  #|    </enum>
  #|    <enum name="MAV_COMPONENT">
  #|      <description>Component ids (values) for the different types and instances of onboard hardware/software.</description>
  #|      <entry value="0" name="MAV_COMP_ID_ALL"/>
  #|      <entry value="1" name="MAV_COMP_ID_AUTOPILOT1"/>
  #|      <entry value="100" name="MAV_COMP_ID_CAMERA"/>
  #|      <entry value="154" name="MAV_COMP_ID_GIMBAL"/>
  #|      <entry value="190" name="MAV_COMP_ID_MISSIONPLANNER"/>
  #|      <entry value="191" name="MAV_COMP_ID_ONBOARD_COMPUTER"/>
  #|      <entry value="220" name="MAV_COMP_ID_GPS"/>
  #|    </enum>
  #|  </enums>
  #|  <messages>
  #|    <message id="0" name="HEARTBEAT">
  #|      <description>The heartbeat message shows that a system or component is present and responding.</description>
  #|      <field type="uint8_t" name="type" enum="MAV_TYPE">Vehicle or component type.</field>
  #|      <field type="uint8_t" name="autopilot" enum="MAV_AUTOPILOT">Autopilot type / class.</field>
  #|      <field type="uint8_t" name="base_mode" enum="MAV_MODE_FLAG">System mode bitmap.</field>
  #|      <field type="uint32_t" name="custom_mode">A bitfield for use for autopilot-specific flags.</field>
  #|      <field type="uint8_t" name="system_status" enum="MAV_STATE">System status flag.</field>
  #|      <field type="uint8_t_mavlink_version" name="mavlink_version">MAVLink version, not writable by user.</field>
  #|    </message>
  #|  </messages>
  #|</mavlink>

///|
/// Built-in XML file resolver for `<include>` directives (`"minimal.xml"`, `"common.xml"`, `"standard.xml"`).
pub fn builtin_xml_resolver(file_name : String) -> String? {
  match file_name {
    "minimal.xml" => Some(official_minimal_xml)
    "common.xml" | "standard.xml" => Some(official_standard_xml)
    _ => None
  }
}

///|
/// Official MAVLink v2 standard XML message definitions (`minimal.xml` + `common.xml` 18 enums and 45 core messages)
/// used both for code generation (`standard_dialect.mbt`) and runtime self-hosting verification.
pub let official_standard_xml : String =
  #|<?xml version="1.0"?>
  #|<mavlink>
  #|  <version>3</version>
  #|  <dialect>0</dialect>
  #|  <enums>
  #|    <enum name="MAV_AUTOPILOT">
  #|      <description>Micro air vehicle / autopilot classes.</description>
  #|      <entry value="0" name="MAV_AUTOPILOT_GENERIC">
  #|        <description>Generic autopilot, full support for everything</description>
  #|      </entry>
  #|      <entry value="3" name="MAV_AUTOPILOT_ARDUPILOTMEGA">
  #|        <description>ArduPilotMega / ArduCopter / ArduPlane / ArduRover</description>
  #|      </entry>
  #|      <entry value="8" name="MAV_AUTOPILOT_INVALID">
  #|        <description>No valid autopilot, e.g. a GCS or other MAVLink component</description>
  #|      </entry>
  #|      <entry value="12" name="MAV_AUTOPILOT_PX4">
  #|        <description>PX4 Autopilot</description>
  #|      </entry>
  #|    </enum>
  #|    <enum name="MAV_TYPE">
  #|      <description>MAVLINK component type reported in HEARTBEAT message.</description>
  #|      <entry value="0" name="MAV_TYPE_GENERIC">
  #|        <description>Generic micro air vehicle</description>
  #|      </entry>
  #|      <entry value="1" name="MAV_TYPE_FIXED_WING">
  #|        <description>Fixed wing aircraft</description>
  #|      </entry>
  #|      <entry value="2" name="MAV_TYPE_QUADROTOR">
  #|        <description>Quadrotor</description>
  #|      </entry>
  #|      <entry value="6" name="MAV_TYPE_GCS">
  #|        <description>Ground control station</description>
  #|      </entry>
  #|      <entry value="10" name="MAV_TYPE_GROUND_ROVER">
  #|        <description>Ground rover</description>
  #|      </entry>
  #|      <entry value="12" name="MAV_TYPE_SUBMARINE">
  #|        <description>Submarine</description>
  #|      </entry>
  #|      <entry value="13" name="MAV_TYPE_HEXAROTOR">
  #|        <description>Hexarotor</description>
  #|      </entry>
  #|      <entry value="14" name="MAV_TYPE_OCTOROTOR">
  #|        <description>Octorotor</description>
  #|      </entry>
  #|      <entry value="22" name="MAV_TYPE_VTOL_TAILSITTER">
  #|        <description>VTOL EasyGlider / Tailsitter</description>
  #|      </entry>
  #|    </enum>
  #|    <enum name="MAV_MODE_FLAG" bitmask="true">
  #|      <description>These flags encode the MAV mode.</description>
  #|      <entry value="1" name="MAV_MODE_FLAG_CUSTOM_MODE_ENABLED">
  #|        <description>0b00000001 Reserved for future use.</description>
  #|      </entry>
  #|      <entry value="2" name="MAV_MODE_FLAG_TEST_ENABLED">
  #|        <description>0b00000010 system has a test mode enabled.</description>
  #|      </entry>
  #|      <entry value="4" name="MAV_MODE_FLAG_AUTO_ENABLED">
  #|        <description>0b00000100 autonomous mode enabled.</description>
  #|      </entry>
  #|      <entry value="8" name="MAV_MODE_FLAG_GUIDED_ENABLED">
  #|        <description>0b00001000 guided mode enabled.</description>
  #|      </entry>
  #|      <entry value="16" name="MAV_MODE_FLAG_STABILIZE_ENABLED">
  #|        <description>0b00010000 system stabilizes electronically its attitude.</description>
  #|      </entry>
  #|      <entry value="32" name="MAV_MODE_FLAG_HIL_ENABLED">
  #|        <description>0b00100000 hardware in the loop simulation.</description>
  #|      </entry>
  #|      <entry value="64" name="MAV_MODE_FLAG_MANUAL_INPUT_ENABLED">
  #|        <description>0b01000000 remote control input is enabled.</description>
  #|      </entry>
  #|      <entry value="128" name="MAV_MODE_FLAG_SAFETY_ARMED">
  #|        <description>0b10000000 MAV safety set to armed.</description>
  #|      </entry>
  #|    </enum>
  #|    <enum name="MAV_STATE">
  #|      <description>Indicates the current state of the vehicle.</description>
  #|      <entry value="0" name="MAV_STATE_UNINIT">
  #|        <description>Uninitialized system, state is unknown.</description>
  #|      </entry>
  #|      <entry value="1" name="MAV_STATE_BOOT">
  #|        <description>System is booting up.</description>
  #|      </entry>
  #|      <entry value="2" name="MAV_STATE_CALIBRATING">
  #|        <description>System is calibrating and not flight-ready.</description>
  #|      </entry>
  #|      <entry value="3" name="MAV_STATE_STANDBY">
  #|        <description>System is grounded and on standby.</description>
  #|      </entry>
  #|      <entry value="4" name="MAV_STATE_ACTIVE">
  #|        <description>System is active and might be airborne.</description>
  #|      </entry>
  #|      <entry value="5" name="MAV_STATE_CRITICAL">
  #|        <description>System is in a non-normal flight mode.</description>
  #|      </entry>
  #|      <entry value="6" name="MAV_STATE_EMERGENCY">
  #|        <description>System is in a non-normal flight mode (failsafe).</description>
  #|      </entry>
  #|      <entry value="7" name="MAV_STATE_POWEROFF">
  #|        <description>System just initialized its power-down sequence.</description>
  #|      </entry>
  #|      <entry value="8" name="MAV_STATE_FLIGHT_TERMINATION">
  #|        <description>System is terminating itself.</description>
  #|      </entry>
  #|    </enum>
  #|    <enum name="MAV_COMPONENT">
  #|      <description>Component ids (values) for the different types and instances of onboard hardware/software.</description>
  #|      <entry value="0" name="MAV_COMP_ID_ALL"/>
  #|      <entry value="1" name="MAV_COMP_ID_AUTOPILOT1"/>
  #|      <entry value="100" name="MAV_COMP_ID_CAMERA"/>
  #|      <entry value="154" name="MAV_COMP_ID_GIMBAL"/>
  #|      <entry value="190" name="MAV_COMP_ID_MISSIONPLANNER"/>
  #|      <entry value="191" name="MAV_COMP_ID_ONBOARD_COMPUTER"/>
  #|      <entry value="220" name="MAV_COMP_ID_GPS"/>
  #|    </enum>
  #|    <enum name="MAV_CMD">
  #|      <description>Commands to be executed by the MAV.</description>
  #|      <entry value="16" name="MAV_CMD_NAV_WAYPOINT">
  #|        <description>Navigate to waypoint.</description>
  #|      </entry>
  #|      <entry value="17" name="MAV_CMD_NAV_LOITER_UNLIM">
  #|        <description>Loiter around this MISSION an unlimited amount of time.</description>
  #|      </entry>
  #|      <entry value="20" name="MAV_CMD_NAV_RETURN_TO_LAUNCH">
  #|        <description>Return to launch location.</description>
  #|      </entry>
  #|      <entry value="21" name="MAV_CMD_NAV_LAND">
  #|        <description>Land at location.</description>
  #|      </entry>
  #|      <entry value="22" name="MAV_CMD_NAV_TAKEOFF">
  #|        <description>Takeoff from ground / hand.</description>
  #|      </entry>
  #|      <entry value="176" name="MAV_CMD_DO_SET_MODE">
  #|        <description>Set system mode.</description>
  #|      </entry>
  #|      <entry value="178" name="MAV_CMD_DO_CHANGE_SPEED">
  #|        <description>Change speed and/or throttle set points.</description>
  #|      </entry>
  #|      <entry value="183" name="MAV_CMD_DO_SET_SERVO">
  #|        <description>Set a servo to a desired PWM value.</description>
  #|      </entry>
  #|      <entry value="400" name="MAV_CMD_COMPONENT_ARM_DISARM">
  #|        <description>Arms / Disarms a component.</description>
  #|      </entry>
  #|      <entry value="511" name="MAV_CMD_SET_MESSAGE_INTERVAL">
  #|        <description>Set the interval between messages for a particular MAVLink message ID.</description>
  #|      </entry>
  #|      <entry value="512" name="MAV_CMD_REQUEST_MESSAGE">
  #|        <description>Request the target system(s) emit a single instance of a specified message.</description>
  #|      </entry>
  #|      <entry value="520" name="MAV_CMD_REQUEST_AUTOPILOT_CAPABILITIES">
  #|        <description>Request autopilot capabilities.</description>
  #|      </entry>
  #|    </enum>
  #|    <enum name="MAV_RESULT">
  #|      <description>Result from a MAVLink command (MAV_CMD).</description>
  #|      <entry value="0" name="MAV_RESULT_ACCEPTED">
  #|        <description>Command is valid and is being executed.</description>
  #|      </entry>
  #|      <entry value="1" name="MAV_RESULT_TEMPORARILY_REJECTED">
  #|        <description>Command is valid, but cannot be executed at this time.</description>
  #|      </entry>
  #|      <entry value="2" name="MAV_RESULT_DENIED">
  #|        <description>Command is invalid or not permitted.</description>
  #|      </entry>
  #|      <entry value="3" name="MAV_RESULT_UNSUPPORTED">
  #|        <description>Command is not supported (unknown).</description>
  #|      </entry>
  #|      <entry value="4" name="MAV_RESULT_FAILED">
  #|        <description>Command is valid, but execution has failed.</description>
  #|      </entry>
  #|      <entry value="5" name="MAV_RESULT_IN_PROGRESS">
  #|        <description>Command is valid and is currently being executed.</description>
  #|      </entry>
  #|      <entry value="6" name="MAV_RESULT_CANCELLED">
  #|        <description>Command has been cancelled.</description>
  #|      </entry>
  #|    </enum>
  #|    <enum name="MAV_SEVERITY">
  #|      <description>Indicates the severity level, generally used for status messages.</description>
  #|      <entry value="0" name="MAV_SEVERITY_EMERGENCY"/>
  #|      <entry value="1" name="MAV_SEVERITY_ALERT"/>
  #|      <entry value="2" name="MAV_SEVERITY_CRITICAL"/>
  #|      <entry value="3" name="MAV_SEVERITY_ERROR"/>
  #|      <entry value="4" name="MAV_SEVERITY_WARNING"/>
  #|      <entry value="5" name="MAV_SEVERITY_NOTICE"/>
  #|      <entry value="6" name="MAV_SEVERITY_INFO"/>
  #|      <entry value="7" name="MAV_SEVERITY_DEBUG"/>
  #|    </enum>
  #|    <enum name="GPS_FIX_TYPE">
  #|      <description>Type of GPS fix.</description>
  #|      <entry value="0" name="GPS_FIX_TYPE_NO_GPS"/>
  #|      <entry value="1" name="GPS_FIX_TYPE_NO_FIX"/>
  #|      <entry value="2" name="GPS_FIX_TYPE_2D_FIX"/>
  #|      <entry value="3" name="GPS_FIX_TYPE_3D_FIX"/>
  #|      <entry value="4" name="GPS_FIX_TYPE_DGPS"/>
  #|      <entry value="5" name="GPS_FIX_TYPE_RTK_FLOAT"/>
  #|      <entry value="6" name="GPS_FIX_TYPE_RTK_FIXED"/>
  #|    </enum>
  #|    <enum name="MAV_FRAME">
  #|      <description>Coordinate frames used by MAVLink mission items and position messages.</description>
  #|      <entry value="0" name="MAV_FRAME_GLOBAL"/>
  #|      <entry value="1" name="MAV_FRAME_LOCAL_NED"/>
  #|      <entry value="2" name="MAV_FRAME_MISSION"/>
  #|      <entry value="3" name="MAV_FRAME_GLOBAL_RELATIVE_ALT"/>
  #|      <entry value="4" name="MAV_FRAME_LOCAL_ENU"/>
  #|      <entry value="5" name="MAV_FRAME_GLOBAL_INT"/>
  #|      <entry value="6" name="MAV_FRAME_GLOBAL_RELATIVE_ALT_INT"/>
  #|      <entry value="8" name="MAV_FRAME_BODY_NED"/>
  #|    </enum>
  #|    <enum name="MAV_MISSION_RESULT">
  #|      <description>Result of a MAVLink mission operation (MAV_MISSION_ACK).</description>
  #|      <entry value="0" name="MAV_MISSION_ACCEPTED"/>
  #|      <entry value="1" name="MAV_MISSION_ERROR"/>
  #|      <entry value="2" name="MAV_MISSION_UNSUPPORTED_FRAME"/>
  #|      <entry value="3" name="MAV_MISSION_UNSUPPORTED"/>
  #|      <entry value="4" name="MAV_MISSION_NO_SPACE"/>
  #|      <entry value="5" name="MAV_MISSION_INVALID"/>
  #|      <entry value="13" name="MAV_MISSION_INVALID_SEQUENCE"/>
  #|      <entry value="14" name="MAV_MISSION_DENIED"/>
  #|      <entry value="15" name="MAV_MISSION_OPERATION_CANCELLED"/>
  #|    </enum>
  #|    <enum name="MAV_MISSION_TYPE">
  #|      <description>Type of mission items being requested, uploaded, or cleared.</description>
  #|      <entry value="0" name="MAV_MISSION_TYPE_MISSION"/>
  #|      <entry value="1" name="MAV_MISSION_TYPE_FENCE"/>
  #|      <entry value="2" name="MAV_MISSION_TYPE_RALLY"/>
  #|      <entry value="255" name="MAV_MISSION_TYPE_ALL"/>
  #|    </enum>
  #|    <enum name="MAV_PARAM_TYPE">
  #|      <description>Specifies the datatype of a MAVLink parameter.</description>
  #|      <entry value="1" name="MAV_PARAM_TYPE_UINT8"/>
  #|      <entry value="2" name="MAV_PARAM_TYPE_INT8"/>
  #|      <entry value="3" name="MAV_PARAM_TYPE_UINT16"/>
  #|      <entry value="4" name="MAV_PARAM_TYPE_INT16"/>
  #|      <entry value="5" name="MAV_PARAM_TYPE_UINT32"/>
  #|      <entry value="6" name="MAV_PARAM_TYPE_INT32"/>
  #|      <entry value="7" name="MAV_PARAM_TYPE_UINT64"/>
  #|      <entry value="8" name="MAV_PARAM_TYPE_INT64"/>
  #|      <entry value="9" name="MAV_PARAM_TYPE_REAL32"/>
  #|      <entry value="10" name="MAV_PARAM_TYPE_REAL64"/>
  #|    </enum>
  #|    <enum name="MAV_DATA_STREAM">
  #|      <description>Data stream IDs for telemetry rate configuration.</description>
  #|      <entry value="0" name="MAV_DATA_STREAM_ALL"/>
  #|      <entry value="1" name="MAV_DATA_STREAM_RAW_SENSORS"/>
  #|      <entry value="2" name="MAV_DATA_STREAM_EXTENDED_STATUS"/>
  #|      <entry value="3" name="MAV_DATA_STREAM_RC_CHANNELS"/>
  #|      <entry value="4" name="MAV_DATA_STREAM_RAW_CONTROLLER"/>
  #|      <entry value="6" name="MAV_DATA_STREAM_POSITION"/>
  #|      <entry value="10" name="MAV_DATA_STREAM_EXTRA1"/>
  #|      <entry value="11" name="MAV_DATA_STREAM_EXTRA2"/>
  #|      <entry value="12" name="MAV_DATA_STREAM_EXTRA3"/>
  #|    </enum>
  #|    <enum name="MAV_DISTANCE_SENSOR">
  #|      <description>Enumeration of distance sensor types.</description>
  #|      <entry value="0" name="MAV_DISTANCE_SENSOR_LASER"/>
  #|      <entry value="1" name="MAV_DISTANCE_SENSOR_ULTRASOUND"/>
  #|      <entry value="2" name="MAV_DISTANCE_SENSOR_INFRARED"/>
  #|      <entry value="3" name="MAV_DISTANCE_SENSOR_RADAR"/>
  #|      <entry value="4" name="MAV_DISTANCE_SENSOR_UNKNOWN"/>
  #|    </enum>
  #|    <enum name="MAV_SENSOR_ORIENTATION">
  #|      <description>Enumeration of sensor orientation, according to its rotations.</description>
  #|      <entry value="0" name="MAV_SENSOR_ROTATION_NONE"/>
  #|      <entry value="1" name="MAV_SENSOR_ROTATION_YAW_45"/>
  #|      <entry value="2" name="MAV_SENSOR_ROTATION_YAW_90"/>
  #|      <entry value="4" name="MAV_SENSOR_ROTATION_YAW_180"/>
  #|      <entry value="6" name="MAV_SENSOR_ROTATION_YAW_270"/>
  #|      <entry value="25" name="MAV_SENSOR_ROTATION_PITCH_270"/>
  #|    </enum>
  #|    <enum name="MAV_LANDED_STATE">
  #|      <description>Enumeration of landed detector states.</description>
  #|      <entry value="0" name="MAV_LANDED_STATE_UNDEFINED"/>
  #|      <entry value="1" name="MAV_LANDED_STATE_ON_GROUND"/>
  #|      <entry value="2" name="MAV_LANDED_STATE_IN_AIR"/>
  #|      <entry value="3" name="MAV_LANDED_STATE_TAKEOFF"/>
  #|      <entry value="4" name="MAV_LANDED_STATE_LANDING"/>
  #|    </enum>
  #|    <enum name="MAV_VTOL_STATE">
  #|      <description>Enumeration of VTOL states.</description>
  #|      <entry value="0" name="MAV_VTOL_STATE_UNDEFINED"/>
  #|      <entry value="1" name="MAV_VTOL_STATE_TRANSITION_TO_FW"/>
  #|      <entry value="2" name="MAV_VTOL_STATE_TRANSITION_TO_MC"/>
  #|      <entry value="3" name="MAV_VTOL_STATE_MC"/>
  #|      <entry value="4" name="MAV_VTOL_STATE_FW"/>
  #|    </enum>
  #|  </enums>
  #|  <messages>
  #|    <message id="0" name="HEARTBEAT">
  #|      <description>The heartbeat message shows that a system or component is present and responding.</description>
  #|      <field type="uint8_t" name="type" enum="MAV_TYPE">Vehicle or component type.</field>
  #|      <field type="uint8_t" name="autopilot" enum="MAV_AUTOPILOT">Autopilot type / class.</field>
  #|      <field type="uint8_t" name="base_mode" enum="MAV_MODE_FLAG">System mode bitmap.</field>
  #|      <field type="uint32_t" name="custom_mode">A bitfield for use for autopilot-specific flags.</field>
  #|      <field type="uint8_t" name="system_status" enum="MAV_STATE">System status flag.</field>
  #|      <field type="uint8_t_mavlink_version" name="mavlink_version">MAVLink version, not writable by user.</field>
  #|    </message>
  #|    <message id="1" name="SYS_STATUS">
  #|      <description>The general system state.</description>
  #|      <field type="uint32_t" name="onboard_control_sensors_present">Bitmap showing which onboard controllers and sensors are present.</field>
  #|      <field type="uint32_t" name="onboard_control_sensors_enabled">Bitmap showing which onboard controllers and sensors are enabled.</field>
  #|      <field type="uint32_t" name="onboard_control_sensors_health">Bitmap showing which onboard controllers and sensors are operational.</field>
  #|      <field type="uint16_t" name="load">Maximum usage in percent of the mainloop time (0..1000).</field>
  #|      <field type="uint16_t" name="voltage_battery" units="mV">Battery voltage, in millivolts.</field>
  #|      <field type="int16_t" name="current_battery" units="cA">Battery current, in 10*milliamperes.</field>
  #|      <field type="int8_t" name="battery_remaining" units="%">Battery energy remaining (0..100).</field>
  #|      <field type="uint16_t" name="drop_rate_comm">Communication drop rate.</field>
  #|      <field type="uint16_t" name="errors_comm">Communication errors.</field>
  #|      <field type="uint16_t" name="errors_count1">Autopilot-specific errors 1.</field>
  #|      <field type="uint16_t" name="errors_count2">Autopilot-specific errors 2.</field>
  #|      <field type="uint16_t" name="errors_count3">Autopilot-specific errors 3.</field>
  #|      <field type="uint16_t" name="errors_count4">Autopilot-specific errors 4.</field>
  #|    </message>
  #|    <message id="2" name="SYSTEM_TIME">
  #|      <description>The system time is the time of the master clock, typically the computer clock of the main onboard computer.</description>
  #|      <field type="uint64_t" name="time_unix_usec" units="us">Timestamp (UNIX epoch time).</field>
  #|      <field type="uint32_t" name="time_boot_ms" units="ms">Timestamp (time since system boot).</field>
  #|    </message>
  #|    <message id="4" name="PING">
  #|      <description>A ping message either requesting or responding to a ping.</description>
  #|      <field type="uint64_t" name="time_usec" units="us">Timestamp (UNIX Epoch time or time since system boot).</field>
  #|      <field type="uint32_t" name="seq">PING sequence.</field>
  #|      <field type="uint8_t" name="target_system">0: request ping from all receiving systems.</field>
  #|      <field type="uint8_t" name="target_component">0: request ping from all receiving components.</field>
  #|    </message>
  #|    <message id="11" name="SET_MODE">
  #|      <description>Set the system mode, as defined by enum MAV_MODE.</description>
  #|      <field type="uint8_t" name="target_system">The system setting the mode.</field>
  #|      <field type="uint8_t" name="base_mode" enum="MAV_MODE_FLAG">The new base mode.</field>
  #|      <field type="uint32_t" name="custom_mode">The new autopilot-specific mode.</field>
  #|    </message>
  #|    <message id="20" name="PARAM_REQUEST_READ">
  #|      <description>Request to read the onboard parameter with the param_id string id.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="char[16]" name="param_id">Onboard parameter id, terminated by NULL if length is less than 16.</field>
  #|      <field type="int16_t" name="param_index">Parameter index. Send -1 to use the param ID field as identifier.</field>
  #|    </message>
  #|    <message id="21" name="PARAM_REQUEST_LIST">
  #|      <description>Request all parameters of this component.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|    </message>
  #|    <message id="22" name="PARAM_VALUE">
  #|      <description>Emit the value of a onboard parameter.</description>
  #|      <field type="char[16]" name="param_id">Onboard parameter id.</field>
  #|      <field type="float" name="param_value">Onboard parameter value.</field>
  #|      <field type="uint8_t" name="param_type" enum="MAV_PARAM_TYPE">Onboard parameter type.</field>
  #|      <field type="uint16_t" name="param_count">Total number of onboard parameters.</field>
  #|      <field type="uint16_t" name="param_index">Index of this onboard parameter.</field>
  #|    </message>
  #|    <message id="23" name="PARAM_SET">
  #|      <description>Set a parameter value (write new value to permanent storage).</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="char[16]" name="param_id">Onboard parameter id.</field>
  #|      <field type="float" name="param_value">Onboard parameter value.</field>
  #|      <field type="uint8_t" name="param_type" enum="MAV_PARAM_TYPE">Onboard parameter type.</field>
  #|    </message>
  #|    <message id="24" name="GPS_RAW_INT">
  #|      <description>The global position, as returned by the Global Positioning System (GPS).</description>
  #|      <field type="uint64_t" name="time_usec" units="us">Timestamp (UNIX Epoch time or time since system boot).</field>
  #|      <field type="uint8_t" name="fix_type" enum="GPS_FIX_TYPE">GPS fix type.</field>
  #|      <field type="int32_t" name="lat" units="degE7">Latitude (WGS84, EGM96 ellipsoid).</field>
  #|      <field type="int32_t" name="lon" units="degE7">Longitude (WGS84, EGM96 ellipsoid).</field>
  #|      <field type="int32_t" name="alt" units="mm">Altitude (MSL).</field>
  #|      <field type="uint16_t" name="eph">GPS HDOP horizontal dilution of position.</field>
  #|      <field type="uint16_t" name="epv">GPS VDOP vertical dilution of position.</field>
  #|      <field type="uint16_t" name="vel" units="cm/s">GPS ground speed.</field>
  #|      <field type="uint16_t" name="cog" units="cdeg">Course over ground.</field>
  #|      <field type="uint8_t" name="satellites_visible">Number of satellites visible.</field>
  #|      <extensions/>
  #|      <field type="int32_t" name="alt_ellipsoid" units="mm">Altitude (above WGS84, EGM96 ellipsoid).</field>
  #|      <field type="uint32_t" name="h_acc" units="mm">Position uncertainty.</field>
  #|      <field type="uint32_t" name="v_acc" units="mm">Altitude uncertainty.</field>
  #|      <field type="uint32_t" name="vel_acc" units="mm/s">Speed uncertainty.</field>
  #|      <field type="uint32_t" name="hdg_acc" units="degE5">Heading / track uncertainty.</field>
  #|      <field type="uint16_t" name="yaw" units="cdeg">Yaw in earth frame from north.</field>
  #|    </message>
  #|    <message id="26" name="SCALED_IMU">
  #|      <description>The RAW IMU readings for the usual 9DOF sensor setup (scaled to milli-g / millirad/s).</description>
  #|      <field type="uint32_t" name="time_boot_ms" units="ms">Timestamp (time since system boot).</field>
  #|      <field type="int16_t" name="xacc" units="mG">X acceleration.</field>
  #|      <field type="int16_t" name="yacc" units="mG">Y acceleration.</field>
  #|      <field type="int16_t" name="zacc" units="mG">Z acceleration.</field>
  #|      <field type="int16_t" name="xgyro" units="mrad/s">Angular speed around X axis.</field>
  #|      <field type="int16_t" name="ygyro" units="mrad/s">Angular speed around Y axis.</field>
  #|      <field type="int16_t" name="zgyro" units="mrad/s">Angular speed around Z axis.</field>
  #|      <field type="int16_t" name="xmag" units="mgauss">X Magnetic field.</field>
  #|      <field type="int16_t" name="ymag" units="mgauss">Y Magnetic field.</field>
  #|      <field type="int16_t" name="zmag" units="mgauss">Z Magnetic field.</field>
  #|      <extensions/>
  #|      <field type="int16_t" name="temperature" units="cdegC">Temperature, 0: IMU does not provide temperature values.</field>
  #|    </message>
  #|    <message id="27" name="RAW_IMU">
  #|      <description>The RAW IMU readings for a 9DOF sensor, which is identified by the id (default IMU1).</description>
  #|      <field type="uint64_t" name="time_usec" units="us">Timestamp (UNIX Epoch time or time since system boot).</field>
  #|      <field type="int16_t" name="xacc">X acceleration (raw).</field>
  #|      <field type="int16_t" name="yacc">Y acceleration (raw).</field>
  #|      <field type="int16_t" name="zacc">Z acceleration (raw).</field>
  #|      <field type="int16_t" name="xgyro">Angular speed around X axis (raw).</field>
  #|      <field type="int16_t" name="ygyro">Angular speed around Y axis (raw).</field>
  #|      <field type="int16_t" name="zgyro">Angular speed around Z axis (raw).</field>
  #|      <field type="int16_t" name="xmag">X Magnetic field (raw).</field>
  #|      <field type="int16_t" name="ymag">Y Magnetic field (raw).</field>
  #|      <field type="int16_t" name="zmag">Z Magnetic field (raw).</field>
  #|      <extensions/>
  #|      <field type="uint8_t" name="id">Id. Ids are numbered from 0 and map to IMUs numbered from 1.</field>
  #|      <field type="int16_t" name="temperature" units="cdegC">Temperature, 0: IMU does not provide temperature values.</field>
  #|    </message>
  #|    <message id="29" name="SCALED_PRESSURE">
  #|      <description>The pressure readings for the typical setup of one absolute and differential pressure sensor.</description>
  #|      <field type="uint32_t" name="time_boot_ms" units="ms">Timestamp (time since system boot).</field>
  #|      <field type="float" name="press_abs" units="hPa">Absolute pressure.</field>
  #|      <field type="float" name="press_diff" units="hPa">Differential pressure 1.</field>
  #|      <field type="int16_t" name="temperature" units="cdegC">Absolute pressure temperature.</field>
  #|      <extensions/>
  #|      <field type="int16_t" name="temperature_press_diff" units="cdegC">Differential pressure temperature.</field>
  #|    </message>
  #|    <message id="30" name="ATTITUDE">
  #|      <description>The attitude in the aeronautical frame (right-handed, Z-down, X-front, Y-right).</description>
  #|      <field type="uint32_t" name="time_boot_ms" units="ms">Timestamp (time since system boot).</field>
  #|      <field type="float" name="roll" units="rad">Roll angle (-pi..+pi).</field>
  #|      <field type="float" name="pitch" units="rad">Pitch angle (-pi..+pi).</field>
  #|      <field type="float" name="yaw" units="rad">Yaw angle (-pi..+pi).</field>
  #|      <field type="float" name="rollspeed" units="rad/s">Roll angular speed.</field>
  #|      <field type="float" name="pitchspeed" units="rad/s">Pitch angular speed.</field>
  #|      <field type="float" name="yawspeed" units="rad/s">Yaw angular speed.</field>
  #|    </message>
  #|    <message id="31" name="ATTITUDE_QUATERNION">
  #|      <description>The attitude in the aeronautical frame (right-handed, Z-down, X-front, Y-right), expressed as quaternion.</description>
  #|      <field type="uint32_t" name="time_boot_ms" units="ms">Timestamp (time since system boot).</field>
  #|      <field type="float" name="q1">Quaternion component 1, w (1 in null-rotation).</field>
  #|      <field type="float" name="q2">Quaternion component 2, x (0 in null-rotation).</field>
  #|      <field type="float" name="q3">Quaternion component 3, y (0 in null-rotation).</field>
  #|      <field type="float" name="q4">Quaternion component 4, z (0 in null-rotation).</field>
  #|      <field type="float" name="rollspeed" units="rad/s">Roll angular speed.</field>
  #|      <field type="float" name="pitchspeed" units="rad/s">Pitch angular speed.</field>
  #|      <field type="float" name="yawspeed" units="rad/s">Yaw angular speed.</field>
  #|      <extensions/>
  #|      <field type="float[4]" name="repr_offset_q">Rotation offset by which the attitude quaternion and angular speed vector should be rotated.</field>
  #|    </message>
  #|    <message id="32" name="LOCAL_POSITION_NED">
  #|      <description>The filtered local position (e.g. fused computer vision and accelerometers) in NED frame.</description>
  #|      <field type="uint32_t" name="time_boot_ms" units="ms">Timestamp (time since system boot).</field>
  #|      <field type="float" name="x" units="m">X Position (North).</field>
  #|      <field type="float" name="y" units="m">Y Position (East).</field>
  #|      <field type="float" name="z" units="m">Z Position (Down).</field>
  #|      <field type="float" name="vx" units="m/s">X Speed.</field>
  #|      <field type="float" name="vy" units="m/s">Y Speed.</field>
  #|      <field type="float" name="vz" units="m/s">Z Speed.</field>
  #|    </message>
  #|    <message id="33" name="GLOBAL_POSITION_INT">
  #|      <description>The filtered global position (e.g. fused GPS and accelerometers).</description>
  #|      <field type="uint32_t" name="time_boot_ms" units="ms">Timestamp (time since system boot).</field>
  #|      <field type="int32_t" name="lat" units="degE7">Latitude, expressed as degrees * 1E7.</field>
  #|      <field type="int32_t" name="lon" units="degE7">Longitude, expressed as degrees * 1E7.</field>
  #|      <field type="int32_t" name="alt" units="mm">Altitude (MSL).</field>
  #|      <field type="int32_t" name="relative_alt" units="mm">Altitude above ground.</field>
  #|      <field type="int16_t" name="vx" units="cm/s">Ground X Speed (Latitude, positive north).</field>
  #|      <field type="int16_t" name="vy" units="cm/s">Ground Y Speed (Longitude, positive east).</field>
  #|      <field type="int16_t" name="vz" units="cm/s">Ground Z Speed (Altitude, positive down).</field>
  #|      <field type="uint16_t" name="hdg" units="cdeg">Vehicle heading (yaw angle), 0.0..359.99 degrees.</field>
  #|    </message>
  #|    <message id="35" name="RC_CHANNELS_RAW">
  #|      <description>The RAW values of the RC channels received.</description>
  #|      <field type="uint32_t" name="time_boot_ms" units="ms">Timestamp (time since system boot).</field>
  #|      <field type="uint8_t" name="port">Servo output port (set of 8 outputs = 1 port).</field>
  #|      <field type="uint16_t" name="chan1_raw" units="us">RC channel 1 value.</field>
  #|      <field type="uint16_t" name="chan2_raw" units="us">RC channel 2 value.</field>
  #|      <field type="uint16_t" name="chan3_raw" units="us">RC channel 3 value.</field>
  #|      <field type="uint16_t" name="chan4_raw" units="us">RC channel 4 value.</field>
  #|      <field type="uint16_t" name="chan5_raw" units="us">RC channel 5 value.</field>
  #|      <field type="uint16_t" name="chan6_raw" units="us">RC channel 6 value.</field>
  #|      <field type="uint16_t" name="chan7_raw" units="us">RC channel 7 value.</field>
  #|      <field type="uint16_t" name="chan8_raw" units="us">RC channel 8 value.</field>
  #|      <field type="uint8_t" name="rssi">Receive signal strength indicator in device-dependent units/scale.</field>
  #|    </message>
  #|    <message id="36" name="SERVO_OUTPUT_RAW">
  #|      <description>The RAW values of the servo outputs (for RC input from the remote, use the RC_CHANNELS messages).</description>
  #|      <field type="uint32_t" name="time_usec" units="us">Timestamp (UNIX Epoch time or time since system boot).</field>
  #|      <field type="uint8_t" name="port">Servo output port (set of 8 outputs = 1 port).</field>
  #|      <field type="uint16_t" name="servo1_raw" units="us">Servo output 1 value.</field>
  #|      <field type="uint16_t" name="servo2_raw" units="us">Servo output 2 value.</field>
  #|      <field type="uint16_t" name="servo3_raw" units="us">Servo output 3 value.</field>
  #|      <field type="uint16_t" name="servo4_raw" units="us">Servo output 4 value.</field>
  #|      <field type="uint16_t" name="servo5_raw" units="us">Servo output 5 value.</field>
  #|      <field type="uint16_t" name="servo6_raw" units="us">Servo output 6 value.</field>
  #|      <field type="uint16_t" name="servo7_raw" units="us">Servo output 7 value.</field>
  #|      <field type="uint16_t" name="servo8_raw" units="us">Servo output 8 value.</field>
  #|      <extensions/>
  #|      <field type="uint16_t" name="servo9_raw" units="us">Servo output 9 value.</field>
  #|      <field type="uint16_t" name="servo10_raw" units="us">Servo output 10 value.</field>
  #|      <field type="uint16_t" name="servo11_raw" units="us">Servo output 11 value.</field>
  #|      <field type="uint16_t" name="servo12_raw" units="us">Servo output 12 value.</field>
  #|      <field type="uint16_t" name="servo13_raw" units="us">Servo output 13 value.</field>
  #|      <field type="uint16_t" name="servo14_raw" units="us">Servo output 14 value.</field>
  #|      <field type="uint16_t" name="servo15_raw" units="us">Servo output 15 value.</field>
  #|      <field type="uint16_t" name="servo16_raw" units="us">Servo output 16 value.</field>
  #|    </message>
  #|    <message id="40" name="MISSION_REQUEST">
  #|      <description>Request the information of the mission item with the sequence number seq.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="uint16_t" name="seq">Sequence.</field>
  #|      <extensions/>
  #|      <field type="uint8_t" name="mission_type" enum="MAV_MISSION_TYPE">Mission type.</field>
  #|    </message>
  #|    <message id="41" name="MISSION_SET_CURRENT">
  #|      <description>Set the mission item with sequence number seq as current item.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="uint16_t" name="seq">Sequence.</field>
  #|    </message>
  #|    <message id="42" name="MISSION_CURRENT">
  #|      <description>Message that announces the sequence number of the current active mission item.</description>
  #|      <field type="uint16_t" name="seq">Sequence.</field>
  #|      <extensions/>
  #|      <field type="uint16_t" name="total">Total number of mission items on vehicle.</field>
  #|      <field type="uint8_t" name="mission_state">Mission state machine state.</field>
  #|      <field type="uint8_t" name="mission_mode">Vehicle is in a mode that can execute mission items or not.</field>
  #|    </message>
  #|    <message id="43" name="MISSION_REQUEST_LIST">
  #|      <description>Request the overall list of mission items from the system/component.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <extensions/>
  #|      <field type="uint8_t" name="mission_type" enum="MAV_MISSION_TYPE">Mission type.</field>
  #|    </message>
  #|    <message id="44" name="MISSION_COUNT">
  #|      <description>This message is emitted as response to MISSION_REQUEST_LIST by the MAV and to initiate a write transaction.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="uint16_t" name="count">Number of mission items in the sequence.</field>
  #|      <extensions/>
  #|      <field type="uint8_t" name="mission_type" enum="MAV_MISSION_TYPE">Mission type.</field>
  #|      <field type="uint32_t" name="opaque_id">Id of current on-vehicle mission, fence, or rally point plan.</field>
  #|    </message>
  #|    <message id="45" name="MISSION_CLEAR_ALL">
  #|      <description>Delete all mission items at once.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <extensions/>
  #|      <field type="uint8_t" name="mission_type" enum="MAV_MISSION_TYPE">Mission type.</field>
  #|    </message>
  #|    <message id="46" name="MISSION_ITEM_REACHED">
  #|      <description>A certain mission item has been reached.</description>
  #|      <field type="uint16_t" name="seq">Sequence.</field>
  #|    </message>
  #|    <message id="47" name="MISSION_ACK">
  #|      <description>Acknowledgment message during waypoint handling.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="uint8_t" name="type" enum="MAV_MISSION_RESULT">Mission result.</field>
  #|      <extensions/>
  #|      <field type="uint8_t" name="mission_type" enum="MAV_MISSION_TYPE">Mission type.</field>
  #|      <field type="uint32_t" name="opaque_id">Id of current on-vehicle mission, fence, or rally point plan.</field>
  #|    </message>
  #|    <message id="51" name="MISSION_REQUEST_INT">
  #|      <description>Request the information of the mission item with the sequence number seq.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="uint16_t" name="seq">Sequence.</field>
  #|      <extensions/>
  #|      <field type="uint8_t" name="mission_type" enum="MAV_MISSION_TYPE">Mission type.</field>
  #|    </message>
  #|    <message id="65" name="RC_CHANNELS">
  #|      <description>The PPM values of the RC channels received.</description>
  #|      <field type="uint32_t" name="time_boot_ms" units="ms">Timestamp (time since system boot).</field>
  #|      <field type="uint8_t" name="chancount">Total number of RC channels being received.</field>
  #|      <field type="uint16_t" name="chan1_raw" units="us">RC channel 1 value.</field>
  #|      <field type="uint16_t" name="chan2_raw" units="us">RC channel 2 value.</field>
  #|      <field type="uint16_t" name="chan3_raw" units="us">RC channel 3 value.</field>
  #|      <field type="uint16_t" name="chan4_raw" units="us">RC channel 4 value.</field>
  #|      <field type="uint16_t" name="chan5_raw" units="us">RC channel 5 value.</field>
  #|      <field type="uint16_t" name="chan6_raw" units="us">RC channel 6 value.</field>
  #|      <field type="uint16_t" name="chan7_raw" units="us">RC channel 7 value.</field>
  #|      <field type="uint16_t" name="chan8_raw" units="us">RC channel 8 value.</field>
  #|      <field type="uint16_t" name="chan9_raw" units="us">RC channel 9 value.</field>
  #|      <field type="uint16_t" name="chan10_raw" units="us">RC channel 10 value.</field>
  #|      <field type="uint16_t" name="chan11_raw" units="us">RC channel 11 value.</field>
  #|      <field type="uint16_t" name="chan12_raw" units="us">RC channel 12 value.</field>
  #|      <field type="uint16_t" name="chan13_raw" units="us">RC channel 13 value.</field>
  #|      <field type="uint16_t" name="chan14_raw" units="us">RC channel 14 value.</field>
  #|      <field type="uint16_t" name="chan15_raw" units="us">RC channel 15 value.</field>
  #|      <field type="uint16_t" name="chan16_raw" units="us">RC channel 16 value.</field>
  #|      <field type="uint16_t" name="chan17_raw" units="us">RC channel 17 value.</field>
  #|      <field type="uint16_t" name="chan18_raw" units="us">RC channel 18 value.</field>
  #|      <field type="uint8_t" name="rssi">Receive signal strength indicator.</field>
  #|    </message>
  #|    <message id="69" name="MANUAL_CONTROL">
  #|      <description>This message provides an API for manually controlling the vehicle using standard joystick axes.</description>
  #|      <field type="uint8_t" name="target">The system to be controlled.</field>
  #|      <field type="int16_t" name="x">X-axis, normalized to the range [-1000,1000].</field>
  #|      <field type="int16_t" name="y">Y-axis, normalized to the range [-1000,1000].</field>
  #|      <field type="int16_t" name="z">Z-axis, normalized to the range [0,1000] or [-1000,1000].</field>
  #|      <field type="int16_t" name="r">R-axis, normalized to the range [-1000,1000].</field>
  #|      <field type="uint16_t" name="buttons">A bitfield corresponding to the joystick buttons' current state.</field>
  #|      <extensions/>
  #|      <field type="uint16_t" name="buttons2">A bitfield corresponding to the joystick buttons' 16-31 current state.</field>
  #|      <field type="uint8_t" name="enabled_extensions">Set bits to 1 to indicate which of the following extension fields contain valid data.</field>
  #|      <field type="int16_t" name="s">Pitch-only-axis, normalized to the range [-1000,1000].</field>
  #|      <field type="int16_t" name="t">Yaw-only-axis, normalized to the range [-1000,1000].</field>
  #|    </message>
  #|    <message id="73" name="MISSION_ITEM_INT">
  #|      <description>Message encoding a mission item using integer latitude/longitude in degE7.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="uint16_t" name="seq">Waypoint ID (sequence number). Starts at zero.</field>
  #|      <field type="uint8_t" name="frame" enum="MAV_FRAME">The coordinate system of the waypoint.</field>
  #|      <field type="uint16_t" name="command" enum="MAV_CMD">The scheduled action for the waypoint.</field>
  #|      <field type="uint8_t" name="current">false:0, true:1.</field>
  #|      <field type="uint8_t" name="autocontinue">Autocontinue to next waypoint.</field>
  #|      <field type="float" name="param1">PARAM1, see MAV_CMD enum.</field>
  #|      <field type="float" name="param2">PARAM2, see MAV_CMD enum.</field>
  #|      <field type="float" name="param3">PARAM3, see MAV_CMD enum.</field>
  #|      <field type="float" name="param4">PARAM4, see MAV_CMD enum.</field>
  #|      <field type="int32_t" name="x">PARAM5 / local: x position in meters * 1e4, global: latitude in degrees * 10^7.</field>
  #|      <field type="int32_t" name="y">PARAM6 / y position: local: x position in meters * 1e4, global: longitude in degrees * 10^7.</field>
  #|      <field type="float" name="z">PARAM7 / z position: global: altitude in meters (relative or absolute, depending on frame).</field>
  #|      <extensions/>
  #|      <field type="uint8_t" name="mission_type" enum="MAV_MISSION_TYPE">Mission type.</field>
  #|    </message>
  #|    <message id="74" name="VFR_HUD">
  #|      <description>Metrics typically displayed on a HUD for fixed wing aircraft.</description>
  #|      <field type="float" name="airspeed" units="m/s">Vehicle indicated airspeed (IAS).</field>
  #|      <field type="float" name="groundspeed" units="m/s">Current ground speed.</field>
  #|      <field type="int16_t" name="heading" units="deg">Current heading in compass units (0-360, 0=north).</field>
  #|      <field type="uint16_t" name="throttle" units="%">Current throttle setting (0 to 100).</field>
  #|      <field type="float" name="alt" units="m">Current altitude (MSL).</field>
  #|      <field type="float" name="climb" units="m/s">Current climb rate.</field>
  #|    </message>
  #|    <message id="75" name="COMMAND_INT">
  #|      <description>Message encoding a command with parameters as scaled integers.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="uint8_t" name="frame" enum="MAV_FRAME">The coordinate system of the COMMAND.</field>
  #|      <field type="uint16_t" name="command" enum="MAV_CMD">The scheduled action for the mission item.</field>
  #|      <field type="uint8_t" name="current">Not used.</field>
  #|      <field type="uint8_t" name="autocontinue">Not used (set 0).</field>
  #|      <field type="float" name="param1">PARAM1, see MAV_CMD enum.</field>
  #|      <field type="float" name="param2">PARAM2, see MAV_CMD enum.</field>
  #|      <field type="float" name="param3">PARAM3, see MAV_CMD enum.</field>
  #|      <field type="float" name="param4">PARAM4, see MAV_CMD enum.</field>
  #|      <field type="int32_t" name="x">PARAM5 / local: x position in meters * 1e4, global: latitude in degrees * 10^7.</field>
  #|      <field type="int32_t" name="y">PARAM6 / local: y position in meters * 1e4, global: longitude in degrees * 10^7.</field>
  #|      <field type="float" name="z">PARAM7 / z position: global: altitude in meters (relative or absolute, depending on frame).</field>
  #|    </message>
  #|    <message id="76" name="COMMAND_LONG">
  #|      <description>Send a command with up to seven parameters to the MAV.</description>
  #|      <field type="uint8_t" name="target_system">System which should execute the command.</field>
  #|      <field type="uint8_t" name="target_component">Component which should execute the command.</field>
  #|      <field type="uint16_t" name="command" enum="MAV_CMD">Command ID (of command to send).</field>
  #|      <field type="uint8_t" name="confirmation">0: First transmission of this command.</field>
  #|      <field type="float" name="param1">Parameter 1 (for the specific command).</field>
  #|      <field type="float" name="param2">Parameter 2 (for the specific command).</field>
  #|      <field type="float" name="param3">Parameter 3 (for the specific command).</field>
  #|      <field type="float" name="param4">Parameter 4 (for the specific command).</field>
  #|      <field type="float" name="param5">Parameter 5 (for the specific command).</field>
  #|      <field type="float" name="param6">Parameter 6 (for the specific command).</field>
  #|      <field type="float" name="param7">Parameter 7 (for the specific command).</field>
  #|    </message>
  #|    <message id="77" name="COMMAND_ACK">
  #|      <description>Report status of a command. Includes feedback whether the command was executed.</description>
  #|      <field type="uint16_t" name="command" enum="MAV_CMD">Command ID (of acknowledged command).</field>
  #|      <field type="uint8_t" name="result" enum="MAV_RESULT">Result of command.</field>
  #|      <extensions/>
  #|      <field type="uint8_t" name="progress">Also used as result_param1, it can be set with an enum containing the errors reasons.</field>
  #|      <field type="int32_t" name="result_param2">Additional parameter of the result.</field>
  #|      <field type="uint8_t" name="target_system">System ID of the target recipient.</field>
  #|      <field type="uint8_t" name="target_component">Component ID of the target recipient.</field>
  #|    </message>
  #|    <message id="80" name="COMMAND_CANCEL">
  #|      <description>Cancel a long running command.</description>
  #|      <field type="uint8_t" name="target_system">System executing long running command.</field>
  #|      <field type="uint8_t" name="target_component">Component executing long running command.</field>
  #|      <field type="uint16_t" name="command" enum="MAV_CMD">Command ID (of command to cancel).</field>
  #|    </message>
  #|    <message id="82" name="SET_ATTITUDE_TARGET">
  #|      <description>Sets a desired vehicle attitude. Used by an external controller to command the vehicle.</description>
  #|      <field type="uint32_t" name="time_boot_ms" units="ms">Timestamp (time since system boot).</field>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="uint8_t" name="type_mask">Bitmap to indicate which dimensions should be ignored by the vehicle.</field>
  #|      <field type="float[4]" name="q">Attitude quaternion (w, x, y, z order, zero-rotation is 1, 0, 0, 0).</field>
  #|      <field type="float" name="body_roll_rate" units="rad/s">Body roll rate.</field>
  #|      <field type="float" name="body_pitch_rate" units="rad/s">Body pitch rate.</field>
  #|      <field type="float" name="body_yaw_rate" units="rad/s">Body yaw rate.</field>
  #|      <field type="float" name="thrust">Collective thrust, normalized to 0 .. 1 (-1 .. 1 for vehicles capable of reverse trust).</field>
  #|    </message>
  #|    <message id="111" name="TIMESYNC">
  #|      <description>Time synchronization message.</description>
  #|      <field type="int64_t" name="tc1" units="ns">Time sync timestamp 1.</field>
  #|      <field type="int64_t" name="ts1" units="ns">Time sync timestamp 2.</field>
  #|      <extensions/>
  #|      <field type="uint8_t" name="target_system">Target system id.</field>
  #|      <field type="uint8_t" name="target_component">Target component id.</field>
  #|    </message>
  #|    <message id="132" name="DISTANCE_SENSOR">
  #|      <description>Distance sensor information for an onboard rangefinder.</description>
  #|      <field type="uint32_t" name="time_boot_ms" units="ms">Timestamp (time since system boot).</field>
  #|      <field type="uint16_t" name="min_distance" units="cm">Minimum distance the sensor can measure.</field>
  #|      <field type="uint16_t" name="max_distance" units="cm">Maximum distance the sensor can measure.</field>
  #|      <field type="uint16_t" name="current_distance" units="cm">Current distance reading.</field>
  #|      <field type="uint8_t" name="type" enum="MAV_DISTANCE_SENSOR">Type of distance sensor.</field>
  #|      <field type="uint8_t" name="id">Onboard ID of the sensor.</field>
  #|      <field type="uint8_t" name="orientation" enum="MAV_SENSOR_ORIENTATION">Direction the sensor faces.</field>
  #|      <field type="uint8_t" name="covariance" units="cm^2">Measurement variance.</field>
  #|      <extensions/>
  #|      <field type="float" name="horizontal_fov" units="rad">Horizontal Field of View (angle) where the distance measurement is valid.</field>
  #|      <field type="float" name="vertical_fov" units="rad">Vertical Field of View (angle) where the distance measurement is valid.</field>
  #|      <field type="float[4]" name="quaternion">Quaternion of the sensor orientation in vehicle body frame (w, x, y, z order).</field>
  #|      <field type="uint8_t" name="signal_quality" units="%">Signal quality of the sensor.</field>
  #|    </message>
  #|    <message id="147" name="BATTERY_STATUS">
  #|      <description>Battery information.</description>
  #|      <field type="uint8_t" name="id">Battery ID.</field>
  #|      <field type="uint8_t" name="battery_function">Function of the battery.</field>
  #|      <field type="uint8_t" name="type">Type (chemistry) of the battery.</field>
  #|      <field type="int16_t" name="temperature" units="cdegC">Temperature of the battery in centi-degrees celsius.</field>
  #|      <field type="uint16_t[10]" name="voltages" units="mV">Battery voltage of cells 1 to 10.</field>
  #|      <field type="int16_t" name="current_battery" units="cA">Battery current, in 10*milliamperes.</field>
  #|      <field type="int32_t" name="current_consumed" units="mAh">Consumed charge, in milliampere hours.</field>
  #|      <field type="int32_t" name="energy_consumed" units="hJ">Consumed energy, in HectoJoules.</field>
  #|      <field type="int8_t" name="battery_remaining" units="%">Remaining battery energy.</field>
  #|      <extensions/>
  #|      <field type="int32_t" name="time_remaining" units="s">Remaining battery time.</field>
  #|      <field type="uint8_t" name="charge_state">State for extent of discharge.</field>
  #|      <field type="uint16_t[4]" name="voltages_ext" units="mV">Battery voltages for cells 11 to 14.</field>
  #|      <field type="uint8_t" name="mode">Battery mode.</field>
  #|      <field type="uint32_t" name="fault_bitmask">Fault/health indications.</field>
  #|    </message>
  #|    <message id="148" name="AUTOPILOT_VERSION">
  #|      <description>Version and capability of autopilot software.</description>
  #|      <field type="uint64_t" name="capabilities">Bitmap of capabilities.</field>
  #|      <field type="uint32_t" name="flight_sw_version">Firmware version number.</field>
  #|      <field type="uint32_t" name="middleware_sw_version">Middleware version number.</field>
  #|      <field type="uint32_t" name="os_sw_version">Operating system version number.</field>
  #|      <field type="uint32_t" name="board_version">HW / board version.</field>
  #|      <field type="uint8_t[8]" name="flight_custom_version">Custom version field, commonly the first 8 bytes of the git hash.</field>
  #|      <field type="uint8_t[8]" name="middleware_custom_version">Custom version field, commonly the first 8 bytes of the git hash.</field>
  #|      <field type="uint8_t[8]" name="os_custom_version">Custom version field, commonly the first 8 bytes of the git hash.</field>
  #|      <field type="uint16_t" name="vendor_id">ID of the board vendor.</field>
  #|      <field type="uint16_t" name="product_id">ID of the product.</field>
  #|      <field type="uint64_t" name="uid">UID if provided by hardware.</field>
  #|      <extensions/>
  #|      <field type="uint8_t[18]" name="uid2">UID if provided by hardware (supersedes the uid field).</field>
  #|    </message>
  #|    <message id="245" name="EXTENDED_SYS_STATE">
  #|      <description>Provides state for additional features.</description>
  #|      <field type="uint8_t" name="vtol_state" enum="MAV_VTOL_STATE">The VTOL state if applicable.</field>
  #|      <field type="uint8_t" name="landed_state" enum="MAV_LANDED_STATE">The landed state.</field>
  #|    </message>
  #|    <message id="253" name="STATUSTEXT">
  #|      <description>Status text message.</description>
  #|      <field type="uint8_t" name="severity" enum="MAV_SEVERITY">Severity of status.</field>
  #|      <field type="char[50]" name="text">Status text message, without null termination character.</field>
  #|      <extensions/>
  #|      <field type="uint16_t" name="id">Unique (opaque) id for this statustext message.</field>
  #|      <field type="uint8_t" name="chunk_seq">This chunk's sequence number; indexing is from zero.</field>
  #|    </message>
  #|    <message id="254" name="DEBUG">
  #|      <description>Send a debug value. The index is used to discriminate between values.</description>
  #|      <field type="uint32_t" name="time_boot_ms" units="ms">Timestamp (time since system boot).</field>
  #|      <field type="uint8_t" name="ind">index of debug variable.</field>
  #|      <field type="float" name="value">DEBUG value.</field>
  #|    </message>
  #|    <message id="268" name="LOGGING_ACK">
  #|      <description>An ack for a LOGGING_DATA_ACKED message (requires 24-bit MAVLink v2 message ID).</description>
  #|      <field type="uint8_t" name="target_system">system ID of the target</field>
  #|      <field type="uint8_t" name="target_component">component ID of the target</field>
  #|      <field type="uint16_t" name="sequence">sequence number (must match the one in LOGGING_DATA_ACKED)</field>
  #|    </message>
  #|  </messages>
  #|</mavlink>
