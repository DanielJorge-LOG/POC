# POC Retrieval Algorithm

MATLAB implementation of a Particulate Organic Carbon (POC) retrieval algorithm based on the combination of three published approaches:

- **Le et al. (2016)**
- **Tran et al. (2019)**
- **Loisel et al. (2007)**

The algorithm uses the **EUMETSAT Optical Water Type (OWT)** classification scheme (Vantrepotte et al., 2012) to dynamically combine the different POC estimates according to the optical properties of the water.

Supported sensors:

- Sentinel-3 OLCI
- MODIS-Aqua

---

## Method Overview

For each pixel, the algorithm:

1. Computes POC using:
   - Le et al. (2016)
   - Tran et al. (2019)
   - Loisel et al. (2007)

2. Performs Optical Water Type (OWT) classification using the 17-class EUMETSAT scheme.

3. Combines the individual POC estimates using class membership probabilities.

4. Applies additional quality-control checks to identify and correct anomalous spectra.

---

## Function

```matlab
[POC_weighted, Class, p, POC] = compute_POC(sensor, Rrs, BBP, chl)
```

---

## Inputs

### `sensor`

Sensor identifier:

```matlab
'OLCI'
```

or

```matlab
'MODIS'
```

---

### `Rrs`

Remote sensing reflectance matrix.

#### OLCI

Columns must be ordered as:

```matlab
[Rrs_412 Rrs_443 Rrs_490 Rrs_510 Rrs_560 Rrs_665]
```

#### MODIS

Columns must be ordered as:

```matlab
[Rrs_412 Rrs_443 Rrs_488 Rrs_547 Rrs_667]
```

For MODIS, a synthetic 510 nm band is internally generated using a neural network model.

---

### `BBP`

Particulate backscattering coefficient.

#### OLCI

```matlab
BBP490
```

#### MODIS

Matrix containing particulate backscattering coefficients, with the 490 nm band located in column 3.

---

### `chl`

Chlorophyll-a concentration.

Units should be consistent with those used during algorithm calibration.

---

## Outputs

### `POC_weighted`

Final probability-weighted POC estimate.

---

### `Class`

Assigned Optical Water Type (OWT) class.

Possible values range from 1 to 17.

---

### `p`

Class membership probabilities returned by the OWT classifier.

Dimensions:

```matlab
[N x 17]
```

where `N` is the number of pixels.

---

### `POC`

Structure containing the individual algorithm outputs:

```matlab
POC.Loisel
POC.Le
POC.Tran
POC.Combined
```

---

## Required Files

The following files must be available in the MATLAB path:

### OWT Classification

```text
Eumetsat_Class_17.m
```

### OLCI Model

```text
LUT_Lee_OLCI.mat
```

### MODIS Models

```text
LUT_Lee_MODIS.mat
net_510_no_normalization.mat
```

---

## Example Usage

### OLCI

```matlab
Rrs = [ ...
    Rrs_412(:), ...
    Rrs_443(:), ...
    Rrs_490(:), ...
    Rrs_510(:), ...
    Rrs_560(:), ...
    Rrs_665(:)];

[POC_weighted, Class, p, POC] = compute_POC( ...
    'OLCI', ...
    Rrs, ...
    BBP490, ...
    CHL);
```

---

### MODIS

```matlab
Rrs = [ ...
    Rrs_412(:), ...
    Rrs_443(:), ...
    Rrs_488(:), ...
    Rrs_547(:), ...
    Rrs_667(:)];

[POC_weighted, Class, p, POC] = compute_POC( ...
    'MODIS', ...
    Rrs, ...
    BBP, ...
    CHL);
```

---

## Algorithm Combination

The final POC estimate is obtained using Optical Water Type probabilities:

| OWT Class | Algorithm |
|------------|------------|
| 1 | Le et al. (2016) |
| 2–8 | Tran et al. (2019) |
| 9–17 | Loisel et al. (2007) |

The weighted estimate is computed as:

```matlab
POC_weighted = ...
      p(:,1) .* POC_Le ...
    + sum(p(:,2:8),2)  .* POC_Tran ...
    + sum(p(:,9:17),2) .* POC_Loisel;
```

---

## Quality Control

Additional spectral quality-control filters are applied to identify anomalous reflectance spectra.

For flagged pixels:

- The spectrum may be reclassified using the OWT classifier.
- The final POC estimate is replaced by the Loisel et al. estimate.
- The OWT class may be forced to Class 17.

These checks help improve algorithm robustness in optically complex waters and for atypical spectral shapes.

---

## References

### Le et al. (2016)

Le, C., Li, Y., Zha, Y., Sun, D., Huang, C., Lu, H., and Yin, B. (2016).  
*A four-band semi-analytical model for estimating particulate organic carbon in inland waters from remote sensing data.*

### Tran et al. (2019)

Tran, K. T., et al. (2019).  
*Remote sensing of particulate organic carbon in coastal and inland waters using red-to-blue reflectance relationships.*

### Loisel et al. (2007)

Loisel, H., Mériaux, X., Berthon, J.-F., and Poteau, A. (2007).  
*Investigation of the optical backscattering-to-particle concentration relationship in coastal waters.*

### Vantrepotte et al. (2012)

Vantrepotte, V., Loisel, H., Dessailly, D., and Mériaux, X. (2012).  
*Optical classification of contrasted coastal waters.*

---

## Notes

- MODIS reflectances are internally converted to an OLCI-like spectral configuration through the estimation of a synthetic 510 nm band.
- Input reflectances should be provided as remote sensing reflectance (`Rrs`) in units of sr⁻¹.
- The algorithm operates on vectors or matrices of pixels and supports batch processing.

---
