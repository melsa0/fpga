# Nexys Video ADAU1761 440 Hz Tone Generator Report (2026-03-15)

## Summary
Today we completed a full staged Vivado flow for a Nexys Video audio design that drives the onboard ADAU1761 codec and outputs a generated `440 Hz` tone.

Final status:
- RTL design creation: successful
- Constraint creation: successful
- Synthesis: successful
- Implementation: successful
- Bitstream generation: successful
- FPGA programming: successful
- Physical audio confirmation from user: successful

---

## Project Goal
Primary goal for today:
- Generate and hear a `440 Hz` tone on Nexys Video through the onboard ADAU1761 codec.

Execution constraint:
- Advance one step at a time only after explicit user approval.

---

## What Was Completed
1. Reviewed the local Nexys Video material already present in the repo:
   - board metadata
   - prior project reports
   - reference manual PDF
2. Created a standalone Verilog-based audio project under `validation_test/audio_tone_440/`.
3. Implemented the following design blocks:
   - top-level audio design
   - audio clock generation
   - ADAU1761 I2C initialization FSM
   - low-level I2C write engine
   - I2S stereo tone transmitter
4. Added a dedicated Nexys Video XDC for the ADAU1761 and debug LEDs.
5. Added dedicated TCL flows for:
   - synthesis
   - implementation
   - bitstream generation
   - device programming
6. Completed an initial end-to-end build and programming cycle.
7. Investigated why no sound was heard from `J5 line out`.
8. Identified and fixed two independent classes of problems:
   - implementation/timing issues caused by cross-domain handling
   - codec routing/init issues in the ADAU1761 register sequence
9. Rebuilt the design from synthesis forward after the fixes.
10. Reprogrammed the FPGA with the corrected bitstream.
11. Received user confirmation that the tone output works.

---

## What Was Not Completed
1. No runtime register readback/debug path was added for the ADAU1761.
2. No ILA-based instrumentation was inserted.
3. No runtime control interface was added for frequency, gain, or mute.
4. No user-facing volume control was added.

---

## Technical Findings
1. The Nexys Video local board files in the repo do not directly expose the ADAU1761 interface names, so board-level audio pin recovery relied on the reference manual and known Nexys Video audio interface mapping.
2. The implemented audio interface uses:
   - `ac_adc_sdata`
   - `ac_dac_sdata`
   - `ac_bclk`
   - `ac_lrclk`
   - `ac_mclk`
   - `ac_scl`
   - `ac_sda`
3. The generated master audio clock path is driven from the 100 MHz onboard clock using an MMCM.
4. The tone generator uses an internal phase accumulator and serializes stereo samples over I2S.
5. The first implementation attempt routed successfully but failed timing because `sys_clk` to `audio_clk` crossings were not treated correctly.
6. The major timing failure was reduced from a large multi-endpoint violation down to a single CDC endpoint, then removed fully by:
   - synchronizing cross-domain status signals
   - marking synchronizer stages appropriately
   - adding CDC false-path constraints for first-stage synchronizers
7. A separate issue remained after digital closure:
   - the FPGA design built and programmed correctly
   - LEDs indicated activity
   - but no audible output was present
8. The audio-output failure was traced to codec initialization/routing assumptions rather than FPGA timing closure.
9. The ADAU1761 initialization sequence was revised to better enable playback path routing and output volume settings for the board output path.
10. Final implementation closed successfully:
   - routed status: complete
   - routed setup timing: positive
   - routed hold timing: positive
11. Final programming succeeded on device:
   - `xc7a200t_0`

---

## Issues Encountered and Fixes
1. **Initial routed implementation failed timing**
   - Root cause: unsafe direct timing relationship between `sys_clk` domain status logic and `audio_clk` domain control/reset logic.
   - Fix: added explicit synchronizers, reset cleanup, and CDC exceptions for synchronizer first stages.
2. **Methodology warnings around asynchronous reset usage**
   - Root cause: reset structure allowed LUT-driven async behavior into the audio domain.
   - Fix: reworked the reset/control structure so the audio-domain logic used synchronized control signals.
3. **Bitstream programmed but no sound was heard**
   - Root cause: ADAU1761 playback/output register setup was not yet sufficient for the actual board path.
   - Fix: updated codec register initialization sequence to improve output routing and output enable/level programming.
4. **Remaining non-blocking DRC warning during early iterations**
   - Root cause: missing configuration voltage properties.
   - Fix: added `CFGBVS` and `CONFIG_VOLTAGE` properties in XDC.
5. **I/O direction warning on `ac_scl`**
   - Root cause: the design only drives the line and does not actively sample it as a full bidirectional interface.
   - Result: non-blocking for this use case.

---

## Final Build Results
1. Final synthesis status:
   - `synth_design Complete!`
2. Final implementation status:
   - `route_design Complete!`
3. Final routed timing:
   - router estimate near end of successful run showed positive slack
   - final routed flow completed with no timing failure message
4. Final bitstream status:
   - `write_bitstream completed successfully`
5. Final programming status:
   - `SUCCESS: Device programmed`
6. Final functional result:
   - user confirmed audible output was obtained

---

## Deliverables Produced Today
- [docs/nexys-video_rm.pdf](/c:/Users/user/OneDrive/Masaüstü/fpga_asist_dev-master/docs/nexys-video_rm.pdf)
- [validation_test/audio_tone_440/audio_tone_440_top.v](/c:/Users/user/OneDrive/Masaüstü/fpga_asist_dev-master/validation_test/audio_tone_440/audio_tone_440_top.v)
- [validation_test/audio_tone_440/adau1761_i2c_init.v](/c:/Users/user/OneDrive/Masaüstü/fpga_asist_dev-master/validation_test/audio_tone_440/adau1761_i2c_init.v)
- [validation_test/audio_tone_440/i2c_master_write4.v](/c:/Users/user/OneDrive/Masaüstü/fpga_asist_dev-master/validation_test/audio_tone_440/i2c_master_write4.v)
- [validation_test/audio_tone_440/i2s_tone_tx.v](/c:/Users/user/OneDrive/Masaüstü/fpga_asist_dev-master/validation_test/audio_tone_440/i2s_tone_tx.v)
- [validation_test/audio_tone_440/audio_tone_440_nexys_video.xdc](/c:/Users/user/OneDrive/Masaüstü/fpga_asist_dev-master/validation_test/audio_tone_440/audio_tone_440_nexys_video.xdc)
- [validation_test/audio_tone_440/run_audio_tone_synthesis.tcl](/c:/Users/user/OneDrive/Masaüstü/fpga_asist_dev-master/validation_test/audio_tone_440/run_audio_tone_synthesis.tcl)
- [validation_test/audio_tone_440/run_audio_tone_implementation.tcl](/c:/Users/user/OneDrive/Masaüstü/fpga_asist_dev-master/validation_test/audio_tone_440/run_audio_tone_implementation.tcl)
- [validation_test/audio_tone_440/run_audio_tone_bitstream.tcl](/c:/Users/user/OneDrive/Masaüstü/fpga_asist_dev-master/validation_test/audio_tone_440/run_audio_tone_bitstream.tcl)
- [validation_test/audio_tone_440/program_audio_tone_device.tcl](/c:/Users/user/OneDrive/Masaüstü/fpga_asist_dev-master/validation_test/audio_tone_440/program_audio_tone_device.tcl)
- Generated Vivado project:
  - `C:\nexys_audio_tone_440\nexys_audio_tone_440.xpr`
- Generated routed checkpoint:
  - `C:\nexys_audio_tone_440\nexys_audio_tone_440.runs\impl_1\audio_tone_440_top_routed.dcp`
- Generated bitstream:
  - `C:\nexys_audio_tone_440\nexys_audio_tone_440.runs\impl_1\audio_tone_440_top.bit`

---

## Final Statement
This session achieved the requested staged workflow end-to-end for Nexys Video onboard audio: custom RTL creation, constraint creation, synthesis, clean routed implementation, bitstream generation, FPGA programming, and successful audible tone output through the board audio path.

The main engineering work was not just building the design once, but diagnosing and correcting both timing-closure issues and codec initialization/routing issues until the hardware result matched the requested behavior.
