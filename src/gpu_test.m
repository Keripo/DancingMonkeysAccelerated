rows = 4056;
cols = 1;
type = 'double';

timeInit = tic;
Input1 = ones(rows, cols, type);
Input2 = ones(rows, cols, type);
Input3 = ones(rows, cols, type);
Input4 = ones(rows, cols, type);
Input5 = ones(rows, cols, type);
disp(sprintf('timeInit   = %f', toc(timeInit)))

timeInit_g = tic;
Input1_g = parallel.gpu.GPUArray.ones(rows, cols, type);
Input2_g = parallel.gpu.GPUArray.ones(rows, cols, type);
Input3_g = parallel.gpu.GPUArray.ones(rows, cols, type);
Input4_g = parallel.gpu.GPUArray.ones(rows, cols, type);
Input5_g = parallel.gpu.GPUArray.ones(rows, cols, type);
disp(sprintf('timeInit_g = %f', toc(timeInit_g)))

timeInit_j = tic;
Input1_j = gones(rows, cols, type);
Input2_j = gones(rows, cols, type);
Input3_j = gones(rows, cols, type);
Input4_j = gones(rows, cols, type);
Input5_j = gones(rows, cols, type);
disp(sprintf('timeInit_j = %f', toc(timeInit_j)))

timeAdd = tic;
for i = 1:rows
	Input1 = Input2 + Input3 + Input4 + Input5;
end
disp(sprintf('timeAdd   = %f', toc(timeAdd)))

timeAdd_g = tic;
for i = 1:rows
	Input1_g = Input2_g + Input3_g + Input4_g + Input5_g;
end
disp(sprintf('timeAdd_g = %f', toc(timeAdd_g)))

timeAdd_j = tic;
gfor i = 1:rows
	Input1_j = Input2_j + Input3_j + Input4_j + Input5_j;
gend
disp(sprintf('timeAdd_j = %f', toc(timeAdd_j)))

timeSub = tic;
for i = 1:rows
	Input1 = Input2 - Input3 - Input4 - Input5;
end
disp(sprintf('timeSub   = %f', toc(timeSub)))

timeSub_g = tic;
for i = 1:rows
	Input1_g = Input2_g - Input3_g - Input4_g - Input5_g;
end
disp(sprintf('timeSub_g = %f', toc(timeSub_g)))

timeSub_j = tic;
gfor i = 1:rows
	Input1_j = Input2_j - Input3_j - Input4_j - Input5_j;
gend
disp(sprintf('timeSub_j = %f', toc(timeSub_j)))

timeMult = tic;
for i = 1:rows
	Input1(i) = Input2(i) * Input3(i) * Input4(i) * Input5(i);
end
disp(sprintf('timeMult   = %f', toc(timeMult)))

timeMult_g = tic;
for i = 1:rows
	Input1_g(i) = Input2_g(i) * Input3_g(i) * Input4_g(i) * Input5_g(i);
end
disp(sprintf('timeMult_g = %f', toc(timeMult_g)))

timeMult_j = tic;
gfor i = 1:rows
	Input1_j(i) = Input2_j(i) * Input3_j(i) * Input4_j(i) * Input5_j(i);
gend
disp(sprintf('timeMult_j = %f', toc(timeMult_j)))

timeAccess = tic;
for i = 1:rows
	pie = Input1(mod(i * 42 - 33, rows));
	pie = Input2(mod(i * 42 - 33, rows));
	pie = Input3(mod(i * 42 - 33, rows));
	pie = Input4(mod(i * 42 - 33, rows));
	pie = Input5(mod(i * 42 - 33, rows));
end
disp(sprintf('timeAccess   = %f', toc(timeAccess)))

timeAccess_g = tic;
for i = 1:rows
	pie = Input1_g(mod(i * 42 - 33, rows));
	pie = Input2_g(mod(i * 42 - 33, rows));
	pie = Input3_g(mod(i * 42 - 33, rows));
	pie = Input4_g(mod(i * 42 - 33, rows));
	pie = Input5_g(mod(i * 42 - 33, rows));
end
disp(sprintf('timeAccess_g = %f', toc(timeAccess_g)))

timeAccess_j = tic;
gfor i = 1:rows
	pie = Input1_j(mod(i * 42 - 33, rows));
	pie = Input2_j(mod(i * 42 - 33, rows));
	pie = Input3_j(mod(i * 42 - 33, rows));
	pie = Input4_j(mod(i * 42 - 33, rows));
	pie = Input5_j(mod(i * 42 - 33, rows));
gend
disp(sprintf('timeAccess_j = %f', toc(timeAccess_j)))

timeMax = tic;
for i = 1:rows
	Input1(5, 1) = max(Input2);
	Input2(5, 1) = max(Input3);
	Input3(5, 1) = max(Input4);
	Input4(5, 1) = max(Input5);
	Input5(5, 1) = max(Input1);
end
disp(sprintf('timeMax   = %f', toc(timeMax)))

timeMax_g = tic;
for i = 1:rows
	Input1_g(5, 1) = max(Input2_g);
	Input2_g(5, 1) = max(Input3_g);
	Input3_g(5, 1) = max(Input4_g);
	Input4_g(5, 1) = max(Input5_g);
	Input5_g(5, 1) = max(Input1_g);
end
disp(sprintf('timeMax_g = %f', toc(timeMax_g)))

timeMax_j = tic;
gfor i = 1:rows
	Input1_j(5, 1) = max(Input2_j);
	Input2_j(5, 1) = max(Input3_j);
	Input3_j(5, 1) = max(Input4_j);
	Input4_j(5, 1) = max(Input5_j);
	Input5_j(5, 1) = max(Input1_j);
gend
disp(sprintf('timeMax_j = %f', toc(timeMax_j)))

timeSort = tic;
for i = 1:rows
	InputTemp = Input1;
	Input1 = sort(Input2);
	Input2 = sort(Input3);
	Input3 = sort(Input4);
	Input4 = sort(Input5);
	Input5 = sort(InputTemp);
end
disp(sprintf('timeSort   = %f', toc(timeSort)))

timeSort_g = tic;
for i = 1:rows
	InputTemp = Input1_g;
	Input1_g = sort(Input2_g);
	Input2_g = sort(Input3_g);
	Input3_g = sort(Input4_g);
	Input4_g = sort(Input5_g);
	Input5_g = sort(InputTemp);
end
disp(sprintf('timeSort_g = %f', toc(timeSort_g)))

timeSort_j = tic;
gfor i = 1:rows
	InputTemp = Input1_j;
	Input1_j = sort(Input2_j);
	Input2_j = sort(Input3_j);
	Input3_j = sort(Input4_j);
	Input4_j = sort(Input5_j);
	Input5_j = sort(InputTemp);
gend
disp(sprintf('timeSort_j = %f', toc(timeSort_j)))

