% Arguments
input_file	= '..\..\input\smooooch.mp3';
output_dir	= '..\..\output';
diff_easy	= '5';
diff_medium	= '7';
diff_hard	= '9';
duration	= '300';

% Execute
% -l	Specify max song duration, higher than 300 goes out of memory
% -ons	No stops (DancingMonkeys' implementation is poor)
% -x 1	Refine BPM as best as possible
DancingMonkeys('-l', duration, '-ons', '-x', '1', input_file, diff_easy, diff_medium, diff_hard, output_dir);
