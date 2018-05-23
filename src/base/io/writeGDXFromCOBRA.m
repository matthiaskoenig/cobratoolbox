function [helpText] = writeGDXFromCOBRA(cobraStruct, varargin)
% Writes a GDX file with the stoichiometric matrix, bounds and
% reversibility information. 
%
% USAGE:
%
%    [helpText] = writeGDXFromCOBRA(cobraStruct,...)
%
% INPUTS:
%    cobraStruct:  Model Structure  
%
%    FileName      char     name of the file
%
%    IncludeSets   boolean  True :  Metabolite and Reactions in the model 
%                                   will be included as sets in the gdx
%                                   files (Default)

%                           False:  Metabolite and Reactions sets in .gms 
%                                   will be generated by using "domain loading"
%
%    IncludeBounds boolean  True:  Model bounds will be included in the gdx
%                                  (Default)
%
%                           False: Model bounds will not be included in the gdx
%
% OUTPUT:
%    helpText:       String with example load
%
% NOTE: 
% 
%    Requires 'wgdx' to be on path, which is provided by a GAMS installation.
%
% .. AUTHORS: 
% .. Claudio Delpino  22/05/2018 Added inputParser and option to include bounds.    
% .. Claudio Delpino & Romina Lasry @PLAPIQUI 02/17/15 Original function

p = inputParser; 
addRequired(p,'cobraStruct',@isstruct)
addParameter(p,'FileName',...
       strcat('COBRAModel_',datestr(now, 'mmddyyHHMMSS'), '.gdx'),@ischar)
addParameter(p,'IncludeSets',true,@islogical)
addParameter(p,'IncludeBounds',true,@islogical)

parse(p,cobraStruct,varargin{:});

if(exist('wgdx','file') ~= 0)

    matStruct.name = 'S';
    matStruct.val = full(cobraStruct.S);
    matStruct.uels = {transpose(cobraStruct.mets), transpose(cobraStruct.rxns)};
    matStruct.form = 'full';
    matStruct.type = 'parameter';

    revStruct.name = 'isRev';
    revStruct.val = double(cobraStruct.lb < 0);
    revStruct.uels = transpose(cobraStruct.rxns);
    revStruct.form = 'full';
    revStruct.type = 'parameter';

    helpText = sprintf('Example load for .gms file:\n\nsets met,rxn;\n');
    loadText = 'S isRev';
    
    structCell = {matStruct,revStruct};
    
    if(p.Results.IncludeSets)
        fprintf('If your GAMS version is higher than 24.2.1,\nyou can set the ''IncludeSets'' option to false\nto get a reduced gdx that uses a special load to populate the sets\n');
        metSetStruct.name = 'met';
        metSetStruct.uels = transpose(cobraStruct.mets);
        rxnSetStruct.name = 'rxn';
        rxnSetStruct.uels = transpose(cobraStruct.rxns);
        structCell = horzcat(structCell,rxnSetStruct,metSetStruct);
        loadText = [loadText ' met rxn'];
    else
        loadText = [loadText ' met<S.dim1 rxn<S.dim2'];
    end
    
    if(p.Results.IncludeBounds) 
        lbStruct.name = 'lb';
        lbStruct.val = cobraStruct.lb;
        lbStruct.uels = transpose(cobraStruct.rxns);
        lbStruct.form = 'full';
        lbStruct.type = 'parameter';
        ubStruct.name = 'ub';
        ubStruct.val = cobraStruct.ub;
        ubStruct.uels = transpose(cobraStruct.rxns);
        ubStruct.form = 'full';
        ubStruct.type = 'parameter';
        structCell = horzcat(structCell,lbStruct,ubStruct);
        helpText = [helpText 'parameters S,isRev,lb,ub;\n'];
        loadText = [loadText ' lb ub'];
    else
        helpText = [helpText 'parameters S,isRev;\n'];
    end
   
    helpText = [sprintf(helpText) sprintf('$gdxin %s%c%s  \n$load %s \n$gdxin', pwd, filesep,p.Results.FileName,loadText)];
    
    wgdx(p.Results.FileName,structCell{:});
else
    fprintf('wgdx() not found. Is the GAMS system directory in the MatLab Path?\n');
end
