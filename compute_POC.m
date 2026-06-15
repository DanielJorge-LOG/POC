function [POC_weighted, Class, p, POC] = compute_POC( ...
    sensor, Rrs, BBP, chl, varargin)
%==========================================================================
% COMPUTE_POC
%
% Computes particulate organic carbon (POC) using:
%   - Le et al. (2017)
%   - Tran et al. (2019)
%   - Loisel et al. (2007)
%   - OWT classification (Vantrepotte et al. 2012)
%
% INPUTS
%   sensor : 'OLCI' or 'MODIS'
%
%   Rrs :
%       OLCI  -> [412 443 490 510 560 665]
%       MODIS -> [412 443 488 547 667]
%
%   BBP :
%       OLCI  -> bbp490
%       MODIS -> bbp matrix (490 band in column 3)
%
%   chl :
%       Chlorophyll concentration
%
% OUTPUTS
%   POC_weighted : final blended POC
%   Class        : OWT class
%   p            : class probabilities
%   POC          : structure containing individual algorithms
%
%==========================================================================

sensor = upper(sensor);

%% ========================================================================
% Sensor-specific setup
% ========================================================================

switch sensor

    case 'OLCI'

        %--------------------------------------------------------------
        % Bands
        %--------------------------------------------------------------
        Rrs412 = Rrs(:,1);
        Rrs443 = Rrs(:,2);
        Rrs490 = Rrs(:,3);
        Rrs510 = Rrs(:,4);
        Rrs560 = Rrs(:,5);
        Rrs665 = Rrs(:,6);

        %--------------------------------------------------------------
        % Loisel
        %--------------------------------------------------------------
        POC_Loisel = 41666.7 .* BBP .* chl.^0.25;

        %--------------------------------------------------------------
        % Le
        %--------------------------------------------------------------
        load('LUT_Lee_OLCI.mat','mdl');%le_16_MERIS_2_3

        X = [Rrs490 Rrs510 Rrs560 Rrs665];
        POC_Le = 10.^(feval(mdl,X));

        %--------------------------------------------------------------
        % Tran
        %--------------------------------------------------------------
        R1 = Rrs665 ./ Rrs490;
        R2 = Rrs665 ./ Rrs510;
        R3 = Rrs665 ./ Rrs560;

        Rk = real(log10(max([R1 R2 R3],[],2)));

        x0 = [0.928 2.875];
        POC_Tran = 10.^(x0(1).*Rk + x0(2));

        %--------------------------------------------------------------
        % Classification
        %--------------------------------------------------------------
        [Class,p] = Eumetsat_Class_17( ...
            Rrs,[], ...
            'method','gaussian', ...
            'distribution','gamma');

    case 'MODIS'

        %--------------------------------------------------------------
        % Create synthetic 510 nm band
        %--------------------------------------------------------------
        load('net_510_no_normalization.mat','net');

        Rrs_in = Rrs;

        NN_output = net(Rrs_in');

        Rrs = [ ...
            Rrs_in(:,1:3), ...
            NN_output', ...
            Rrs_in(:,4:5)];

        %--------------------------------------------------------------
        % Bands
        %--------------------------------------------------------------
        Rrs412 = Rrs(:,1);
        Rrs443 = Rrs(:,2);
        Rrs490 = Rrs(:,3);
        Rrs510 = Rrs(:,4);
        Rrs560 = Rrs(:,5);
        Rrs665 = Rrs(:,6);

        %--------------------------------------------------------------
        % Loisel
        %--------------------------------------------------------------
        POC_Loisel = 41666.7 .* BBP(:,3) .* chl.^0.25;

        %--------------------------------------------------------------
        % Le
        %--------------------------------------------------------------
        load('LUT_Lee_MODIS.mat','mdl');%le_16_new_17092024

        X = [Rrs490 Rrs510 Rrs560 Rrs665];
        POC_Le = 10.^(feval(mdl,X));

        %--------------------------------------------------------------
        % Tran
        %--------------------------------------------------------------
        x0 = [0.75 2.81];

        Rk = real(log10(Rrs665 ./ Rrs490));
        POC_Tran = 10.^(x0(1).*Rk + x0(2));

        %--------------------------------------------------------------
        % Classification
        %--------------------------------------------------------------
        [Class,p] = Eumetsat_Class_17( ...
            Rrs,[], ...
            'method','gaussian', ...
            'distribution','gamma');

    otherwise
        error('Unknown sensor: %s',sensor);

end

%% ========================================================================
% Weighted combination
% ========================================================================

POC_comb(:,1) = p(:,1) .* POC_Le;
POC_comb(:,2) = sum(p(:,2:8),2)  .* POC_Kien;
POC_comb(:,3) = sum(p(:,9:17),2) .* POC_Loisel;

POC_weighted = sum(POC_comb,2);

%% ========================================================================
% Quality Control (all sensors)
% ========================================================================

flag1 = Rrs665 <= 1e-4;

flag2 = ...
    Rrs412 > Rrs443 & ...
    Rrs490 > Rrs443;

flag3 = ...
    Rrs412 > Rrs490 & ...
    Rrs490 > Rrs665;

% Reclassify suspicious Class-1 spectra
idx = find(flag3 & Class == 1);

if ~isempty(idx)

    [Class(idx), p(idx,:)] = Eumetsat_Class_17( ...
        Rrs(idx,:), ...
        idx, ...
        'method', 'gaussian', ...
        'distribution', 'gamma');

end

% Force Loisel solution for problematic spectra
POC_weighted(flag1) = POC_Loisel(flag1);
POC_weighted(flag2) = POC_Loisel(flag2);

Class(flag1) = 17;
Class(flag2) = 17;

%% ========================================================================
% Outputs
% ========================================================================

POC.Loisel   = POC_Loisel;
POC.Le       = POC_Le;
POC.Tran     = POC_Tran;
POC.Combined = POC_weighted;

end