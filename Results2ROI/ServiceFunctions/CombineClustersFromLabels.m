function [Output_Path,Vo]=CombineClustersFromLabels(ClusterNII_path,Labels_path)
% This function can be used to combine ROIs/Clusters via selecting Labels.
%
%V1.0
%Author: Rainer Boegle (Rainer.Boegle@googlemail.com)
%Comment(20.January.2015): initial implementation based on test script.

%% check inputs
%to do

%% get Clusters Volume
Vin     = spm_vol(ClusterNII_path);
[BaseDir,fname_in] = fileparts(Vin.fname);
NIIin   = nifti(ClusterNII_path);
NII_data= NIIin.dat(:,:,:);

%% get Labels
load(Labels_path);
Labels_Org = Labels;

%% Combine Areas till user stops combining
KeepCombining = 1;
while(KeepCombining)
    [CombineIndices, KeepCombining] = listdlg('ListString',Labels,'CancelString','Quit','Name','Select Labels...','PromptString','Select Labels to combine these Clusters...','ListSize',[600 200]);
    if(KeepCombining)
        ClusterInd = min(CombineIndices);
        SuggestedNewLabel = [num2str(ClusterInd),'.'];
        for Ind = 1:length(CombineIndices)
            SuggestedNewLabel = [SuggestedNewLabel, deblank(Labels{CombineIndices(Ind)})];
        end
        answer_str = inputdlg({['ROI ',num2str(min(CombineIndices)),' Name: ']},'ROI-name?',1,{deblank(SuggestedNewLabel)});
        if(~isempty(answer_str))
            Labels{ClusterInd} = answer_str{1};
            CombineIndices(CombineIndices==ClusterInd) = []; %remove this one
            Labels(CombineIndices) = []; %remove
        else
            KeepCombining = KeepCombining+1;
        end
        if(KeepCombining>2)%stop it user doesn't want to continue
            error('obviously you want to stop, don''t you?');
        end
        clear SuggestedNewLabel answer_str 
        
        %% change clusters
        try
            close(gcf);
        end
        for Ind = 1:length(CombineIndices)
            NII_data(NII_data==CombineIndices(Ind))=ClusterInd;
        end
        % new ordering
        UniqueVals = unique(NII_data(:));
        UniqueVals(UniqueVals==0) = [];
        NII_data_Org = NII_data;
        for Ind = 1:length(UniqueVals)
            NII_data(NII_data_Org==UniqueVals(Ind)) = Ind;
        end
        clear NII_data_Org
        Vo = Vin;
        Vo.fname = [BaseDir,filesep,'Reduced_',fname_in,'.nii'];
        Vo = spm_write_vol(Vo,NII_data);
        pause(0.1); %bug fix
        DisplayClusters(Vo.fname);
        pause(0.1); %bug fix
    end
end
Output_Path = Vo.fname;

%% done
disp(' ');
disp('Done.');

end