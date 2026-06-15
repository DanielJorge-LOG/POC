function [p, Class, D, Pdf] = probability(Input,flag,Rrs_norm, opts)

    % Syntax:
    %   Probability(Input, Rrs_norm, varargin)
    %
    % Input Arguments:
    %   (Required)
    %   Input               - Input corresponding to the probability method
    %                         {cov_matrix, mean_matrix} - 'gaussian'
    %                         coefficients - 'logistic'
    %
    %   Rrs_norm            - Normalized remote sensing reflectance
    %                           [vector | matrix]
    %   (Optional)
    %   method              - Probability method
    %                          'gaussian' (default)|'logistic'
    %                           [char]
    %
    %   distribution        - Distribution type (only for Gaussian method)
    %                           'normal' (default) | 'gamma'
    %                           [char]   
    % Outputs:
    %   p                   - Probability of each defined Class
    %                           [vector | matrix]  
    % 
    %   Class               - Class retrieval according to maximum probability
    %                           [vector | matrix]    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Default arguments
    arguments
        Input
        flag
        Rrs_norm
        opts.method char {mustBeMember(opts.method,{'gaussian','logistic','tree','svm','naivebayes','adaboostm2'})} = 'gaussian'
        opts.distribution char {mustBeMember(opts.distribution,{'normal','gamma'})} = 'normal'
    end
    
    % Config Inputs
    if strcmp(opts.method,'gaussian')
        if ~iscell(Input)&&numel(Input)~=2
            error('Input must be a cell array containing covariance and mean matrices')
        end
        cov_matrix=Input{1};
        mean_matrix=Input{2};
        % Numer of Class
        nc=size(mean_matrix,3);
        % Number of band involved
        b=size(mean_matrix,2);
    end

    % Load support functions
    HSF= handle_support_functions();

    % Handle Input Rrs
    Rrs_input=log10(double(Rrs_norm));
    Rrs_input=HSF.handle_inf_img(Rrs_input);
    
   
    %%% Get Maximum likely hood
    switch opts.method
        case 'gaussian'
            for i=1:nc
                D(:,i)=(pdist2(Rrs_input,mean_matrix(:,:,i),'mahalanobis',cov_matrix(:,:,i))).^2;
                if i==1
                    D(flag==1,i)=9999;
                end
                % D(:,i)=(pdist2(Rrs_input,mean_matrix(:,:,i),'mahalanobis',cov_matrix(:,:,i)));
                % distribution
                switch opts.distribution
                    case 'normal'
                        Pdf(:,i)=mvnpdf(Rrs_input,mean_matrix(:,:,i),cov_matrix(:,:,i));
                        % MS=((2*pi)^(b/2))*(det(cov_matrix(:,:,i)).^(1/2));
                        % Pdf(:,i)=(1/MS)*(exp(-0.5.*D(:,i)));
                    case 'gamma'
                        Pdf(:,i)=gammainc(b/2,D(:,i)./2,'lower')./gamma(b/2);
                end
    
            end
    
            % Calculate the normalized probability from Pdf
            Pdf=double(Pdf);
            p=Pdf./sum(Pdf,2);            
    
        case 'logistic'
            try
                p = mnrval(Input,Rrs_input);
            catch
                [~,p] = Input.predict(Rrs_input);
            end

        case 'tree'
            [~,p]=predict(Input, Rrs_input);

        case 'svm'
            [~, scores] = predict(Input,Rrs_input);
            p = exp(scores) ./ sum(exp(scores), 2);

        case 'naivebayes'
            [~,p]=predict(Input, Rrs_input);

        case 'adaboostm2'
            [~, scores] = predict(Input,Rrs_input);
            p = scores ./ sum(scores, 2);
            
    end
    

    [Val,Class]=max(p,[],2);


    % Class(Val==0|isnan(Val))=nan;
    Class(isnan(Val))=nan;
    Class(any(isnan(Rrs_norm),2))=nan;
    for i=1:size(p,2)
        p(isnan(Class))=nan;
    end
    % Class=int8(Class);
end




