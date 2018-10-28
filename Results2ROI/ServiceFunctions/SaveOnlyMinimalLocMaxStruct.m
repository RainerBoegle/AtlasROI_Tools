function [LocMaxStruct] = SaveOnlyMinimalLocMaxStruct(varargin)
% Remove iterations field from LocMaxStruct
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(19.January.2015): initial implementation based on test script.


%% check input 
if(nargin==0)
    LocMaxStruct_path = spm_select(1,'mat','Select *.mat-file containing LocMaxStruct...');
    load(LocMaxStruct_path);
else
    if(isstruct(varargin{1}))
        LocMaxStruct = varargin{1};
        LocMaxStruct_path = []; %no path --> ask user later for that
    else
        Input = varargin{1}; 
        if(iscell(Input))
            LocMaxStruct_path = Input{1};
            load(LocMaxStruct_path); %assume this is the path to LocMaxStruct *.mat-file
        elseif(ischar(Input))
            LocMaxStruct_path = Input;
            load(LocMaxStruct_path); %assume this is the path to LocMaxStruct *.mat-file
        else
            LocMaxStruct_path = spm_select(1,'mat','Select *.mat-file containing LocMaxStruct...');
            load(LocMaxStruct_path);
        end
    end
end

%% remove iterations field
LocMaxStruct= rmfield(LocMaxStruct,'Iterations');

%% save
if(~isempty(LocMaxStruct_path)) %save with prefix
    [BaseDir,LocMaxStruct_fname,ext] = fileparts(LocMaxStruct_path);
    save([BaseDir,filesep,'Minimal_',LocMaxStruct_fname,'.mat'],'LocMaxStruct');
else
    uisave({'LocMaxStruct'},'Minimal_LocMaxStruct.mat');
end

end