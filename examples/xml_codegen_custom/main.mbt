///|
fn main {
  println("=== Example 3: Custom Drone Payload XML-to-MoonBit Codegen ===")
  let custom_xml =
    #|<?xml version="1.0"?>
    #|<mavlink>
    #|  <version>3</version>
    #|  <dialect>9</dialect>
    #|  <enums>
    #|    <enum name="GIMBAL_MODE">
    #|      <description>Camera gimbal operating mode.</description>
    #|      <entry value="0" name="GIMBAL_MODE_LOCK"/>
    #|      <entry value="1" name="GIMBAL_MODE_FOLLOW"/>
    #|      <entry value="2" name="GIMBAL_MODE_FPV"/>
    #|    </enum>
    #|  </enums>
    #|  <messages>
    #|    <message id="9001" name="GIMBAL_ATTITUDE_STATUS">
    #|      <description>3-axis camera gimbal attitude and motor current status.</description>
    #|      <field type="uint8_t" name="mode" enum="GIMBAL_MODE">Operating mode</field>
    #|      <field type="float" name="pitch_deg">Pitch angle in degrees</field>
    #|      <field type="float" name="yaw_deg">Yaw angle in degrees</field>
    #|      <field type="uint16_t[3]" name="motor_current_ma">Current of 3 gimbal motors</field>
    #|      <field type="uint32_t" name="time_boot_ms">Timestamp since boot</field>
    #|      <extensions/>
    #|      <field type="char[16]" name="lens_model">Active camera lens identifier</field>
    #|    </message>
    #|  </messages>
    #|</mavlink>

  match @mavlink.generate_moonbit_from_xml(custom_xml) {
    Ok((schema, code)) => {
      let msg = schema.messages[0]
      println(
        "Parsed Message: \{msg.name} (ID=\{msg.id}, CRC_EXTRA=\{msg.crc_extra.to_int() & 0xFF}, BaseLen=\{msg.base_payload_len}B, MaxLen=\{msg.max_payload_len}B)",
      )
      println("Wire-Reordered Field Layout:")
      for wf in msg.wire_ordered_fields {
        let ext_tag = if wf.is_extension { " [v2 extension]" } else { "" }
        println(
          "  + offset \{wf.wire_offset}B : \{wf.name} : \{wf.wire_type}\{ext_tag}",
        )
      }
      println("\nGenerated MoonBit Code Preview (first 380 chars):")
      let chars = code.to_array()
      let sb = StringBuilder()
      for i = 0; i < 380 && i < chars.length(); i = i + 1 {
        sb.write_char(chars[i])
      }
      println(sb.to_string() + "\n...")
    }
    Err(e) => println("Error: \{e.to_repr()}")
  }
}
