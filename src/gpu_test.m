import parallel.gpu.GPUArray;

% Note: 10 is just for loading the library
% Delete the 10 data afterwards as it screws up the trends
testCounts = [
	10,
%	50,
%	100,
%	200,
%	400,
%	600,
%	800,
%	1000,
%	2000,
%	4000,
%	6000,
	8000,
	10000,
	15000,
	20000,
	25000,
	30000
];

testLength = length(testCounts);

%Input = __r.a.n.d__(rows, 1);
%Input = __GPUArray.r.a.n.d__(rows, 1);
%Input = __g.r.a.n.d__(rows, 1);


% Init test
for k = 1:testLength
	rows = testCounts(k); i = [];
	
	test = 'timeInit';
	time = tic;
	Input1 = GPUArray.rand(rows, 1);
	Input2 = GPUArray.rand(rows, 1);
	Input3 = GPUArray.rand(rows, 1);
	disp(sprintf('%s\t%i\t%f', test, rows, toc(time)))
	pause(1);
end

% Access test
for k = 1:testLength
	rows = testCounts(k); i = [];
	Input1 = GPUArray.rand(rows, 1);
	Input2 = GPUArray.rand(rows, 1);
	Input3 = GPUArray.rand(rows, 1);
	
	test = 'timeAccess';
	time = tic;
	for i = 1:rows
		pie1 = Input1(i);
		pie2 = Input2(i);
		pie3 = Input3(i);
	end
	disp(sprintf('%s\t%i\t%f', test, rows, toc(time)))
	pause(1);
end

% Assign test
for k = 1:testLength
	rows = testCounts(k); i = [];
	Input1 = GPUArray.rand(rows, 1);
	Input2 = GPUArray.rand(rows, 1);
	Input3 = GPUArray.rand(rows, 1);
	
	test = 'timeAssign';
	time = tic;
	for i = 1:rows
		Input1(i) = 1.2345;
		Input2(i) = 2.3456;
		Input3(i) = 3.4567;
	end
	disp(sprintf('%s\t%i\t%f', test, rows, toc(time)))
	pause(1);
end

% AddSub test
for k = 1:testLength
	rows = testCounts(k); i = [];
	Input1 = GPUArray.rand(rows, 1);
	Input2 = GPUArray.rand(rows, 1);
	Input3 = GPUArray.rand(rows, 1);
	
	test = 'timeAddSub';
	time = tic;
	for i = 1:rows
		pie = Input1(i) + Input2(i) - Input3(i);
	end
	disp(sprintf('%s\t%i\t%f', test, rows, toc(time)))
	pause(1);
end

% Mult test
for k = 1:testLength
	rows = testCounts(k); i = [];
	Input1 = GPUArray.rand(rows, 1);
	Input2 = GPUArray.rand(rows, 1);
	Input3 = GPUArray.rand(rows, 1);
	
	test = 'timeMult';
	time = tic;
	for i = 1:rows
		pie = Input1(i) * Input2(i) * Input3(i);
	end
	disp(sprintf('%s\t%i\t%f', test, rows, toc(time)))
	pause(1);
end

% Mod test
for k = 1:testLength
	rows = testCounts(k); i = [];
	Input1 = GPUArray.rand(rows, 1);
	Input2 = GPUArray.rand(rows, 1);
	Input3 = GPUArray.rand(rows, 1);
	
	test = 'timeMod';
	time = tic;
	for i = 1:rows
		pie1 = mod(Input1, i);
		pie2 = mod(Input2, i);
		pie3 = mod(Input3, i);
	end
	disp(sprintf('%s\t%i\t%f', test, rows, toc(time)))
	pause(1);
end

% Max test
for k = 1:testLength
	rows = testCounts(k); i = [];
	Input1 = GPUArray.rand(rows, 1);
	Input2 = GPUArray.rand(rows, 1);
	Input3 = GPUArray.rand(rows, 1);
	
	test = 'timeMax';
	time = tic;
	pie1 = max(Input1);
	pie2 = max(Input2);
	pie3 = max(Input3);
	disp(sprintf('%s\t%i\t%f', test, rows, toc(time)))
	pause(1);
end

% Sort test
for k = 1:testLength
	rows = testCounts(k); i = [];
	Input1 = GPUArray.rand(rows, 1);
	Input2 = GPUArray.rand(rows, 1);
	Input3 = GPUArray.rand(rows, 1);
	
	test = 'timeSort';
	time = tic;
	pie1 = sort(Input1);
	pie2 = sort(Input2);
	pie3 = sort(Input3);
	disp(sprintf('%s\t%i\t%f', test, rows, toc(time)))
	pause(1);
end
