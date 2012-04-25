% Arguments
input_file	= 'D:\Development\Sandbox\Input\smooooch.mp3';
output_dir	= 'D:\Development\Sandbox\Output\';
diff_easy	= '5';
diff_medium	= '7';
diff_hard	= '9';
duration	= '1000';

% Execute
% -onl  Do not output log info
% -l	Specify max song duration, higher than 300 goes out of memory
% -ons	No stops (DancingMonkeys' implementation is poor)
% -ob	Calculate BPM and gap only, no patterns or file output
% -x 1	Refine BPM as best as possible
DancingMonkeys_faster('-onl', '-l', duration, '-ons', '-ob', '-x', '1', input_file, diff_easy, diff_medium, diff_hard, output_dir);
