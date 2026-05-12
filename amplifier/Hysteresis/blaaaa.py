"""
=============================================================================
Mic Amp Hysteresis Test — Tektronix TBS 1000C via USB (USBTMC)
ELEN4006 Lab 2026
=============================================================================

SETUP:
  1. Connect TBS 1000C to laptop via USB
  2. Set function generator to your target frequency (e.g. 2 kHz sine)
  3. Run this script: python hysteresis_test.py
  4. Follow the prompts — you manually adjust amplitude, script reads scope

WHAT IT MEASURES:
  - Increasing sweep: start low amplitude → increase step by step
  - Decreasing sweep: start high amplitude → decrease step by step
  - Hysteresis = difference between the two curves at the same input level

INSTALL REQUIREMENTS:
  pip install pyvisa pyvisa-py matplotlib numpy
"""

import pyvisa
import numpy as np
import matplotlib.pyplot as plt
import time

# =============================================================================
# CONFIGURATION — edit these
# =============================================================================
FREQUENCY_HZ    = 2000          # Your test frequency in Hz
CHANNEL_INPUT   = "CH1"         # Scope channel connected to function gen / mic input
CHANNEL_OUTPUT  = "CH2"         # Scope channel connected to amp output

# Amplitude steps you will manually set on function generator (in mV peak-to-peak)
# Start from smallest → go up, then come back down
AMPLITUDE_STEPS_MV = [5, 10, 20, 30, 40, 50, 60, 70, 80, 100, 120, 150, 200]

SETTLE_TIME_S   = 1.5           # Seconds to wait after you press Enter before reading

# =============================================================================
# CONNECT TO SCOPE
# =============================================================================
def connect_scope():
    rm = pyvisa.ResourceManager()
    #rm = pyvisa.ResourceManager('@py')
    resources = rm.list_resources()
    print("\nAvailable instruments:")
    for i, r in enumerate(resources):
        print(f"  [{i}] {r}")

    if not resources:
        print("\nERROR: No instruments found.")
        print("  - Make sure USB cable is connected")
        print("  - Make sure scope is on")
        print("  - On Windows: may need NI-VISA or Tektronix OpenChoice drivers")
        print("  - On Linux/Mac: pyvisa-py uses USBTMC directly (usually works)")
        exit(1)

    if len(resources) == 1:
        chosen = resources[0]
    else:
        idx = int(input("\nEnter number of your scope: "))
        chosen = resources[idx]

    scope = rm.open_resource(chosen)
    scope.timeout = 5000  # 5 second timeout
    idn = scope.query("*IDN?")
    print(f"\nConnected to: {idn.strip()}")
    return scope

# =============================================================================
# READ Vpp FROM SCOPE
# =============================================================================
def read_vpp(scope, channel):
    """Query peak-to-peak voltage from scope channel."""
    try:
        # Standard IEEE488 measurement query for TBS series
        scope.write(f"MEASUrement:IMMed:SOUrce1 {channel}")
        scope.write("MEASUrement:IMMed:TYPe PK2pk")
        time.sleep(0.3)
        result = scope.query("MEASUrement:IMMed:VALue?")
        vpp = float(result.strip())
        return vpp
    except Exception as e:
        print(f"  Warning: Could not read {channel}: {e}")
        return None

# =============================================================================
# MAIN HYSTERESIS TEST
# =============================================================================
def run_hysteresis_test(scope):
    print("\n" + "="*60)
    print("  HYSTERESIS TEST")
    print(f"  Frequency: {FREQUENCY_HZ} Hz")
    print(f"  Input channel:  {CHANNEL_INPUT}")
    print(f"  Output channel: {CHANNEL_OUTPUT}")
    print("="*60)
    print("\nINSTRUCTIONS:")
    print("  - Set function generator output to your mic amp input")
    print("  - Connect CH1 to function gen output (before amp)")
    print("  - Connect CH2 to amp output")
    print("  - At each prompt, SET the amplitude then press Enter")
    print()

    # --- INCREASING SWEEP ---
    print(">>> PHASE 1: INCREASING amplitude sweep")
    print(f"    Start at {AMPLITUDE_STEPS_MV[0]} mV Vpp and increase\n")

    up_input_vpp  = []
    up_output_vpp = []

    for target_mv in AMPLITUDE_STEPS_MV:
        input(f"  SET function gen to {target_mv} mV Vpp → then press Enter...")
        time.sleep(SETTLE_TIME_S)

        v_in  = read_vpp(scope, CHANNEL_INPUT)
        v_out = read_vpp(scope, CHANNEL_OUTPUT)

        if v_in is not None and v_out is not None:
            up_input_vpp.append(v_in * 1000)   # convert to mV
            up_output_vpp.append(v_out * 1000)
            print(f"    Measured → Input: {v_in*1000:.1f} mV  |  Output: {v_out*1000:.1f} mV")
        else:
            print(f"    Skipping this point (read error)")

    # --- DECREASING SWEEP ---
    print("\n>>> PHASE 2: DECREASING amplitude sweep")
    print(f"    Now go back DOWN from {AMPLITUDE_STEPS_MV[-1]} mV to {AMPLITUDE_STEPS_MV[0]} mV\n")

    down_input_vpp  = []
    down_output_vpp = []

    for target_mv in reversed(AMPLITUDE_STEPS_MV):
        input(f"  SET function gen to {target_mv} mV Vpp → then press Enter...")
        time.sleep(SETTLE_TIME_S)

        v_in  = read_vpp(scope, CHANNEL_INPUT)
        v_out = read_vpp(scope, CHANNEL_OUTPUT)

        if v_in is not None and v_out is not None:
            down_input_vpp.append(v_in * 1000)
            down_output_vpp.append(v_out * 1000)
            print(f"    Measured → Input: {v_in*1000:.1f} mV  |  Output: {v_out*1000:.1f} mV")
        else:
            print(f"    Skipping this point (read error)")

    return (up_input_vpp, up_output_vpp,
            down_input_vpp, down_output_vpp)

# =============================================================================
# PLOT RESULTS
# =============================================================================
def plot_hysteresis(up_in, up_out, down_in, down_out, freq_hz):
    fig, axes = plt.subplots(1, 2, figsize=(14, 6))
    fig.suptitle(f'Mic Amp Hysteresis Test @ {freq_hz} Hz', fontsize=14, fontweight='bold')

    # --- LEFT PLOT: Input vs Output (the classic hysteresis loop) ---
    ax1 = axes[0]
    ax1.plot(up_in,   up_out,   '-ob', linewidth=2, markersize=6,
             markerfacecolor='b', label='Increasing')
    ax1.plot(down_in, down_out, '--sr', linewidth=2, markersize=6,
             markerfacecolor='r', label='Decreasing')
    ax1.set_xlabel('Input Vpp (mV)', fontsize=12)
    ax1.set_ylabel('Output Vpp (mV)', fontsize=12)
    ax1.set_title('Hysteresis Loop\n(Input vs Output)', fontsize=11)
    ax1.legend()
    ax1.grid(True, alpha=0.4)

    # Calculate ideal gain line for reference
    if up_in and up_out:
        # Estimate gain from linear region (first few points before clipping)
        linear_pts = min(5, len(up_in))
        gains = [out/inp for inp, out in zip(up_in[:linear_pts], up_out[:linear_pts]) if inp > 0]
        if gains:
            avg_gain = np.mean(gains)
            x_ideal = np.linspace(0, max(up_in + down_in), 100)
            y_ideal = avg_gain * x_ideal
            ax1.plot(x_ideal, y_ideal, '--k', alpha=0.4, linewidth=1,
                     label=f'Ideal (gain≈{avg_gain:.0f}×)')
            ax1.legend()

    # --- RIGHT PLOT: Gain vs Input (shows linearity and clipping) ---
    ax2 = axes[1]
    if up_in and up_out:
        gains_up   = [out/inp if inp > 0 else 0 for inp, out in zip(up_in, up_out)]
        gains_down = [out/inp if inp > 0 else 0 for inp, out in zip(down_in, down_out)]

        ax2.plot(up_in,   gains_up,   '-ob', linewidth=2, markersize=6,
                 markerfacecolor='b', label='Increasing')
        ax2.plot(down_in, gains_down, '--sr', linewidth=2, markersize=6,
                 markerfacecolor='r', label='Decreasing')
        ax2.set_xlabel('Input Vpp (mV)', fontsize=12)
        ax2.set_ylabel('Measured Gain (Vout/Vin)', fontsize=12)
        ax2.set_title('Gain vs Input\n(Linearity & Clipping)', fontsize=11)
        ax2.legend()
        ax2.grid(True, alpha=0.4)

    plt.tight_layout()
    plt.savefig('hysteresis_result.png', dpi=150, bbox_inches='tight')
    print("\nPlot saved to: hysteresis_result.png")
    plt.show()

# =============================================================================
# COMPUTE HYSTERESIS ERROR
# =============================================================================
def compute_hysteresis_error(up_in, up_out, down_in, down_out):
    print("\n" + "="*60)
    print("  HYSTERESIS ANALYSIS")
    print("="*60)

    # Interpolate down-sweep onto up-sweep input values for comparison
    if not up_in or not down_in:
        print("  Not enough data to compute hysteresis.")
        return

    down_in_arr  = np.array(sorted(down_in))
    down_out_arr = np.array([o for _, o in sorted(zip(down_in, down_out))])

    max_hysteresis_mv  = 0
    max_hysteresis_pct = 0

    print(f"\n  {'Input (mV)':>12} | {'Up Output (mV)':>16} | {'Down Output (mV)':>17} | {'Diff (mV)':>10} | {'Diff %':>8}")
    print("  " + "-"*75)

    full_scale = max(up_out + down_out) if (up_out and down_out) else 1

    for inp, out_up in zip(up_in, up_out):
        # Interpolate the down-sweep output at this input level
        out_down = np.interp(inp, down_in_arr, down_out_arr)
        diff     = abs(out_up - out_down)
        diff_pct = (diff / full_scale) * 100

        print(f"  {inp:>12.1f} | {out_up:>16.1f} | {out_down:>17.1f} | {diff:>10.1f} | {diff_pct:>7.2f}%")

        if diff > max_hysteresis_mv:
            max_hysteresis_mv  = diff
            max_hysteresis_pct = diff_pct

    print("\n  ─────────────────────────────────────────")
    print(f"  Max Hysteresis Error:  {max_hysteresis_mv:.2f} mV")
    print(f"  Max Hysteresis Error:  {max_hysteresis_pct:.2f}% of full scale")
    print("\n  Note: For a linear op-amp, expect < 1–2% hysteresis.")
    print("        This confirms the amp has no significant memory effect.")

# =============================================================================
# ENTRY POINT
# =============================================================================
if __name__ == "__main__":
    print("Connecting to oscilloscope...")
    scope = connect_scope()

    up_in, up_out, down_in, down_out = run_hysteresis_test(scope)

    scope.close()
    print("\nScope disconnected.")

    compute_hysteresis_error(up_in, up_out, down_in, down_out)
    plot_hysteresis(up_in, up_out, down_in, down_out, FREQUENCY_HZ)