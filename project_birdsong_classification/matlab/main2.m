%% Load songs

close all; clear all; clc;

path = ['/home/hengji/Documents/amath582_winter_2019/'...
    'project_birdsong_classification/british-birdsong-dataset/songs/'];
list = dir(fullfile(path));

nfile = size(list,1) - 2;

meta = importfile(['/home/hengji/Documents/amath582_winter_2019/'...
    'project_birdsong_classification/'...
    'british-birdsong-dataset/birdsong_metadata.csv']);

%% Construct training/test set
time_clip = 10;
npick = 10;

data_set = [];
cnames = [];
genuses = [];

train_set = [];
test_set = [];
genuses_train = [];
genuses_test = [];
count_cnames = []; 
cnames_train = [];
cnames_test = [];

h=waitbar(0,'please wait');
for k = 3:(nfile+2)
    name = list(k).name;
    song = audioread(strcat(path,name));
    info = audioinfo(strcat(path,name));
    Fs = info.SampleRate; 
    T = info.Duration;
    
    if T<time_clip
        continue
    end
    
    time = linspace(0,T,length(song));
    % plot(time, song);
    % spectrogram(song,gausswin(5000),2000,[],Fs, 'yaxis');
    
    genus = meta.genus(index(name, meta)); 
    cname = meta.english_cname(index(name, meta));
    
    genuses = [genuses, repmat(genus, 1, npick)];
    cnames = [cnames, repmat(cname, 1, npick)];
    data = construct_data(npick, song, length(song), Fs, 2, time_clip);
    data_set = [data_set, data];
    
    str=['please wait...',num2str(k/nfile*100),'%'];
    waitbar(k/nfile,h, str)
end
delete(h)

%% 

L = (length(genuses'));

inds = randperm(L);

data_set = data_set(:,inds);
genuses = genuses(:,inds);
cnames = cnames(:,inds);

%% 

train_set = data_set(:, 1:floor(0.8*L));
test_set = data_set(:, ceil(0.8*L):end);

genuses_train = genuses(1:floor(0.8*L));
genuses_test = genuses(ceil(0.8*L):end);

%%

training = abs(train_set);
testing = abs(test_set);

%%

% LDA
class = classify(testing', training', genuses_train');
accuracy = sum(class==genuses_test')/length(class);

%%

% Naive Bayes
Mdl_cnb = fitcnb(training', genuses_train');
class_cnb = predict(Mdl_cnb, testing');
accuracy_cnb = sum(class_cnb==genuses_test')/length(class_cnb);

%%

% Random Forests
Mdl_rf = TreeBagger(500, training', genuses_train');
class_rf = predict(Mdl_rf, testing');
accuracy_rf = sum(class_rf==genuses_test')/length(class_rf);


% KNN
Mdl_knn = fitcknn(training', genuses_train');
class_knn = predict(Mdl_knn, testing');
accuracy_knn = sum(class_knn==genuses_test')/length(class_knn);


% fit ensembles
Mdl_ens = fitcensemble(training', genuses_train');
class_ens = predict(Mdl_ens, testing');
accuracy_ens = sum(class_ens==genuses_test')/length(class_ens);