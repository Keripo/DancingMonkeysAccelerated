function varargout=mkdir(varargin)
%MKDIR   Make new directory.
%   [SUCCESS,MESSAGE,MESSAGEID] = MKDIR(PARENTDIR,NEWDIR) makes a new directory,
%   NEWDIR, under the parent, PARENTDIR. While PARENTDIR may be an absolute
%   path, NEWDIR must be a relative path. When NEWDIR exists, MKDIR returns
%   SUCCESS = 1 and issues to the user a warning that the directory already
%   exists.
%
%   [SUCCESS,MESSAGE,MESSAGEID] = MKDIR(NEWDIR) creates the directory NEWDIR
%   in the current directory. 
%
%   [SUCCESS,MESSAGE,MESSAGEID] = MKDIR(PARENTDIR,NEWDIR) creates the
%   directory NEWDIR in the existing directory PARENTDIR. 
%
%   INPUT PARAMETERS:
%       PARENTDIR : string specifying the parent directory. See NOTE 1.
%       NEWDIR : string specifying the new directory. 
%
%   RETURN PARAMETERS:
%       SUCCESS: logical scalar, defining the outcome of MKDIR. 
%                1 : MKDIR executed successfully.
%                0 : an error occurred.
%       MESSAGE: string, defining the error or warning message. 
%                empty string : MKDIR executed successfully.
%                message : an error or warning message, as applicable.
%       MESSAGEID: string, defining the error or warning identifier.
%                  empty string : MKDIR executed successfully.
%                  message id: the MATLAB error or warning message identifier
%                  (see ERROR, LASTERR, WARNING, LASTWARN).
%
%   NOTE 1: UNC paths are supported. 
%
%   See also CD, COPYFILE, DELETE, DIR, FILEATTRIB, MOVEFILE, RMDIR.

%   JP Barnard
%   Copyright 1984-2002 The MathWorks, Inc. 
%   $Revision: 1.37 $ $Date: 2002/06/06 18:42:43 $
% -----------------------------------------------------------------------------

% Set up MKDIR

% test if source and destination arguments are strings
% handle input arguments
ArgError = nargchk(1,2,nargin);  % Number of input arguments must be 1 of 2.
if ~isempty(ArgError)
   error('MATLAB:MKDIR:NumberOfInputArguments',ArgError);
end

% check if additional arguments are strings
if ~isempty(varargin) & ~iscellstr(varargin) 
   error('MATLAB:MKDIR:ArgumentType','Arguments must be strings')
end

% handle output arguments
% Number of output arguments must be 1 to 3.
ArgOutError = nargoutchk(-1,3,nargout);  
if ~isempty(ArgOutError)
   error('MATLAB:MKDIR:NumberOfOutputArguments',ArgOutError);
end

% Initialise variables.
Success = true;
OldDir = '';
ErrorMessage='';  % annotations to raw OS error message
ErrorID = '';
Status = 0;
OSMessage = '';   % raw OS message
PreWin2000 = false;

% handle input arguments
if nargin == 1
   % Mode 1: create a new directory inside current directory
   DirName = pwd;
   NewDirName = varargin{1};

elseif nargin == 2
   % Mode 2: create a new directory inside a specified directory
   if ~isempty(varargin{2})
      DirName = varargin{1};
      NewDirName = varargin{2};
   else
      error('MATLAB:MKDIR:ArgumentIndeterminate',...
         'Second directory argument is an empty string.');
   end
end


% Build full path that has valid path syntax.
% Add double quotes around the source and destination files 
%	so as to support file names containing spaces.
Directory = validpath(DirName,NewDirName);

% rehash non-toolbox directory path global
% rehash path
% -----------------------------------------------------------------------------
% Attempt to make directory

try
   % Throw error if UNC path is found in new directory name
   if strncmp('\\',NewDirName,2)
      error('MATLAB:MKDIR:DirectoryIsUNC',...
         'Cannot create UNC directory inside %s',DirName);
   end
   
   % Throw error if new directory name implies an absolute path.
   if ~isempty(strfind(NewDirName,':'))
      error('MATLAB:MKDIR:DirectoryContainsDriveLetter',...
         'Cannot create absolute directory inside %s',DirName);
   end

   % Test for existance of directory
   if ~isempty(dir(strrep(Directory,'"','')))
      WarningMessage = sprintf('Directory "%s" already exists.', NewDirName);
      WarningID = 'MATLAB:MKDIR:DirectoryExists';
      
      if nargout
         varargout{1} = Success;
         varargout{2} = WarningMessage;
         varargout{3} = WarningID;
      else
         warning(WarningID, WarningMessage, NewDirName);
      end
      return
   end

% UNIX file system

   if isunix
		% ensure correct file separator
		Directory = strrep(Directory,'\',filesep);

      % make directory structure
		[Status, OSMessage] = unix(['mkdir -p ' Directory]); 

% MS DOS file system
     
   elseif ispc
      
      % Change to safe directory in Windows when UNC path cause failures
      OldDir = cd; % store current directory

      % find version of Windows
      WinSwitches = setwinmkdir;
      
      % ensure correct file separator
      Directory = strrep(Directory,'/',filesep);
      
      % make directory
      [Status,OSMessage]=winmkdir(Directory,WinSwitches);
      
      % if changed to %windir%, restore original current directory
      if ~isempty(OldDir)
         cd(OldDir);
      end
      
   end % if computer type

	%---------------------------------------------------------------------------   
   % Consolidate OS status reply. 
   % We consistently return Success = false if anything on error or warning. 
   Success = ConsolidateMkdirStatus(Status,OSMessage);      
   
	% throw applicable OS errors.
   if ~Success
      error('MATLAB:MKDIR:OSError','%s',strvcat(OSMessage,ErrorMessage)') 
   end

catch
   Success = false;
   [ErrorMessage,ErrorID] = lasterr;
   % extract descriptive lines from error message
   if ~isempty(ErrorMessage)
      ErrorMessage = strread(ErrorMessage,'%s','delimiter','\n');
      ErrorMessage = strvcat(ErrorMessage(2:end));
   end
   % throw error if no output arguments are specified
   if ~nargout 
      error(ErrorID,'%s',ErrorMessage');
   end
end

%------------------------------------------------------------------------------
% parse output values to output parameters, if outout arguments are specified
if nargout
   varargout{1} = Success;
   varargout{2} = ErrorMessage;
   varargout{3} = ErrorID;
end
%==============================================================================
% end of MKDIR


% ConsolidateMkdirStatus. Consolidate the status returns in COPYFILE into a
%     success logical output
% Input:
%        Status: scalar double defining the status output from OS calls
%        OSMessage: string array defining OS call message outputs
% Return:
%        Success: logical scalar defining outcome of COPYFILE
%------------------------------------------------------------------------------
function [Success] = ConsolidateMkdirStatus(Status,OSMessage)
%------------------------------------------------------------------------------
switch Status
   
case 0
   if isempty(OSMessage)
      Success = true; % no error
   else
      % an error with zero status value occurred (originates from WIN95/98/ME)
      Success = false; 
   end
   
otherwise
   Success = false; % some error or warning was returned by the OS call
end
%------------------------------------------------------------------------------
return
% end of ConsolidateMkdirStatus
%==============================================================================

% SETWINMKDIR. determine Windows platform
% Return:
%        WinCopySwitches: struct scalar defining copy and xcopy switches
%           .PreWin2000: logical scalar defining pre or post Windows 2000 (0 or 1)
%------------------------------------------------------------------------------
function [WinMkdirSwitches]=setwinmkdir
%------------------------------------------------------------------------------
% find version of Windows
[Status,WinVersion] = dos('ver');
if length(strfind(WinVersion,'Windows 95')) || ...
      length(strfind(WinVersion,'Windows 98')) || ...
      length(strfind(WinVersion,'Windows Millennium'))
   WinMkdirSwitches.PreWin2000 = true;
else
   WinMkdirSwitches.PreWin2000 = false;
end
%-------------------------------------------------------------------------------
return
%===============================================================================

% WINMKDIR. makes directory on various Windows platforms
% 
% Input:
%        Directory: string defining directory path
%        WinSwitches: struct defining Windows specific switches
%           .PreWin2000: logical scalar defining pre or post Windows 2000 (0 or 1)
% Return:
%        Status: OS command status
%        OSMessage: string containing OS message, if any.
%------------------------------------------------------------------------------
function [Status,OSMessage]=winmkdir(Directory,WinSwitches)
%------------------------------------------------------------------------------
if WinSwitches.PreWin2000
   % Pre Windows 2000 we need to make a subtree iteratively, since DOS MKDIR
   % cannot make a subdirectory tree at once. 
   
   % Temporarily strip double quotes.
   parentDir = strrep(Directory,'"',''); 
   % count subdirectory tree levels up from bottom of directory tree.
   nrlevels = 0; 

   % Find path depth at which directory tree exists.
   while isempty(dir(parentDir))
      nrlevels = nrlevels+1;
      [parentDir,subtree{nrlevels},ext{nrlevels}] = fileparts(parentDir);
   end
   
   % Build subdirectory tree recursively.
   for i  = nrlevels:-1:1
      parentDir = validpath(parentDir,[subtree{i},ext{nrlevels}]);
      [Status, OSMessage] = dos(['mkdir ', parentDir]);
   end
   
else
   % make new directory
   [Status, OSMessage] = dos(['mkdir ' Directory]);
end
%-------------------------------------------------------------------------------
return
%===============================================================================

% VALIDPATH. makes directory on various Windows platforms
% 
% Input:
%        DirName: string defining parent directory
%        NewDirName: string defining new directory
% Return:
%        Directory: string defining full path to new directory
%------------------------------------------------------------------------------
function [Directory] = validpath(DirName,NewDirName)
%------------------------------------------------------------------------------
% Add double quotes around the source and destination files 
%	so as to support file names containing spaces. 

Directory = ['"' fullfile(DirName,NewDirName) '"'];

% place ~ outside quoted path, otherwise UNIX would not translate ~
if strcmp(Directory(1:2),'"~') 
   if length(Directory)>4
      [firstPathPart,remainder] = strtok(Directory,filesep);
      Directory = [firstPathPart(2:end),'/"',remainder(2:end)];
   else
      Directory = DirName;
   end
end
%-------------------------------------------------------------------------------
return
%===============================================================================
