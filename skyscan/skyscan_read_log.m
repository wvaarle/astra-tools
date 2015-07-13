function data=skyscan_read_log(fname)

%------------------------------------------------------------------------
% data=skyscan_read_log(fname)
% 
% Read skyscan log file
%
% fname: filename of the skyscan log file.
% data: a structure with fields as encounterd in logfile.
%
% author : Gert Van Gompel
% Date last update : 14/03/2008
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% This file is part of the
% All Scale Tomographic Reconstruction Antwerp Toolbox ("ASTRA-Toolbox")
%
% Copyright: iMinds-Vision Lab, University of Antwerp
% License: Open Source under GPLv3
% Contact: mailto:astra@ua.ac.be
% Website: http://astra.ua.ac.be
%------------------------------------------------------------------------
% $Id: skyscan_read_log.m 1787 2014-04-22 13:43:26Z wpalenst $

S=textread(fname,'%s','delimiter','\n');
vars=repmat({[]},length(S),2);
for i=1:length(S)
    iEQ=find(S{i}=='=');
    if ~isempty(iEQ)
        iEQ=iEQ(1);
        varName=strtrim(S{i}(1:iEQ-1));
		
		varName = lower(varName);
		
        % remove non-letters
        varName(~isletter(varName) & ~(varName>47 & varName<57) )='_';
        
        varValue=strtrim(S{i}(iEQ+1:end));
        % try to convert to numerical value
        varNum=str2double(varValue);
        if ~isnan(varNum)
            varValue=varNum;
        end
        vars(i,:)={varName,varValue};
    else
        %warning('no parameter assigned at line %i: %s',i,S{i})
    end
end
vars=vars(~cellfun('isempty',vars(:,1)),:).';
data=struct(vars{:});
