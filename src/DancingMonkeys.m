% Dancing Monkeys Project
%   Karl O'Keeffe, versions 1.00 and 1.01, 2003
%   modified by Eric Haines, version 1.02 on, 2006

function DancingMonkeys( varargin )
% Difficulty levels must be given as strings and not integers

% Remove warnings for things such as existing directories or clipped
% waveforms
warning off
tic;

VersionNumber = '1.06';

MaximumDifficulty = 9;

MusicFullFilename = '';

% Constants
SmoothingFilterOrder = 3;               % Order for the smoothing filter.
SmoothingFilterLowpassFrequency = 10;   % Frequency above which to discard data.
WindowLength = 5;                       % Length of the window used for normalising, in seconds.
PeakThreshold = 90;                     % Threshold for throwing away data before peak picking, in percent.
HeightWindowSize = 0.01;                % When estimating the height of a peak or through on the original waveform, this gives the size of window to use, in seconds.
BeatPositioningThreshold = 0.7;         % Between 0 and 1. How close to the calculated peak value the data must be to be considered the onset point.
MinimumBPM = 89;                        % The minimum BPM value that will be tested.
MaximumBPM = 205;                       % The maximum BPM value that will be tested.
%unused - TODO? IntervalGradientLimit = 20;             % The maximum difference between values for gaps to be considered the same.
MaxArrowsPerBar = 8;                    % The number of arrows per bar.
BarSize = 4;                            % The number of beats per bar.
%unused - TODO? BarsBeginningPadding = 2;               % The number of bars we should pad the beginning of the arrow track with.
%unused - TODO? BarsEndPadding = 1;                     % The number of bars we should pad the end of the arrow track with.
StepFileFudgeFactor = 0;                % Amount to alter the gap value by, in seconds.
FadeSeconds = 5;                        % How far from the end to start fading out the music
MaxSongLengthInSeconds = 105;           % Maximum length of music in seconds
MinConfidence = 10;                     % Minimum confidence for BPM determination
MaxPauses = 5;                          % If there are more than this many pauses (stops), warn user.
SpecialExecution = 0;                  % If 0, try bpm.exe method of finding BPM.
DefaultArtist = 'Dancing Monkeys Project';
SongCredit = [ 'Dancing Monkeys v' VersionNumber ];

% Commands
CommandWriteFormat = 0;                 % 0 = MP3 always, 1 = WAV always, 2 = same as input
CommandReadMP3Data = 1;                 % 1 = read MP3 header if available
CommandStops = 1;                       % 1 = output stops if found
CommandMaxStopsDelete = -1;             % -1 = not used; >=0 = if more than this many stops found, delete song
CommandBPMonly = 0;                     % 1 = output BPM and gap value, no other output
CommandLog = 1;                         % 0 = do not output to the log file.
CommandImportant = 0;                   % 1 = brief, only useful messages.
CommandTestOnly = 0;                    % 1 = test, do nothing else.

InputCount = 0;
SkipArg = 0;

for i = 1 : nargin
    if ( SkipArg )
        % we cannot actually increment "i" inside this loop, so have to do
        % this trickiness
        SkipArg = 0;
        continue;
    end
    Arg = varargin{i};
    if ( size(Arg,2) > 0 && Arg(1:1) == '-' )
        % commands
        
        % don't read MP3 header 
        if ( strcmpi(Arg,'-v') || strcmpi(Arg,'--version') )
            disp( sprintf( 'Version: Dancing Monkeys v%s', VersionNumber ) );
            return;
        % important - output only errors and important stuff
        elseif ( strcmpi(Arg,'-i') || strcmpi(Arg,'--important') )
            CommandImportant = 1;
        % important - output only errors and important stuff
        elseif ( strcmpi(Arg,'-t') || strcmpi(Arg,'--test') )
            CommandTestOnly = 1;
        % force file output to be WAV
        elseif ( strcmpi(Arg,'-omw') || strcmpi(Arg,'--outputmusicwav') )
            CommandWriteFormat = 1;
        % force file output to be same as input 
        elseif ( strcmpi(Arg,'-oms') || strcmpi(Arg,'--outputmusicsame') )
            CommandWriteFormat = 2;
        % output no stops 
        elseif ( strcmpi(Arg,'-ons') || strcmpi(Arg,'--outputnostops') )
            CommandStops = 0;
        % output only BPM and gap found, no other output
        elseif ( strcmpi(Arg,'-ob') || strcmpi(Arg,'--outputBPM') )
            CommandBPMonly = 1;
        % beat range 
        elseif ( strcmpi(Arg,'-b') || strcmpi(Arg,'--BPM') )
            ii = i + 1;
            if ( ii <= nargin )
                bpm = sscanf( varargin{ii}, '%f:%f' );
            else
                error('ERROR: Input minimum and maximum beats (e.g. "120:240") argument not found.');
            end
            if ( numel(bpm) < 2 )
                error('ERROR: Input minimum and maximum beats (e.g. "120:240") argument not found.');
            end
            MinimumBPM = bpm(1);
            MaximumBPM = bpm(2);
            if ( MinimumBPM <= 0 || MaximumBPM < MinimumBPM )
                error('ERROR: Illegal minimum and maximum beats "%s".',varargin{ii});
            end
            SkipArg = 1;
        % delete if too many stops
        elseif ( strcmpi(Arg,'-es') || strcmpi(Arg,'--errorstops') )
            ii = i + 1;
            if ( ii <= nargin )
                CommandMaxStopsDelete = str2double(varargin{ii});
            else
                error('ERROR: Input maximum stops argument not found.');
            end
            SkipArg = 1;
        % don't read MP3 header 
        elseif ( strcmpi(Arg,'-onl') || strcmpi(Arg,'--outputnolog') )
            CommandLog = 0;
        % don't read MP3 header 
        elseif ( strcmpi(Arg,'-n') || strcmpi(Arg,'--noID3') )
            CommandReadMP3Data = 0;
        % change song length 
        elseif ( strcmpi(Arg,'-l') || strcmpi(Arg,'--length') )
            ii = i + 1;
            if ( ii <= nargin )
                MaxSongLengthInSeconds = str2double(varargin{ii});
            else
                error('ERROR: Input song length argument not found.');
            end
            if ( MaxSongLengthInSeconds < 1 )
                error('ERROR: Input song length must be 1 or more.');
            end
            SkipArg = 1;
        % change fade length 
        elseif ( strcmpi(Arg,'-f') || strcmpi(Arg,'--fade') )
            ii = i + 1;
            if ( ii <= nargin )
                FadeSeconds = str2double(varargin{ii});
            else
                error('ERROR: Input fade length argument not found.');
            end
            SkipArg = 1;
        % change confidence 
        elseif ( strcmpi(Arg,'-c') || strcmpi(Arg,'--confidence') )
            ii = i + 1;
            if ( ii <= nargin )
                MinConfidence = str2double(varargin{ii});
            else
                error('ERROR: Input confidence argument not found.');
            end
            SkipArg = 1;
        % change beats per measure 
        elseif ( strcmpi(Arg,'-m') || strcmpi(Arg,'--measure') )
            ii = i + 1;
            if ( ii <= nargin )
                BarSize = str2double(varargin{ii});
                MaxArrowsPerBar = BarSize * 2;
            else
                error('ERROR: Input beats to a measure argument not found.');
            end
            SkipArg = 1;
        % change gap adjustment 
        elseif ( strcmpi(Arg,'-g') || strcmpi(Arg,'--gapadjust') )
            ii = i + 1;
            if ( ii <= nargin )
                StepFileFudgeFactor = str2double(varargin{ii});
            else
                error('ERROR: Input gap adjustment argument not found.');
            end
            SkipArg = 1;
        % change execution
        elseif ( strcmpi(Arg,'-x') || strcmpi(Arg,'--execution') )
            ii = i + 1;
            if ( ii <= nargin )
                SpecialExecution = floor(str2double(varargin{ii}));
            else
                error('ERROR: Input execution argument not found.');
            end
            SkipArg = 1;
        % no credit 
        elseif ( strcmpi(Arg,'-onc') || strcmpi(Arg,'--outputnocredit') )
            SongCredit = '';
        % lock credit 
        elseif ( strcmpi(Arg,'-oc') || strcmpi(Arg,'--outputcredit') )
            ii = i + 1;
            if ( ii <= nargin )
                SongCredit = varargin{ii};
            else
                error('ERROR: Credit argument not found.');
            end
            SkipArg = 1;
        elseif ( strcmpi(Arg,'-?') )
disp( sprintf('Dancing Monkeys version %s  (http://www.realtimerendering.com/dm/)', VersionNumber) );
disp(' ');
disp('usage: DancingMonkeys [options] <infile> [basic medium hard [outdirectory]]');
disp(' ');
disp('    <infile> is an MP3 or WAV file, a directory, or an M3U playlist.');
disp('    [basic medium hard] are values from 1 to 9 for step difficulty.');
disp('    [outdirectory] is the results directory. This is .\..\..\output by default.');
disp('    [options] can actually be placed anywhere in the command line.');
disp(' ');
disp('Recommended usage: DancingMonkeys -es 3 infile');
disp(' ');
disp('Options:');
disp(' ');
disp('-v (--version) - Return version to the screen (only) and exit without');
disp('further processing.');
disp(' ');
disp('-i (--important) - Important message mode. No output except for errors');
disp('and file processing basics.');
disp(' ');
disp('-n (--noID3) - Do not attempt to parse the incoming MP3 file ID3 tag for');
disp('title and artist. Dancing Monkeys'' parser is pretty good, but can');
disp('sometimes get tripped up, so avoid this problem by setting this argument.');
disp(' ');
disp('-oc "text string" (--outputcredit "text string") - Instead of the default');
disp( sprintf('"Dancing Monkeys v%s" text, put your own text for the CREDIT field in', VersionNumber));
disp('the .sm steps file.');
disp(' ');
disp('-onc (--outputnocredit) - Do not include the CREDIT string in the .sm');
disp(sprintf('steps file. Normally this says "Dancing Monkeys v%s".',VersionNumber));
disp(' ');
disp('-oms (--outputmusicsame) - Use the same music file format when writing a');
disp('song, i.e. if a WAV file is read in, a WAV file is output; MP3 gives');
disp('MP3. Normally output files are always MP3''s.');
disp(' ');
disp('-omw (--outputmusicwav) - Always create output music files as WAV''s.');
disp('This is what v1.01 used by default.');
disp(' ');
disp('-onl (--outputnolog) - Do not output to a log file.');
disp(' ');
disp('-ob (--outputBPM) - Output the beats per minute and gap value, but end');
disp('processing and output nothing else (no steps files). Useful for people');
disp('writing manual steps for a song who want just the beat and gap');
disp('calculated.');
disp(' ');
disp('-t (--test) - Show which music files would be processed, but do no work.');
disp('For use when a directory or playlist is used as input, to check input.');
disp(' ');
disp('-ons (--outputnostops) - Do not output any stops (pauses) in the steps');
disp('files. Can be used in conjunction with "-es #"; the number of stops are');
disp('detected for purposes of checking for a bad song conversion, but if');
disp('good are still not output.');
disp(' ');
disp('-es # (--errorstops #) - If the number of stops found is > #, then');
disp('consider the process unsuccessful and exit. Off by default; 3 is');
disp('recommended. When Dancing Monkeys detects many stops, this is usually');
disp('a sign that it is failing to find the information it wants for making');
disp('steps, so the resulting steps file is (sometimes extremely) poor.');
disp(' ');
disp('-l # (--length #) - Maximum song length. Songs longer than this value');
disp('are truncated, faded out at the end. Default is 105 seconds. WARNING:');
disp('currently this feature tends to result in songs with sparse step');
disp('patterns, and needs to be fixed.');
disp(' ');
disp('-f # (--fade #) - How far from the end of the song to start fading out');
disp('the music, when the original track is too long. Default is 5 seconds.');
disp(' ');
disp('-c # (--confidence #) - A confidence level is computed for the beats');
disp('per minute value computed. If the confidence is below this level, abort');
disp('song creation for this file. Default is 10. Set to 0 to never abort and');
disp('always use the best BPM value found (no matter how poor).');
disp(' ');
disp('-m # (--measure #) - Number of beats per measure of music. Default is 4.');
disp(' ');
disp('-b #:# (--BPM #:#) - Give a range to search the song for BPM. Default');
disp('is 89-205.');
disp(' ');
disp('-g # (--gapadjust #) - Gap adjust, in seconds. This value is added to');
disp('the gap factor on output. Default is 0. If songs generated feel like');
disp('the steps come slightly before the musical beat, set a positive gap');
disp('value, e.g. "-g 0.05".');
disp(' ');
disp('-x # (--execution #) - Change mode of execution. A value of 1 means to');
disp('try refining the BPM as best as possible once a BPM is found.');
return;
        elseif ( strcmpi(Arg(1:1),'-') )
            error( 'ERROR: incorrect option "%s".',Arg );
        end
        
    else
        % MusicFullFilename, EasyDifficulty, MedDifficulty, HardDifficulty,
        % RootOutputDirectory
        if ( InputCount == 0 )
            MusicFullFilename = Arg;
            InputCount = InputCount + 1;
        elseif ( InputCount == 1 )
            EasyDifficulty = Arg;
            InputCount = InputCount + 1;
        elseif ( InputCount == 2 )
            MedDifficulty = Arg;
            InputCount = InputCount + 1;
        elseif ( InputCount == 3 )
            HardDifficulty = Arg;
            InputCount = InputCount + 1;
        elseif ( InputCount == 4 )
            RootOutputDirectory = Arg;
            InputCount = InputCount + 1;
        else
            error( 'ERROR: Too many arguments in command line.\nUse double-quotes around infile and outdirectory.\nUsage: DancingMonkeys "infile" 3 5 8 "outdirectory"\ninfile can also be a directory.');
        end
    end
end

if ( InputCount == 0 )
    disp(sprintf('Dancing Monkeys version %s  (http://www.realtimerendering.com/dm/)',VersionNumber));
    disp(' ');
    disp('usage: DancingMonkeys [options] <infile> [basic medium hard [outdirectory]]');
    disp(' ');
    disp('    <infile> is an MP3 or WAV file, a directory, or an M3U playlist.');
    disp('    [basic medium hard] are values from 1 to 9 for step difficulty.');
    disp('    [outdirectory] is the results directory. This is .\..\..\output by default.');
    disp('    [options] can actually be placed anywhere in the command line.');
    disp(' ');
    disp('Recommended usage: DancingMonkeys -es 3 infile');
    disp(' ');
    disp('Try: "DancingMonkeys -?"              for a complete options list.');
    return;
end


% Split music filename into parts
[ InputDirectory , MusicFileName , MusicFileExt , Temp ] = Fileparts( MusicFullFilename );

% Randomly generate difficulty levels if they are not given
if ( InputCount < 2 )
    EasyDifficulty = int2str( ceil( rand(1)*3 ) );
else
end
if ( InputCount < 3 )
    MedDifficulty  = int2str( 3 + ceil( rand(1)*3 ) );
end
if ( InputCount < 4 )
    HardDifficulty = int2str( 6 + ceil( rand(1)*3 ) );
end

% clean up fractional inputs from any jokers out there
EasyDifficulty = round(str2double(EasyDifficulty));
MedDifficulty = round(str2double(MedDifficulty));
HardDifficulty = round(str2double(HardDifficulty));

if ( EasyDifficulty <= 0 || EasyDifficulty > MaximumDifficulty )
    error( 'ERROR: illegal easy difficulty setting of %d; should be from 1 to 9', EasyDifficulty );
end
if ( MedDifficulty <= 0 || MedDifficulty > MaximumDifficulty )
    error( 'ERROR: illegal medium difficulty setting of %d; should be from 1 to 9', MedDifficulty );
end
if ( HardDifficulty <= 0 || HardDifficulty > MaximumDifficulty )
    error( 'ERROR: illegal hard difficulty setting of %d; should be from 1 to 9', HardDifficulty );
end

ChosenDifficultyRatings = [ EasyDifficulty, MedDifficulty, HardDifficulty ];

%ExeFullFilename = which('DancingMonkeys.m');
%i = findstr('DancingMonkeys.m',ExeFullFilename);
%ExeDirectory = ExeFullFilename(1:i-2);
ExeDirectory = pwd;

if ( InputCount < 5 )
    RootOutputDirectory = fullfile( ExeDirectory, '..\..\Output\');
end

% make log file's directory so log file writes out properly.
if ( ~ exist( RootOutputDirectory, 'dir' ) )
    [ RootOutputParentDirectory, RODirectory, Temp, Temp ] = Fileparts( RootOutputDirectory );
    [status,Temp,Temp] = kmkdir( RootOutputParentDirectory, RODirectory );

    if ( status ~= 1 )
        % yes, really die on this error
        error( 'ERROR: cannot create ''%s'' directory for the output.', RootOutputDirectory);
    end
end


LameFullFilename = [ ExeDirectory '\..\..\LAME\Lame.exe'];    
[ LamePath, LameFilename , LameFileExt , Temp ] = Fileparts( LameFullFilename );

TempWavFile = fullfile( ExeDirectory, '\..\..\Temp Music\Temp Song.wav' );        
[ TempWavFileDirectory, Temp, Temp, Temp ] = Fileparts( TempWavFile );

% check temp wav file's directory exists.
if ( ~ exist( TempWavFileDirectory, 'dir' ) )
    error( 'ERROR: temporary directory %s does not exist, please create it.', TempWavFileDirectory);
end


% Check music file exists
if ( ~exist( MusicFullFilename, 'file' ) )
    error( 'ERROR: Unable to find input music file or directory.\nUse double-quotes around infile and outdirectory.\nUsage: DancingMonkeys "infile" 3 5 8 "outdirectory"\ninfile can also be a directory.');
end

% Check LAME decoder exists
if ( ~exist( LameFullFilename, 'file' ) )
    error( 'ERROR: Unable to find LAME mp3 decoder.' );    
end

% Check bpm.exe existence
%if ( bitand( SpecialExecution,2 ) )
%    BpmFullFilename = [ ExeDirectory '\..\..\bpm\bpm.exe'];    
%    [ BpmPath, BpmFilename , BpmFileExt , Temp ] = Fileparts( BpmFullFilename );
%    if ( ~exist( BpmFullFilename, 'file' ) )
%        displog( ImportantMsg, LFN, 'WARNING: Unable to find fast BPM executable. Continuing without.' );
%        SpecialExecution = bitxor(SpecialExecution,2);
%    end
%end

% important messages are always output.
% nonvital messages can be suppressed.
% progress messages are never output to log.
% log message are only output to the log (if used). Normally used for
% error() messages that terminate.
% 1 == to screen, 2 == to log file
% command log on?
LFN = fullfile( RootOutputDirectory, 'dm_log.txt' );
if ( CommandLog == 0 )
    ImportantMsg = 1;
    % only important messages?
    if ( CommandImportant == 1 )
        NonvitalMsg = 0;
    else
        NonvitalMsg = 1;
    end
    ProgressMsg = NonvitalMsg;
else
    % log is on
    ImportantMsg = 3;
    % only important messages?
    if ( CommandImportant == 1 )
        NonvitalMsg = 0;
    else
        NonvitalMsg = 3;
    end
    ProgressMsg = bitand(1,NonvitalMsg);
end
if ( CommandLog > 0 )
    % Open log file, append to existing one if present
    ClockTime = clock;
    displog( NonvitalMsg, LFN, '===============================================================================' );
    displog( NonvitalMsg, LFN, sprintf( 'Start Time: %d:%02d:%02d %d/%02d/%d (U.S. format)', ClockTime(4), ClockTime(5), floor(ClockTime(6)), ClockTime(2), ClockTime(3), ClockTime(1) ));
end   

displog( ProgressMsg, LFN, 'Initialized.' );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We have all the information we need to start processing.

% If the input file is a directory, open it and pull in all the files.
if ( isdir( MusicFullFilename ) )
    % read directory contents
    InputFileList = dirlistsongs( NonvitalMsg, LFN, MusicFullFilename );
    SongCount = size( InputFileList, 2 );
    if ( SongCount == 0 )
        error( 'ERROR: no MP3 or WAV files found in input directory %s', MusicFullFilename );
    end
    displog( ProgressMsg, LFN, sprintf('Found %d songs to process.',SongCount));
elseif ( strcmpi( MusicFileExt, '.wav') || strcmpi( MusicFileExt, '.mp3') )
    InputFileList(1).name = MusicFullFilename;
    SongCount = 1;
elseif ( strcmpi( MusicFileExt, '.m3u') )
    %[ InputDirectory , MusicFileName , MusicFileExt , Temp ] = Fileparts( MusicFullFilename );
    SongCount = 0;
    fid = fopen( MusicFullFilename );
    TextLine = fgetl( fid );
    while ( TextLine ~= -1 )
        string = TextLine;
        if ( ~strcmp(string(1:1),'#') )
            strrep( string, '/', '\' ); % dos delimiters go backwards
            if ( findstr( string, ':' ) )   % dos-dependent
                % absolute path name
                fullname = string ;
            else
                % relative path name
                fullname = fullfile( InputDirectory, string );
            end
            if ( exist( fullname, 'file' ) )
                % line is a file; is it a music file we can do?
                if ( size( string, 2 ) > 4 )
                    ext = string(end-3:end);
                    if ( strcmpi( ext, '.wav') || strcmpi( ext, '.mp3') )
                        SongCount = SongCount + 1;
                        InputFileList(SongCount).name = fullname;
                    elseif ( strcmpi( ext, '.m4a'));
                        displog( NonvitalMsg, LFN, sprintf('WARNING: cannot convert .m4a file %s; first convert to MP3 or WAV (e.g. right-click on file in iTunes).', string ));
                    elseif ( strcmpi( ext, '.ogg'));
                        displog( NonvitalMsg, LFN, sprintf('WARNING: cannot convert .ogg file %s; first convert to MP3 or WAV.', string ));
                    elseif ( strcmpi( ext, '.wma'));
                        displog( NonvitalMsg, LFN, sprintf('WARNING: cannot convert .wma file %s; first convert to MP3 or WAV.', string ));
                    end
                end
            end
        end
        TextLine = fgetl( fid );
    end
    fclose( fid );            
    
else
    error( 'ERROR: unknown input file extension "%s". Please convert to MP3 or WAV.', MusicFileExt );    
end

% The major loop through music files
for SongNumber = 1 : SongCount
    ErrorFound = 0;
    MusicFullFilename = InputFileList(SongNumber).name;
    if ( CommandTestOnly )
        displog( ImportantMsg, LFN, sprintf( 'Input file: %s', MusicFullFilename ) );
        continue;
    end
    
[ Temp , MusicFileName , MusicFileExt , Temp ] = Fileparts( MusicFullFilename );
% delete trailing ' ' at end of file name, as these cause problems.
while ( strcmp(MusicFileName(end:end),' ') )
    MusicFileName = MusicFileName(1:end-1);    
end
displog( NonvitalMsg, LFN, '----------------------------------------------------------------' );
displog( ImportantMsg, LFN, sprintf( 'Begin processing input file %s', MusicFullFilename ) );

% This can be changed by the MP3 reader
SongTitle = MusicFileName;
SongArtist = DefaultArtist;

OutputDirectory = fullfile(RootOutputDirectory, MusicFileName);
OutputDirectory = [ OutputDirectory '\' ];

% Decode WAV or MP3.
% If we are reading a WAV, just prepare to read it normally
SongComment = '';
SongAlbum = '';
SongYear = '';
SongTrack = '';
SongGenre = '';
ImageSize = 0;
ImageData = '';

if ( strcmpi( MusicFileExt, '.wav') )
    % do wavread() on the original file.
    WavReadFile = MusicFullFilename;

elseif ( strcmpi( MusicFileExt, '.mp3') )
    % For MP3 we convert first to WAV, then read in the WAV
    LastDirectory = cd;
    cd( LamePath );
    % decode MP3 to a temporary WAV file. This WAV will then get read in.
    WavReadFile = TempWavFile;
    % get Results so it doesn't spew on the screen
    [ Status Results ] = dos( [ 'Lame --decode "' MusicFullFilename '" "' WavReadFile '"' ] );
    
    if ( Status ~= 0 )
        cd( LastDirectory );
        displog( ImportantMsg, LFN, Results );
        displog( ImportantMsg, LFN, 'ERROR: conversion of MP3 to WAV failed. Try first converting your file to a fixed rate MP3 or WAV file using another sound program.' );    
        continue;   % on to the next file
    end
    
    cd( LastDirectory );
        
    % get the artist and title information from the MP3 header, as possible
    % Structure of ID3:
    % "FF" means "end of header"; First 10 bytes are fixed:
    % First three characters are "ID3"
    % two version bytes follow, e.g. 04 00
    % next byte is a flag byte, with various bits. Bit 0x40 = "extended header"
    % 4 bytes are "safe" integer (topmost bit off) for length of total header
    % If extended header is present, first four bytes is length, skip it
    % Frames follow. Each frame has a 10 byte header:
    % 4 character ID, e.g. "TIT2" means "Title".
    % 4 byte size, "safe" integer.
    % 2 flag bytes
    % information itself, starting with a "00" byte, then characters, no
    % final "\0" byte.
    % Useful pages:
    % http://www.id3.org/id3v2.4.0-structure.txt
    % http://en.wikipedia.org/wiki/ID3
    % http://www.codeproject.com/csharp/mp3tags-to-xml-tree.asp
    if ( CommandReadMP3Data )
        fid = fopen( MusicFullFilename );
        % Try v1 read
        % V1 is dead simple:
        % bytes 1-3 are "TAG"
        % bytes 4-33 are title
        % bytes 34-63 are artist
        % bytes 64-93 are album
        % bytes 94-97 are year
        % bytes 98-127 are comment (or if 127 is set and 126 is not, track)
        % byte 128 is genre number
        % See:
        % http://www.id3.org/id3v1.html
        % http://www.codeproject.com/csharp/mp3tags-to-xml-tree.asp
        
        % Interestingly enough, some MP3s have the TAG at the end, and have
        % ID3 at the beginning. Try V2 first, then drop back to V1
        
        % Try v2+ read
        %fseek( fid, 0, 'bof' );
        ID3header = fread( fid, 3, '*char' )';
        if ( strcmp( ID3header, 'ID3') )
            % lookin' good; check if there's an extended header; if so, skip it
            MP3MajorVersion = fread( fid, 1, 'uint8' ); % major version
            MP3MinorVersion = fread( fid, 1, 'uint8' ); % minor version
            FoundArtist = 0;
            ID3flags = fread( fid, 1, 'uint8' ); % flag - pay attention
            HeaderBytes = fread( fid, 4, 'uint8' )';
            %ID3HeaderSize = HeaderBytes(1)*(2^21) + HeaderBytes(2)*(2^14) + HeaderBytes(3)*(2^7) + HeaderBytes(4);
            ID3HeaderSize = HeaderBytes(1)*(2^24) + HeaderBytes(2)*(2^16) + HeaderBytes(3)*(2^8) + HeaderBytes(4);
            if ( bitand(ID3flags,64) )
                % skip extended header - TODO: test this! Need to find a
                % file with one.
                ExtHeaderBytes = fread( fid, 4, 'uint8' )';
                %ExtendedSize = ExtHeaderBytes(1)*(2^21) + ExtHeaderBytes(2)*(2^14) + ExtHeaderBytes(3)*(2^7) + ExtHeaderBytes(4);
                ExtendedSize = ExtHeaderBytes(1)*(2^24) + ExtHeaderBytes(2)*(2^16) + ExtHeaderBytes(3)*(2^8) + ExtHeaderBytes(4);
                % read rest of extended header; note that the size includes
                % the header itself, unlike other sizes.
                fread( fid, ExtendedSize-4 );
                ID3HeaderSize = ID3HeaderSize - ExtendedSize;
            end
            NotDone = 1;
            FrameCount = 0;
            % MP3 ID3v2 & v3 we do here
            if ( MP3MajorVersion > 2 || ( MP3MajorVersion == 2 && MP3MinorVersion >= 3 ) )
                % We try to be pretty safe here and not run off the end of the
                % header.
                % FrameCount is a safety valve - if we hit 50, we've probably
                % left Kansas (are past the header) and should quit.
                while ( NotDone && FrameCount < 50 && ID3HeaderSize > 0 )
                    % Frames - process until an "ff" is found
                    [ID3frameHeaderID count] = fread( fid, 4, '*char' );
                    ID3frameHeaderID = ID3frameHeaderID';   % transpose
                    if ( ID3frameHeaderID(1) == 255 || ID3frameHeaderID(1) == 0 || ID3frameHeaderID(1) == '3' || count == 0 )
                        NotDone = 0;
                    else
                        FrameCount = FrameCount + 1;
                        TagBytes = fread( fid, 4, 'uint8' )';
                        ID3frameHeaderFlags = fread( fid, 2, 'uint8' )';
                        %FrameSize = TagBytes(1)*(2^21) + TagBytes(2)*(2^14) + TagBytes(3)*(2^7) + TagBytes(4);
                        FrameSize = TagBytes(1)*(2^24) + TagBytes(2)*(2^16) + TagBytes(3)*(2^8) + TagBytes(4);
                        ID3HeaderSize = ID3HeaderSize - FrameSize - 10;
                        % check if it's an image file
                        if ( strcmp(ID3frameHeaderID,'APIC') )
                            TextEncoding = fread( fid, 1, 'uint8' );    % read the 0x0 byte, text encoding, and ignore; if it's unicode 0x01 we might be in trouble...
                            FrameSize = FrameSize - 1;
                            if ( TextEncoding ~= 0 )
                                % We don't handle unicode right now, so stop reading
                                NotDone = 0;    % not really needed because of the break, but...
                                break;
                            end
                            Tempstring = fread( fid, 1, '*char' );    % read character
                            FrameSize = FrameSize - 1;
                            ImageType = '';
                            while ( Tempstring ~= 0 )
                                ImageType = [ ImageType Tempstring ];
                                Tempstring = fread( fid, 1, '*char' );    % read character
                                FrameSize = FrameSize - 1;
                            end

                            % MIME type: image/png, image/jpeg, PNG,
                            % JPEG, JPG...
                            % read as a string
                            if ( strcmpi(ImageType,'image/png') )
                                ImageType = 'png';
                            elseif ( strcmpi(ImageType,'image/jpeg') || strcmpi(ImageType,'image/jpg') || strcmpi(ImageType,'JPEG') )
                                ImageType = 'jpg';
                            else
                                ImageType = lower(ImageType);
                            end
                            if ( strcmpi(ImageType,'JPG') || strcmpi(ImageType,'PNG') )
                                fread( fid, 1 );    % read picture type 0x0 bytes
                                FrameSize = FrameSize - 1;
                                Tempstring = fread( fid, 1, 'uint8' );    % read string
                                FrameSize = FrameSize - 1;
                                while ( Tempstring ~= 0 )
                                    Tempstring = fread( fid, 1, 'uint8' );    % read string
                                    FrameSize = FrameSize - 1;
                                end
                                % there could be multiple images, so just
                                % read largest one
                                if ( ImageSize < FrameSize )
                                    ImageSize = FrameSize;
                                    ImageData = fread( fid, ImageSize, 'uint8' )';
                                else
                                    % ignore image, it's smaller
                                    fread( fid, ImageSize );
                                end
                            end
                        elseif ( FrameSize > 300 )
                            % It's likely we're past any useful frame data, so
                            % quit
                            NotDone = 0;    % not really needed because of the break, but...
                            break;

                        % look for various info:
                        % TIT2 - title
                        % TPE1 - artist
                        % TALB - album
                        % TDRC - year
                        % COMM - comment
                        % TRCK - track number
                        % TCON - music type (techno, etc.)
                        % TODO: UTF-8 is supported in ID3 v2.4, but we
                        % don't do anything special here - might work...
                        elseif ( strcmp(ID3frameHeaderID,'TIT2') )
                            fread( fid, 1 );    % read the 0x0 byte
                            SongTitle = deblank(fread( fid, FrameSize-1, '*char' )');
                            displog( ProgressMsg, LFN, sprintf( 'MP3 Title found: %s', SongTitle ) );
                        % take whatever we can find first. Could get more
                        % involved, but I'm betting TPE1 appears before
                        % TPE2 in the header
                        elseif ( strcmp(ID3frameHeaderID,'TPE1') )
                            FoundArtist = 4;    % highest level
                            fread( fid, 1 );    % read the 0x0 byte
                            SongArtist = deblank(fread( fid, FrameSize-1, '*char' )');
                            displog( ProgressMsg, LFN, sprintf( 'MP3 Primary Artist found: %s', SongArtist ) );
                        elseif ( (FoundArtist < 3 ) && strcmp(ID3frameHeaderID,'TPE2') )
                            FoundArtist = 3;    % next highest level
                            fread( fid, 1 );    % read the 0x0 byte
                            SongArtist = deblank(fread( fid, FrameSize-1, '*char' )');
                            displog( ProgressMsg, LFN, sprintf( 'MP3 Band/Orchestra found: %s', SongArtist ) );
                        elseif ( (FoundArtist < 2 ) && strcmp(ID3frameHeaderID,'TPE3') )
                            FoundArtist = 2;    % next highest level
                            fread( fid, 1 );    % read the 0x0 byte
                            SongArtist = deblank(fread( fid, FrameSize-1, '*char' )');
                            displog( ProgressMsg, LFN, sprintf( 'MP3 Conductor/Performer found: %s', SongArtist ) );
                        elseif ( (FoundArtist < 1 ) && strcmp(ID3frameHeaderID,'TPE4') )
                            FoundArtist = 1;    % next highest level
                            fread( fid, 1 );    % read the 0x0 byte
                            SongArtist = deblank(fread( fid, FrameSize-1, '*char' )');
                            displog( ProgressMsg, LFN, sprintf( 'MP3 Interpreted/Remixed Artist found: %s', SongArtist ) );
                        elseif ( strcmp(ID3frameHeaderID,'COMM') )
                            fread( fid, 1 );    % read the 0x0 byte
                            SongComment = deblank(fread( fid, FrameSize-1, '*char' )');
                        elseif ( strcmp(ID3frameHeaderID,'TALB') )
                            fread( fid, 1 );    % read the 0x0 byte
                            SongAlbum = deblank(fread( fid, FrameSize-1, '*char' )');
                        elseif ( strcmp(ID3frameHeaderID,'TYER') )
                            fread( fid, 1 );    % read the 0x0 byte
                            SongYear = deblank(fread( fid, FrameSize-1, '*char' )');
                        elseif ( strcmp(ID3frameHeaderID,'TRCK') )
                            fread( fid, 1 );    % read the 0x0 byte
                            SongTrack = deblank(fread( fid, FrameSize-1, '*char' )');
                        elseif ( strcmp(ID3frameHeaderID,'TCON') )
                            fread( fid, 1 );    % read the 0x0 byte
                            SongGenre = deblank(fread( fid, FrameSize-1, '*char' )');
                        else
                            % ignore useless data
                            if ( FrameSize > 0 )
                                fread( fid, FrameSize );
                            end
                        end
                    end
                end % end while
            else
                % ID3 v2.2 (actually, 2.2 has a version of "0").
                % We try to be pretty safe here and not run off the end of the
                % header.
                % FrameCount is a safety valve - if we hit 50, we've probably
                % left Kansas (are past the header) and should quit.
                while ( NotDone && FrameCount < 50 && ID3HeaderSize > 0 )
                    % Frames - process until an "ff" is found
                    [ID3frameHeaderID count] = fread( fid, 3, '*char' );
                    ID3frameHeaderID = ID3frameHeaderID';   % transpose
                    if ( ID3frameHeaderID(1) == 255 || ID3frameHeaderID(1) == 0 || ID3frameHeaderID(1) == '3' || count == 0 )
                        NotDone = 0;
                    else
                        FrameCount = FrameCount + 1;
                        TagBytes = fread( fid, 3, 'uint8' )';
                        % Hmmm, iTunes does this *wrong*! Really, the
                        % numbers should be 14/7, not 16/8.
                        FrameSize = TagBytes(1)*(2^16) + TagBytes(2)*(2^8) + TagBytes(3);
                        ID3HeaderSize = ID3HeaderSize - FrameSize - 6;
                        % check if it's an image file
                        if ( strcmp(ID3frameHeaderID,'PIC') )
                            TextEncoding = fread( fid, 1, 'uint8' );    % read the 0x0 byte, text encoding, and ignore; if it's unicode 0x01 we might be in trouble...
                            if ( TextEncoding ~= 0 )
                                % We don't handle unicode right now, so
                                % stop reading
                                NotDone = 0;    % not really needed because of the break, but...
                                break;
                            end
                            ImageType = lower(fread( fid, 3, '*char' )');
                            if ( strcmpi(ImageType,'JPG') || strcmpi(ImageType,'PNG') )
                                fread( fid, 1 );    % read picture type 0x0 bytes
                                Tempstring = fread( fid, 1, 'uint8' );    % read string
                                while ( Tempstring ~= 0 )
                                    Tempstring = fread( fid, 1, 'uint8' );    % read string
                                    FrameSize = FrameSize - 1;
                                end
                                % there could be multiple images, so just
                                % read largest one
                                if ( ImageSize < FrameSize-6 )
                                    ImageSize = FrameSize-6;
                                    ImageData = fread( fid, ImageSize, 'uint8' )';
                                else
                                    % ignore image, it's smaller
                                    fread( fid, ImageSize );
                                end
                            end
                        elseif ( FrameSize > 500 )  % was 300, which usually works, but...
                            % It's likely we're past any useful frame data, so
                            % quit
                            NotDone = 0;    % not really needed because of the break, but...
                            break;

                        % look for various info:
                        % TT2 - title
                        % TP1/2/3/4 - artist
                        % TAL - album
                        % TYE - year
                        % COM - comment
                        % TRK - track number
                        % TCO - music type (techno, etc.)
                        elseif ( strcmp(ID3frameHeaderID,'TT2') )
                            fread( fid, 1 );    % read the 0x0 byte
                            SongTitle = deblank(fread( fid, FrameSize-1, '*char' )');
                            displog( ProgressMsg, LFN, sprintf( 'MP3 Title found: %s', SongTitle ) );
                        % take whatever we can find first. Could get more
                        % involved, but I'm betting TPE1 appears before
                        % TPE2 in the header
                        elseif ( strcmp(ID3frameHeaderID,'TP1') )
                            FoundArtist = 4;    % highest level
                            fread( fid, 1 );    % read the 0x0 byte
                            SongArtist = deblank(fread( fid, FrameSize-1, '*char' )');
                            displog( ProgressMsg, LFN, sprintf( 'MP3 Primary Artist found: %s', SongArtist ) );
                        elseif ( (FoundArtist < 3 ) && strcmp(ID3frameHeaderID,'TP2') )
                            FoundArtist = 3;    % next highest level
                            fread( fid, 1 );    % read the 0x0 byte
                            SongArtist = deblank(fread( fid, FrameSize-1, '*char' )');
                            displog( ProgressMsg, LFN, sprintf( 'MP3 Band/Orchestra found: %s', SongArtist ) );
                        elseif ( (FoundArtist < 2 ) && strcmp(ID3frameHeaderID,'TP3') )
                            FoundArtist = 2;    % next highest level
                            fread( fid, 1 );    % read the 0x0 byte
                            SongArtist = deblank(fread( fid, FrameSize-1, '*char' )');
                            displog( ProgressMsg, LFN, sprintf( 'MP3 Conductor/Performer found: %s', SongArtist ) );
                        elseif ( (FoundArtist < 1 ) && strcmp(ID3frameHeaderID,'TP4') )
                            FoundArtist = 1;    % next highest level
                            fread( fid, 1 );    % read the 0x0 byte
                            SongArtist = deblank(fread( fid, FrameSize-1, '*char' )');
                            displog( ProgressMsg, LFN, sprintf( 'MP3 Interpreted/Remixed Artist found: %s', SongArtist ) );
                        elseif ( strcmp(ID3frameHeaderID,'COM') )
                            fread( fid, 1 );    % read the 0x0 byte
                            SongComment = deblank(fread( fid, FrameSize-1, '*char' )');
                        elseif ( strcmp(ID3frameHeaderID,'TAL') )
                            fread( fid, 1 );    % read the 0x0 byte
                            SongAlbum = deblank(fread( fid, FrameSize-1, '*char' )');
                        elseif ( strcmp(ID3frameHeaderID,'TYE') )
                            fread( fid, 1 );    % read the 0x0 byte
                            SongYear = deblank(fread( fid, FrameSize-1, '*char' )');
                        elseif ( strcmp(ID3frameHeaderID,'TRK') )
                            fread( fid, 1 );    % read the 0x0 byte
                            SongTrack = deblank(fread( fid, FrameSize-1, '*char' )');
                        elseif ( strcmp(ID3frameHeaderID,'TCO') )
                            fread( fid, 1 );    % read the 0x0 byte
                            SongGenre = deblank(fread( fid, FrameSize-1, '*char' )');
                        else
                            % ignore useless data
                            if ( FrameSize > 0 )
                                fread( fid, FrameSize );
                            end
                        end
                    end
                end % end while
            end
        else
            % Try V1 header read
            fseek( fid, -128, 'eof' );
            if ( strcmpi( 'TAG', fread(fid,3,'*char' )' ) )
                % lookin' good
                SongTitle = deblank(fread( fid, 30, '*char' )');
                SongArtist = deblank(fread( fid, 30, '*char' )');
                SongAlbum = deblank(fread( fid, 30, '*char' )');
                SongYear = deblank(fread( fid, 4, '*char' )');
                SongComment = fread( fid, 30, '*char' )';
                if ( SongComment(30) ~= 0 && SongComment(29) == 0 )
                    SongTrack = sprintf('%d',SongComment(30));
                    SongComment(30) = 0;
                    SongComment = deblank(SongComment);
                end
                SongGenre = sprintf('%d',deblank(fread( fid, 1, '*char' )'));
                displog( ProgressMsg, LFN, sprintf( 'MP3 Title found: %s', SongTitle ) );
                displog( ProgressMsg, LFN, sprintf( 'MP3 Artist found: %s', SongArtist ) );
            end
        end % MP3 header
        fclose(fid);
    end % Read MP3 Data command end

else
    % unknown file suffix
    % really should never reach here (earlier tests stop things), but just in case!
    displog( ImportantMsg, LFN, sprintf( 'ERROR: unknown extension "%s" for file "%s". Please convert to MP3 or WAV.', MusicFileExt, MusicFullFilename ) );    
    continue;
end


% If we want to find BPM the fast way, we need to check the WavReadFile for
% its BPM. (Note, might want to write out SongData below and check that instead?)

% FEATURE DISABLED: BPM.exe was found to be too flaky. Left in, as this is
% a nice way to access an outside BPM application someday.
%RunQuickBPM = 0;
%if ( bitand( SpecialExecution,2 ) )
%    LastDirectory = cd;
%    cd( BpmPath );
%    % decode MP3 to a temporary WAV file. This WAV will then get read in.
%    WavReadFile = TempWavFile;
%    % get Results so it doesn't spew on the screen
%    [ Status Results ] = dos( sprintf( 'bpm -q -l %f -h %f "%s"' , MinimumBPM, MaximumBPM, WavReadFile ) );
%    
%    cd( LastDirectory );
%    
%    if ( Status ~= 0 )
%         cd( LastDirectory );
%         displog( ImportantMsg, LFN, Results );
%         displog( ImportantMsg, LFN, 'WARNING: BPM execution failed. Using traditional approach.' );
%     else
%         % Passed status, get BPM
%         QuickBPM = sscanf( Results, '%f' );
%         if ( QuickBPM > 0 )
%             QuickMinBPM = QuickBPM - 2;
%             QuickMaxBPM = QuickBPM + 2;
%             displog( ImportantMsg, LFN, sprintf( 'Quick BPM method found BPM of %-7.3f.', QuickBPM ) );
%             RunQuickBPM = 1;
%         else
%             displog( ImportantMsg, LFN, 'WARNING: bpm.exe returned 0 as BPM. Using traditional approach.' );
%         end
%     end
%     
% end


% Get Frequency of Wav File; just read a single sample so we get frequency
[ Temp1, Frequency, Temp2 ] = wavread( WavReadFile, 1 );
displog( ProgressMsg, LFN, 'Song file successfully read.' );

% Get Size of Wav File
Temp = wavread( WavReadFile, 'size' );
NumSamples = Temp( 1 );

% Load wav file itself
SongSizeLimit = Frequency * MaxSongLengthInSeconds;
[ SongData, Frequency, NumBits ] = wavread( WavReadFile, min( [SongSizeLimit NumSamples] ) );
SongLength = size( SongData, 1 );

OutputTrimmed = 0;
if ( SongLength == SongSizeLimit )
    OutputTrimmed = 1;
end

% If we have to truncate the song fade it out at the end
if ( OutputTrimmed )
    Mask(:,1) = (1:-(1/((44100 * FadeSeconds) - 1)):0)';
    Mask(:, size(SongData, 2 ) ) = Mask(:,1);             % Need to fix for possible greater than 2 tracks.
    SongData( end - ((44100 * FadeSeconds) - 1):end, : ) = SongData( end - ((44100 * FadeSeconds) - 1):end, : ) .* Mask;
end

% Normalise Song
SongData = SongData ./ prctile( abs( SongData(:) ), 99.999 );
SongData( SongData > 1 ) = 1;
SongData( SongData < -1 ) = -1;
displog( ProgressMsg, LFN, 'Normalized song.' );


% Now save normalized, possibly trimmed song.
% Convert song to mono
NumTracks = size( SongData, 2 );
Mono = sum( SongData' ./ NumTracks, 1 )';
SongLength = size( SongData, 1 );
displog( ProgressMsg, LFN, 'Monoed song.' )

% Note: if we find that we're still running out of memory, we could do a
% stupid, painful thing: write SongData to a WAV now, clear, then read it
% back in for writing out when the song is saved.
if ( CommandBPMonly == 1 )
    clear SongData; % done with the original now, since no output needed
end

% Lowpass filter the song. This removes any high frequency data, and makes 
% it possible to peak pick the data.

% Create the Butterworth lowpass filter.
[m,n] = butter( SmoothingFilterOrder, SmoothingFilterLowpassFrequency * 2 / Frequency );

% Filter the data both forwards and backwards in order to remove the phase
% shifts generated by filtering.
SmoothedData = filter( m, n, abs( Mono ) );
displog( ProgressMsg, LFN, 'Smoothed song.' );


% Normalise the mono and smoothed song data. This is done by taking hamming windows along
% the mono and smoothed data and normalising each window to a peak of amplitude
% 1. The windows are then added back together to make a normalied version 
% of the smoothed data. This allows for more robust peak picking.

% Length of window in seconds. Windows overlap by half the length of a
% window.
WindowSizeInSamples = round( WindowLength * Frequency );
WindowShape = hamming( WindowSizeInSamples );

% Create blank versions of the normalised data.
NormalisedMonoData   = zeros( size( Mono ) );
NormalisedSmoothData = zeros( size( Mono ) );

% Loop through each window, moving the start point of by the length of half
% a window each time.
Position = 1;
while ( Position + WindowSizeInSamples < SongLength )
    % We take the absolute value of the window in order to half wave
    % rectify the mono data. The smoothed data is already rectified.
    Window = abs( Mono( Position:(Position+WindowSizeInSamples)-1 ) );
    Window = Window ./ max( Window );
    NormalisedMonoData( Position:(Position+WindowSizeInSamples)-1 )   = NormalisedMonoData( Position:(Position+WindowSizeInSamples)-1 )   + (Window .* WindowShape);
    
    Window = SmoothedData( Position:(Position+WindowSizeInSamples)-1 );
    Window = Window ./ max( Window );
    NormalisedSmoothData( Position:(Position+WindowSizeInSamples)-1 ) = NormalisedSmoothData( Position:(Position+WindowSizeInSamples)-1 ) + (Window .* WindowShape);
    
    Position = Position + ( WindowSizeInSamples / 2 );
end

% At the end of the song we can't fit the full length of a window so just
% multiply by the part of the window shape that will fit.
Window = Mono( Position:SongLength );
Window = Window ./ max( Window );
NormalisedMonoData( Position:SongLength )   = NormalisedMonoData( Position:SongLength )   + ( Window .* WindowShape( 1:(SongLength - Position) + 1 ) );

Window = SmoothedData( Position:SongLength );
Window = Window ./ max( Window );
NormalisedSmoothData( Position:SongLength ) = NormalisedSmoothData( Position:SongLength ) + ( Window .* WindowShape( 1:(SongLength - Position) + 1 ) );


NormalisedMonoData   = NormalisedMonoData   ./ max( NormalisedMonoData   );
NormalisedSmoothData = NormalisedSmoothData ./ max( NormalisedSmoothData );
displog( ProgressMsg, LFN, 'Normalised mono and smoothed data.' );

% Now we throw away any samples not in the top 10% of the normalised
% smoothed data.

% Sort the smoothed data, and take the value at the 90% percent mark as the
% limit for discarding the data.
SortedData = sort( NormalisedSmoothData );
Limit = SortedData( round( (SongLength/100) * PeakThreshold ) );

clear SortedData;

% Set any element below the limit value to 0.
PeakData = NormalisedSmoothData;
PeakData( find( PeakData < Limit ) ) = 0;
displog( ProgressMsg, LFN, 'Thresholded data.' );


% Find peaks in thresholded smoothed track.
NonZeroData = PeakData( PeakData ~= 0 );
% The expression on the right finds all peaks in the NonZeroData.
IndexToNonZeroData = find(sign(-sign(diff(sign(diff( NonZeroData )))+0.5)+1))+1;
IndexToPeakData = find( PeakData ~=0 );
Peaks = IndexToPeakData( IndexToNonZeroData );

clear PeakData NonZeroData IndexToPeakData;

% Find all the troughs in the unthresholded smoothed data.
Troughs = find(sign(-sign(diff(sign(diff( NormalisedSmoothData )))-0.5)-1))+1;
displog( ProgressMsg, LFN, 'Found peaks and troughs.' );

% Compute the normalised strengths of each beat from 0 to 1
BeatStrengths = NormalisedSmoothData( Peaks );
BeatStrengths = BeatStrengths - min( BeatStrengths );
BeatStrengths = BeatStrengths ./ max( BeatStrengths );

clear NormalisedSmoothData;

% Now we try and find how much the peaks have been shifted by.

% Create a blank holder for the positions of the beats
BeatPositions = ones( size( Peaks ) );

% Loop through each peak we have found. Find the trough to the left of it.
% Now try and find the sharp onset of the beat by looking at the normalised
% rectified mono data.
for ct1 = 1 : size( Peaks, 1 )
    Peak = Peaks( ct1 ); 
    
    TroughsLessThanPeak = Troughs( Troughs < Peak );
    
    if ( size( TroughsLessThanPeak, 1 ) > 0 ) 
        NearestTrough = TroughsLessThanPeak( end );
        
        % TODO: Improve the method of estimating peak/trough height, use
        % some emperical evidence to find what works best. Also make sure
        % that it won't break at the ends of the data. Need a better way to
        % quantify which element of PeakSize we pick and why.
        
        HeightWindow = round(Frequency * HeightWindowSize);
        HalfHeightWindow = round( HeightWindow / 2 );
        
        % Find the rough height around the peak on the normalised mono data.
        Temp = sort( abs( NormalisedMonoData( Peak - HalfHeightWindow : Peak + HalfHeightWindow ) ) );
        PeakSize   = Temp( end - round( HeightWindow / 100 ) );
        
        % Find the rough height around the trough on the normalised mono data.
        Temp = sort( abs( NormalisedMonoData( NearestTrough - HalfHeightWindow :NearestTrough + HalfHeightWindow ) ) );
        TroughSize = Temp( end - round( HeightWindow / 100 ) );
        
        % Calculate the threshold at which a value is considered to be the
        % onset point.
        Threshold = ( ( PeakSize - TroughSize ) * BeatPositioningThreshold ) + TroughSize;
        
        Candidates = NormalisedMonoData( NearestTrough : Peak );
        CandidatesPos = find( Candidates >= Threshold );
        
        if ( size( CandidatesPos, 1 ) < 1 )
            Pos = 1;    % If no candidates are good enough, then take the trough as the beat position.
        else
            Pos = CandidatesPos( 1 );
        end
        BeatPos = NearestTrough + Pos - 1;
        
        BeatPositions( ct1 ) = BeatPos;
    end
end
displog( ProgressMsg, LFN, 'Found beat positions.' );

clear NormalisedMonoData Troughs;

% Find the average difference between the peaks and what we think are the
% onsets. Shifting all the peak data by the same amount, rather than using
% the calculated beat positions for each one gives us much better accuracy
% in computing the BPM.

% unused: Offsets = Peaks - BeatPositions;
% Offset = median( Offsets );

% Beats = Peaks - round( Offset );
Beats = BeatPositions;
clear BeatPositions;
displog( ProgressMsg, LFN, 'Calculated peak to beat offset.' );

HalfGapWindowSize = 1000;
GapWindow = hamming( HalfGapWindowSize*2 );
NumBeats = size( Beats,1 ) * 2;

% Now we brute force all possible BPMS from a very high value to a very low
% value. This involves testing each possible interval between beats and
% rating them by the amount of data that supports them being the correct
% BPM.

% for now, always run the normal and refined BPM test, unless shortcut by the quick test:
%TestQuickBPM = RunQuickBPM;
TestNormalBPM = 1;

if ( bitand( SpecialExecution,1 ) )
    TestRefinedBPM = 1;
else
    TestRefinedBPM = 0;
end

Confidence = 0;

BPMfailure = 1;  % means ultimate failure
% TestQuickBPM ~= 0 ||
while ( TestNormalBPM ~= 0 || TestRefinedBPM ~= 0 )   
    % We want to run up to three times:
    % Quick BPM, fair resolution
    % Normal method, slow low resolution
    % Refine, high resolution
    IntervalFrequency = 10; % low resolution
    ConfidenceScale = 1.0;
    
    % The minimum BPM becomes the maximum interval, because the less beats per
    % minute the longer the gap between them.
%     if ( TestQuickBPM ~= 0 )
%         displog( ImportantMsg, LFN, sprintf( 'Quick BPM test: %f to %f', QuickMinBPM, QuickMaxBPM ) );
%         MaximumInterval = round( Frequency / ( QuickMinBPM / 60 ) );
%         MinimumInterval = round( Frequency / ( QuickMaxBPM / 60 ) );
%         IntervalFrequency = 10;
%         ConfidenceScale = 0.65;
%     else
    if ( TestNormalBPM ~= 0 )
        displog( ImportantMsg, LFN, sprintf( 'Normal BPM test: %f to %f', MinimumBPM, MaximumBPM ) );
        MaximumInterval = round( Frequency / ( MinimumBPM / 60 ) );
        MinimumInterval = round( Frequency / ( MaximumBPM / 60 ) );
    else
        % refined attempt
        RefinedInterval = round( Frequency / ( BPM / 60 ) );
        MaximumInterval = RefinedInterval + round(IntervalFrequency/2);
        MinimumInterval = RefinedInterval - round(IntervalFrequency/2);
        displog( ImportantMsg, LFN, sprintf( 'Refined BPM test: best previous was %f, searching %f to %f', BPM, ( Frequency / MaximumInterval ) * 60, ( Frequency / MinimumInterval ) * 60 ) );
        IntervalFrequency = 1;
    end

    IntervalFitness  = zeros( [ (MaximumInterval - MinimumInterval + 1) 1 ] );
    IntervalGap      = zeros( [ (MaximumInterval - MinimumInterval + 1) 1 ] );

    % Loop through every 10th possible BPM, later we will fill in those that
    % look interesting

    checkIntervalRange = MaximumInterval - MinimumInterval + 1;
    % The costliest part ahead...
    doneIncrement = 10; % just for display that something is happening
    doneLevel = doneIncrement;  % just for display
    for i = MinimumInterval : IntervalFrequency : MaximumInterval
        curDone = 100 * (i-MinimumInterval) / checkIntervalRange;
        if ( curDone > doneLevel )
            displog( ProgressMsg, LFN, sprintf( '  BPM testing: %3.0f%% done, BPM %f', curDone, ( Frequency / i ) * 60 ) );
            doneLevel = doneLevel + doneIncrement;
        end
        %     displog( ProgressMsg, LFN, sprintf( 'Started %d', i ) );

        Gaps = mod( Beats, i );
        ExtraGaps = Gaps + i;

        FullGaps = [ Gaps ExtraGaps ]';
        FullGaps = FullGaps(:);
        [ SortedGaps SortedIndex ] = sort( FullGaps );


        % Here we take a hamming window over a small window of Gap positions
        % and record the amount of support we get from gap values within that
        % hamming window, based on the strength of the beat predicting each
        % gap and the distance of the gap from the centre of the hamming
        % window.
        GapsFiltered = zeros( NumBeats, 1 );
        for ct1 = 1 : NumBeats
            Area = 0;

            Centre = SortedGaps( ct1 );

            Pos = ct1;
            PosVal = SortedGaps( Pos );
            while ( PosVal > Centre - HalfGapWindowSize )

                if Pos <= 1 
                    break;
                end
                xPos = SortedIndex( Pos );
                if ( xPos > size( Beats,1 ) ) 
                    xPos = xPos - size( Beats,1 );
                end
                Area = Area + ( BeatStrengths( xPos ) * GapWindow( PosVal - (Centre - HalfGapWindowSize) ) );
                Pos = Pos - 1;
                PosVal = SortedGaps( Pos );
            end

            Pos = ct1;
            PosVal = SortedGaps( Pos );
            while ( PosVal <= Centre + HalfGapWindowSize )

                if Pos >= NumBeats
                    break;
                end
                xPos = SortedIndex( Pos );
                if ( xPos > size( Beats,1 ) ) 
                    xPos = xPos - size( Beats,1 );
                end
                Area = Area + ( BeatStrengths( xPos ) * GapWindow( PosVal - (Centre - HalfGapWindowSize) ) );
                Pos = Pos + 1;
                PosVal = SortedGaps( Pos );
            end

            GapsFiltered( ct1 ) = Area;

        end


        % Here we work out how much evidence there is to support each gap
        % by the GapFiltered value for each gap and a portion of the
        % GapFiltered value from offbeats.

        % Need to take care of end cases better
        GapsConfidence = zeros( NumBeats, 1 );
        for ct1 = 1 : NumBeats -1 

            OffbeatPos = SortedGaps( ct1 ) + round(i / 2);

            % We know the position of where an offbeat gap value would be but
            % we need to work out its index in the SortedGaps array
            Pos = ct1;
            PosVal = SortedGaps( Pos );
            while ( PosVal < OffbeatPos )
                if Pos >= NumBeats - 1
                    break;
                end
                Pos = Pos + 1;
                PosVal = SortedGaps( Pos );
            end

            % Not sure why I have this taking the average of the two nearest
            % gaps. Might give some improvement to accuracy, but most probably
            % pointless. TODO?
            OffBeatValue = ( GapsFiltered( Pos ) + GapsFiltered( Pos + 1 ) ) / 2;

            GapsConfidence( ct1 ) = GapsFiltered( ct1 ) + ( OffBeatValue * 0.5 );        
        end

        GapPeaks = SortedGaps( find( GapsConfidence == max( GapsConfidence ) ) );

        IntervalFitness( (i + 1) - MinimumInterval ) = max( GapsConfidence );
        IntervalGap( (i+1) - MinimumInterval )       = GapPeaks( 1 );

    end

    % Find the top 50 possible BPMs that look interesting and compute the
    % fitness of every interval around them
    Temp = sort( IntervalFitness );
    BPMCandidates = 50;
    if ( size( Temp,1 ) < BPMCandidates )
        BPMCandidates = size( Temp,1 );
    end
    DoMoreWorkOn = find( IntervalFitness >= Temp( end-BPMCandidates+1 ) );
    for ct1 = 1 : BPMCandidates
        LookAt = DoMoreWorkOn( ct1 );

        if ( LookAt >= IntervalFrequency )
            IntervalFitness( LookAt - IntervalFrequency + 1 : LookAt - 1 ) = -1;
        end
        if ( LookAt <= (MaximumInterval - MinimumInterval + 1) - IntervalFrequency )
            IntervalFitness( LookAt + 1 : LookAt + IntervalFrequency - 1 ) = -1;
        end
    end

    displog( ProgressMsg, LFN, 'Check fitness of BPMs.' );
    doneIncrement = 10;
    doneLevel = doneIncrement;
    for i = MinimumInterval : MaximumInterval
        curDone = 100 * (i-MinimumInterval) / checkIntervalRange;
        if ( curDone > doneLevel )
            displog( ProgressMsg, LFN, sprintf( '  Fitness testing: %3.0f%% done', curDone ));
            doneLevel = doneLevel + doneIncrement;
        end
        if ( IntervalFitness( (i + 1) - MinimumInterval ) == -1 )

            Gaps = mod( Beats, i );
            ExtraGaps = Gaps + i;

            FullGaps = [ Gaps ExtraGaps ]';
            FullGaps = FullGaps(:);
            [ SortedGaps SortedIndex ] = sort( FullGaps );

            GapsFiltered = zeros( NumBeats, 1 );
            for ct1 = 1 : NumBeats
                Area = 0;

                Centre = SortedGaps( ct1 );

                Pos = ct1;
                PosVal = SortedGaps( Pos );
                while ( PosVal > Centre - HalfGapWindowSize )

                    if Pos <= 1 
                        break;
                    end
                    xPos = SortedIndex( Pos );
                    if ( xPos > size( Beats,1 ) ) 
                        xPos = xPos - size( Beats,1 );
                    end
                    Area = Area + ( BeatStrengths( xPos ) * GapWindow( PosVal - (Centre - HalfGapWindowSize) ) );
                    Pos = Pos - 1;
                    PosVal = SortedGaps( Pos );
                end

                Pos = ct1;
                PosVal = SortedGaps( Pos );
                while ( PosVal <= Centre + HalfGapWindowSize )

                    if Pos >= NumBeats
                        break;
                    end
                    xPos = SortedIndex( Pos );
                    if ( xPos > size( Beats,1 ) ) 
                        xPos = xPos - size( Beats,1 );
                    end
                    Area = Area + ( BeatStrengths( xPos ) * GapWindow( PosVal - (Centre - HalfGapWindowSize) ) );
                    Pos = Pos + 1;
                    PosVal = SortedGaps( Pos );
                end

                GapsFiltered( ct1 ) = Area;

            end

            % Need to take care of end cases better
            % Here we work out how much evidence there is to support each gap
            % by the GapFiltered value for each gap and a portion of the
            % GapFiltered value from offbeats.

            % Need to take care of end cases better
            GapsConfidence = zeros( NumBeats, 1 );
            for ct1 = 1 : NumBeats -1 

                OffbeatPos = SortedGaps( ct1 ) + round(i / 2);

                % We know the position of where an offbeat gap value would be but
                % we need to work out its index in the SortedGaps array
                Pos = ct1;
                PosVal = SortedGaps( Pos );
                while ( PosVal < OffbeatPos )
                    if Pos >= NumBeats - 1
                        break;
                    end
                    Pos = Pos + 1;
                    PosVal = SortedGaps( Pos );
                end

                % Not sure why I have this taking the average of the two nearest
                % gaps. Might give some improvement to accuracy, but most probably
                % pointless.
                OffBeatValue = ( GapsFiltered( Pos ) + GapsFiltered( Pos + 1 ) ) / 2;

                GapsConfidence( ct1 ) = GapsFiltered( ct1 ) + ( OffBeatValue * 0.5 );        
            end

            GapPeaks = SortedGaps( find( GapsConfidence == max( GapsConfidence ) ) );

            IntervalFitness( (i + 1) - MinimumInterval ) = max( GapsConfidence );
            IntervalGap( (i+1) - MinimumInterval )       = GapPeaks( 1 );

        end
    end
    displog( ProgressMsg, LFN, 'Brute forced the interval tests.' );

    % Fit a polynomial to the fitness value in order to normalise the results
    % to remove bias towards high BPMs
    Y = IntervalFitness( 1:IntervalFrequency:end );
    Range = (MinimumInterval:MaximumInterval)';
    X = Range(1:IntervalFrequency:end);
    NormalisedIntervalFitness = IntervalFitness - polyval( polyfit( X, Y, 3 ), Range );


    % Now we do a bit of calculations to find the best interval, BPM and Gap
    % value.
    FitnessIndex = find( NormalisedIntervalFitness == max( NormalisedIntervalFitness ) );

    % NOTE: the Confidence test is done relative to the other BPMs and
    % their fitness. So, counter-intuitive as it may seem, searching a tiny
    % range of BPMs will give lower confidence, since all the BPMs found
    % might be pretty good. It's sort of like you not knowing you live in a
    % hot place until you learn about other cold places, since the places
    % near you are also hot. An absolute value confidence test would be
    % great to have here, beats me how to make one... TODO
    TestConfidence = abs(max( NormalisedIntervalFitness )); % make sure it's positive
    Interval     = FitnessIndex(end) + (MinimumInterval - 1);
    GapInSamples = IntervalGap( FitnessIndex(end) );
    GapInSeconds = GapInSamples / Frequency;
    BPM = ( Frequency / Interval ) * 60;

    if ( TestConfidence < ( MinConfidence * ConfidenceScale ) )
        % check if we are doing a quick BPM test
%        if ( TestQuickBPM ~= 0 )
%            TestQuickBPM = 0;
%            displog( ImportantMsg, LFN, sprintf( 'Calculated BPM: %f', BPM ) );
%            displog( ImportantMsg, LFN, sprintf( '           Tentative gap in seconds: %f', GapInSeconds ) );
%            displog( ImportantMsg, LFN, sprintf( '           Confidence: %f (minimum is %f)', TestConfidence, MinConfidence) );
%            displog( ImportantMsg, LFN, 'Quick BPM test failed to confidently find BPM, so trying full test.' );
%        else
        if ( TestNormalBPM ~= 0 )
            % failed, and refined test will not improve things
            displog( ImportantMsg, LFN, sprintf( 'Calculated BPM: %f', BPM ) );
            displog( ImportantMsg, LFN, sprintf( '           Tentative gap in seconds: %f', GapInSeconds ) );
            displog( ImportantMsg, LFN, sprintf( '           Confidence: %f (minimum is %f)', TestConfidence, MinConfidence) );
            displog( ImportantMsg, LFN, 'FAILURE: Unable to confidently find BPM, so steps not created. Use "-c #" option to lower confidence minimum.' );
            TestNormalBPM = 0;
            TestRefinedBPM = 0;
        else
            % refined attempt - don't worry about failure, we're refining
            % success
            TestRefinedBPM = 0;
        end
    else
        % Success, so finish test and refine if desired.
        % Note that confidence can actually fall on the refined test, so we
        % save the best one here.
        BPMfailure = 0;
        if ( Confidence < TestConfidence )
            Confidence = TestConfidence;
        end
%         if ( TestQuickBPM ~= 0 )
%             TestQuickBPM = 0;
%             TestNormalBPM = 0;
%         else
        if ( TestNormalBPM ~= 0 )
            TestNormalBPM = 0;
        else
            % refined attempt
            TestRefinedBPM = 0;
        end
    end

% end of loop to test BPM
end

% Did we really fail? Then go to next song.
if ( BPMfailure == 1 )
    continue;
end

% Calculate the energy of each beat. It is simply the sum of the squared
% values of each sample in the waveform.
Position = round( GapInSamples ); 
WindowNum = 1;
AbsoluteEnergy = [];
% unused: Energy = [];
while ( Position + Interval < SongLength )
    
    Window = Mono( Position:(Position+round(Interval/2))-1 );
    AbsoluteEnergy( WindowNum ) = sum( Window .^ 2 );
    WindowNum = WindowNum + 1;
    
    Window = Mono( (Position+round(Interval/2)):(Position+Interval) );
    AbsoluteEnergy( WindowNum ) = sum( Window .^ 2 );
    WindowNum = WindowNum + 1;
    
    Position = Position + Interval;
end

clear Mono Window;

Energy = AbsoluteEnergy ./ max( AbsoluteEnergy );
displog( ProgressMsg, LFN, 'Calculated Energy.' );
% bar( Energy, 'r' );


% If the offbeats consistently have more energy than the beats themselves
% we have probably incorrectly computed the gap value. Shift the gap by
% half a beat.
if ( mean( Energy( 2:2:end ) ) > mean( Energy( 1:2:end ) ) + 0.001 )
    displog( ProgressMsg, LFN, ' *** Shift gap half beat out ***' );
    
    GapInSamples = GapInSamples + round(Interval / 2);
    %GapInSeconds = GapInSamples / Frequency;
    Energy = Energy(2:end);
    
end


% Now compute a matrix of the similarity of each half beat to every other
% half beat.
BeatData = Energy;
SizeBeatData = size( BeatData, 2 );

SelfSimilarity = zeros(  SizeBeatData  );
for ct1 = 1 : SizeBeatData
    for ct2 = ct1 : SizeBeatData
        SelfSimilarity( ct1, ct2 ) = 1 - ( sqrt( sum( (BeatData( :, ct1 ) - BeatData( :, ct2 )).^2 ) ) / sqrt( size( BeatData, 1 ) ) );
        SelfSimilarity( ct2, ct1 ) = SelfSimilarity( ct1, ct2 );
    end
end
displog( ProgressMsg, LFN, 'Computed Self Similarity.' );


% Now try and divide the music in bars of four notes. This requires picking
% the best position to start the division of bars. This is found by
% computing a self-similarity matrix for each possible bar start and taking
% the sharpest image.
%X = 1;
PossibleBarStarts = zeros( BarSize, 1 );
BarSimilarities = [];
BarSizeInHalfBeats = BarSize * 2;
for FirstBarStart = 1 : 1 :  BarSizeInHalfBeats
    
    BarSimilarity = zeros( ceil( (SizeBeatData - ( BarSizeInHalfBeats - 1) - (BarSizeInHalfBeats-1)) / BarSizeInHalfBeats ) ); 
    %Num1 = 1;
    %Num2 = 1;
    
    % Produce self-similarity matrix.
    for ct1 = 1 : size( BarSimilarity, 1 )
        for ct2 = 1 : size( BarSimilarity, 2 )
            Pos1 = FirstBarStart + (ct1-1)*BarSizeInHalfBeats;
            Pos2 = FirstBarStart + (ct2-1)*BarSizeInHalfBeats;
            
            BarSimilarity( ct1, ct2 ) = mean( diag( SelfSimilarity( Pos1:Pos1 + ( BarSizeInHalfBeats - 1), ...
                Pos2:Pos2 + ( BarSizeInHalfBeats - 1) ) ) );
            BarSimilarity( ct2, ct1 ) = BarSimilarity( ct1, ct2 );
        end
    end
    
    % Compute the 'sharpness' as a measure of the mean difference between
    % the similarity of adjacent bars.
    BarSimilarity( 1, 1 ) = 0;
    BarSimilarities( :, :, FirstBarStart ) = BarSimilarity;
    Temp = BarSimilarity( 3:end-2, 3:end-2 );
    Temp = abs( diff( Temp ) );
    PossibleBarStarts( FirstBarStart ) = mean( Temp(:) );
end

clear SelfSimilarity;

% Now pick the best bar start. If it is on an offbeat, choose the next beat
% as the correct bar start.
BestBarStarts = find( PossibleBarStarts == max( PossibleBarStarts ) );
if ( numel(BestBarStarts) > 0 )
    BarStart = BestBarStarts(1);
else
    % This music is pretty defective, there's no best bar start! At least
    % don't crash.
    BarStart = 1;
end
if ( mod( BarStart, 2 ) == 0 )
    BarStart = mod( BarStart + 1, BarSize );
end

BarSimilarity = BarSimilarities( :, :, BarStart );
displog( ProgressMsg, LFN, 'Calculated Bar Similarity.' );

% Now we know when the first bar occurs we can shift the Gap values,
% Similarity, Energy data etc to start at that point.
GapInSamples = GapInSamples + ((BarStart - 1)/2)*Interval;
GapInSeconds = GapInSamples / Frequency;
Energy = Energy( BarStart:end );
AbsoluteEnergy = AbsoluteEnergy( BarStart:end );
%BeatData = BeatData( BarStart:end, BarStart:end );

displog( ImportantMsg, LFN, sprintf( 'Calculated BPM: %f', BPM ) );
displog( ImportantMsg, LFN, sprintf( '           Gap in seconds: %f', GapInSeconds ) );
displog( ImportantMsg, LFN, sprintf( '           Confidence: %f (minimum is %f)', Confidence, MinConfidence) );

% if computing BPM and gap only, skip the rest (output, etc.)
if ( CommandBPMonly == 1 )
    continue;
end


% Now we want to use the self-similarity matrix of bars to compute a linear
% grouping of the music. First we find all the maximal cliques of similar
% bars and then use a greedy algorithm to choose a linear combination of
% these.

% Threshold the self-similarity matrix
Z = BarSimilarity;
Z(1,1) = 1;
Z( Z > 0.90 ) = 1;
Z( Z < 1 ) = 0;

% Find the maximalcliques
Y = maximalcliques( Z );

% Place the returned cliques into a matrix representation
X = [];
CurrentMax = 0;
for ct1 = 1 : size( Y, 2 )
    ThisClique = Y{ct1};
    CliqueSize = size( ThisClique, 2 );
    if ( CurrentMax < CliqueSize  )
        CurrentMax = CliqueSize;
    end
    
    X( ct1, 1:CurrentMax ) = [ ThisClique zeros( 1, CurrentMax - CliqueSize ) ];
end

% Greedily choose the biggest cliques. We make sure cliques whoch are very
% large are not chosen in order to keep the grouping interesting.
SimilarSections = zeros( size( BarSimilarity, 2), 1 );
NextSection = 1;
X2 = X;
while( any( X2(:) ~= 0 ) )
    [ Junk, Index ] = sort( sum( X2 ~= 0, 2 ) );

    % Find the biggest clique, which is not too big
    ct1 = 0;
    i = Index( end );
    SelectedClique = X2( i, : );
    % check if clique is too large, and it's not the only clique left
    % (NOTE: code was "> 0", but this causes blowup on doing "Index(0)" below
    while( (sum(SelectedClique ~= 0 ) > size( BarSimilarity, 2) * 0.5) && (size(Index, 1)-ct1 > 1) )
        displog( ProgressMsg, LFN, 'Ignoring a too large clique.' );
        ct1 = ct1 + 1;
        i = Index( end - ct1 );
        SelectedClique = X2( i, : );
    end
    
    % Break out of the loop if only single element cliques are left.
    if ( sum(SelectedClique ~= 0 ) <= 1 )
        break;    
    end
    
    SimilarSections( SelectedClique( SelectedClique ~= 0 ) ) = NextSection;
    NextSection = NextSection + 1;

    % Remove the chosen elements from any remaining cliques
    for ct1 = 1 : size( SelectedClique, 2 )
        NodeInClique = SelectedClique( ct1 );
        X2( X2 == NodeInClique ) = 0;          
    end
end

% Now give any remaining bars their own sections.
Next = max( SimilarSections ) + 1;
for ct1 = 1 : size( SimilarSections, 1 )
    if ( SimilarSections( ct1 ) == 0 )
        SimilarSections( ct1 ) = Next;
        Next = Next + 1;
    end
end

% For each beat we store which section it is in.
SimilarityOnBeats = zeros( size( Energy, 2 ) );
for ct1 = 1 : size( SimilarSections, 1 )
    Range = ( 1 + (ct1 - 1)*BarSizeInHalfBeats : 1 + (ct1*BarSizeInHalfBeats) -1 );
    SimilarityOnBeats( Range ) = SimilarSections( ct1 );
end
displog( ProgressMsg, LFN, 'Divided song into groups.' );


% Extract pauses from the music. Simply find bars which are very quiet.
PauseThreshold = 150;
Temp = find( AbsoluteEnergy >= PauseThreshold );
% TODO: if all music is "too quiet", shouldn't we boost it up instead?
if ( numel(Temp) == 0 )
    displog( ImportantMsg, LFN, 'ERROR: all music is too quiet.' );
    continue;
end
FirstMajorEnergy  = Temp(1);
LastMajorEnergy = Temp(end);
Pauses = [];

for ct1 = 1 : size( BarSimilarity, 1 )
    Range = ( 1 + (ct1 - 1)*BarSizeInHalfBeats : 1 + (ct1*BarSizeInHalfBeats) -1 );
    BarAbsoluteEnergy = AbsoluteEnergy( Range );

    if ( prctile( BarAbsoluteEnergy, 65 ) < PauseThreshold && Range(1) > FirstMajorEnergy && Range(end) < LastMajorEnergy )
        Pauses = [ Pauses ; [ ((Range(1)-1)/2)-1, BarSize * (Interval / Frequency ) ] ];        
    end
end
displog( ProgressMsg, LFN, 'Found pauses.' );


% Find good positions for freeze arrows. This is done by finding areas in
% the song with no large onsets.
Z = SmoothedData ./ max( SmoothedData );
A = gradient( Z );

clear SmoothedData;

Freezes = [];
FreezeStarted = 0;
for ct1 = FirstMajorEnergy : LastMajorEnergy
    WaveformStart = round( GapInSamples + ((ct1 - 1)/2)*Interval );
    WaveformEnd   = round( GapInSamples + ((ct1)/2)*Interval - 1 );    
    
    % don't know what this next line does, but don't dare change the & to && as it will fail
    if ( ~isempty( Pauses ) & any( ( ((Pauses( :, 1 )+1).*2)+1  <= ct1  ) & ( ((Pauses( :, 1 )+1).*2)+BarSizeInHalfBeats+1  >= ct1 ) ) )
        FreezeStarted = 0;
        continue;
    end
    
    if ( max( A(WaveformStart:WaveformEnd) ) < 8e-5 && AbsoluteEnergy( ct1 ) < 3000 && AbsoluteEnergy( ct1 ) > 0 )
        if ( FreezeStarted == 0 )
            FreezeStarted = ( floor( ct1 / 2 ) * 2 ) - 1;
        end
    else
        if ( FreezeStarted > 0 )
            if ( FreezeStarted < ct1-6 )
                FreezeEnd = ct1;
                if ( mod( FreezeEnd, 2 ) == 0 )
                    FreezeEnd = FreezeEnd - 1;    
                end
                Freezes = [ Freezes ; FreezeStarted FreezeEnd ];
            end
        end
        FreezeStarted = 0;
    end
end

% Freezes longer than 8 half beats we deal with after placing the rest of
% the arrows.
LongFreezes = [];
FreezeBeats = zeros( size( Energy ) );
for ct1 = 1 : size( Freezes, 1 )
    if ( Freezes( ct1, 2 ) - Freezes( ct1, 1 ) < 8 )
        FreezeBeats( Freezes( ct1, 1 ):Freezes( ct1, 2 ) ) = 1;
    else
        LongFreezes = [ LongFreezes ; Freezes( ct1, 1 ), Freezes( ct1, 2 ) ];           
    end
end
displog( ProgressMsg, LFN, 'Found freeze arrow positions.' );


% Here the patterns of arrows are created.

% Set variables which do not change when generating each set of arrows
SongLengthInSeconds = SongLength / 44100;
DifficultyOffbeatModifier = [ 0 0 0 0.2 0.5 0.6 0.7 0.8 0.9 ];
% Karl's original numbers, meant for songs of 100 seconds duration
DifficultyRatings = [ 107 137 170 194 228 262 305 366 ];
MaxDifficultyRating = 420;
% change difficulty ratings to be in terms of feet per second;
% code from Robert McCarthy
DifficultyRatings = DifficultyRatings * SongLengthInSeconds / 100;
MaxDifficultyRating = MaxDifficultyRating * SongLengthInSeconds / 100;
% unused: NumBars = size( BarSimilarity, 2 );


% The Allowable moves matrix stores which arrows can be placed depending
% on the position of the players feet and which foot they will move next.
AllowableMoves = [];
%                            [    Left    ] [   Right   ] [ Index  ]
AllowableMoves( :, :, 1 )  = [ 1  1  1  0  ; 0  1  1  1  ; 1 0 0 2 ];
AllowableMoves( :, :, 2 )  = [ 1  1  1  0  ; .1 1  0  1  ; 0 0 1 2 ];
AllowableMoves( :, :, 3 )  = [ 1  1  0  .1 ; 0  1  1  1  ; 1 0 2 0 ];
AllowableMoves( :, :, 4 )  = [ 1  1  1  0  ; .1 0  1  1  ; 0 1 0 2 ];
AllowableMoves( :, :, 5 )  = [ 1  0  1  .1 ; 0  1  1  1  ; 1 2 0 0 ];
AllowableMoves( :, :, 6 )  = [ 1  1  0  .1 ; .1 0  1  1  ; 0 1 2 0 ];
AllowableMoves( :, :, 7 )  = [ 1  0  1  .1 ; .1 1  0  1  ; 0 2 1 0 ];
AllowableMoves( :, :, 8 )  = [ 1  0  1  0  ; 0  1  0  0  ; 0 2 0 1 ];
AllowableMoves( :, :, 9 )  = [ 1  1  0  0  ; 0  0  1  0  ; 0 0 2 1 ];
AllowableMoves( :, :, 10 ) = [ 0  0  1  0  ; 0  1  0  1  ; 2 0 1 0 ];
AllowableMoves( :, :, 11 ) = [ 0  0  1  0  ; 0  0  1  1  ; 2 1 0 0 ];


%EnergyDiff = diff( AbsoluteEnergy );
%EnergyDiff = [ 0 EnergyDiff ];

ArrowTrackSize = size( BarSimilarity, 1 ) * MaxArrowsPerBar;
ArrowTracks = [];
FootRatings = [];

% For each of the three difficulty levels we will produce arrows for.
for ArrowSet = 1 : 3
    UserDifficultyRating = ChosenDifficultyRatings( ArrowSet );
    
    OffbeatModifier = DifficultyOffbeatModifier( UserDifficultyRating );
    % TODO. This is a little peculiar: make an array that's the average of
    % the difficulty rating and the previous rating and then grab the
    % number generated. Why? Why not just have arrows per level, period?
    AvgArrowsPerLevel = mean( [ DifficultyRatings MaxDifficultyRating ; 0 DifficultyRatings ] );
    
    NumArrows = AvgArrowsPerLevel( UserDifficultyRating );
    % unused: ArrowsPerBar = NumArrows / NumBars;
    ModdedEnergy = Energy;
    ModdedEnergy( 2:2:end ) = ModdedEnergy( 2:2:end ) .* OffbeatModifier;
    
    % Work out the spread of the arrows based on energy of each bar of
    % music.
    FullBarEnergy = [];
    for ct1 = 1 : size( BarSimilarity, 1 )
        Range = ( 1 + (ct1 - 1)*BarSizeInHalfBeats : 1 + (ct1*BarSizeInHalfBeats) -1 );
        FullBarEnergy(ct1) = mean( ModdedEnergy( Range ) );
    end
    
    % Normalise this and ensure each bar does not have too many or too few
    % arrows.
    for ct0 = 1 : 10
        FullBarEnergy = FullBarEnergy ./ ( sum( FullBarEnergy ) / NumArrows );
        
        for ct1 = 3 : size( BarSimilarity, 1 )
            if ( all( round( FullBarEnergy( ct1-2:ct1 ) ) < 1 ) ) 
                FullBarEnergy(ct1) = 1;
            end
            if ( all( round( FullBarEnergy( ct1-2:ct1 ) ) >= 7 ) ) 
                FullBarEnergy(ct1) = 6;
            end
            if ( round( FullBarEnergy( ct1 ) ) > 8 )
                FullBarEnergy(ct1) = 8;    
            end
        end
        
    end
       
    ArrowTrack = zeros( ArrowTrackSize, 4 );
    
    JumpThreshold = 0.95 - ( UserDifficultyRating * 0.03 );
    
    %  For each group we have, compute an arrow pattern for that group
    SectionArrowData = zeros( BarSizeInHalfBeats, 4,  max( SimilarSections ) ) - 1;
    for ct1 = 1 : max( SimilarSections )
        CurrentFoot = 0;
        FootPlacement = [ 1 0 0 2 ];
        
        % work out average energy and number of notes per bar in this
        % section
        TempModdedEnergy = ModdedEnergy( SimilarityOnBeats == ct1 );
        TempEnergy = Energy( SimilarityOnBeats == ct1 );
        TempFreezes = FreezeBeats( SimilarityOnBeats == ct1 );
        
        BarModdedEnergy = zeros( BarSizeInHalfBeats, 1 );
        BarEnergy = zeros( BarSizeInHalfBeats, 1 );
        for ct2 = 1 : BarSizeInHalfBeats
            BarModdedEnergy( ct2 ) = mean( TempModdedEnergy( ct2:BarSizeInHalfBeats:end ) );
            BarEnergy( ct2 ) = mean( TempEnergy( ct2:BarSizeInHalfBeats:end ) );
            BarFreezes( ct2 ) = mean( TempFreezes( ct2:BarSizeInHalfBeats:end ) );
        end
        
        NumArrows = round( mean( FullBarEnergy( SimilarSections == ct1 ) ) );
        PlaceArrow = zeros( BarSizeInHalfBeats, 1 );
        NumArrowsToHave = min( NumArrows, sum( BarModdedEnergy > 0 ) );
        [ Temp Index ] = sort( BarModdedEnergy );
        PlaceArrow( Index( end - (NumArrowsToHave - 1):end ) ) = 1;
        
        % Now compute the arrows for that group
        FreezeOn = false;
        PrevBeatEnergy = 0.4;
        BarArrows = zeros( BarSizeInHalfBeats, 4 );
        for ct2 = 1 : BarSizeInHalfBeats
            if ( ~FreezeOn && BarFreezes( ct2 ) >= 0.5 )
                    FreezeOn = true;
                
                    if ( CurrentFoot == 0 )
                        % Place a left or right arrow to get started.
                        CurrentFoot = ceil(rand(1) * 2); 
                        if ( CurrentFoot == 1 )
                            ArrowType = 1;   
                        else
                            ArrowType = 4;
                        end
                    else      
                        % Find allowable moves pattern for current foot
                        % placement.
                        CurrentFoot = mod( CurrentFoot, 2 ) + 1;

                        PossibleMoves = [ 0 0 0 0 ];
                        for ct3 = 1 : size( AllowableMoves, 3 )
                            if ( AllowableMoves( 3, :, ct3 ) == FootPlacement )
                                PossibleMoves = AllowableMoves( CurrentFoot, :, ct3 );
                            end
                        end
                        
                        if ( PossibleMoves == [ 0 0 0 0 ] )
                            displog( ImportantMsg, LFN, 'ERROR: no possible moves found.' );
                            ErrorFound = 1;
                            ct2 = BarSizeInHalfBeats;
                            ct1 = max( SimilarSections );
                            ArrowSet = 3;
                            continue;
                        end
                        
                        % Calculate Probabilities of new move.
                        ProbMoves = cumsum( PossibleMoves ./ sum( PossibleMoves ) );
                        
                        % Choose arrow based on probabilities
                        Temp = find( ProbMoves >= rand(1) );
                        ArrowType = Temp(1);
                        
                    end
                    
                    NewArrow = [ 0 0 0 0 ];
                    NewArrow( ArrowType ) = 2;
                    BarArrows( ct2, : ) = NewArrow;
                    
                    FootPlacement( FootPlacement == CurrentFoot ) = 0;
                    FootPlacement( NewArrow > 0 ) = CurrentFoot;
                    
                    FreezeArrow = ArrowType;
                    
             elseif ( FreezeOn && mod( ct2, 2 ) == 1 && ( BarFreezes( ct2 ) < 0.5  || ct2 == BarSizeInHalfBeats-1 ) )
                 
                    FreezeOn = false;
                    NewArrow = [ 0 0 0 0 ];
                    NewArrow( FreezeArrow ) = 3;
                    BarArrows( ct2, : ) = NewArrow;
                 
             elseif ( PlaceArrow( ct2 ) == 1 && ~( FreezeOn && ( mod(ct2,2) == 0 || UserDifficultyRating <= 3 || (UserDifficultyRating <= 6 && mod( ct2, 4 ) == 1) ) ) )
                if ( ~FreezeOn && (BarEnergy(ct2) > PrevBeatEnergy + 0.2) && (BarEnergy(ct2) > JumpThreshold) && mod( ct2, 2 ) == 1 )  %%%% IMPROVE JUMP SELECTION STUFF %%%%
                    % A lot of energy so place a double jump

                    JumpType = ceil( rand(1) * 6 );
                    switch( JumpType )
                        case 1
                            BarArrows( ct2, : ) = [ 0 1 1 0 ];
                            % For this double jump foot placement
                            % depends on the previous foot placement.
                            if ( FootPlacement( 3 ) == 1 || FootPlacement( 2 ) == 2 )
                                FootPlacement = [ 0 1 2 0 ];
                            else
                                FootPlacement = [ 0 2 1 0 ];
                            end
                        case 2
                            BarArrows( ct2, : ) = [ 1 0 0 1 ];
                            FootPlacement = [ 1 0 0 2 ];
                        case 3
                            BarArrows( ct2, : ) = [ 1 1 0 0 ];
                            FootPlacement = [ 1 2 0 0 ];
                        case 4
                            BarArrows( ct2, : ) = [ 0 0 1 1 ];
                            FootPlacement = [ 0 0 1 2 ];
                        case 5
                            BarArrows( ct2, : ) = [ 1 0 1 0 ];
                            FootPlacement = [ 1 0 2 0 ];
                        case 6
                            BarArrows( ct2, : ) = [ 0 1 0 1 ];
                            FootPlacement = [ 0 1 0 2 ];
                    end
                    CurrentFoot = 0;
                else
                    % Place a normal arrow.
                    if ( CurrentFoot == 0 )
                        % Place a left or right arrow to get started.
                        CurrentFoot = ceil(rand(1) * 2); %%%%%%% FIX RAND %%%%%
                        if ( CurrentFoot == 1 )
                            ArrowType = 1;   
                        else
                            ArrowType = 4;
                        end
                    elseif ( CurrentFoot > 0 && ct2 > 1 && abs( BarEnergy( ct2-1 ) - BarEnergy( ct2 ) ) < 0.02 )    
                        % Place the same arrow as last time, and
                        % keeps the same current foot as last time.
                        
                        % Leave Current Foot and Arrow Type unchanged.
                    else      
                        % Find allowable moves pattern for current foot
                        % placement.
                        CurrentFoot = mod( CurrentFoot, 2 ) + 1;

                        PossibleMoves = [ 0 0 0 0 ];
                        for ct3 = 1 : size( AllowableMoves, 3 )
                            if ( AllowableMoves( 3, :, ct3 ) == FootPlacement )
                                PossibleMoves = AllowableMoves( CurrentFoot, :, ct3 );
                            end
                        end
                        
                        if ( PossibleMoves == [ 0 0 0 0 ] )
                            displog( ImportantMsg, LFN, 'ERROR: No possible moves found.' );    
                            ErrorFound = 1;
                            ct2 = BarSizeInHalfBeats;
                            ct1 = max( SimilarSections );
                            ArrowSet = 3;
                            continue;
                        end
                        
                        % Calculate Probabilities of new move.
                        ProbMoves = cumsum( PossibleMoves ./ sum( PossibleMoves ) );
                        
                        % Choose arrow based on probabilities
                        Temp = find( ProbMoves >= rand(1) );
                        ArrowType = Temp(1);
                        
                    end
                    
                    NewArrow = [ 0 0 0 0 ];
                    NewArrow( ArrowType ) = 1;
                    BarArrows( ct2, : ) = NewArrow;
                    
                    FootPlacement( FootPlacement == CurrentFoot ) = 0;
                    FootPlacement( NewArrow > 0 ) = CurrentFoot;
                    
                end
            end
            
            if ( mod( ct2, 2 ) == 1 )
                PrevBeatEnergy = BarEnergy( ct2 );    
            end
        end % ct2
        if ( ErrorFound )
            continue;
        end
        
        SectionArrowData( :, :, ct1 ) = BarArrows;        
    end % ct1
    if ( ErrorFound )
        continue;
    end
    
    
    
    
    FreezeOn = false;
    FreezeArrow = -1;
    for ct1 = 1 : size( BarSimilarity, 1 )
        % This section has already had its arrows chosen, so just repeat
        % them but with subtle modifications, eg. swap left/right or
        % up/down.
        BarSection = SimilarSections( ct1 );
        ArrowIndex = (((1 + (ct1 - 1)*BarSizeInHalfBeats)-1)*(MaxArrowsPerBar/BarSizeInHalfBeats))+1;
        
        
        % First check if we should have a pause here, if so write out -1
        % for arrows instead
        if ( ~isempty( Pauses ) && any( Pauses( :, 1 )  + 2 == ((ct1-1)*BarSize)+1 ) )
            BarArrows( :, : ) = -1;    
        else
            
            % No pause so use data from sections
            if ( ct1 > 1 && SimilarSections( ct1 - 1 ) == BarSection )
                % Last bar was in the same section so alter the repeated arrows
                ChangeLeftRightProbability = 0.5;
                ChangeUpDownProbability = 0.5;
            else
                % Last bar was a different section so make in unlikely that the repeated arrows will be changed.
                ChangeLeftRightProbability = 0.00;
                ChangeUpDownProbability = 0.00;
            end
            
            BarArrows = SectionArrowData( :, :, BarSection );
            if ( rand(1) > ChangeLeftRightProbability )
                % Swap left and right arrows            
                Temp = BarArrows( :, 1 );
                BarArrows( :, 1 ) = BarArrows( :, 4 ); 
                BarArrows( :, 4 ) = Temp;
            end
            if ( rand(1) > ChangeUpDownProbability )
                % Swap up and down arrows            
                Temp = BarArrows( :, 2 );
                BarArrows( :, 2 ) = BarArrows( :, 3 ); 
                BarArrows( :, 3 ) = Temp;
            end
            
        end
        
        % Freeze arrow stuff
        if ( ~isempty( LongFreezes ))
            for ct2 = 1 : BarSizeInHalfBeats
                CurrentBeat = ( (ct1-1)*BarSizeInHalfBeats ) + ct2;
                
                if ( FreezeOn )
                    % Stop other arrows while freeze arrow going past.
                    if ( UserDifficultyRating <= 3 )
                        BarArrows( ct2, : ) = 0;    
                    end
                    if ( UserDifficultyRating <= 6 && mod( CurrentBeat, 4 ) == 1 )
                        BarArrows( ct2, : ) = 0;    
                    end
                    if ( mod( CurrentBeat, 2 ) == 0 )
                        BarArrows( ct2, : ) = 0;    
                    end
                    
                    % Stop any jumps occuring
                    if ( sum( BarArrows( ct2, : ) > 0 ) > 1 )
                        BarArrows( ct2, : ) = 0;    
                    end
                end
                if ( any( LongFreezes( :, 2 ) == CurrentBeat ) && FreezeOn )
                    BarArrows( ct2, FreezeArrow ) = 3;
                    FreezeOn = false;
                    FreezeArrow = -1;
                end
                if ( any( LongFreezes( :, 1 ) == CurrentBeat ) && ~FreezeOn )
                    FreezeOn = true;
                    FreezeArrow = ceil( rand(1) * 4 );
                    Temp = BarArrows( ct2, : );
                    Temp( Temp == 1 ) = 0;
                    BarArrows( ct2, : ) = Temp;
                    BarArrows( ct2, FreezeArrow ) = 2;
                end
            end 
        end
        
        
        for ct2 = 1 : BarSizeInHalfBeats
            Index = ArrowIndex + (ct2 - 1) * ( MaxArrowsPerBar / BarSizeInHalfBeats );    
            ArrowTrack( Index, : ) = BarArrows( ct2, : );
        end
        
    end
        
    for ct1 = 3 : 2 : size( ArrowTrack, 1 ) - 1
        % If this is a jump
        if ( sum( ArrowTrack( ct1, : ) == 1 ) > 1 )
            % remove any offbeats around it
            ArrowTrack( ct1 - 1, : ) = 0;
            ArrowTrack( ct1 + 1, : ) = 0;
        end
    end
    
    NumArrows = sum( ArrowTrack(:) > 0 );
    % TODO: if NumArrows gets modified, so should difficulty rating
    % TODO: if FootRating is 0 or less, do something... (happens on
    % Blitzkrieg Bop, for instance)
    FootRating = 9 - sum( DifficultyRatings > NumArrows );
    displog( NonvitalMsg, LFN, [ 'Foot Rating: ' int2str( FootRating ) ] );
    
    FootRatings( ArrowSet ) = FootRating;
    ArrowTracks( :, :, ArrowSet ) = ArrowTrack;
    
end
clear BarSimilarity;

if ( ErrorFound )
    continue;
end

displog( ProgressMsg, LFN, 'Created arrow patterns for each difficulty level.' );


% first check if we shouldn't output at all
if ( ~ isempty( Pauses ) )
    % delete on too many pauses?
    if ( CommandMaxStopsDelete >= 0 && size( Pauses, 1 ) > CommandMaxStopsDelete )
        displog( ImportantMsg, LFN, sprintf( 'FAILURE: %d stops found, above stop maximum of %d, so steps not created.', size( Pauses, 1 ), CommandMaxStopsDelete ) );
        continue;
    end
end

% Create Output Directory
%kmkdir( RootOutputDirectory, MusicFileName );
[status,mkdirmess,messid] = kmkdir( RootOutputDirectory, MusicFileName );
displog( ProgressMsg, LFN, sprintf('Created output song directory %s.', fullfile(RootOutputDirectory, MusicFileName)));

if ( status ~= 1 )
    % yes, really die on this error
    error( 'ERROR: cannot create ''%s'' directory at ''%s''. \nUse double-quotes around infile and outdirectory.\nUsage: DancingMonkeys "infile" 3 5 8 "outdirectory"\ninfile can also be a directory.', MusicFileName, RootOutputDirectory);
end

if ( CommandWriteFormat == 0 )
    CommandWriteWav = 0;
elseif ( CommandWriteFormat == 1 )
    CommandWriteWav = 1;
else
    CommandWriteWav = strcmpi( MusicFileExt, '.wav' );
end

if ( CommandWriteWav )
    % WAV is final output
    OutputFile = [ MusicFileName '.wav' ];
    OutputFullFilename = fullfile( OutputDirectory, OutputFile );
    WavWriteFile = OutputFullFilename;
else
    % MP3 is final output, so write temp WAV file and convert
    OutputFile = [ MusicFileName '.mp3' ];
    OutputFullFilename = fullfile( OutputDirectory, OutputFile );
    WavWriteFile = TempWavFile;
end

if ( CommandBPMonly == 0 )
    % Output the new normalized, possibly shorter song to the StepMania or DWI songs directory
    wavwrite( SongData, Frequency, NumBits, WavWriteFile );
    clear SongData;
    if ( CommandWriteWav )
        OutputFullFilename = WavWriteFile;
    else
        % convert WAV to MP3
        LastDirectory = cd;
        cd( LamePath );

        % get options
        SongMP3Title = SongTitle;
        % TODO: songs like Blitzkrieg Bop have a comment string that LAME
        % doesn't like. Maybe it's too long? Anyway, removed.
        %if ( size(SongComment) > 0 )
        %    TempString = strrep( SongComment, '"', '\"' );
        %    MP3Comment = [ TempString ' ; Dancing Monkeys v' VersionNumber ];
        %else
            MP3Comment = [ 'Dancing Monkeys v' VersionNumber ];
        %end
        if ( OutputTrimmed )
            SongMP3Title = [ SongMP3Title ' (DDR)' ];
            MP3Comment = [ MP3Comment ' trim' ];
        end
        % escape all quotes
        TempString = strrep( SongMP3Title, '"', '\"' );
        TempString1 = strrep( SongArtist, '"', '\"' );
        TempString2 = strrep( MP3Comment, '"', '\"' );
        MP3options = [ '--tt "' TempString '" --ta "' TempString1 '" --tc "' TempString2 '"' ];
        if ( size(SongAlbum) > 0 )
            TempString = strrep( SongAlbum, '"', '\"' );
            MP3options = [ MP3options ' --tl "' TempString '"' ];
        end
        if ( size(SongYear) > 0 )
            % should never happen, but...
            TempString = strrep( SongYear, '"', '\"' );
            MP3options = [ MP3options ' --ty "' TempString '"' ];
        end
        if ( size(SongTrack) > 0 )
            MP3options = [ MP3options ' --tn "' SongTrack '"' ];
        end
        % LAME really wants a number here, some MP3's just have a text string
        if ( size(SongGenre) > 0 )
            SongGenreID = sscanf( '%d', SongGenre );
            if ( SongGenreID == 0 )
                SongGenreID = sscanf( '(%d)', SongGenre );
            end
            if ( SongGenreID > 0 )
                MP3options = [ MP3options ' --tg "' SongGenre '"' ];
            end
        end
        % get Results so it doesn't spew on the screen
        [ Status Results ] = dos( [ 'Lame ' MP3options ' -h "' WavWriteFile '" "' OutputFullFilename '"' ] );

        if ( Status ~= 0 )
            % try again, but without options
            [ Status Results ] = dos( [ 'Lame -h "' WavWriteFile '" "' OutputFullFilename '"' ] );
            if ( Status ~= 0 )
                cd( LastDirectory );
                displog( ImportantMsg, LFN, Results );
                displog( ImportantMsg, LFN, sprintf('ERROR: conversion of WAV to MP3 %s failed. Try the -n option.',OutputFullFilename) );
                continue;
            end
            cd( LastDirectory );
            displog( NonvitalMsg, LFN, 'WARNING: attempted to use MP3 ID3 tags (title, artist), but WAV to MP3 conversion fails with them.');
            displog( NonvitalMsg, LFN, '         Converted to MP3 file without exporting these tags.');
        end
        % TODO: this conversion to MP3 may add a 50 millisecond shift to the
        % gap. We could try to readjust by converting back to WAV yet again and
        % reading in this new file.

        cd( LastDirectory );
        displog( ProgressMsg, LFN, 'Converted output song to MP3.' );
    end

    if ( OutputTrimmed )
        displog( ProgressMsg, LFN, 'Outputted truncated normalized song.' );
    else
        displog( ProgressMsg, LFN, 'Outputted normalized song.' );
    end
end

% Now we need to output the arrow track to a step file.

% Output step file in .dwi format
displog( NonvitalMsg, LFN, sprintf( 'Output directory: %s', OutputDirectory ) );
fid = fopen ( strcat( OutputDirectory, MusicFileName, '.dwi' ), 'wt');

fprintf( fid, '#TITLE:%s;\n', SongTitle );
fprintf( fid, '#ARTIST:%s;\n', SongArtist );
fprintf( fid, '#GAP:%f;\n', (GapInSeconds + StepFileFudgeFactor) * 1000 );
fprintf( fid, '#BPM:%f;\n', BPM );
fprintf( fid, '#FILE:%s;\n', OutputFullFilename );

% TODO: Fix DWI to use MaxArrowsPerBar

if ( ~ isempty( Pauses ) )
    fprintf( fid, '#FREEZE:' );
    for ct1 = 1 : size( Pauses, 1 )
        if ( ct1 > 1 )
            fprintf( fid, ',' );
        end
        fprintf( fid, '%d=%d', (( Pauses( ct1, 1 ) - (ct1-1)*BarSize )) * BarSize, round( Pauses( ct1, 2 )*1000 ) );
    end
    fprintf( fid, ';\n' );
end
fprintf( fid, '\n// --- Arrows ---\n');

DWIDifficultyNames = { 'BASIC', 'ANOTHER', 'MANIAC' };
for ArrowSet = 1 : 3
    FootRating = FootRatings( ArrowSet );
    ArrowTrack = ArrowTracks( :, :, ArrowSet );
    
    fprintf( fid, '#SINGLE:%s:%d:\n', DWIDifficultyNames{ ArrowSet }, FootRating );

    % Assuming MaxArrowsPerBar == 8
    for ct1 = 1 : size( ArrowTrack, 1 )
        
        if ( ArrowTrack( ct1, : ) == [ -1 -1 -1 -1 ] )
            % Don't write out any arrows as we have a pause.    
            continue;    
        end
        ThisBeat = ArrowTrack( ct1, : ) > 0;
        
        if ThisBeat == [ 0 0 0 0 ]
            Character = '0';
        elseif ThisBeat == [ 1 0 0 0 ]
            Character = '4';
        elseif ThisBeat == [ 0 1 0 0 ]
            Character = '2';
        elseif ThisBeat == [ 0 0 1 0 ]
            Character = '8';
        elseif ThisBeat == [ 0 0 0 1 ]
            Character = '6';
        elseif ThisBeat == [ 1 0 0 1 ]
            Character = 'B';
        elseif ThisBeat == [ 0 1 1 0 ]
            Character = 'A';
        elseif ThisBeat == [ 0 0 1 1 ]
            Character = '9';
        elseif ThisBeat == [ 0 1 0 1 ]
            Character = '3';
        elseif ThisBeat == [ 1 0 1 0 ]
            Character = '7';
        elseif ThisBeat == [ 1 1 0 0 ]
            Character = '1';
        end
        fprintf( fid, '%c', Character );
        
        % Freeze Arrows
        ThisBeat = ( ArrowTrack( ct1, : ) == 2 );
        if ( any( ThisBeat ) )
            if ThisBeat == [ 1 0 0 0 ]
                Character = '4';
            elseif ThisBeat == [ 0 1 0 0 ]
                Character = '2';
            elseif ThisBeat == [ 0 0 1 0 ]
                Character = '8';
            elseif ThisBeat == [ 0 0 0 1 ]
                Character = '6';
            end
            fprintf( fid, '!%c', Character );    
        end
        
    end
    fprintf( fid, ';\n\n' );
end

fclose( fid );
displog( ProgressMsg, LFN, 'Created .dwi step file.' );

% Output step file in .sm format
fid = fopen ( strcat( OutputDirectory, MusicFileName, '.sm' ), 'wt');

% Option: #CREDIT:...; - Give yourself some credit here for creating a wonderful song.
fprintf( fid, '#TITLE:%s;\n', SongTitle );
fprintf( fid, '#ARTIST:%s;\n', SongArtist );
% gap, I believe, is actually the opposite of what is documented: a
% negative gap means the music start later. TODO.
fprintf( fid, '#OFFSET:%f;\n', -( GapInSeconds + StepFileFudgeFactor ) );
fprintf( fid, '#BPMS:0=%f;\n', BPM );
fprintf( fid, '#MUSIC:%s;\n', OutputFile );
if ( size(SongCredit) > 0 )
    fprintf( fid, '#CREDIT:%s;\n', SongCredit );
end

if ( ~ isempty( Pauses ) )
    if ( size( Pauses, 1 ) > MaxPauses )
        % TODO: if we found this many stops, how about figuring out some
        % real corrective action vs. this lame "we stink" warning.
        displog( ImportantMsg, LFN, sprintf( 'WARNING: This set of steps is probably poor, as there are %d stops.', size( Pauses, 1 ) ) );
    end
    if ( CommandStops )
        fprintf( fid, '#STOPS:' );
        for ct1 = 1 : size( Pauses, 1 )
            if ( ct1 > 1 )
                fprintf( fid, ',' );
            end
            fprintf( fid, '%f=%f', (Pauses( ct1, 1 ) - (ct1-1)*BarSize), Pauses( ct1, 2 ) );
        end
        fprintf( fid, ';\n' );
    end
end
fprintf( fid, '\n// --- Arrows ---\n');

DifficultyNames = { 'Basic' 'easy' ; 'Standard' 'medium' ; 'Heavy' 'hard' };
for ArrowSet = 1 : 3
    FootRating = FootRatings( ArrowSet );
    ArrowTrack = ArrowTracks( :, :, ArrowSet );
    
    fprintf( fid, '#NOTES:\n\tdance-single:\n\t%s:\n\t%s:\n\t%d:\n\t:\n' ...
        , DifficultyNames{ ArrowSet, 1 }, DifficultyNames{ ArrowSet, 2 }, FootRating );
    
    for ct1 = 1 : size( ArrowTrack, 1 )
        
        if ( ArrowTrack( ct1, : ) == [ -1 -1 -1 -1 ] )
            % Don't write out any arrows as we have a pause.    
            continue;    
        end
        fprintf( fid, '%d%d%d%d\n', ArrowTrack( ct1, : ) );
        
        if ( mod( ct1, MaxArrowsPerBar ) == 0 )
            fprintf( fid, ',\n');
        end
    end
    
end

fclose( fid );
displog( ProgressMsg, LFN,'Created .sm step file.');


% Output image, if any found
if ( ImageSize > 0 )
    ImageOut = strcat( OutputDirectory, 'banner.', ImageType );
    Fwriteid = fopen(ImageOut,'w');
    fwrite(Fwriteid,ImageData,'uint8');
    fclose(Fwriteid);
    
    ImageOut = strcat( OutputDirectory, 'background.', ImageType );
    Fwriteid = fopen(ImageOut,'w');
    fwrite(Fwriteid,ImageData,'uint8');
    fclose(Fwriteid);
    displog( ProgressMsg, LFN, 'Created banner and background files.' );
    
    clear ImageData;
end


% Output the results to the screen.
displog( ProgressMsg, LFN, 'Results: ' );
displog( ProgressMsg, LFN, ['  Song file name: ' MusicFileName ] );
displog( ProgressMsg, LFN, sprintf('  BPM: %g', BPM) );
displog( ProgressMsg, LFN, sprintf('  Gap: %g', GapInSeconds) );
displog( ProgressMsg, LFN, sprintf('  Confidence: %g', Confidence) );

end % end of for loop for a single song

if ( CommandLog > 0 )
    % Close log file
    ClockTime = clock;
    displog( NonvitalMsg, LFN, sprintf( 'End Time: %d:%02d:%02d %d/%02d/%d (U.S. format)', ClockTime(4), ClockTime(5), floor(ClockTime(6)), ClockTime(2), ClockTime(3), ClockTime(1) ));
end   

toc;