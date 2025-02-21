%% Analysis script for Spike x Sleep x SUA project
%
% (c) Stephen Whitmarsh, stephen.whitmarsh@gmail.com
%
set(0, 'DefaultFigurePosition', [2500 100  1000 1000]);
set(0, 'DefaultFigurePosition', [200  300  1000 500]);

addpath /network/lustre/iss01/charpier/analyses/stephen.whitmarsh/EpiCode/projects/hspike/
addpath \\lexport\iss01.charpier\analyses\stephen.whitmarsh\EpiCode\projects\hspike

hspike_setpaths;

feature('DefaultCharacterSet', 'CP1252') % To fix bug for weird character problems in reading neurlynx

labels = ["BAD__START__", "BAD__END__", ...
    "PHASE_1__START__", "PHASE_1__END__", ...
    "PHASE_2__START__", "PHASE_2__END__", ...
    "PHASE_3__START__", "PHASE_3__END__", ...
    "REM__START__", "REM__END__", ...
    "AWAKE__START__", "AWAKE__END__", ...
    "PRESLEEP__START__", "PRESLEEP__END__", ...
    "POSTSLEEP__START__", "POSTSLEEP__END__"];

disp('Settings loaded');

% TODO:
% Add scalp EEG (for slow wave synchronization?)?
% Different loops for templates (first 3 days) and window (whole recording)

%% General analyses, looping over patients
MuseStruct{8} = [];
clusterindx{8} = [];
LFP_cluster{8} = [];
LFP_cluster_detected{8} = [];

for ipatient = 1:8
    config                                                          = hspike_setparams;
    config{ipatient}                                                = addparts(config{ipatient});
    MuseStruct{ipatient}                                            = readMuseMarkers(config{ipatient}, false);
    MuseStruct{ipatient}                                            = padHypnogram(MuseStruct{ipatient});   
    MuseStruct{ipatient}                                            = alignMuseMarkersXcorr(config{ipatient}, MuseStruct{ipatient}, false);
    [clusterindx{ipatient}, LFP_cluster{ipatient}]                  = clusterLFP(config{ipatient}, MuseStruct{ipatient}, false);
    [config{ipatient}, LFP_cluster{ipatient}{1}.Hspike.kmedoids{6}] = alignClusters(config{ipatient}, LFP_cluster{ipatient}{1}.Hspike.kmedoids{6});
    
    [MuseStruct{ipatient}, ~, LFP_cluster_detected{ipatient}]       = detectTemplate(config{ipatient}, MuseStruct{ipatient}, LFP_cluster{ipatient}{1}.Hspike.kmedoids{6}, false); 
    
    % exportHypnogram(config{ipatient})
    
    % get hypnogram data
    [marker{ipatient}, hypnogram{ipatient}, hypmusestat{ipatient}] = hypnogramMuseStats(config{ipatient}, MuseStruct{ipatient}, false);
    
    % add (sliding) timewindow
    [config{ipatient}, MuseStruct{ipatient}] = addSlidingWindows(config{ipatient}, MuseStruct{ipatient});
    
    % template LFP
    config{ipatient}.LFP.name   = {'window'};
    LFP{ipatient}               = readLFP(config{ipatient}, MuseStruct{ipatient}, false);
    
    % template TFR
    %     config{ipatient}.TFR.name   = {'template1', 'template2', 'template3', 'template4', 'template5', 'template6'};
    %     TFR{ipatient}             = TFRtrials(config{ipatient}, false);
    
    % calculate FFT on sliding timewindow
    config{ipatient}.FFT.name  = {'window'};
    FFT{ipatient}              = FFTtrials(config{ipatient}, false);
    
    %     writeSpykingCircusDeadfiles(config{ipatient}, MuseStruct{ipatient}, true);
    %     writeSpykingCircusFileList(config{ipatient}, true);
    %     writeSpykingCircusParameters(config{ipatient});
    
    %    SpikeRaw{ipatient} = readSpikeRaw_Phy(config{ipatient}, false);
    %
    %     if ipatient == 3
    %         SpikeRaw{ipatient}{1}.template_maxchan(1) = 1;
    %     end
    
    %     SpikeWaveforms{ipatient} = readSpikeWaveforms(config{ipatient}, SpikeRaw{ipatient}, true);
    % figure; plot(mean(vertcat(SpikeWaveforms{ipatient}{1}{4}.trial{:})))
    
    % segment into trials/segments
    %     config{ipatient}.spike.name = {'window'};
    %     SpikeTrials{ipatient}       = readSpikeTrials(config{ipatient}, MuseStruct{ipatient}, SpikeRaw{ipatient}, false);
    %
    %     for ipart = 1 : 3
    %         SpikeTrials{ipatient}{ipart}.window.trialinfo.IEDrate = zeros(height(SpikeTrials{ipatient}{ipart}.window.trialinfo), 1);
    %         for fn = ["template1_cnt", "template2_cnt", "template3_cnt", "template4_cnt", "template5_cnt", "template6_cnt"]
    %           SpikeTrials{ipatient}{ipart}.window.trialinfo.IEDrate = ...
    %               SpikeTrials{ipatient}{ipart}.window.trialinfo.IEDrate + ...
    %               SpikeTrials{ipatient}{ipart}.window.trialinfo.(fn) * 6;
    %         end
    %     end
    %
    %     % statistics
    %     config{ipatient}.spike.name         = {'window'};
    %     SpikeStats{ipatient}                 = spikeTrialStats(config{ipatient}, SpikeTrials{ipatient}, false);
    %
    %     % spike density
    %     % don't calculate on window
    %     config{ipatient}.spike.psth.name     = {'template1', 'template2', 'template3', 'template4', 'template5', 'template6'};
    %     SpikeDensity{ipatient}               = spikeTrialDensity(config{ipatient}, SpikeTrials{ipatient}, false);
    
    clear LFP FFT SpikeRaw SpikeTrials SpikeStats SpikeDensity
end

%% Create figures

Figure_hypnograms
Figure_templates
Figure_FFT
Figure_LFP_stages % also writes data for 

%% Plot locations with BrainNetViewer

% per patient
for ipatient = 1 : 8
    
    t_sel       = t(t.patient == ipatient, :);
    nodes       = [t_sel.X, t_sel.Y, t_sel.Z, t_sel.color, t_sel.size, t_sel.patient];
    
    % resize nodes that are not analyzed
    nodes(nodes(:, 4) == 1, 5) = 2;
    nodes(nodes(:, 4) == 0, 5) = 2;
    
    fname_surf  = '\\lexport\iss01.charpier\analyses\stephen.whitmarsh\scripts\BrainNetViewer_20191031\Data\SurfTemplate\BrainMesh_Ch2.nv';
    fname_cfg   = '\\lexport\iss01.charpier\analyses\stephen.whitmarsh\data\hspike\brainnet_config.mat';
    fname_image = fullfile(cfg.imagesavedir, [cfg.prefix, 'brainnet.jpg']);
    fname_nodes = fullfile(cfg.datasavedir,  'brainnet_all.node');
    dlmwrite(fname_nodes, nodes, '\t');
    
    BrainNet_MapCfg(fname_nodes, fname_surf, fname_cfg, fname_image);
    
end

% all
t_sel  = t(t.color > 0, :);
nodes  = [t_sel.X, t_sel.Y, t_sel.Z, t_sel.color, t_sel.size, t_sel.patient];

% resize nodes that are not analyzed
nodes(nodes(:, 4) == 1, 5) = 2;
nodes(nodes(:, 4) == 0, 5) = 2;

fname_surf  = '\\lexport\iss01.charpier\analyses\stephen.whitmarsh\scripts\BrainNetViewer_20191031\Data\SurfTemplate\BrainMesh_Ch2.nv';
fname_cfg   = '\\lexport\iss01.charpier\analyses\stephen.whitmarsh\data\hspike\brainnet_config.mat';
fname_image = fullfile(cfg.imagesavedir, ['brainnet_all.jpg']);
fname_nodes = fullfile(cfg.datasavedir,  'brainnet_all.node');
dlmwrite(fname_nodes, nodes, '\t');

BrainNet_MapCfg(fname_nodes, fname_surf, fname_cfg, fname_image);

% https://www.nitrc.org/docman/view.php/504/1190/BrainNet%20Viewer%20Manual%201.41.pdf
% The node file is defined as an ASCII text file with the suffix node. In the node file, there
% are 6 columns: columns 1-3 represent node coordinates, column 4 represents node
% colors, column 5 represents node sizes, and the last column represents node labels.
% Please note, a symbol -(no ) in column 6 means no labels. The user may put the
% modular information of the nodes into column 4, like 1, 2, 3 or other information to
% be shown by color. Column 5 could be set as nodal degree, centrality, T-value, etc. to
% emphasize nodal differences by size. You can generate your nodal file according to the
% requirements.

%% Create table for R: location of electrodes in MNI

config      = hspike_setparams;
nodes_all   = [];

t = table;
for ipatient = 1 : 8
    
    cfg     = config{ipatient};
    fname   = cfg.locfile;
    fid     = fopen(fname);
    dat     = textscan(fid, '%s%d%s%f%f%f%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s', 'Headerlines', 4, 'delimiter', ';');
    fclose(fid);
    
    for i = 1 : size(dat{1}, 1)

        if ~isempty(dat{1}{i})
            elecname = string(dat{1}{i});
        end
        
        t_temp           = table;
        t_temp.electrode = strcat('_', elecname, '_',  num2str(dat{2}(i)));
        t_temp.contact   = dat{2}(i);
        t_temp.X         = dat{4}(i);
        t_temp.Y         = dat{5}(i);
        t_temp.Z         = dat{6}(i);
        t_temp.patient   = ipatient;
        t_temp.color     = 0;
        t_temp.size      = 3;
        for name = string(cfg.LFP.channel)
            if contains(name, t_temp.electrode)
                t_temp.color = 1;
            end
        end    
        t_temp.electrode{1}  = t_temp.electrode{1}(2:end-2);
        t = [t; t_temp];
    end
end

t = t(t.contact > 0, :);

% save data to table for R
fname   = fullfile(config{ipatient}.datasavedir, 'MNI_table');
writetable(t, fname);

%% Create table for R: summary of hypnogram

% durations for normalization
t_summary = table;

for ipatient = 1 : 8
    [hypmarkers{ipatient}, hypnogram{ipatient}, hypmusestat{ipatient}] = hypnogramMuseStats(config{ipatient});
    
    for ipart = 1 : 3
        
        temp    = fields(hypmusestat{ipatient}{ipart});
        fn      = temp{1}; % just take the first, they all contain the same durations
        
        t_temp  = struct2table(hypmusestat{ipatient}{ipart}.(fn).duration);
        t_temp.part = ipart;
        t_temp.patient = ipatient;
        t_summary = [t_summary; t_temp];
        
    end
end

fname   = fullfile(config{ipatient}.datasavedir, 'hypnogram_duration');
writetable(t_summary, fname);

%% Create table for R: hypnograms

t_position = table;

for ipatient = 1 : 8
    for ipart = 1 : 3
        disp(ipart)
        hypnogram{ipatient}.epochtime   = convertTo(hypnogram{ipatient}.starttime ,'epochtime','Epoch','2001-01-01','TicksPerSecond',1);
        indx                            = hypnogram{ipatient}.part == ipart;        
        hypnogram{ipatient}.x(indx)     = hypnogram{ipatient}.epochtime(indx) - hypnogram{ipatient}.epochtime(find(indx, 1));
        [dt, X, Y, label]               = plot_hyp_lines(hypnogram{ipatient}(hypnogram{ipatient}.part == ipart, :));
        
        if X(1).Hour < 12
            X0 = datetime(X.Year,X.Month,X.Day-1,0,0,0, 'Format', 'dd/MM/yyyy HH:mm');
        else
            X0 = datetime(X.Year,X.Month,X.Day,0,0,0, 'Format', 'dd/MM/yyyy HH:mm');
        end

        t_temp          = table;
        t_temp.X        = X';
        t_temp.Y        = Y';
        t_temp.dt       = dt';
        t_temp.label    = label';
        t_temp.part     = ones(height(t_temp), 1) * ipart;
        t_temp.patient  = ones(height(t_temp), 1) * ipatient;
        t_temp.hour     = (X.Hour/24 + X.Minute/24/60 + X.Second/24/60/60)';
        t_temp.hour0    = double(convertTo(X','epochtime','Epoch',X0(1),'TicksPerSecond',1))/24/60/60-1;
        t_temp.radian   = t_temp.hour * pi * 2;
        t_temp.degree   = t_temp.hour * 360;

        t_temp_position             = table;
        t_temp_position.offset      = X.Hour(1)/24 + X.Minute(1)/24/60 + X.Second(1)/24/60/60;
        t_temp_position.duration    = double(convertTo(X(end),'epochtime','Epoch',X(1),'TicksPerSecond',1))/24/60/60;
        t_temp_position.part        = ones(height(t_temp_position), 1) * ipart;
        t_temp_position.patient     = ones(height(t_temp_position), 1) * ipatient;

        t           = [t; t_temp];
        t_position  = [t_position; t_temp_position];
    end
end

fname   = fullfile(config{ipatient}.datasavedir, 'hypnogram_table');
writetable(t, fname);
fname   = fullfile(config{ipatient}.datasavedir, 'offset_table');
writetable(t_position, fname);

%% Create table for R: LFP power values over time + IED sum

config  = hspike_setparams;
t_long  = table;
t_wide  = table;

for ipatient = 1 : 8
    config{ipatient}.FFT.name  = {'window'};
    FFT = FFTtrials(config{ipatient});
    for ipart = 1 : size(FFT, 2)
        
        IEDsum = 0;
        for itemplate = 1 : 6
            if ~any(itemplate == config{ipatient}.template.rejected)
                IEDsum = IEDsum + FFT{ipart}.window.trialinfo.(sprintf('template%d_cnt', itemplate));
            end
        end
        
        t_wide_temp         = FFT{ipart}.window.trialinfo;
        t_wide_temp.IEDsum  = IEDsum;
        t_wide_temp.part    = ones(height(t_wide_temp), 1) * ipart;
        t_wide_temp.patient = ones(height(t_wide_temp), 1) * ipatient;
        
        % average over frequency bands
        cfg                 = [];
        cfg.avgoverfreq     = 'yes';
        cfg.avgoverchan     = 'yes';
        freq_band           = {[1, 4], [5, 7], [8, 14], [15, 25], [26, 40]};
        freq_name           = ["delta", "theta", "alpha", "beta"];

        for ifreq = 1 : length(freq_name)   
            
            cfg.frequency        = freq_band{ifreq};
            power                = ft_selectdata(cfg, FFT{ipart}.window);
            t_long_temp          = FFT{ipart}.window.trialinfo;
            t_long_temp.power    = power.powspctrm;
            t_long_temp.band     = repmat(freq_name(ifreq), height(t_long_temp), 1);
            t_long_temp.part     = ones(height(t_long_temp), 1) * ipart;
            t_long_temp.patient  = ones(height(t_long_temp), 1) * ipatient;
            t_long_temp.IEDsum   = IEDsum;
            t_long               = [t_long; t_long_temp];
            
            t_wide_temp.(freq_name(ifreq)) = power.powspctrm;            
        end
        t_wide = [t_wide; t_wide_temp];
    end
end

% adding ratio low vs high
for ipatient = unique(t_long.patient)'
    for ipart =  unique(t_long.part)'
        i1 = find(t_long.patient == ipatient & t_long.part == ipart & t_long.band == "delta");
        i2 = find(t_long.patient == ipatient & t_long.part == ipart & t_long.band == "alpha");        
        t_long_temp         = t_long(i1, :);
        t_long_temp.power   = t_long.power(i1) ./ t_long.power(i2);
        t_long_temp.band    = repmat("delta_div_alpha", height(t_long_temp), 1);   
        t_long              = [t_long; t_long_temp];        
    end
end

t_wide.delta_div_alpha = t_wide.delta ./ t_wide.alpha;
t_long.minute = hour(t_long.starttime + (t_long.endtime-t_long.starttime)/2)*60 + minute(t_long.starttime + (t_long.endtime-t_long.starttime)/2);
t_wide.minute = hour(t_wide.starttime + (t_wide.endtime-t_wide.starttime)/2)*60 + minute(t_wide.starttime + (t_wide.endtime-t_wide.starttime)/2);

% save data to table for R
fname   = fullfile(config{ipatient}.datasavedir, 'power_table_long');
writetable(t_long, fname);

% save data to table for R
fname   = fullfile(config{ipatient}.datasavedir, 'power_table_wide');
writetable(t_wide, fname);

%% Create table for R: IED timing list based on LFP (3 nights with sleep stage)

config  = hspike_setparams;
t       = table;

for ipatient = 1 : 8
    
    config{ipatient}.LFP.name  = ["template1", "template2", "template3", "template4", "template5", "template6"];
    LFP = readLFP(config{ipatient});
    
    for ipart = 1 : size(LFP, 2)
        for marker = ["template1", "template2", "template3", "template4", "template5", "template6"]
            if any(str2double(marker{1}(end)) == config{ipatient}.template.rejected)
                continue
            end
            if isempty(LFP{ipart}.(marker))
                continue
            end
            fprintf('Concatinating Patient %d, part %d, marker %s\n', ipatient, ipart, marker);
            t_temp          = LFP{ipart}.(marker).trialinfo;
            t_temp.marker   = repmat(marker,   height(t_temp), 1);
            t_temp.part     = repmat(ipart,    height(t_temp), 1);
            t_temp.patient  = repmat(ipatient, height(t_temp), 1);
            t               = [t; t_temp];
        end
    end
end

t.minute = hour(t.starttime)*60 + minute(t.starttime);
t.hour   = hour(t.starttime) + minute(t.starttime) / 60;
t.theta  = t.minute / (24*60) * 2 * pi;

% save data to table for R
fname   = fullfile(config{ipatient}.datasavedir, 'IED_table_PSG');
writetable(t, fname);

%% Create table for R: seizure timings

config  = hspike_setparams;
t       = table;

for ipatient = 1:8
    [MuseStruct{ipatient}, ~, ~] = detectTemplate(config{ipatient});    
    t_temp = table;
    t_temp.datetime = config{ipatient}.seizures';
    t_temp.patient  = ones(height(t_temp), 1) * ipatient;
    t_temp.minute   = hour(t_temp.datetime)*60 + minute(t_temp.datetime);
    t = [t; t_temp];
end

% save data to table for R
fname   = fullfile(config{ipatient}.datasavedir, 'seizuredata_table');
writetable(t, fname);

%% Create slurm job list

config = hspike_setparams;
for ipatient = 1:8
    MuseStruct{ipatient} = readMuseMarkers(config{ipatient}, false);
    MuseStruct{ipatient} = updateMarkers(config{ipatient}, MuseStruct{ipatient}, ["BAD__START__", "BAD__END__"]);
    writeSpykingCircusDeadfiles(config{ipatient}, MuseStruct{ipatient}, true);
    writeSpykingCircusFileList(config{ipatient}, true);
    writeSpykingCircusParameters(config{ipatient});
end

fname_slurm_joblist = fullfile('//network/lustre/iss01/charpier/analyses/stephen.whitmarsh/EpiCode/projects/hspike/slurm_job_list.txt');
delete(fname_slurm_joblist);
for ipatient = 1:8
    for ipart = 1 : size(config{ipatient}.directorylist, 2)
        subjdir     = config{ipatient}.prefix(1:end-1);
        partdir     = ['p', num2str(ipart)];
        if ~isfield(config{ipatient}.circus, 'channelname')
            fid = fopen(fname_slurm_joblist, 'a');
            if fid == -1
                error('Could not create/open %s', fname_slurm_joblist);
            end
            filename    = 'SpykingCircus.params';
            dirname     = strcat('//network/lustre/iss01/charpier/analyses/stephen.whitmarsh/data/hspike/', subjdir, '/', partdir);
            fprintf(fid,'module load spyking-circus/1.0.8 ; cd %s; spyking-circus %s -c 28; spyking-circus %s -m converting -c 28; echo DONE!!! \n', dirname, filename, filename);
            fclose(fid);
        else
            for chandir = unique(config{ipatient}.circus.channelname)
                fid = fopen(fname_slurm_joblist, 'a');
                if fid == -1
                    error('Could not create/open %s', fname_slurm_joblist);
                end
                temp        = strcmp(config{ipatient}.circus.channelname, chandir);
                firstchan   = string(config{ipatient}.circus.channel(find(temp,1,'first')));
                filename    = 'SpykingCircus.params';
                dirname     = strcat('//network/lustre/iss01/charpier/analyses/stephen.whitmarsh/data/hspike/', subjdir, '/', partdir, '/', string(chandir));
                fprintf(fid,'module load spyking-circus/1.0.8 ; cd %s; spyking-circus %s -c 28; spyking-circus %s -m converting -c 28; echo DONE!!! \n', dirname, filename, filename);
                fclose(fid);
            end
        end
    end
end

%% Create table for R: UNITS

t       = table;
config  = hspike_setparams;

for ipatient = 8
    config{ipatient}                                                = addparts(config{ipatient});
    MuseStruct{ipatient}                                            = readMuseMarkers(config{ipatient}, false);
    MuseStruct{ipatient}                                            = alignMuseMarkersXcorr(config{ipatient}, MuseStruct{ipatient}, false);
    [clusterindx{ipatient}, LFP_cluster{ipatient}]                  = clusterLFP(config{ipatient}, MuseStruct{ipatient}, false);
    [config{ipatient}, LFP_cluster{ipatient}{1}.Hspike.kmedoids{6}] = alignClusters(config{ipatient}, LFP_cluster{ipatient}{1}.Hspike.kmedoids{6});
    LFP_cluster{ipatient}{1}.Hspike.kmedoids{6}                     = LFP_cluster{ipatient}{1}.Hspike.kmedoids{6}(config{ipatient}.template.selection);
    MuseStruct{ipatient}                                            = padHypnogram(MuseStruct{ipatient});
    
    % get hypnogram data
    [markers{ipatient}, hypnogram{ipatient}, hypmusestat{ipatient}] = hypnogramMuseStats(config{ipatient}, MuseStruct{ipatient}, true);
    
    % FFT  sliding timewindow
    config{ipatient}.FFT.name   = {'window'};
    FFT{ipatient}               = FFTtrials(config{ipatient}, false);
    
    % spike data trials/segments
    SpikeRaw{ipatient}          = readSpikeRaw_Phy(config{ipatient}, false);
    config{ipatient}.spike.name = {'window'};
    SpikeTrials{ipatient}       = readSpikeTrials(config{ipatient});
    
    % spike stats
    config{ipatient}.spike.name = {'window'};
    SpikeStats{ipatient}        = spikeTrialStats(config{ipatient}, SpikeTrials{ipatient}, false);
    
    for ipart = 1 : 3
        
        for iunit = 1 : size(SpikeStats{ipatient}{ipart}.window, 2)
            
            % spike data
            spk = SpikeTrials{ipatient}{ipart}.window.trialinfo;
            for fn = ["CV2_trial", "CV_trial", "trialfreq", "trialfreq_corrected", "burst_trialsum", "amplitude"]
                spk.(fn) = SpikeStats{ipatient}{ipart}.window{iunit}.(fn)';
            end
            spk.unit = ones(height(spk), 1) * iunit;
            spk.RPV = ones(height(spk), 1) * SpikeStats{ipatient}{ipart}.window{iunit}.RPV;
            spk.label = repmat(string(SpikeStats{ipatient}{ipart}.window{iunit}.label), height(spk), 1);
            spk.cluster_group = repmat(string(deblank(SpikeTrials{ipatient}{ipart}.window.cluster_group{iunit})), height(spk), 1);
            
            IEDsum = 0;
            for fn = ["template1", "template2", "template3", "template4", "template5", "template6"]
                IEDsum = IEDsum + spk.(sprintf('%s_cnt', fn{1}));
            end
            spk.IEDsum = IEDsum;
            pow = FFT{ipatient}{ipart}.window.trialinfo;
            
            % LFP & power date
            cfg             = [];
            cfg.avgoverfreq = 'yes';
            cfg.avgoverchan = 'yes';
            cfg.frequency   = [1, 4];
            temp            = ft_selectdata(cfg, FFT{ipatient}{ipart}.window);
            pow.delta        = log(temp.powspctrm);
            cfg.frequency   = [5, 7];
            temp            = ft_selectdata(cfg, FFT{ipatient}{ipart}.window);
            pow.theta        = log(temp.powspctrm);
            cfg.frequency   = [8, 14];
            temp            = ft_selectdata(cfg, FFT{ipatient}{ipart}.window);
            pow.alpha        = log(temp.powspctrm);
            cfg.frequency   = [15, 25];
            temp            = ft_selectdata(cfg, FFT{ipatient}{ipart}.window);
            pow.beta         = log(temp.powspctrm);
            cfg.frequency   = [26, 40];
            temp            = ft_selectdata(cfg, FFT{ipatient}{ipart}.window);
            pow.gamma       = log(temp.powspctrm);
            
            % combine
            t_temp          = innerjoin(spk, pow, 'Keys', 'starttime');
            t_temp.part     = ones(height(t_temp), 1) * ipart;
            t_temp.patient  = ones(height(t_temp), 1) * ipatient;
            t               = [t; t_temp];
        end
    end
    clear FFT SpikeRaw SpikeTrials SpikeStats SpikeDensity
end

t.minute = hour(t.starttime + (t.endtime_spk-t.starttime)/2)*60 + minute(t.starttime + (t.endtime_spk-t.starttime)/2);

% save data to table for R
fname   = fullfile(config{ipatient}.datasavedir, 'alldata_table');
writetable(t, fname);
t = readtable(fname);

% for ipatient = 1 : 7
%     i = t.patient == ipatient;
%     t.zAlpha(i) = (t.alpha(i) - mean(t.alpha(i))) ./ std(t.alpha(i));
%     t.zDelta(i) = (t.delta(i) - mean(t.delta(i))) ./ std(t.delta(i));
%     t.zTheta(i) = (t.theta(i) - mean(t.theta(i))) ./ std(t.theta(i));
%     t.zBeta(i)  = (t.beta(i)  - mean(t.beta(i)))  ./ std(t.beta(i));
% end
% 
% [~, ~, t.bin] = histcounts(t.minute, [0:24*60]);
% 
% t_binned = table;
% 
% for ipatient = 1 : 7
%     for ibin = unique(t.bin)'
%         t_temp          = table;
%         t_temp.patient  = ipatient;
%         t_temp.bin      = ibin;
%         t_temp.alpha    = mean(t.alpha(t.bin == ibin & t.patient == ipatient));
%         t_temp.beta     = mean(t.beta( t.bin == ibin & t.patient == ipatient));
%         t_temp.theta    = mean(t.theta(t.bin == ibin & t.patient == ipatient));
%         t_temp.delta    = mean(t.delta(t.bin == ibin & t.patient == ipatient));        
%         t_temp.zAlpha   = mean(t.zAlpha(t.bin == ibin & t.patient == ipatient));
%         t_temp.zBeta    = mean(t.zBeta( t.bin == ibin & t.patient == ipatient));
%         t_temp.zTheta   = mean(t.zTheta(t.bin == ibin & t.patient == ipatient));
%         t_temp.zDelta   = mean(t.zDelta(t.bin == ibin & t.patient == ipatient));
%         t_binned = [t_binned; t_temp];
%     end
% end
% 
% for ipatient = 1 : 7
%     i = t_binned.patient == ipatient;
%     t_binned.nAlpha(i) = t_binned.alpha(i) + min(t_binned.alpha(i));
%     t_binned.nAlpha(i) = t_binned.nAlpha(i) ./ max(t_binned.nAlpha(i));
%     t_binned.nBeta(i)  = t_binned.beta(i) + min(t_binned.beta(i));
%     t_binned.nBeta(i)  = t_binned.nBeta(i) ./ max(t_binned.nBeta(i));
%     t_binned.nTheta(i) = t_binned.theta(i) + min(t_binned.theta(i));
%     t_binned.nTheta(i) = t_binned.nTheta(i) ./ max(t_binned.nTheta(i));
%     t_binned.nDelta(i) = t_binned.delta(i) + min(t_binned.delta(i));
%     t_binned.nDelta(i) = t_binned.nDelta(i) ./ max(t_binned.nDelta(i));
% end
% 
% 
% % save data to table for R
% fname   = fullfile(config{ipatient}.datasavedir, 'alldata_binned_table');
% writetable(t_binned, fname);
% t_binned = readtable(fname);

%% plotting overview of each patient / night

for ipatient = 3 : 7
    config = hspike_setparams;
    MuseStruct{ipatient}                                        = readMuseMarkers(config{ipatient}, false);
    MuseStruct{ipatient}                                        = alignMuseMarkersXcorr(config{ipatient}, MuseStruct{ipatient}, false);
    [clusterindx{ipatient}, LFP_cluster{ipatient}]              = clusterLFP(config{ipatient}, MuseStruct{ipatient}, false);
    [MuseStruct{ipatient}, ~,~, LFP_cluster_detected{ipatient}] = detectTemplate(config{ipatient}, MuseStruct{ipatient}, LFP_cluster{ipatient}{1}.Hspike.kmedoids{6}, true);
    
    
    
    [config{ipatient}, MuseStruct{ipatient}]                    = alignTemplates(config{ipatient}, MuseStruct{ipatient}, LFP_cluster_detected{ipatient});
    
    
    
    MuseStruct{ipatient}                                        = padHypnogram(MuseStruct{ipatient});
    MuseStruct{ipatient}                                        = updateMarkers(config{ipatient}, MuseStruct{ipatient}, labels);
        
    % get hypnogram data
    [marker{ipatient}, hypnogram{ipatient}, hypmusestat{ipatient}] = hypnogramMuseStats(config{ipatient}, MuseStruct{ipatient}, true);
    
    % FFT on sliding timewindow
    config{ipatient}.FFT.name  = {'window'};
    FFT{ipatient}              = FFTtrials(config{ipatient}, false);
    
    % spike data on sliding timewindow
    config{ipatient}.spike.name = {'window'};
    SpikeTrials{ipatient}       = readSpikeTrials(config{ipatient});
    
    % spike statistics on sliding timewindow
    config{ipatient}.spike.name = {'window'};
    SpikeStats{ipatient}        = spikeTrialStats(config{ipatient}, SpikeTrials{ipatient}, false);
    
    for ipart = 1 : 3
        
        % combine markers for total IED rate
        SpikeTrials{ipatient}{ipart}.window.trialinfo.IEDrate = zeros(height(SpikeTrials{ipatient}{ipart}.window.trialinfo), 1);
        for fn = ["template1_cnt", "template2_cnt", "template3_cnt", "template4_cnt", "template5_cnt", "template6_cnt"]
            SpikeTrials{ipatient}{ipart}.window.trialinfo.IEDrate = ...
                SpikeTrials{ipatient}{ipart}.window.trialinfo.IEDrate + ...
                SpikeTrials{ipatient}{ipart}.window.trialinfo.(fn) * 6;
        end
        
        % you can plot any metric shown here:
        % SpikeStats{ipatient}{ipart}.window{1}, or:
        % SpikeTrials{ipatient}{ipart}.window.trialinfo, or:
        % FFT{ipatient}{ipart}.window.trialinfo
        
        iunit = 1 : size(SpikeTrials{ipatient}{ipart}.window.label, 2); % spikes to plot
        %         tunit = 3; % for spike distance
        
        cfg                 = [];
        cfg.ipart           = ipart;
        cfg.filename        = fullfile(config{ipatient}.imagesavedir, 'spikeoverview', sprintf('spikeoverview_s%sp%d.jpg', config{ipatient}.prefix, ipart));
        cfg.xlim            = [MuseStruct{ipatient}{cfg.ipart}{1}.starttime, MuseStruct{ipatient}{cfg.ipart}{end}.endtime];
        cfg.orientation     = 'landscape';
        
        cfg.type{1}         = 'hypnogram';
        cfg.title{1}        = 'Hypnogram';
        cfg.PSGcolors(1)    = false;
        
        cfg.type{2}         = 'power';
        cfg.frequency{2}    = [1, 7];
        cfg.channel{2}      = 'all';
        cfg.title{2}        = sprintf('Power %d-%dHz', cfg.frequency{2}(1), cfg.frequency{2}(2));
        cfg.plotart(2)      = false;
        cfg.log(2)          = true;
        cfg.PSGcolors(2)    = true;
        cfg.hideart(2)      = false;
        cfg.marker_indx{2}  = FFT{ipatient}{ipart}.window.trialinfo.BAD_cnt>0;
        cfg.marker_sign{2}  = '.r';
        cfg.marker_label{2} = 'artefact';
        
        cfg.type{3}         = 'power';
        cfg.frequency{3}    = [8, 14];
        cfg.channel{3}      = 'all';
        cfg.title{3}        = sprintf('Power %d-%dHz', cfg.frequency{3}(1), cfg.frequency{3}(2));
        cfg.plotart(3)      = false;
        cfg.log(3)          = true;
        cfg.PSGcolors(3)    = true;
        cfg.hideart(3)      = false;
        
        cfg.type{4}         = 'relpower';
        cfg.frequency1{4}   = [1, 7];
        cfg.frequency2{4}   = [8, 14];
        cfg.channel{4}      = 'all';
        cfg.title{4}        = sprintf('Power (%d-%dHz)/(%d-%dHz)', cfg.frequency1{4}(1), cfg.frequency1{4}(2), cfg.frequency2{4}(1), cfg.frequency2{4}(2));
        cfg.plotart(4)      = false;
        cfg.log(4)          = false;
        cfg.PSGcolors(4)    = true;
        cfg.hideart(4)      = false;
        
        cfg.type{5}         = 'trialinfo';
        cfg.title{5}        = sprintf('IED rate');
        cfg.metric{5}       = 'IEDrate';
        cfg.plotart(5)      = true;
        cfg.log(5)          = false;
        cfg.PSGcolors(5)    = true;
        cfg.hideart(5)      = false;
        
        cfg.type{6}         = 'trialinfo';
        cfg.title{6}        = sprintf('BAD count');
        cfg.metric{6}       = 'BAD_cnt';
        cfg.plotart(6)      = true;
        cfg.log(6)          = false;
        cfg.PSGcolors(6)    = false;
        cfg.hideart(6)      = false;
        
        cfg.type{7}         = 'spike';
        cfg.title{7}        = sprintf('Firing rate (corrected) unit %d-%d', iunit(1), iunit(end));
        cfg.metric{7}       = 'trialfreq_corrected';
        cfg.unit{7}         = iunit;
        cfg.plotart(7)      = true;
        cfg.log(7)          = true;
        cfg.PSGcolors(7)    = false;
        cfg.hideart(7)      = false;
        
        cfg.type{8}         = 'spike';
        cfg.title{8}        = sprintf('Nr. bursts unit %d-%d', iunit(1), iunit(end));
        cfg.metric{8}       = 'burst_trialsum';
        cfg.unit{8}         = iunit;
        cfg.plotart(8)      = true;
        cfg.log(8)          = false;
        cfg.PSGcolors(8)    = false;
        cfg.hideart(8)      = false;
        
        cfg.type{9}         = 'spike';
        cfg.title{9}        = sprintf('CV unit %d-%d', iunit(1), iunit(end));
        cfg.metric{9}       = 'CV_trial';
        cfg.unit{9}         = iunit;
        cfg.plotart(9)      = true;
        cfg.log(9)          = false;
        cfg.PSGcolors(9)    = false;
        cfg.hideart(9)      = false;
        
        cfg.type{10}        = 'spike';
        cfg.title{10}       = sprintf('CV2 unit %d-%d', iunit(1), iunit(end));
        cfg.metric{10}      = 'CV2_trial';
        cfg.unit{10}        = iunit;
        cfg.plotart(10)     = true;
        cfg.log(10)         = false;
        cfg.PSGcolors(10)   = false;
        cfg.hideart(10)     = false;
        
        
        plotWindowedData(cfg, MuseStruct{ipatient}, SpikeTrials{ipatient}, SpikeStats{ipatient}, FFT{ipatient}, hypnogram{ipatient});
%         plotWindowedData(cfg, MuseStruct{ipatient}, hypnogram{ipatient});
        
        
        close all
        
    end % ipart
    % to not bloat memory
%     clear SpikeRaw SpikeTrials SpikeStats SpikeDensity
    
end
% plot eventrelated LFP, TFR, raster and psth
config{ipatient}.plot.ncols         = 6;
config{ipatient}.plot.name          = {'template1', 'template2', 'template3', 'template4', 'template5', 'template6'};
plot_patterns_multilevel_examples(config{ipatient});





  
    

    plotstats(config_trimmed{ipatient});

    %     SpikeWaveforms{ipatient}              = readSpikeWaveforms(config_trimmed{ipatient}, SpikeTrials_windowed{ipatient}, true);
    


% prepare spyking-circus

for ipatient = 3:7
    
    config                  = hspike_setparams;
    [MuseStruct{ipatient}]  = readMuseMarkers(config{ipatient});
    [MuseStruct{ipatient}]  = alignMuseMarkersXcorr(config{ipatient});
    
    % add any new artefacts
    MuseStruct{ipatient}    = updateMarkers(config{ipatient}, MuseStruct{ipatient}, labels);
    
    % write spyking-circus files
    writeSpykingCircusDeadfiles(config{ipatient}, MuseStruct{ipatient}, true);
    writeSpykingCircusFileList(config{ipatient}, true);
    writeSpykingCircusParameters_new(config{ipatient});
end
    
for ipatient = 2 : 4
        config = hspike_setparams;
        SpikeRaw{ipatient} = readSpikeRaw_Phy_new(config{ipatient}, false);
        SpikeWaveforms{ipatient} = readSpikeWaveforms(config{ipatient}, SpikeRaw{ipatient}, true);
end



% Average over patients
[dat_unit, dat_lfp]                         = stats_IED_behaviour(config, true);
[dat_window]                                = stats_unit_behaviour(config, true);
[dat_density, stats_all, stats_responsive]  = stats_unit_density(config, true);

for ipatient = 1 : 7
    plot_patterns_multilevel(config{ipatient});
end


% 
% 
% %% Create slurm job list
% config              = hspike_setparams;
% fname_slurm_joblist = fullfile(config{1}.datasavedir, 'slurm_job_list.txt');
% delete(fname_slurm_joblist);
% for ipatient = 1:7
%     for ipart = 1 : size(config{ipatient}.directorylist, 2)
%         subjdir     = config{ipatient}.prefix(1:end-1);
%         partdir     = ['p', num2str(ipart)];
%         if ~isfield(config{ipatient}.circus, 'channelname')
%             fid = fopen(fname_slurm_joblist, 'a');
%             if fid == -1
%                 error('Could not create/open %s', fname_slurm_joblist);
%             end
%             filename    = strcat(config{ipatient}.prefix, 'p', num2str(ipart), '-multifile-', config{ipatient}.circus.channel{1} ,'.ncs');
%             dirname     = strcat('//network/lustre/iss01/charpier/analyses/stephen.whitmarsh/data/hspike/', subjdir, '/', partdir);
%             fprintf(fid,'module load spyking-circus/0.9.9 ; cd %s; spyking-circus %s -c 28; spyking-circus %s -m converting -c 28; echo DONE!!! \n', dirname, filename, filename);
%             fprintf('module load spyking-circus/0.9.9 ; cd %s; spyking-circus %s -c 28; spyking-circus %s -m converting -c 28; echo DONE!!! \n', dirname, filename, filename);
%             fclose(fid);
%         else
%             for chandir = unique(config{ipatient}.circus.channelname)
%                 fid = fopen(fname_slurm_joblist, 'a');
%                 if fid == -1
%                     error('Could not create/open %s', fname_slurm_joblist);
%                 end
%                 temp        = strcmp(config{ipatient}.circus.channelname, chandir);
%                 firstchan   = string(config{ipatient}.circus.channel(find(temp,1,'first')));
%                 filename    = strcat(config{ipatient}.prefix, 'p', num2str(ipart), '-multifile-', firstchan ,'.ncs');
%                 dirname     = strcat('//network/lustre/iss01/charpier/analyses/stephen.whitmarsh/data/hspike/', subjdir, '/', partdir, '/', string(chandir));
%                 fprintf(fid,'module load spyking-circus/0.9.9 ; cd %s; spyking-circus %s -c 28; spyking-circus %s -m converting -c 28; echo DONE!!! \n', dirname, filename, filename);
%                 fprintf('module load spyking-circus/0.9.9 ; cd %s; spyking-circus %s -c 28; spyking-circus %s -m converting -c 28; echo DONE!!! \n', dirname, filename, filename);
%                 fclose(fid);
%             end
%         end
%     end
% end

















