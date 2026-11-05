///|
/// Official MAVLink v2 standard XML message definitions (`minimal.xml` + core `common.xml` subset)
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
  #|    </enum>
  #|    <enum name="MAV_MODE_FLAG" bitmask="true">
  #|      <description>These flags encode the MAV mode.</description>
  #|      <entry value="1" name="MAV_MODE_FLAG_CUSTOM_MODE_ENABLED">
  #|        <description>0b00000001 Reserved for future use.</description>
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
  #|    </enum>
  #|    <enum name="MAV_CMD">
  #|      <description>Commands to be executed by the MAV.</description>
  #|      <entry value="16" name="MAV_CMD_NAV_WAYPOINT">
  #|        <description>Navigate to waypoint.</description>
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
  #|      <entry value="400" name="MAV_CMD_COMPONENT_ARM_DISARM">
  #|        <description>Arms / Disarms a component.</description>
  #|      </entry>
  #|      <entry value="512" name="MAV_CMD_REQUEST_MESSAGE">
  #|        <description>Request the target system(s) emit a single instance of a specified message.</description>
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
  #|      <entry value="3" name="MAV_FRAME_GLOBAL_RELATIVE_ALT"/>
  #|      <entry value="5" name="MAV_FRAME_GLOBAL_INT"/>
  #|      <entry value="6" name="MAV_FRAME_GLOBAL_RELATIVE_ALT_INT"/>
  #|    </enum>
  #|    <enum name="MAV_MISSION_RESULT">
  #|      <description>Result of a MAVLink mission operation (MAV_MISSION_ACK).</description>
  #|      <entry value="0" name="MAV_MISSION_ACCEPTED"/>
  #|      <entry value="1" name="MAV_MISSION_ERROR"/>
  #|      <entry value="2" name="MAV_MISSION_UNSUPPORTED_FRAME"/>
  #|      <entry value="3" name="MAV_MISSION_UNSUPPORTED"/>
  #|      <entry value="13" name="MAV_MISSION_INVALID_SEQUENCE"/>
  #|    </enum>
  #|    <enum name="MAV_MISSION_TYPE">
  #|      <description>Type of mission items being requested, uploaded, or cleared.</description>
  #|      <entry value="0" name="MAV_MISSION_TYPE_MISSION"/>
  #|      <entry value="1" name="MAV_MISSION_TYPE_FENCE"/>
  #|      <entry value="2" name="MAV_MISSION_TYPE_RALLY"/>
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
  #|    <message id="20" name="PARAM_REQUEST_READ">
  #|      <description>Request to read the onboard parameter with the param_id string id.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="char[16]" name="param_id">Onboard parameter id, terminated by NULL if length is less than 16.</field>
  #|      <field type="int16_t" name="param_index">Parameter index. Send -1 to use the param ID field as identifier.</field>
  #|    </message>
  #|    <message id="22" name="PARAM_VALUE">
  #|      <description>Emit the value of a onboard parameter.</description>
  #|      <field type="char[16]" name="param_id">Onboard parameter id.</field>
  #|      <field type="float" name="param_value">Onboard parameter value.</field>
  #|      <field type="uint8_t" name="param_type">Onboard parameter type.</field>
  #|      <field type="uint16_t" name="param_count">Total number of onboard parameters.</field>
  #|      <field type="uint16_t" name="param_index">Index of this onboard parameter.</field>
  #|    </message>
  #|    <message id="23" name="PARAM_SET">
  #|      <description>Set a parameter value (write new value to permanent storage).</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="char[16]" name="param_id">Onboard parameter id.</field>
  #|      <field type="float" name="param_value">Onboard parameter value.</field>
  #|      <field type="uint8_t" name="param_type">Onboard parameter type.</field>
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
  #|    <message id="44" name="MISSION_COUNT">
  #|      <description>This message is emitted as response to MISSION_REQUEST_LIST by the MAV and to initiate a write transaction.</description>
  #|      <field type="uint8_t" name="target_system">System ID.</field>
  #|      <field type="uint8_t" name="target_component">Component ID.</field>
  #|      <field type="uint16_t" name="count">Number of mission items in the sequence.</field>
  #|      <extensions/>
  #|      <field type="uint8_t" name="mission_type" enum="MAV_MISSION_TYPE">Mission type.</field>
  #|      <field type="uint32_t" name="opaque_id">Id of current on-vehicle mission, fence, or rally point plan.</field>
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
  #|    <message id="253" name="STATUSTEXT">
  #|      <description>Status text message.</description>
  #|      <field type="uint8_t" name="severity" enum="MAV_SEVERITY">Severity of status.</field>
  #|      <field type="char[50]" name="text">Status text message, without null termination character.</field>
  #|      <extensions/>
  #|      <field type="uint16_t" name="id">Unique (opaque) id for this statustext message.</field>
  #|      <field type="uint8_t" name="chunk_seq">This chunk's sequence number; indexing is from zero.</field>
  #|    </message>
  #|    <message id="268" name="LOGGING_ACK">
  #|      <description>An ack for a LOGGING_DATA_ACKED message (requires 24-bit MAVLink v2 message ID).</description>
  #|      <field type="uint8_t" name="target_system">system ID of the target</field>
  #|      <field type="uint8_t" name="target_component">component ID of the target</field>
  #|      <field type="uint16_t" name="sequence">sequence number (must match the one in LOGGING_DATA_ACKED)</field>
  #|    </message>
  #|  </messages>
  #|</mavlink>
