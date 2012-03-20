function cliques = maximalcliques( connected )
% CLIQUES = cliqueBK (PAIRS);
%
% PAIRS has list of pairs of data items, this routine finds mutual pairs (maximal cliques)
% PAIRS are of form 1 1 1 1 2 2 2 6
%                   2 3 6 7 3 5 7 7
% CLIQUES returned   {1 2 3}, {1 2 7}, {1 6 7} and {2 5} 
% MATLAB efficient Implementation of algorithm due to Bron and Kerbosch
% forms connected, a symmetrical Boolean matrix connected. 
% n is the number of nodes in the graph. The values of the diagonal elements should be true
% then processes connected using backtracking, but with branch and bound method to
% prevent paths searched more than once.
%
% Dr Richard Mitchell, 22.5.02; 
% revised 29.7.02 - to speed first half, and use smaller connected
%         08.8.02
%

% n = max(max(pairs));                                    % find maximum number in pairs
% connected = eye(n);                                     % set matrix with each node connected to self
% for ct = 1:size(pairs,1),                               % fill in connections
%     connected(pairs(ct,1),pairs(ct,2)) = 1; 
%     connected(pairs(ct,2),pairs(ct,1)) = 1; 
% end; 
ndx = find(sum(connected)>1);                           % ndx is numbers which do exist
cliques = extend (0, [], connected(ndx,ndx), ndx);      % find the cliques

function cliques = extend(ne, compsub, connected, index)
% old[1..ne] are NOT, OLD[ne+1..ce] are CANDIDATES
% compsub is clique array, c is position in array
cliques = {};                                           % no cliques initially
ce = size(connected,1);                                 % set ce
old = 1:ce;                                             % old is range 1 to ce

[maxv, maxw] = max(sum(connected(:,ne+1:ce),2));        % find column with most 1's
if ( numel(maxw) > 0 )                                  % safety check
    fixp = maxw(1);                                     % this is column to use: remember it
else
    fixp = 1;
end
minnod = ce - ne - maxv;                                % this is number of zeros
if fixp > ne                                            % if minimum is from CANDIDATES
    s = fixp;                                           % this is first column to use
    minnod = minnod + 1;                                % preincrement number of disconnections
elseif minnod > 0                                       % if some non connections
    nocons = find (connected(ne+1:ce,fixp)==0);
    s = ne + nocons(length(nocons));                    % s is last non connection
end
                                                        % BACKTRACKCYCLE
for nod = minnod : -1 : 1, 
    sel = old(s);                                       % select item, and swap with ne+1'th
	old(s) = old(ne + 1);                               % so can add selected to NOT set
	old(ne + 1) = sel;

    connected(sel,sel)=0;                               % so sel not included in new sets
    newne = sum(connected(old(1:ne),sel)>0);            % num in NOT = those in sel connected to NOT
    new = old(connected(old,sel)>0);                    % new is old items connected to sel
    newce = length(new);
    
    if newce==0                                         % compsub + sel is new cliqe
        if length(compsub)>0, cliques = [cliques, {[compsub, index(sel)]}]; end
                                                        % add found CLIQUE to cliques
    elseif newce == 1 && newne == 0                     % only 1 new candidate
                                                        % so compsub, sel and candidate is clique
        cliques = [cliques, {[compsub, index([sel, new(1)])]}];
                                                        % add CLIQUE
    elseif newne < newce                                % if some CANDIDATES, search
		newcliques = extend(newne, [compsub, index(sel)], connected(new,new), index(new));
        if ~isempty(newcliques), cliques = [cliques, newcliques]; end
    end	                                                % if new cliques, add them

	if nod > 1 
    	ne = ne + 1;                                    % add selected candidate to NOT
        s = ne + 1;                                     % select candidate not connected to fixp
		while connected(fixp, old(s)), s = s + 1; end
	end
end

