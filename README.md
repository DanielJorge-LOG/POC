# POC Algorithm

This repository contains a MATLAB implementation of a Particulate Organic Carbon (POC) retrieval algorithm based on a combination of:

- Le et al. (2016)
- Kien et al.
- Loisel (Hubert formulation)
- EUMETSAT Optical Water Type (OWT) classification

The algorithm supports both **Sentinel-3 OLCI** and **MODIS-Aqua** observations and combines multiple POC estimates using OWT class probabilities.

---

## Overview

The workflow consists of:

1. Optical Water Type classification using the EUMETSAT 17-class scheme.
2. Computation of POC using:
   - Le et al. algorithm
   - Kien et al. algorithm
   - Loisel/Hubert algorithm
3. Probability-weighted blending of the three estimates.
4. Quality-control checks and reclassification of suspicious spectra.

---

## Requirements

The following files must be available in your MATLAB path:

### OWT Classifier

- `Eumetsat_Class_17.m`

### Models

#### OLCI

- `le_16_MERIS_2_3.mat`

#### MODIS

- `le_16_new_17092024.mat`
- `net_510_no_normalization.mat`

---

## Function

```matlab
[POC, Class, p, POC_alg] = compute_POC(sensor, Rrs, BBP, CHL)
```

### Inputs

#### `sensor`

String specifying the sensor:

```matlab
'OLCI'
```

or

```matlab
'MODIS'
```

---

#### `Rrs`

Remote sensing reflectance matrix.

##### OLCI

Columns must be ordered as:

```matlab
[Rrs_412 Rrs_443 Rrs_490 Rrs_510 Rrs_560 Rrs_665]
```

##### MODIS

Columns must be ordered as:

```matlab
[Rrs_412 Rrs_443 Rrs_488 Rrs_547 Rrs_667]
```

For MODIS, the 510 nm band is estimated internally using a neural network.

---

#### `BBP`

Backscattering coefficient.

##### OLCI

```matlab
BBP490
```

##### MODIS

Matrix containing the particulate backscattering coefficients, with the 490 nm band in column 3.

---

#### `CHL`

Chlorophyll-a concentration.

---

## Outputs

### `POC`

Final probability-weighted POC estimate.

### `Class`

Optical Water Type class (1–17).

### `p`

Class membership probabilities.

### `POC_alg`

Structure containing individual algorithm estimates:

```matlab
POC_alg.Le
POC_alg.Kien
POC_alg.Loisel
POC_alg.Combined
```

---

# Example Usage

## OLCI

```matlab
Rrs = [ ...
    Rrs_412(:), ...
    Rrs_443(:), ...
    Rrs_490(:), ...
    Rrs_510(:), ...
    Rrs_560(:), ...
    Rrs_665(:)];

[POC, Class, p, POC_alg] = compute_POC( ...
    'OLCI', ...
    Rrs, ...
    BBP490, ...
    CHL);
```

---

## MODIS

```matlab
Rrs = [ ...
    Rrs_412(:), ...
    Rrs_443(:), ...
    Rrs_488(:), ...
    Rrs_547(:), ...
    Rrs_667(:)];

[POC, Class, p, POC_alg] = compute_POC( ...
    'MODIS', ...
    Rrs, ...
    BBP, ...
    CHL);
```

---

# Algorithm Combination

The final POC estimate is obtained using OWT probabilities:

| OWT Class | Algorithm |
|------------|------------|
| 1 | Le et al. |
| 2–8 | Kien et al. |
| 9–17 | Loisel/Hubert |

The weighted estimate is computed as:

```matlab
POC = ...
    p(:,1) .* POC_Le + ...
    sum(p(:,2:8),2) .* POC_Kien + ...
    sum(p(:,9:17),2) .* POC_Loisel;
```

---

# Quality Control

Additional spectral checks are applied to identify anomalous spectra.

For flagged pixels:

- OWT class is reassigned when appropriate.
- The final estimate is replaced by the Loisel/Hubert formulation.
- Pixels may be forced to OWT Class 17.

---

# Citation

If you use this code in a publication, please cite:

- Le et al. (2016)
- Kientz et al.
- Loisel et al.
- EUMETSAT Optical Water Type classification framework

and the corresponding publication describing this algorithm.

---

# Contact

For questions, bug reports, or contributions, please open an issue in this repository.
