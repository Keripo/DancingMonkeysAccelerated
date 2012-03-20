% Arguments
input_file	= '..\..\input\smooooch.mp3';
output_dir	= '..\..\output';
diff_easy	= '5';
diff_medium	= '7';
diff_hard	= '9';

% Execute
% -n	No parsing of ID3 tags
% -ob	Calculate BPM and gap only, no patterns or file output
% -x 1	Refine BPM as best as possible
DancingMonkeys('-n', '-ob', '-x', '1', input_file, diff_easy, diff_medium, diff_hard, output_dir);
