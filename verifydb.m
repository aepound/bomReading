%% Verify the Numbers..


% Run the database stuff...
run('bomdb')

% Run the reading chart (without Latex Processing...)
NoLatexOutput = true;
run('bomReadingChart')



%% check the number of chapters in each book...
CHPS = cellfun(@length,{testament.book.chaps});
chaps;

assert(length(CHPS) == length(chaps))

assert(~sum(chaps - CHPS))
%% Check the number of versus in each chapter..
VV = [];
for iter = 1:length(testament.book)
bk = testament.book(iter);
for jiter = 1:length(bk.chaps)
VV = [VV; length(bk.chaps(jiter).verse)];
end
end

assert(length(VV) == length(vs))

assert(~sum(vs-VV))

