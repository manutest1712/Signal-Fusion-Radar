# FMCW Radar Target Detection with 2D CFAR

This repository contains a MATLAB script that simulates a 77 GHz Frequency Modulated Continuous Wave (FMCW) radar system to detect a single moving target. The core of the detection process involves generating a Range-Doppler Map (RDM) using a 2D Fast Fourier Transform (FFT) and applying the **2D Cell-Averaging Constant False Alarm Rate (CA-CFAR)** algorithm for robust automatic target detection.

## ⚙️ Radar System Specifications

| Parameter | Value |
| :--- | :--- |
| **Operating Frequency ($f_c$)** | 77 GHz |
| **Maximum Range ($R_{max}$)** | 200 m |
| **Range Resolution ($\Delta R$)** | 1 m |
| **Maximum Velocity ($V_{max}$)** | 100 m/s |
| **Speed of Light ($c$)** | $3 \times 10^8$ m/s |

## 🎯 Target Configuration

A single moving target is simulated with constant velocity throughout the observation period.

| Parameter | Value |
| :--- | :--- |
| **Initial Range** | 110 m |
| **Velocity** | -20 m/s (Approaching) |

## 🛠️ Code Structure and Signal Processing Steps

The script is divided into four main sections:

### 1. FMCW Waveform Generation
The script first calculates the necessary FMCW parameters based on the specifications:

* **Bandwidth ($B_{sweep}$):** Determined by the required Range Resolution. $B_{sweep} = \frac{c}{2 \cdot \Delta R} = 150 \text{ MHz}$.
* **Chirp Time ($T_{chirp}$):** Calculated based on the maximum range to ensure the beat frequency falls within the processing window. $$T_{chirp} = \frac{5.5 \times 2 \times R_{max}}{c}$$
* **Slope ($S$):** $S = B_{sweep} / T_{chirp}$.

### 2. Signal Generation and Moving Target Simulation
This section generates the transmitted (`Tx`) and received (`Rx`) signals based on the target's instantaneous range and time delay, accounting for the Doppler shift. The beat signal (`Mix`) is calculated by multiplying the `Tx` and `Rx` signals.

### 3. Range Doppler Response
The script uses the 2D FFT to generate the Range-Doppler Map (RDM).

* **First FFT (Range FFT):** Applied along the columns ($\text{Nr}=1024$ samples per chirp) to separate beat frequencies, providing the target's range profile.
* **Second FFT (Doppler FFT):** Applied along the rows ($\text{Nd}=128$ chirps) to separate the Doppler frequencies, providing the target's velocity.
* The RDM is converted to a logarithmic scale ($\text{dB}$) using $10 \log_{10}(RDM)$ for CFAR processing. 

### 4. 2D CA-CFAR Implementation
The **Cell-Averaging Constant False Alarm Rate (CA-CFAR)** algorithm is applied to the RDM to automatically detect the target while maintaining a consistent false alarm rate against background noise and clutter.

#### CFAR Parameters:

| Parameter | Symbol | Value | Description |
| :--- | :--- | :--- | :--- |
| **Range Training Cells (one side)** | $\text{Tr}$ | 10 | Used for noise estimation in the range dimension. |
| **Doppler Training Cells (one side)** | $\text{Td}$ | 8 | Used for noise estimation in the Doppler dimension. |
| **Range Guard Cells (one side)** | $\text{Gr}$ | 4 | Cells around the CUT that are excluded from noise estimation. |
| **Doppler Guard Cells (one side)** | $\text{Gd}$ | 4 | Cells around the CUT that are excluded from noise estimation. |
| **Threshold Offset ($\alpha$)** | $\text{offset}$ | 6 dB | The required Signal-to-Noise Ratio (SNR) margin for detection. |

#### 2D CA-CFAR Core Logic

The algorithm iterates through the RDM, defining an adaptive detection threshold ($T_h$) for each Cell Under Test ($\text{CUT}$) based on the local noise power ($\hat{P}_n$) estimated from the surrounding Training Cells. 
1.  **Noise Estimation:** The power of the Training Cells within the window is summed in the **linear** domain ($\text{db2pow}$).
2.  **Exclusion:** The Guard Cells and CUT are explicitly set to zero power in the **linear** domain to prevent signal leakage from corrupting the noise average.
3.  **Threshold Calculation:** The average linear noise power is converted back to decibels (dB) using `pow2db`, and a fixed SNR offset is added to form the adaptive threshold:

```math
T_h = \text{pow2db}\left( \frac{\sum P_{\text{linear}}}{N_{\text{tc}}} \right) + \text{offset}_{\text{dB}}
```
4.  **Detection**: The final step is to compare the power of the Cell Under Test (CUT) against the calculated adaptive threshold ($T_h$).
* **Comparison Rule:** If the CUT power ($P_{\text{CUT}}$) from the Range-Doppler Map (RDM) is greater than the Threshold ($T_h$), the cell is declared a target.
* **Output:** The cell is marked as a target (`1`) in the final CFAR output map ($M_{\text{CFAR}}$).
####       Mathematical Expression (Simplified)

$$P_{\text{CUT}} > T_h \quad \rightarrow \quad \text{Target Detected} = 1$$


---

## 📈 Expected Output Plots

The script generates three plots to visualize the processing pipeline and final result:

1.  **Range from First FFT:** Shows the range profile of the first chirp, clearly indicating the target range.
2.  **Range Doppler Map (RDM):** A 3D surface plot showing the target's power peak at its correct range and velocity coordinates.
3.  **CFAR Detection Map:** A binary map ($\text{RDM}_{\text{cfar}}$) where only the detected target cell(s) are set to 1, demonstrating the successful suppression of noise and clutter.
