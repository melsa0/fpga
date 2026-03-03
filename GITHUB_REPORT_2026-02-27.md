# HDMI Passthrough Progress Report (2026-02-27)

## Summary
Today we achieved reliable Vivado build/programming flow and produced multiple valid bitstreams, but we did **not** achieve visible video output on monitor.

Status:
- Bitstream generation: successful
- FPGA programming: successful
- HDMI image passthrough on monitor: **failed**

---

## Project Goal
Primary goal for today:
- Transfer image through FPGA only:
  - Source (RK3288 HDMI OUT) -> Nexys Video HDMI IN
  - Nexys Video HDMI OUT -> Monitor

Secondary goals (deferred):
- Color/brightness/resolution control application after passthrough works.

---

## What Was Completed
1. Fixed and stabilized build scripts for short-path Windows build (`C:\hdmiCtrl` / `C:\hdmiCtrl_passthrough`).
2. Generated and validated several bitstreams with successful DRC at bitgen stage.
3. Programmed device successfully multiple times (`xc7a200t_0`, DONE high).
4. Built two design variants:
   - Complex chain (MIG + VDMA + MicroBlaze + HDMI IP)
   - Minimal HDMI passthrough chain (DVI2RGB -> RGB2DVI)
5. Added HDMI RX HPD assertion in minimal design (`hdmi_rx_hpd` forced high) and rebuilt/reprogrammed.
6. Verified implementation route/bitstream success in logs for final minimal build.

---

## What Was Not Completed
1. No video displayed on monitor after programming.
2. End-to-end passthrough functionality was not validated physically.
3. Source/monitor compatibility path was not closed (EDID/handshake behavior still unresolved).

---

## Technical Findings
1. Earlier failures fixed:
   - Windows path length failures in MIG/IP temporary paths.
   - Invalid/unsafe clock pin usage in earlier flow.
   - MMCM FVCO violation in `dvi2rgb` path (`kClkRange` mismatch).
2. Final minimal design:
   - `write_bitstream completed successfully`
   - No blocking DRC error at bitgen
   - Device programmed successfully
3. Despite successful digital flow, physical video output remained absent.

---

## Root Causes of Failure
1. **Scope mismanagement at start**
   - Began with over-complex architecture (DDR/VDMA/MicroBlaze) instead of direct passthrough-first.
2. **Late convergence on board-level handshake details**
   - HDMI bring-up depends on HPD/DDC/EDID behavior beyond basic bitstream success.
3. **Assumption risk**
   - Treated “bitstream/program success” as near-functional success; in HDMI this is insufficient.
4. **Iteration cost**
   - Multiple long Vivado cycles consumed time before narrowing to strict board-interface validation.

---

## Why This Is Still a Failure
Because the acceptance criterion was clear:
- “Video must appear on monitor through FPGA.”

This criterion is not met yet.

---

## Corrective Actions (Next Session)
1. Lock a strict hardware bring-up checklist before any rebuild.
2. Verify board-level HDMI transceiver/bridge requirements (HPD/DDC/EDID direction) against reference design.
3. Create a known-good reference pass from Digilent Nexys Video HDMI sample and compare net-by-net to current design.
4. Add explicit runtime validation points:
   - Source sees sink via EDID
   - HPD level confirmed
   - Pixel clock lock status from decoder IP
5. Continue only with minimal passthrough until first visible frame appears.

---

## Deliverables Produced Today
- `build_hdmi_passthrough.tcl`
- `hdmi_passthrough_nexys_video.xdc`
- Updated build flow scripts in `final_delivery`
- Working bitstreams:
  - `C:\hdmiCtrl\...\hdmi_bd_wrapper.bit` (complex flow)
  - `C:\hdmiCtrl_passthrough\...\hdmi_passthrough_bd_wrapper.bit` (minimal flow)

---

## Final Statement
This session delivered tooling/build stability and reproducible programming, but failed the core functional target (visible HDMI passthrough image).  
Primary responsibility is incorrect sequencing and late hardware-handshake convergence.

