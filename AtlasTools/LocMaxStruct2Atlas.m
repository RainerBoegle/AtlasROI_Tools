function [AtlasQueryOutput,MainDataRows,MainDataCols] = LocMaxStruct2Atlas(varargin)
% This Script will ask the user to select one or more Atlases from FSL to inquire the
% atlas labels using the coordinates from the Coordinates in the LocMaxStruct (Iteration-Results).
%
% 1.) Use clustering tool to create LocMaxStruct
% 2.) Type "LocMaxStruct2Atlas(LocMaxStruct);" on the commandline of MATLAB.
% 2b) OR   "LocMaxStruct2Atlas();" to load the LocMaxStruct.mat file.
%
%
%V1.5
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(19.January.2015): initial implementation based on test script.

%% check input 
if(nargin==0)
    load(spm_select(1,'mat','Select *.mat-file containing LocMaxStruct...'));
else
    if(isstruct(varargin{1}))
        LocMaxStruct = varargin{1};
    else
        Input = varargin{1}; 
        if(iscell(Input))
            load(Input{1}); %assume this is the path to LocMaxStruct *.mat-file
        elseif(ischar(Input))
            load(Input); %assume this is the path to LocMaxStruct *.mat-file
        else
            load(spm_select(1,'mat','Select *.mat-file containing LocMaxStruct...'));
        end
    end
end

%% assign VoxCell
VoxCell = cell(size(LocMaxStruct.LocMaxCoords_mm,1),1);
for IndVox = 1:length(VoxCell)
    VoxCell{IndVox} = LocMaxStruct.LocMaxCoords_mm(IndVox,:);
end

%% get available atlases & ask user to choose one or more for atlas inquiry
KeepSelecting = 1;
while(KeepSelecting)
    AvailableAtlasesFSL = getAtlases('select');
    if(any(cell2mat(strfind((AvailableAtlasesFSL),'Cerebellar'))))
        if(any(cell2mat(strfind((AvailableAtlasesFSL),'Juelich'))))
            MessageTimeIsMoney = {'Warning: This could take a lot of time!'; ' '; 'You have selected a Cerebellar Atlas and the Juelich Atlas.'; 'The Cerebellar Atlas(es) in particular will take a very long time to query, according to our tests.'; 'If you do not really need it then reselect the atlases,'; 'otherwise if you continue, you will have to wait a very loooong time.'};
        else
            MessageTimeIsMoney = {'Warning: This could take a lot of time!'; ' '; 'You have selected a Cerebellar Atlas.'; 'These will take a very long time to query, according to our tests.'; 'If you do not really need it then reselect the atlases,'; 'otherwise if you continue, you will have to wait a very loooong time.'};
        end
    else
        if(any(cell2mat(strfind((AvailableAtlasesFSL),'Juelich'))))
            MessageTimeIsMoney = {'Warning: This could take a little while!'; ' '; 'You have selected the Juelich Atlas.'; 'This one is not so fast when inquired, -according to our tests.'; 'If you do not really need it then reselect the atlases,'; 'otherwise if you continue, you will have to wait a little while.'};
        else
            MessageTimeIsMoney = [];
        end
    end
    if(~isempty(MessageTimeIsMoney))
        ChoiceTimeIsMoney = questdlg(MessageTimeIsMoney,'Warning: This could take a lot of time!','Continue','Reselect','Quit','Continue');
        switch(ChoiceTimeIsMoney)
            case 'Continue'
                KeepSelecting = 0;
            case 'Reselect'
                KeepSelecting = 1;
            case 'Quit'
                return;
            otherwise
                error(['Unknown switch "',ChoiceTimeIsMoney,'".']);
        end
    else
        KeepSelecting = 0;
    end
end

%% write out the query results for the list of atlas(es). --> make this into a function, given the atlas name and the list of voxels to return TMP.
AtlasQueryResults = InquireAtlases(AvailableAtlasesFSL,VoxCell);

%% fill in the stats vals
for IndVox = 1:length(VoxCell)
    AtlasQueryResults{1+IndVox,2} = num2str(LocMaxStruct.LocMaxStats(IndVox,1));
end
MainDataRows = 2:size(AtlasQueryResults,1);
MainDataCols = 3:size(AtlasQueryResults,2);

%% create output cell-array
% OutputCell = cell(length(VoxCell)+1,length(AvailableAtlasesFSL)+1); %first line is: Coordinate[mm]; Atlas name1; ... Atlas nameN; & the lines following are the values
%FUTURE EXTENSION: instead of fixed information, ask user what should be added, i.e. should the p-vals be added, and/or cluster size...???
%                 2.) ask user if another column should be added at the end based on another image/volume file
%                     i.e. this column contains the value of the respective voxel nearest to the coordinate maybe also add
%                     another TWO column with the average+-deviation (mean+-SEM&median+-IOR) of a sphere around the voxel
%                     This can be done several times such that several files/images/volumes == columns can be added.
%                     THIS WOULD BE PARTICULARILY USEFUL WHEN LOOKING AT STATISTICAL TESTS WHEN WE WANT TO KNOW WHY THEY ARE SIGNIFICANT, E.G. BECAUSE OF THE CAMPARED VALUES BEING POSITIVE OR NEGATIVE OR ANY COMBINATION.

%append additional information
if(strcmp('Yes',questdlg({'Do you want to add further columns to the atlas inquiry, based on NIFTI-files?'; ' '; 'This can be particularily useful when the initial inquiry is from a comparison of two (or more) effects.'; 'You can select the NIFTIs corresponding to the individual statistics of these effects by themselves,'; 'which will give you the information if the difference/comparison effect comes from the combination of positive or negative (statistical) amplitudes.'},'Append Inquiry with NIFTI values?','Yes','No','No')))
    AtlasQueryOutput = AppendNIFTIvalsToInquiry(AtlasQueryResults);
else
    AtlasQueryOutput = AtlasQueryResults;
end

%% write out a XLS file with one sheet per Atlas
%check computer PCWIN or PCWIN64
try
    [status,message,FileName,PathName] = WriteAtlasInquiry2Excel(AtlasQueryOutput);
    disp(['Status ',num2str(status),': ',message]);
catch
    disp('Writing of XLS failed...');
end

end
