function [closest,d]=nt_proximity(coordinates,N)
%[closest,d]=nt_proximity(coordinates,N) - distance to neighboring channels
%
%  closest: indices of closest channels
%  d: table of distances from each channel (row) to other channels (column)
%
%  coordinates: spatial coordinates of each channel
%  N: consider only N nearest neighbors
% 
% If coordinates is a n*2 or n*3 matrix, it is iterpreted as cartesian coordinates
% in the plane or 3D space. A n*q matrix indicates coordinates in a qD space.
% If coordinates is a list of strings, it is interpreted as a list of standard 
% 10-20 positions.  
% If coordinates is a single string (e.g. 'biosemi128') it is interpreted as the 
% name of a standard layout file .
% If coordinates is a pair of numbers, it is interpreted as the dimensions in pixels 
% of a rectangle. Pixels are listed by columns. 
% If coordinates is a triplet, it is interpreted as the dimensions of a cuboid. 
%  
% Examples:
% 10 closest channels in a 64-channel biosemi cap:
%  [closest,d]=nt_proximity('biosemi64.lay',10);
% 10 closest channels based on cosine distance between signals:
%  [closest,d]=nt_proximity(nt_normcol(x)',10);
% 10 closest pixels in a 120 rows * 100 column image:
%  [closest,d]=nt_proximity([120,100],10);
%
% NoiseTools
nt_greetings();

disp(coordinates)

if nargin<1; error('!'); end
if nargin<2; N=[]; end
if isempty(coordinates); error('!'); end


if ischar(coordinates)
    switch coordinates
        case {'biosemi256.lay','biosemi160.lay','biosemi128.lay', 'biosemi64.lay', 'biosemi32.lay', 'biosemi16.lay'};
            cfg.layout=coordinates; 
            layout=ft_prepare_layout(cfg);
            coordinates=layout.pos;
            coordinates=coordinates(1:end-2,:); % remove last two rows (COMNT, SCALE)
        otherwise
            if exist (coordinates,'file') && numel(coordinates)>4 && all(coordinates(end-3:end)=='.lay') 
                fid=fopen(coordinates);
                a=textscan(fid, '%d %f %f %f %f %s');
                fclose(fid);
                coordinates=[a{2},a{3}];
            elseif exist (coordinates,'file') && numel(coordinates)>4 && all(coordinates(end-3:end)=='.ced') 
                fid=fopen(coordinates);
                a=textscan(fid,'%d%s%f%f%f%f%f%f%f%d', 'headerlines', 1);
                fclose(fid);
                coordinates=[a{5},a{6},a{7}];
            elseif exist (coordinates,'file') && numel(coordinates)>4 && all(coordinates(end-3:end)=='.loc') 
                fid=fopen(coordinates);
                a=textscan(fid, '%d %f %f %s');
                fclose(fid);
                coordinates=[a{2},a{3}];
            elseif exist (coordinates,'file') && numel(coordinates)>4 && all(coordinates(end-3:end)=='.mat') 
                load (coordinates);
                coordinates=lay.pos;
                coordinates=coordinates(1:end-2,:); % remove last two rows (COMNT, SCALE)
             end                
    end
end

if isempty(N); N=size(coordinates,1)-1; end

if isnumeric(coordinates)
    if size(coordinates,1)==1
        if numel(coordinates)==2 % dimensions in pixels of a rectangle
            nrows=coordinates(1); ncols=coordinates(2);
            a=repmat(1:nrows,ncols,1); b=repmat((1:ncols)',1,nrows); c=[a(:),b(:)];
            [closest,d]=knnsearch(c,c,'K',N+1);
            closest=closest(:,2:end);
            d=d(:,2:end);
        else
            error('cuboids, etc not yet implemented');
        end
    else
        if 0
            [nchans, ~]=size(coordinates);
            d=zeros(nchans);
            closest=zeros(nchans);
            for iChan=1:nchans
                d(iChan,:)=sqrt( sum( bsxfun(@minus,coordinates, coordinates(iChan,:)).^2, 2) )';
                [~,closest(iChan,:)]=sort(d(iChan,:)','ascend');
            end
        else
            [nchans, ~]=size(coordinates);
            if ~isempty(N)
                d=zeros(nchans,N+1);
                closest=zeros(nchans,N+1);
                tic;
                for iChan=1:nchans
                    if 0==rem(iChan,1000); disp([iChan, nchans]); toc; end; 
                    dd=sqrt( sum( bsxfun(@minus,coordinates, coordinates(iChan,:)).^2, 2) )';
                    [~,cc]=sort(dd','ascend');
                    closest(iChan,:)=cc(1:N+1);
                    d(iChan,:)=dd(1:N+1);
                end
            end 
        end
        if ~isempty(closest); closest=closest(:,1:end); end
    end
elseif iscell(coordinates) && ischar(coordinates{1});
    nchans=numel(coordinates);
    elec=elec_1020all_cart;
    labels={elec(:).labels};
    c=[];
    for iChan=1:nchans
        idx=find(strcmp(deblank(coordinates{iChan}),deblank(labels)));
        if numel(idx) ~= 1; error(['label not recognized: ',coordinates{iChan}]); end
        c=[c;[elec(idx).X, elec(idx).Y, elec(idx).Z]];
    end
    [closest,d]=nt_proximity(c);
else
    error('coordinates should be numeric or cell array of strings');
end

if ~isempty(N);
    closest=closest(:,1:N+1); 
    d=d(:,1:N+1);
end


% modified from https://sccn.ucsd.edu/svn/software/branches/eeglab9/plugins/ctfimport1.03/elec_1020all_cart.m
function [elec] = elec_1020all_cart

% elec_1020all_cart - all 10-20 electrode Cartesian coordinates
% 
% [elec] = elec_1020all_cart
%
% elec is a struct array with fields:
%
% elec.labels
% elec.X
% elec.Y
% elec.Z
%
% We gratefully acknowledge the provision of this data from 
% Robert Oostenveld.  The elec struct contains all channel names and
% locations for the International 10-20 electrode placement system, please
% see details in:
%
% Oostenveld, R. & Praamstra, P. (2001). The five percent electrode system
% for high-resolution EEG and ERP measurements. Clinical Neurophysiology,
% 112:713-719.
%

% $Revision: 1.1 $ $Date: 2009-01-30 03:49:27 $

% Copyright (C) 2005  Darren L. Weber
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

% Modified: 02/2004, Darren.Weber_at_radiology.ucsf.edu
%                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ver = '$Revision: 1.1 $ $Date: 2009-01-30 03:49:27 $';
% fprintf('\nELEC_1020ALL_CART [v %s]\n',ver(11:15));
% 

names = {'LPA','RPA','Nz','Fp1','Fpz','Fp2','AF9','AF7','AF5','AF3',...
    'AF1','AFz','AF2','AF4','AF6','AF8','AF10','F9','F7','F5','F3','F1',...
    'Fz','F2','F4','F6','F8','F10','FT9','FT7','FC5','FC3','FC1','FCz',...
    'FC2','FC4','FC6','FT8','FT10','T9','T7','C5','C3','C1','Cz','C2',...
    'C4','C6','T8','T10','TP9','TP7','CP5','CP3','CP1','CPz','CP2','CP4',...
    'CP6','TP8','TP10','P9','P7','P5','P3','P1','Pz','P2','P4','P6','P8',...
    'P10','PO9','PO7','PO5','PO3','PO1','POz','PO2','PO4','PO6','PO8',...
    'PO10','O1','Oz','O2','I1','Iz','I2','AFp9h','AFp7h','AFp5h','AFp3h',...
    'AFp1h','AFp2h','AFp4h','AFp6h','AFp8h','AFp10h','AFF9h','AFF7h',...
    'AFF5h','AFF3h','AFF1h','AFF2h','AFF4h','AFF6h','AFF8h','AFF10h',...
    'FFT9h','FFT7h','FFC5h','FFC3h','FFC1h','FFC2h','FFC4h','FFC6h',...
    'FFT8h','FFT10h','FTT9h','FTT7h','FCC5h','FCC3h','FCC1h','FCC2h',...
    'FCC4h','FCC6h','FTT8h','FTT10h','TTP9h','TTP7h','CCP5h','CCP3h',...
    'CCP1h','CCP2h','CCP4h','CCP6h','TTP8h','TTP10h','TPP9h','TPP7h',...
    'CPP5h','CPP3h','CPP1h','CPP2h','CPP4h','CPP6h','TPP8h','TPP10h',...
    'PPO9h','PPO7h','PPO5h','PPO3h','PPO1h','PPO2h','PPO4h','PPO6h',...
    'PPO8h','PPO10h','POO9h','POO7h','POO5h','POO3h','POO1h','POO2h',...
    'POO4h','POO6h','POO8h','POO10h','OI1h','OI2h','Fp1h','Fp2h','AF9h',...
    'AF7h','AF5h','AF3h','AF1h','AF2h','AF4h','AF6h','AF8h','AF10h',...
    'F9h','F7h','F5h','F3h','F1h','F2h','F4h','F6h','F8h','F10h','FT9h',...
    'FT7h','FC5h','FC3h','FC1h','FC2h','FC4h','FC6h','FT8h','FT10h',...
    'T9h','T7h','C5h','C3h','C1h','C2h','C4h','C6h','T8h','T10h','TP9h',...
    'TP7h','CP5h','CP3h','CP1h','CP2h','CP4h','CP6h','TP8h','TP10h',...
    'P9h','P7h','P5h','P3h','P1h','P2h','P4h','P6h','P8h','P10h','PO9h',...
    'PO7h','PO5h','PO3h','PO1h','PO2h','PO4h','PO6h','PO8h','PO10h','O1h',...
    'O2h','I1h','I2h','AFp9','AFp7','AFp5','AFp3','AFp1','AFpz','AFp2',...
    'AFp4','AFp6','AFp8','AFp10','AFF9','AFF7','AFF5','AFF3','AFF1',...
    'AFFz','AFF2','AFF4','AFF6','AFF8','AFF10','FFT9','FFT7','FFC5',...
    'FFC3','FFC1','FFCz','FFC2','FFC4','FFC6','FFT8','FFT10','FTT9',...
    'FTT7','FCC5','FCC3','FCC1','FCCz','FCC2','FCC4','FCC6','FTT8',...
    'FTT10','TTP9','TTP7','CCP5','CCP3','CCP1','CCPz','CCP2','CCP4',...
    'CCP6','TTP8','TTP10','TPP9','TPP7','CPP5','CPP3','CPP1','CPPz',...
    'CPP2','CPP4','CPP6','TPP8','TPP10','PPO9','PPO7','PPO5','PPO3',...
    'PPO1','PPOz','PPO2','PPO4','PPO6','PPO8','PPO10','POO9','POO7',...
    'POO5','POO3','POO1','POOz','POO2','POO4','POO6','POO8','POO10',...
    'OI1','OIz','OI2','T3','T5','T4','T6'};

xyz = [ ...
0.0000	0.9237	-0.3826	;
0.0000	-0.9237	-0.3826	;
0.9230	0.0000	-0.3824	;
0.9511	0.3090	0.0001	;
1.0000	0.0000	0.0001	;
0.9511	-0.3091	0.0000	;
0.7467	0.5425	-0.3825	;
0.8090	0.5878	0.0000	;
0.8553	0.4926	0.1552	;
0.8920	0.3554	0.2782	;
0.9150	0.1857	0.3558	;
0.9230	0.0000	0.3824	;
0.9150	-0.1857	0.3558	;
0.8919	-0.3553	0.2783	;
0.8553	-0.4926	0.1552	;
0.8090	-0.5878	0.0000	;
0.7467	-0.5425	-0.3825	;
0.5430	0.7472	-0.3826	;
0.5878	0.8090	0.0000	;
0.6343	0.7210	0.2764	;
0.6726	0.5399	0.5043	;
0.6979	0.2888	0.6542	;
0.7067	0.0000	0.7067	;
0.6979	-0.2888	0.6542	;
0.6726	-0.5399	0.5043	;
0.6343	-0.7210	0.2764	;
0.5878	-0.8090	0.0000	;
0.5429	-0.7472	-0.3826	;
0.2852	0.8777	-0.3826	;
0.3090	0.9511	0.0000	;
0.3373	0.8709	0.3549	;
0.3612	0.6638	0.6545	;
0.3770	0.3581	0.8532	;
0.3826	0.0000	0.9233	;
0.3770	-0.3581	0.8532	;
0.3612	-0.6638	0.6545	;
0.3373	-0.8709	0.3549	;
0.3090	-0.9511	0.0000	;
0.2852	-0.8777	-0.3826	;
-0.0001	0.9237	-0.3826	;
0.0000	1.0000	0.0000	;
0.0001	0.9237	0.3826	;
0.0001	0.7066	0.7066	;
0.0002	0.3824	0.9231	;
0.0002	0.0000	1.0000	;
0.0001	-0.3824	0.9231	;
0.0001	-0.7066	0.7066	;
0.0001	-0.9237	0.3826	;
0.0000	-1.0000	0.0000	;
0.0000	-0.9237	-0.3826	;
-0.2852	0.8777	-0.3826	;
-0.3090	0.9511	-0.0001	;
-0.3372	0.8712	0.3552	;
-0.3609	0.6635	0.6543	;
-0.3767	0.3580	0.8534	;
-0.3822	0.0000	0.9231	;
-0.3767	-0.3580	0.8534	;
-0.3608	-0.6635	0.6543	;
-0.3372	-0.8712	0.3552	;
-0.3090	-0.9511	-0.0001	;
-0.2853	-0.8777	-0.3826	;
-0.5429	0.7472	-0.3826	;
-0.5878	0.8090	-0.0001	;
-0.6342	0.7211	0.2764	;
-0.6724	0.5401	0.5045	;
-0.6975	0.2889	0.6545	;
-0.7063	0.0000	0.7065	;
-0.6975	-0.2889	0.6545	;
-0.6724	-0.5401	0.5045	;
-0.6342	-0.7211	0.2764	;
-0.5878	-0.8090	-0.0001	;
-0.5429	-0.7472	-0.3826	;
-0.7467	0.5425	-0.3825	;
-0.8090	0.5878	0.0000	;
-0.8553	0.4929	0.1555	;
-0.8918	0.3549	0.2776	;
-0.9151	0.1858	0.3559	;
-0.9230	0.0000	0.3824	;
-0.9151	-0.1859	0.3559	;
-0.8918	-0.3549	0.2776	;
-0.8553	-0.4929	0.1555	;
-0.8090	-0.5878	0.0000	;
-0.7467	-0.5425	-0.3825	;
-0.9511	0.3090	0.0000	;
-1.0000	0.0000	0.0000	;
-0.9511	-0.3090	0.0000	;
-0.8785	0.2854	-0.3824	;
-0.9230	0.0000	-0.3823	;
-0.8785	-0.2854	-0.3824	;
0.8732	0.4449	-0.1949	;
0.9105	0.4093	0.0428	;
0.9438	0.3079	0.1159	;
0.9669	0.1910	0.1666	;
0.9785	0.0647	0.1919	;
0.9785	-0.0647	0.1919	;
0.9669	-0.1910	0.1666	;
0.9438	-0.3079	0.1159	;
0.9105	-0.4093	0.0428	;
0.8732	-0.4449	-0.1949	;
0.6929	0.6929	-0.1949	;
0.7325	0.6697	0.1137	;
0.7777	0.5417	0.3163	;
0.8111	0.3520	0.4658	;
0.8289	0.1220	0.5452	;
0.8289	-0.1220	0.5452	;
0.8111	-0.3520	0.4658	;
0.7777	-0.5417	0.3163	;
0.7325	-0.6697	0.1138	;
0.6929	-0.6929	-0.1949	;
0.4448	0.8730	-0.1950	;
0.4741	0.8642	0.1647	;
0.5107	0.7218	0.4651	;
0.5384	0.4782	0.6925	;
0.5533	0.1672	0.8148	;
0.5533	-0.1672	0.8148	;
0.5384	-0.4782	0.6925	;
0.5107	-0.7218	0.4651	;
0.4741	-0.8642	0.1647	;
0.4448	-0.8730	-0.1950	;
0.1533	0.9678	-0.1950	;
0.1640	0.9669	0.1915	;
0.1779	0.8184	0.5448	;
0.1887	0.5466	0.8154	;
0.1944	0.1919	0.9615	;
0.1944	-0.1919	0.9615	;
0.1887	-0.5466	0.8154	;
0.1779	-0.8184	0.5448	;
0.1640	-0.9669	0.1915	;
0.1533	-0.9678	-0.1950	;
-0.1532	0.9678	-0.1950	;
-0.1639	0.9669	0.1915	;
-0.1778	0.8185	0.5449	;
-0.1883	0.5465	0.8153	;
-0.1940	0.1918	0.9611	;
-0.1940	-0.1918	0.9611	;
-0.1884	-0.5465	0.8153	;
-0.1778	-0.8185	0.5449	;
-0.1639	-0.9669	0.1915	;
-0.1533	-0.9678	-0.1950	;
-0.4448	0.8731	-0.1950	;
-0.4740	0.8639	0.1646	;
-0.5106	0.7220	0.4653	;
-0.5384	0.4786	0.6933	;
-0.5532	0.1673	0.8155	;
-0.5532	-0.1673	0.8155	;
-0.5384	-0.4786	0.6933	;
-0.5106	-0.7220	0.4653	;
-0.4740	-0.8638	0.1646	;
-0.4449	-0.8731	-0.1950	;
-0.6928	0.6928	-0.1950	;
-0.7324	0.6700	0.1139	;
-0.7776	0.5420	0.3167	;
-0.8108	0.3520	0.4659	;
-0.8284	0.1220	0.5453	;
-0.8284	-0.1220	0.5453	;
-0.8108	-0.3519	0.4659	;
-0.7775	-0.5421	0.3167	;
-0.7324	-0.6700	0.1139	;
-0.6928	-0.6928	-0.1950	;
-0.8730	0.4448	-0.1950	;
-0.9106	0.4097	0.0430	;
-0.9438	0.3080	0.1160	;
-0.9665	0.1908	0.1657	;
-0.9783	0.0647	0.1918	;
-0.9783	-0.0647	0.1918	;
-0.9665	-0.1908	0.1657	;
-0.9438	-0.3080	0.1160	;
-0.9106	-0.4097	0.0430	;
-0.8730	-0.4448	-0.1950	;
-0.9679	0.1533	-0.1950	;
-0.9679	-0.1533	-0.1950	;
0.9877	0.1564	0.0001	;
0.9877	-0.1564	0.0001	;
0.7928	0.5759	-0.1949	;
0.8332	0.5463	0.0810	;
0.8750	0.4284	0.2213	;
0.9053	0.2735	0.3231	;
0.9211	0.0939	0.3758	;
0.9210	-0.0939	0.3758	;
0.9053	-0.2735	0.3231	;
0.8750	-0.4284	0.2212	;
0.8332	-0.5463	0.0810	;
0.7927	-0.5759	-0.1949	;
0.5761	0.7929	-0.1949	;
0.6117	0.7772	0.1420	;
0.6549	0.6412	0.3987	;
0.6872	0.4214	0.5906	;
0.7045	0.1468	0.6933	;
0.7045	-0.1468	0.6933	;
0.6872	-0.4214	0.5906	;
0.6549	-0.6412	0.3987	;
0.6117	-0.7772	0.1420	;
0.5761	-0.7929	-0.1949	;
0.3027	0.9317	-0.1950	;
0.3235	0.9280	0.1813	;
0.3500	0.7817	0.5146	;
0.3703	0.5207	0.7687	;
0.3811	0.1824	0.9054	;
0.3811	-0.1824	0.9054	;
0.3703	-0.5207	0.7687	;
0.3500	-0.7817	0.5146	;
0.3235	-0.9280	0.1813	;
0.3028	-0.9317	-0.1950	;
0.0000	0.9801	-0.1950	;
0.0000	0.9801	0.1949	;
0.0001	0.8311	0.5552	;
0.0002	0.5550	0.8306	;
0.0001	0.1950	0.9801	;
0.0002	-0.1950	0.9801	;
0.0002	-0.5550	0.8306	;
0.0001	-0.8311	0.5552	;
0.0000	-0.9801	0.1949	;
0.0000	-0.9801	-0.1950	;
-0.3028	0.9319	-0.1949	;
-0.3234	0.9278	0.1813	;
-0.3498	0.7818	0.5148	;
-0.3699	0.5206	0.7688	;
-0.3808	0.1825	0.9059	;
-0.3808	-0.1825	0.9059	;
-0.3699	-0.5206	0.7688	;
-0.3498	-0.7818	0.5148	;
-0.3234	-0.9278	0.1813	;
-0.3028	-0.9319	-0.1949	;
-0.5761	0.7929	-0.1950	;
-0.6116	0.7771	0.1420	;
-0.6546	0.6411	0.3985	;
-0.6869	0.4217	0.5912	;
-0.7041	0.1469	0.6934	;
-0.7041	-0.1469	0.6934	;
-0.6870	-0.4216	0.5912	;
-0.6546	-0.6411	0.3985	;
-0.6116	-0.7771	0.1420	;
-0.5761	-0.7929	-0.1950	;
-0.7926	0.5759	-0.1950	;
-0.8331	0.5459	0.0809	;
-0.8752	0.4292	0.2219	;
-0.9054	0.2737	0.3233	;
-0.9210	0.0939	0.3757	;
-0.9210	-0.0940	0.3757	;
-0.9054	-0.2737	0.3233	;
-0.8752	-0.4292	0.2219	;
-0.8331	-0.5459	0.0809	;
-0.7926	-0.5758	-0.1950	;
-0.9877	0.1564	0.0000	;
-0.9877	-0.1564	0.0000	;
-0.9118	0.1444	-0.3824	;
-0.9118	-0.1444	-0.3824	;
0.8225	0.4190	-0.3825	;
0.8910	0.4540	0.0000	;
0.9282	0.3606	0.0817	;
0.9565	0.2508	0.1438	;
0.9743	0.1287	0.1828	;
0.9799	0.0000	0.1949	;
0.9743	-0.1287	0.1828	;
0.9565	-0.2508	0.1437	;
0.9282	-0.3606	0.0817	;
0.8910	-0.4540	0.0000	;
0.8225	-0.4191	-0.3825	;
0.6527	0.6527	-0.3825	;
0.7071	0.7071	0.0000	;
0.7564	0.6149	0.2206	;
0.7962	0.4535	0.3990	;
0.8221	0.2404	0.5148	;
0.8312	0.0000	0.5554	;
0.8221	-0.2404	0.5148	;
0.7962	-0.4535	0.3990	;
0.7564	-0.6149	0.2206	;
0.7071	-0.7071	0.0000	;
0.6527	-0.6527	-0.3825	;
0.4192	0.8226	-0.3826	;
0.4540	0.8910	0.0000	;
0.4932	0.8072	0.3215	;
0.5260	0.6110	0.5905	;
0.5477	0.3286	0.7685	;
0.5553	0.0000	0.8310	;
0.5477	-0.3286	0.7685	;
0.5260	-0.6110	0.5905	;
0.4932	-0.8072	0.3216	;
0.4540	-0.8910	0.0000	;
0.4192	-0.8226	-0.3826	;
0.1444	0.9119	-0.3826	;
0.1565	0.9877	0.0000	;
0.1713	0.9099	0.3754	;
0.1838	0.6957	0.6933	;
0.1922	0.3764	0.9059	;
0.1951	0.0000	0.9804	;
0.1922	-0.3764	0.9059	;
0.1838	-0.6957	0.6933	;
0.1713	-0.9099	0.3754	;
0.1564	-0.9877	0.0000	;
0.1444	-0.9119	-0.3826	;
-0.1444	0.9117	-0.3826	;
-0.1564	0.9877	-0.0001	;
-0.1711	0.9100	0.3754	;
-0.1836	0.6959	0.6936	;
-0.1918	0.3763	0.9056	;
-0.1948	0.0000	0.9800	;
-0.1919	-0.3763	0.9056	;
-0.1836	-0.6959	0.6936	;
-0.1711	-0.9100	0.3754	;
-0.1564	-0.9877	-0.0001	;
-0.1444	-0.9117	-0.3826	;
-0.4191	0.8225	-0.3826	;
-0.4540	0.8910	-0.0001	;
-0.4931	0.8073	0.3216	;
-0.5259	0.6109	0.5904	;
-0.5476	0.3285	0.7685	;
-0.5551	0.0000	0.8311	;
-0.5475	-0.3286	0.7685	;
-0.5258	-0.6109	0.5904	;
-0.4931	-0.8073	0.3216	;
-0.4540	-0.8910	-0.0001	;
-0.4191	-0.8225	-0.3826	;
-0.6529	0.6529	-0.3825	;
-0.7071	0.7071	0.0000	;
-0.7561	0.6147	0.2205	;
-0.7960	0.4537	0.3995	;
-0.8218	0.2405	0.5152	;
-0.8306	0.0000	0.5551	;
-0.8218	-0.2405	0.5152	;
-0.7960	-0.4537	0.3995	;
-0.7562	-0.6147	0.2205	;
-0.7071	-0.7071	0.0000	;
-0.6529	-0.6529	-0.3825	;
-0.8228	0.4191	-0.3824	;
-0.8910	0.4540	0.0000	;
-0.9283	0.3608	0.0818	;
-0.9567	0.2511	0.1442	;
-0.9739	0.1285	0.1822	;
-0.9797	0.0000	0.1949	;
-0.9739	-0.1286	0.1822	;
-0.9567	-0.2511	0.1442	;
-0.9283	-0.3608	0.0818	;
-0.8910	-0.4540	0.0000	;
-0.8228	-0.4191	-0.3824	;
-0.9322	0.3029	-0.1949	;
-0.9799	0.0000	-0.1949	;
-0.9322	-0.3029	-0.1949	;
0.0000	1.0000	0.0000	;
-0.5878	0.8090	-0.0001	;
0.0000	-1.0000	0.0000	;
-0.5878	-0.8090	-0.0001	]';


elec = struct(...
    'labels',names,...
    'X',num2cell(xyz(1,:)),...
    'Y',num2cell(xyz(2,:)),...
    'Z',num2cell(xyz(3,:)));


return

% LPA       0.0000  0.9237 -0.3826
% RPA       0.0000 -0.9237 -0.3826
% Nz        0.9230  0.0000 -0.3824
% Fp1       0.9511  0.3090  0.0001
% Fpz       1.0000 -0.0000  0.0001
% Fp2       0.9511 -0.3091  0.0000
% AF9       0.7467  0.5425 -0.3825
% AF7       0.8090  0.5878  0.0000
% AF5       0.8553  0.4926  0.1552
% AF3       0.8920  0.3554  0.2782
% AF1       0.9150  0.1857  0.3558
% AFz       0.9230  0.0000  0.3824
% AF2       0.9150 -0.1857  0.3558
% AF4       0.8919 -0.3553  0.2783
% AF6       0.8553 -0.4926  0.1552
% AF8       0.8090 -0.5878  0.0000
% AF10      0.7467 -0.5425 -0.3825
% F9        0.5430  0.7472 -0.3826
% F7        0.5878  0.8090  0.0000
% F5        0.6343  0.7210  0.2764
% F3        0.6726  0.5399  0.5043
% F1        0.6979  0.2888  0.6542
% Fz        0.7067  0.0000  0.7067
% F2        0.6979 -0.2888  0.6542
% F4        0.6726 -0.5399  0.5043
% F6        0.6343 -0.7210  0.2764
% F8        0.5878 -0.8090  0.0000
% F10       0.5429 -0.7472 -0.3826
% FT9       0.2852  0.8777 -0.3826
% FT7       0.3090  0.9511  0.0000
% FC5       0.3373  0.8709  0.3549
% FC3       0.3612  0.6638  0.6545
% FC1       0.3770  0.3581  0.8532
% FCz       0.3826  0.0000  0.9233
% FC2       0.3770 -0.3581  0.8532
% FC4       0.3612 -0.6638  0.6545
% FC6       0.3373 -0.8709  0.3549
% FT8       0.3090 -0.9511  0.0000
% FT10      0.2852 -0.8777 -0.3826
% T9       -0.0001  0.9237 -0.3826
% T7        0.0000  1.0000  0.0000
% C5        0.0001  0.9237  0.3826
% C3        0.0001  0.7066  0.7066
% C1        0.0002  0.3824  0.9231
% Cz        0.0002  0.0000  1.0000
% C2        0.0001 -0.3824  0.9231
% C4        0.0001 -0.7066  0.7066
% C6        0.0001 -0.9237  0.3826
% T8        0.0000 -1.0000  0.0000
% T10       0.0000 -0.9237 -0.3826
% TP9      -0.2852  0.8777 -0.3826
% TP7      -0.3090  0.9511 -0.0001
% CP5      -0.3372  0.8712  0.3552
% CP3      -0.3609  0.6635  0.6543
% CP1      -0.3767  0.3580  0.8534
% CPz      -0.3822  0.0000  0.9231
% CP2      -0.3767 -0.3580  0.8534
% CP4      -0.3608 -0.6635  0.6543
% CP6      -0.3372 -0.8712  0.3552
% TP8      -0.3090 -0.9511 -0.0001
% TP10     -0.2853 -0.8777 -0.3826
% P9       -0.5429  0.7472 -0.3826
% P7       -0.5878  0.8090 -0.0001
% P5       -0.6342  0.7211  0.2764
% P3       -0.6724  0.5401  0.5045
% P1       -0.6975  0.2889  0.6545
% Pz       -0.7063  0.0000  0.7065
% P2       -0.6975 -0.2889  0.6545
% P4       -0.6724 -0.5401  0.5045
% P6       -0.6342 -0.7211  0.2764
% P8       -0.5878 -0.8090 -0.0001
% P10      -0.5429 -0.7472 -0.3826
% PO9      -0.7467  0.5425 -0.3825
% PO7      -0.8090  0.5878  0.0000
% PO5      -0.8553  0.4929  0.1555
% PO3      -0.8918  0.3549  0.2776
% PO1      -0.9151  0.1858  0.3559
% POz      -0.9230 -0.0000  0.3824
% PO2      -0.9151 -0.1859  0.3559
% PO4      -0.8918 -0.3549  0.2776
% PO6      -0.8553 -0.4929  0.1555
% PO8      -0.8090 -0.5878  0.0000
% PO10     -0.7467 -0.5425 -0.3825
% O1       -0.9511  0.3090  0.0000
% Oz       -1.0000  0.0000  0.0000
% O2       -0.9511 -0.3090  0.0000
% I1       -0.8785  0.2854 -0.3824
% Iz       -0.9230  0.0000 -0.3823
% I2       -0.8785 -0.2854 -0.3824
% AFp9h     0.8732  0.4449 -0.1949
% AFp7h     0.9105  0.4093  0.0428
% AFp5h     0.9438  0.3079  0.1159
% AFp3h     0.9669  0.1910  0.1666
% AFp1h     0.9785  0.0647  0.1919
% AFp2h     0.9785 -0.0647  0.1919
% AFp4h     0.9669 -0.1910  0.1666
% AFp6h     0.9438 -0.3079  0.1159
% AFp8h     0.9105 -0.4093  0.0428
% AFp10h    0.8732 -0.4449 -0.1949
% AFF9h     0.6929  0.6929 -0.1949
% AFF7h     0.7325  0.6697  0.1137
% AFF5h     0.7777  0.5417  0.3163
% AFF3h     0.8111  0.3520  0.4658
% AFF1h     0.8289  0.1220  0.5452
% AFF2h     0.8289 -0.1220  0.5452
% AFF4h     0.8111 -0.3520  0.4658
% AFF6h     0.7777 -0.5417  0.3163
% AFF8h     0.7325 -0.6697  0.1138
% AFF10h    0.6929 -0.6929 -0.1949
% FFT9h     0.4448  0.8730 -0.1950
% FFT7h     0.4741  0.8642  0.1647
% FFC5h     0.5107  0.7218  0.4651
% FFC3h     0.5384  0.4782  0.6925
% FFC1h     0.5533  0.1672  0.8148
% FFC2h     0.5533 -0.1672  0.8148
% FFC4h     0.5384 -0.4782  0.6925
% FFC6h     0.5107 -0.7218  0.4651
% FFT8h     0.4741 -0.8642  0.1647
% FFT10h    0.4448 -0.8730 -0.1950
% FTT9h     0.1533  0.9678 -0.1950
% FTT7h     0.1640  0.9669  0.1915
% FCC5h     0.1779  0.8184  0.5448
% FCC3h     0.1887  0.5466  0.8154
% FCC1h     0.1944  0.1919  0.9615
% FCC2h     0.1944 -0.1919  0.9615
% FCC4h     0.1887 -0.5466  0.8154
% FCC6h     0.1779 -0.8184  0.5448
% FTT8h     0.1640 -0.9669  0.1915
% FTT10h    0.1533 -0.9678 -0.1950
% TTP9h    -0.1532  0.9678 -0.1950
% TTP7h    -0.1639  0.9669  0.1915
% CCP5h    -0.1778  0.8185  0.5449
% CCP3h    -0.1883  0.5465  0.8153
% CCP1h    -0.1940  0.1918  0.9611
% CCP2h    -0.1940 -0.1918  0.9611
% CCP4h    -0.1884 -0.5465  0.8153
% CCP6h    -0.1778 -0.8185  0.5449
% TTP8h    -0.1639 -0.9669  0.1915
% TTP10h   -0.1533 -0.9678 -0.1950
% TPP9h    -0.4448  0.8731 -0.1950
% TPP7h    -0.4740  0.8639  0.1646
% CPP5h    -0.5106  0.7220  0.4653
% CPP3h    -0.5384  0.4786  0.6933
% CPP1h    -0.5532  0.1673  0.8155
% CPP2h    -0.5532 -0.1673  0.8155
% CPP4h    -0.5384 -0.4786  0.6933
% CPP6h    -0.5106 -0.7220  0.4653
% TPP8h    -0.4740 -0.8638  0.1646
% TPP10h   -0.4449 -0.8731 -0.1950
% PPO9h    -0.6928  0.6928 -0.1950
% PPO7h    -0.7324  0.6700  0.1139
% PPO5h    -0.7776  0.5420  0.3167
% PPO3h    -0.8108  0.3520  0.4659
% PPO1h    -0.8284  0.1220  0.5453
% PPO2h    -0.8284 -0.1220  0.5453
% PPO4h    -0.8108 -0.3519  0.4659
% PPO6h    -0.7775 -0.5421  0.3167
% PPO8h    -0.7324 -0.6700  0.1139
% PPO10h   -0.6928 -0.6928 -0.1950
% POO9h    -0.8730  0.4448 -0.1950
% POO7h    -0.9106  0.4097  0.0430
% POO5h    -0.9438  0.3080  0.1160
% POO3h    -0.9665  0.1908  0.1657
% POO1h    -0.9783  0.0647  0.1918
% POO2h    -0.9783 -0.0647  0.1918
% POO4h    -0.9665 -0.1908  0.1657
% POO6h    -0.9438 -0.3080  0.1160
% POO8h    -0.9106 -0.4097  0.0430
% POO10h   -0.8730 -0.4448 -0.1950
% OI1h     -0.9679  0.1533 -0.1950
% OI2h     -0.9679 -0.1533 -0.1950
% Fp1h      0.9877  0.1564  0.0001
% Fp2h      0.9877 -0.1564  0.0001
% AF9h      0.7928  0.5759 -0.1949
% AF7h      0.8332  0.5463  0.0810
% AF5h      0.8750  0.4284  0.2213
% AF3h      0.9053  0.2735  0.3231
% AF1h      0.9211  0.0939  0.3758
% AF2h      0.9210 -0.0939  0.3758
% AF4h      0.9053 -0.2735  0.3231
% AF6h      0.8750 -0.4284  0.2212
% AF8h      0.8332 -0.5463  0.0810
% AF10h     0.7927 -0.5759 -0.1949
% F9h       0.5761  0.7929 -0.1949
% F7h       0.6117  0.7772  0.1420
% F5h       0.6549  0.6412  0.3987
% F3h       0.6872  0.4214  0.5906
% F1h       0.7045  0.1468  0.6933
% F2h       0.7045 -0.1468  0.6933
% F4h       0.6872 -0.4214  0.5906
% F6h       0.6549 -0.6412  0.3987
% F8h       0.6117 -0.7772  0.1420
% F10h      0.5761 -0.7929 -0.1949
% FT9h      0.3027  0.9317 -0.1950
% FT7h      0.3235  0.9280  0.1813
% FC5h      0.3500  0.7817  0.5146
% FC3h      0.3703  0.5207  0.7687
% FC1h      0.3811  0.1824  0.9054
% FC2h      0.3811 -0.1824  0.9054
% FC4h      0.3703 -0.5207  0.7687
% FC6h      0.3500 -0.7817  0.5146
% FT8h      0.3235 -0.9280  0.1813
% FT10h     0.3028 -0.9317 -0.1950
% T9h       0.0000  0.9801 -0.1950
% T7h       0.0000  0.9801  0.1949
% C5h       0.0001  0.8311  0.5552
% C3h       0.0002  0.5550  0.8306
% C1h       0.0001  0.1950  0.9801
% C2h       0.0002 -0.1950  0.9801
% C4h       0.0002 -0.5550  0.8306
% C6h       0.0001 -0.8311  0.5552
% T8h       0.0000 -0.9801  0.1949
% T10h      0.0000 -0.9801 -0.1950
% TP9h     -0.3028  0.9319 -0.1949
% TP7h     -0.3234  0.9278  0.1813
% CP5h     -0.3498  0.7818  0.5148
% CP3h     -0.3699  0.5206  0.7688
% CP1h     -0.3808  0.1825  0.9059
% CP2h     -0.3808 -0.1825  0.9059
% CP4h     -0.3699 -0.5206  0.7688
% CP6h     -0.3498 -0.7818  0.5148
% TP8h     -0.3234 -0.9278  0.1813
% TP10h    -0.3028 -0.9319 -0.1949
% P9h      -0.5761  0.7929 -0.1950
% P7h      -0.6116  0.7771  0.1420
% P5h      -0.6546  0.6411  0.3985
% P3h      -0.6869  0.4217  0.5912
% P1h      -0.7041  0.1469  0.6934
% P2h      -0.7041 -0.1469  0.6934
% P4h      -0.6870 -0.4216  0.5912
% P6h      -0.6546 -0.6411  0.3985
% P8h      -0.6116 -0.7771  0.1420
% P10h     -0.5761 -0.7929 -0.1950
% PO9h     -0.7926  0.5759 -0.1950
% PO7h     -0.8331  0.5459  0.0809
% PO5h     -0.8752  0.4292  0.2219
% PO3h     -0.9054  0.2737  0.3233
% PO1h     -0.9210  0.0939  0.3757
% PO2h     -0.9210 -0.0940  0.3757
% PO4h     -0.9054 -0.2737  0.3233
% PO6h     -0.8752 -0.4292  0.2219
% PO8h     -0.8331 -0.5459  0.0809
% PO10h    -0.7926 -0.5758 -0.1950
% O1h      -0.9877  0.1564  0.0000
% O2h      -0.9877 -0.1564  0.0000
% I1h      -0.9118  0.1444 -0.3824
% I2h      -0.9118 -0.1444 -0.3824
% AFp9      0.8225  0.4190 -0.3825
% AFp7      0.8910  0.4540  0.0000
% AFp5      0.9282  0.3606  0.0817
% AFp3      0.9565  0.2508  0.1438
% AFp1      0.9743  0.1287  0.1828
% AFpz      0.9799 -0.0000  0.1949
% AFp2      0.9743 -0.1287  0.1828
% AFp4      0.9565 -0.2508  0.1437
% AFp6      0.9282 -0.3606  0.0817
% AFp8      0.8910 -0.4540  0.0000
% AFp10     0.8225 -0.4191 -0.3825
% AFF9      0.6527  0.6527 -0.3825
% AFF7      0.7071  0.7071  0.0000
% AFF5      0.7564  0.6149  0.2206
% AFF3      0.7962  0.4535  0.3990
% AFF1      0.8221  0.2404  0.5148
% AFFz      0.8312  0.0000  0.5554
% AFF2      0.8221 -0.2404  0.5148
% AFF4      0.7962 -0.4535  0.3990
% AFF6      0.7564 -0.6149  0.2206
% AFF8      0.7071 -0.7071  0.0000
% AFF10     0.6527 -0.6527 -0.3825
% FFT9      0.4192  0.8226 -0.3826
% FFT7      0.4540  0.8910  0.0000
% FFC5      0.4932  0.8072  0.3215
% FFC3      0.5260  0.6110  0.5905
% FFC1      0.5477  0.3286  0.7685
% FFCz      0.5553  0.0000  0.8310
% FFC2      0.5477 -0.3286  0.7685
% FFC4      0.5260 -0.6110  0.5905
% FFC6      0.4932 -0.8072  0.3216
% FFT8      0.4540 -0.8910  0.0000
% FFT10     0.4192 -0.8226 -0.3826
% FTT9      0.1444  0.9119 -0.3826
% FTT7      0.1565  0.9877  0.0000
% FCC5      0.1713  0.9099  0.3754
% FCC3      0.1838  0.6957  0.6933
% FCC1      0.1922  0.3764  0.9059
% FCCz      0.1951  0.0000  0.9804
% FCC2      0.1922 -0.3764  0.9059
% FCC4      0.1838 -0.6957  0.6933
% FCC6      0.1713 -0.9099  0.3754
% FTT8      0.1564 -0.9877  0.0000
% FTT10     0.1444 -0.9119 -0.3826
% TTP9     -0.1444  0.9117 -0.3826
% TTP7     -0.1564  0.9877 -0.0001
% CCP5     -0.1711  0.9100  0.3754
% CCP3     -0.1836  0.6959  0.6936
% CCP1     -0.1918  0.3763  0.9056
% CCPz     -0.1948  0.0000  0.9800
% CCP2     -0.1919 -0.3763  0.9056
% CCP4     -0.1836 -0.6959  0.6936
% CCP6     -0.1711 -0.9100  0.3754
% TTP8     -0.1564 -0.9877 -0.0001
% TTP10    -0.1444 -0.9117 -0.3826
% TPP9     -0.4191  0.8225 -0.3826
% TPP7     -0.4540  0.8910 -0.0001
% CPP5     -0.4931  0.8073  0.3216
% CPP3     -0.5259  0.6109  0.5904
% CPP1     -0.5476  0.3285  0.7685
% CPPz     -0.5551  0.0000  0.8311
% CPP2     -0.5475 -0.3286  0.7685
% CPP4     -0.5258 -0.6109  0.5904
% CPP6     -0.4931 -0.8073  0.3216
% TPP8     -0.4540 -0.8910 -0.0001
% TPP10    -0.4191 -0.8225 -0.3826
% PPO9     -0.6529  0.6529 -0.3825
% PPO7     -0.7071  0.7071  0.0000
% PPO5     -0.7561  0.6147  0.2205
% PPO3     -0.7960  0.4537  0.3995
% PPO1     -0.8218  0.2405  0.5152
% PPOz     -0.8306  0.0000  0.5551
% PPO2     -0.8218 -0.2405  0.5152
% PPO4     -0.7960 -0.4537  0.3995
% PPO6     -0.7562 -0.6147  0.2205
% PPO8     -0.7071 -0.7071  0.0000
% PPO10    -0.6529 -0.6529 -0.3825
% POO9     -0.8228  0.4191 -0.3824
% POO7     -0.8910  0.4540  0.0000
% POO5     -0.9283  0.3608  0.0818
% POO3     -0.9567  0.2511  0.1442
% POO1     -0.9739  0.1285  0.1822
% POOz     -0.9797 -0.0000  0.1949
% POO2     -0.9739 -0.1286  0.1822
% POO4     -0.9567 -0.2511  0.1442
% POO6     -0.9283 -0.3608  0.0818
% POO8     -0.8910 -0.4540  0.0000
% POO10    -0.8228 -0.4191 -0.3824
% OI1      -0.9322  0.3029 -0.1949
% OIz      -0.9799  0.0000 -0.1949
% OI2      -0.9322 -0.3029 -0.1949
% T3        0.0000  1.0000  0.0000
% T5       -0.5878  0.8090 -0.0001
% T4        0.0000 -1.0000  0.0000
% T6       -0.5878 -0.8090 -0.0001