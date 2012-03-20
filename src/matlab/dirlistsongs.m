function list = dirlistsongs( msgflag, logfile, dirname )
% LIST = dirlistsongs( MSGFLAG, LOGFILE, DIRNAME );
%
% msgflag and logfile are for use by displog(). Filename is the directory
% to search for files. Returned list is a structured array with a .name
% field of the full path and filename for each song.

songcount = 0;
dircount = 0;
while ( ~strcmp( dirname, '' ) )
    MusicDir = dir( dirname );
    for MusicDirNumber = 1 : size( MusicDir )
        MusicFilename = MusicDir(MusicDirNumber).name;
        if ( strcmp(MusicFilename, '.') || strcmp(MusicFilename, '..') )
            continue;
        elseif ( MusicDir(MusicDirNumber).isdir )
            dircount = dircount + 1;
            dirlist(dircount).name = fullfile( dirname, MusicFilename );
        elseif ( size( MusicFilename, 2 ) <= 4 )
            % name's not long enough to have a suffix!
            continue;
        else
            ext = MusicFilename(end-3:end);
            if ( strcmpi( ext, '.wav') || strcmpi( ext, '.mp3') )
                songcount = songcount + 1;
                list(songcount).name = fullfile(dirname, MusicDir(MusicDirNumber).name);
            elseif ( strcmpi( ext, '.m4a'));
                displog( msgflag, logfile, sprintf('WARNING: cannot convert .m4a file %s; first convert to MP3 or WAV (e.g. right-click on file in iTunes).', fullfile(dirname, MusicDir(MusicDirNumber).name) ));
            elseif ( strcmpi( ext, '.ogg'));
                displog( msgflag, logfile, sprintf('WARNING: cannot convert .ogg file %s; first convert to MP3 or WAV.', fullfile(dirname, MusicDir(MusicDirNumber).name) ));
            elseif ( strcmpi( ext, '.wma'));
                displog( msgflag, logfile, sprintf('WARNING: cannot convert .wma file %s; first convert to MP3 or WAV.', fullfile(dirname, MusicDir(MusicDirNumber).name) ));
            end
        end
    end
    if ( dircount > 0 )
        dirname = dirlist(1).name;
        dirlist(:,1) = [];
        dircount = dircount - 1;
    else
        dirname = '';
    end
end
% There's no doubt a better way to do this... TODO
if ( songcount == 0 )
    % if there's no song found, then we need to make *something* for list
    % to return, so it exists; else error.
    list(1).name = '';
end