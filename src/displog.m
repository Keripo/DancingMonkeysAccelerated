function displog( flags, logfile, string )
% displog(FLAGS, LOGFILE, STRING );
%
% If flags has 0x1 bit set, output to screen. If 0x2 bit set, also write to
% file. logfile is file path and name, and is always appended.

if ( bitand( flags, 1 ) )
    disp( string );
end
if ( bitand( flags, 2 ) )
    logfid = fopen ( logfile, 'at');
    fprintf( logfid, '%s\n', string );
    fclose( logfid );
end

