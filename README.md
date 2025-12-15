# FMCW Radar Target Detection with 2D CA-CFAR

This repository contains a MATLAB script that simulates a **77 GHz Frequency Modulated Continuous Wave (FMCW) radar** system for detecting a single moving target. The detection pipeline includes **Range–Doppler Map (RDM) generation using a 2D Fast Fourier Transform (FFT)** and **automatic target detection using a 2D Cell-Averaging Constant False Alarm Rate (CA-CFAR)** algorithm.

---

## ⚙️ Radar System Specifications

| Parameter | Value |
|---------|------|
| **Operating Frequency ($f_c$)** | 77 GHz |
| **Maximum Range ($R_{max}$)** | 200 m |
| **Range Resolution ($\Delta R$)** | 1 m |
| **Maximum Velocity ($V_{max}$)** | 100 m/s |
| **Speed of Light ($c$)** | $3 \times 10^8$ m/s |

---

## 🎯 Target Configuration

A single point target is simulated with **constant radial velocity** throughout the observation period.

| Parameter | Value |
|---------|------|
| **Initial Range** | 110 m |
| **Radial Velocity** | −20 m/s (approaching the radar) |

---

## 🛠️ Signal Processing Flow

The MATLAB script is divided into four main stages:

---

## 1️⃣ FMCW Waveform Generation

The FMCW waveform parameters are derived from the radar specifications:

- **Sweep Bandwidth ($B_{sweep}$)**  
  Determined by the required range resolution:
  \[
  B_{sweep} = \frac{c}{2 \Delta R} = 150~\text{MHz}
  \]

- **Chirp Duration ($T_{chirp}$)**  
  Selected to satisfy the maximum unambiguous range condition:
  \[
  T_{chirp} = 5.5 \times \frac{2 R_{max}}{c}
  \]

- **Chirp Slope ($S$)**  
  \[
  S = \frac{B_{sweep}}{T_{chirp}}
  \]

These parameters define the linear frequency modulation of the transmitted FMCW chirp.

---

## 2️⃣ Signal Generation and Moving Target Simulation

For each time sample:

- The target range is updated assuming constant velocity motion.
- The round-trip propagation delay is computed from the instantaneous range.
- Transmitted (**Tx**) and received (**Rx**) signals are generated using the FMCW phase model.
- The **beat signal (Mix)** is formed by mixing Tx and Rx:
  \[
  \text{Mix}(t) = \text{Tx}(t) \cdot \text{Rx}(t)
  \]

The Doppler effect is naturally captured through the time-varying propagation delay of the received signal.

---

## 3️⃣ Range–Doppler Map (RDM) Generation

The Range–Doppler Map is generated using a 2D FFT:

- **Range FFT**  
  Applied along the fast-time dimension ($N_r = 1024$ samples per chirp) to extract beat frequencies corresponding to target range.

- **Doppler FFT**  
  Applied along the slow-time dimension ($N_d = 128$ chirps) to estimate target radial velocity.

- The resulting RDM is converted to logarithmic scale (dB):
  \[
  \text{RDM}_{\text{dB}} = 10 \log_{10}(|\text{RDM}|)
  \]

This RDM serves as the input to the CFAR detector.

---

## 4️⃣ 2D CA-CFAR Implementation

A **Cell-Averaging Constant False Alarm Rate (CA-CFAR)** detector is applied to the RDM to identify targets while maintaining a constant false alarm probability.

### CFAR Parameters

| Parameter | Symbol | Value | Description |
|---------|-------|-------|------------|
| Range Training Cells (one side) | Tr | 10 | Noise estimation in range dimension |
| Doppler Training Cells (one side) | Td | 8 | Noise estimation in Doppler dimension |
| Range Guard Cells (one side) | Gr | 4 | Protect CUT from signal leakage |
| Doppler Guard Cells (one side) | Gd | 4 | Protect CUT from signal leakage |
| Threshold Offset | Offset | 6 dB | Required SNR margin |

---

### CFAR Detection Logic

For each **Cell Under Test (CUT)**:

1. A sliding window is formed around the CUT containing training and guard cells.
2. Guard cells and the CUT are excluded from noise estimation.
3. Training cell power is summed in the **linear domain** using `db2pow`.
4. Average noise power is computed and converted back to dB:
   \[
   T_h = \text{pow2db}\left(\frac{\sum P_{\text{training}}}{N_{\text{training}}}\right) + \text{Offset}
   \]
5. If the CUT power exceeds the threshold, the cell is declared a detection.

---

## 📈 Output Visualizations

The script generates the following plots:

1. **Range FFT Output**  
   Displays the range profile of the first chirp, clearly showing the target range.

2. **Range–Doppler Map (RDM)**  
   A 3D surface plot highlighting the target’s location in range and velocity.

3. **CFAR Detection Map**  
   A binary detection map where detected target cells are marked as `1`, demonstrating effective noise and clutter suppression.

---

## ✅ Summary

This project demonstrates a complete FMCW radar signal processing chain, including waveform design, signal simulation, FFT-based range–Doppler processing, and robust target detection using 2D CA-CFAR.
