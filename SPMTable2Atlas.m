function [AtlasQueryOutput,AtlasQueryResults,WordCloudStruct] = SPMTable2Atlas(varargin)
% This function will ask the user to select one or more Atlases from FSL to inquire the
% atlas labels using the coordinates from the SPM Results-Table.
%
% 1.) Use SPM to display the Results-Table
% 2.) Type "SPMTable2Atlas;" on the commandline of MATLAB. 
%     OR: [AtlasQueryOutput,AtlasQueryResults,WordCloudStruct] = SPMTable2Atlas(TabDat,xSPM);
%
%
%V1.5
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(02.February.2015): initial implementation based on test script.

%% init
AtlasQueryOutput = [];
AtlasQueryResults= [];
WordCloudStruct  = [];

%% check inputs
if(nargin~=2)
    if(~exist('TabDat','var'))
        try
            TabDat = evalin('base','TabDat;');
        end
    end
    if(~exist('xSPM','var'))
        try
            xSPM = evalin('base','xSPM;');
        end
    end
else
    TabDat = varargin{1};
    xSPM   = varargin{2};
end

%% ask user to select SPM analysis evaluate contrast and save the table. Try to catch user-error if he did not do that already.
keepLooking = 0;
Message = {'Error: Variable "TabDat" not found!'; 'Open Statistics Results and select "whole Brain" to get the table.'; '(This should create a variable called "TabDat" in the matlab workspace.)'; ' '; 'Then type: "SPMTable2Atlas;" on the matlab command line to continue.'};
while(keepLooking<2);
    if(~exist('TabDat','var'))
        h = helpdlg(Message,'How to proceed.');
        uiwait(h);
        return;
    end
    try
        VoxCell = TabDat.dat(:,end);
        keepLooking = 3;
    catch
        if(exist('xSPM','var'))
            Message = {'Error! Open Statistics Results and select "whole Brain" to get the table.'; ' '; 'Then type: TabDat = ans;'; ' '; 'On the matlab command line (and then after that type "return;").'};
            keepLooking = keepLooking+1;
        else
            Message = {'Error! Open SPM and display statistics "Results" for a contrast and select "whole Brain" to get the table.'; ' '; 'Then type: TabDat = ans;'; ' '; 'On the matlab command line (and then after that type "return;").'};
            keepLooking = keepLooking+1;
        end
    end
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
%% need to find the right entry of the table using xSPM.STAT field indicating the statistics type
try
    StatsCol = [];
    for IndCol = 1:size(TabDat.hdr,2)
        if(strcmp(TabDat.hdr{1,IndCol},'peak')&&strcmp(TabDat.hdr{2,IndCol},xSPM.STAT))
            StatsCol = IndCol;
        end
    end
catch
    StatsCol = 9; %a guess in case the above fails for some reason. Most of the time this should be right.
end
for IndVox = 1:length(VoxCell)
    AtlasQueryResults{1+IndVox,2} = num2str(TabDat.dat{IndVox,StatsCol});
end
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
[status,message,FileName,PathName] = WriteAtlasInquiry2Excel(AtlasQueryOutput,[pwd,filesep,'Clusters_SPM_',regexprep(regexprep(xSPM.title,' |:','_'),'\(|\)',''),'_',date,filesep,'LocMaxList.xls']);

%% create clusters NIFTI and display (get colors).
[H,ColorsRGBperId,bg,OutputPath] = ShowOverlayClusters(spm_clusters(xSPM.XYZ)',xSPM.XYZ',xSPM.Vspm,[PathName,filesep,'Clusters_SPM.nii']);

%% save also thresholded SPM
LocMaxClusters2NIFTI(xSPM.Z',xSPM.XYZ',xSPM.Vspm,[PathName,filesep,'Thresholded_SPM.nii']); %I am abusing this function here for writing the image.

%% make word cloud per atlas
try
    AllClNums = spm_clusters(xSPM.XYZ)';
    Coords_mm = cell2mat(VoxCell')'; %somehow this only works when transposing twice (once between operations); -probably because of MATLAB's column-major design...
    IdNumbersPerWord = zeros(size(Coords_mm,1),1);
    for IndVox = 1:size(Coords_mm,1)
        [x, i] = spm_XYZreg('NearestXYZ', Coords_mm(IndVox,:), xSPM.XYZmm); clear x
        IdNumbersPerWord(IndVox) = AllClNums(i);
    end
    [WordCloudStruct] = AtlasOutput2WordCloud(AtlasQueryOutput,IdNumbersPerWord,MainDataCols,PathName,ColorsRGBperId);
catch CATCH_WordCloudTools
    disp_catch(CATCH_WordCloudTools,'AtlasOutput2WordCloud','CATCH_WordCloudTools');
    disp('WordCloudTools are not available!');
end    


%% Done.
disp(' ');
disp('Done.');

end

%% subfunction
%% disp_catch
function [] = disp_catch(CATCHobj,varargin)
if(nargin==2)
    disp(['Error occurred in function "',mfilename,'>',varargin{1},'"...']);
else
    disp(['Error occurred in function "',mfilename,'"...']);
end
disp([CATCHobj.identifier,': ',CATCHobj.message]);

if(nargin==3)
    if(ischar(varargin{2}))
        assignin('base',varargin{2},CATCHobj);
    else
        assignin('base',['CATCHobj_',regexprep(datestr(now),' |-|:','_')],CATCHobj);
    end
end

end
