function [Class, p] = Eumetsat_Class_17(Rrs,flag,opts)
% Syntax:
%   [Class, probability] = Eumetsat_Class_17(Rrs)
%
% Input Arguments:
%   (Required)
%   Rrs                 - Input Remote sensing reflectance
%                           [double | cell]
% Outputs:
%   Class               - 17 OWTs defined from (Vantrepotte et al., 2019)
%                           [vector | matrix]
%   P                   - Probability for each Class
%                           [cell]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: Manh Tran on 10-07-2023
% Institution: Laboratoire d'Océanologie et de Géosciences - CNRS
% Citation:
% Vantrepotte, V.; Loisel, H.; Dessailly, D.; Mériaux, X. 
% Optical Classification of Contrasted Coastal Waters. 
% Remote Sens. Environ. 2012, 123, 306–323
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    arguments 
        Rrs
        flag
        opts.sensor char{mustBeMember(opts.sensor,{'olci','meris','msi','modis'})} = 'olci'
        opts.method char {mustBeMember(opts.method,{'gaussian','logistic','svm'})} = 'gaussian'
        opts.distribution char {mustBeMember(opts.distribution,{'normal','gamma'})} = 'normal'
    end

    % Load inputs
    file_path = fileparts(mfilename('fullpath'));
    if strcmp(opts.method,'gaussian')
    load('Input_probability_gaussian_olci_17.mat');
%     load('D:\Danielsfj\Vincent\Images_matchup_Chl\config\Input_probability_gaussian_modis_17_DJ.mat');
    
    elseif strcmp(opts.method,'logistic')
    load('Input_probability_logistic_olci_17_2.mat')
        
    end
    
    % Load support functions
    HSF=handle_support_functions();
    
    % Sensor Bands
    vis_bands = SensorBands.olci_vis;


    % Handle Rrs input
    if isnumeric(Rrs)
        if size(Rrs,2)~=numel(vis_bands)
            error('Error: Reflectance input must contain %d columns',numel(vis_bands))
        end
    elseif iscell(Rrs)
        if size(Rrs,2)~=numel(vis_bands)
            error('Error: Reflectance input must contain %d cells',numel(vis_bands))
        end
    end

    % Read Rrs input and reshape
    Rrs_input = [];
    for i = 1:numel(vis_bands)
        if iscell(Rrs)
            eval(sprintf('Rrs%d = Rrs{%d};',vis_bands(i),i))
        elseif isnumeric(Rrs)
            eval(sprintf('Rrs%d = Rrs(:,i);',vis_bands(i),i))
        end

        eval(sprintf('[mx,my] = size(Rrs%d);',vis_bands(i)));
        eval(sprintf('Rrs%d = reshape(Rrs%d,[],1);',vis_bands(i),vis_bands(i)))
        eval(sprintf('Rrs_input = [Rrs_input, Rrs%d];',vis_bands(i)));
    end
    

    % Normalize Rrs
    Rrs_norm = normalize_Rrs(Rrs_input,vis_bands);

    % Perform the classification
    [p , Class] = probability(Input_probability,flag,Rrs_norm, ...
                             "method",opts.method, ...
                             "distribution",opts.distribution);

    % Return probability and Class matrices
    for i=1:size(p,2)
        P{i} = reshape(p(:,i),mx,my);
    end

    Class = reshape(Class,mx,my);

end