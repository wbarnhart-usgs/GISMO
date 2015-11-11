      function h = specgram(s, ws, varargin)
         %specgram - plots spectrogram of waveforms
         %  h = TraceSpectra.specgram(waveforms) Generates a spectrogram from the
         %  waveform(s), overwriting the current figure.  The return value is a
         %  handle to the spectrogram, and is optional. The spectrograms will be
         %  created in the same shape as the passed waveforms.  ie, if W is a 2x3
         %  matrix of waveforms, then specgram(TraceSpectra,W) will generate a 2x3
         %  plot of spectra.
         %
         %  Many additional behaviors can be modified through the passing of
         %  additional parameters, as listed further below.  These parameters are
         %  always passed in pairs, as such:
         %
         %  TraceSpectra.specgram(waveforms,'PARAM1',VALUE1,...,'PARAMn',VALUEn)
         %    Any number of these parameters may be passed to specgram.
         %
         %  specgram(..., 'axis', AXIS_HANDLE)
         %    Specify the axis AXIS_HANDLE within which the spectrogram will be
         %    generated.  The boundary of the axis becomes the boundary for the
         %    entire spectra plot.  For a matrix of waveforms, this area is
         %    subdivided into NxM subplots, where N and M are the size of the
         %    waveform matrix.
         %
         %  specgram(..., 'xunit', XUNIT)
         %    Spedifies the x-unit scale to be used with the spectrogram.  The
         %    default unit is 'seconds'.
         %    valid xunits:
         %     'seconds','minutes','hours','days','doy' (day of year),and 'date'
         %
         %  specgram(..., 'colormap', ALTERNATEMAP)
         %    Instead of using the default colormap, any colormap may be used.  An
         %    alternate way of setting the global map is by using the SETMAP
         %    function.  ALTERNATEMAP will either be a name (eg. grayscale) or an
         %    Nx3 numeric. Type HELP GRAPH3D to see additional useful colormaps.
         %
         %
         %  specgram(..., 'colorbar', COLORBAR_OPTION)
         %    Generates a spectrogram from the waveform and uses a specific map
         %    valid COLORBAR_OPTION values: 'horiz' (default),'vert','none',
         %      'HORIZ' places a single colorbar below all plots
         %      'VERT' places a single colorbar to the right of all plots
         %      'NONE' supresses the colorbar placement
         %
         %  specgram(..., 'yscale', YSCALE)
         %    Choosing 'log' Allows the y-axis to be generated on a log-frequency
         %    scale, with uneven vertical cell spacing.  The default value is
         %    'normal', and provides the standard spectrogram view.
         %    valid yscales: 'normal', 'log' (see NOTE below)
         %
         %    NOTE: In order to use the log scale, UIMAGESC needs to be available on
         %    the matlab path.  This routine was created by Frederic Moisy, and may
         %    be downloaded from the maltabcentral fileexchange (File ID: 11368).
         %    If this routine is not found,then the original spectrogram will be
         %    created.
         %
         %   h = specgram(..., 'fontsize', FONTSIZE)
         %   Specify the font size for a spectrogram.  The default font size is 8.
         %
         %  specgram2(..., 'innerLabels', SHOWINNERLABELS)
         %    Suppress the labling of the inside graphs by setting SHOWINNERLABELS
         %    to false.  If this is false, then the frequency label only shows on
         %    the leftmost spectrograms, and the X-unit label only shows on the
         %    bottommost spectrograms.
         %
         %  The following plots a waveform using an alternate mapping, an xunit of
         %  'hours', and with the y-axis plotted using a log scale.
         %  ex. specgram(TraceSpectra, waveform,...
         %      'colormap', alternateMap,'xunit','h','yscale','log')
         %
         %
         %  Example:
         %    % create an arbitrary subplot, and then plot multiple spectra
         %    a = subplot(3,2,1);
         %    specgram(TraceSpectra,waves,'axis',a); % waves is an NxM waveform
         %
         %
         %  See also SPECTRALOBJECT/SPECGRAM2, WAVEFORM/PLOT, WAVEFORM/FILLGAPS

         
         % Thanks to Jason Amundson for providing the way to do log scales
                  
         
         currFontSize = 8;
         %enforce input arguments.
         if ~isa(ws,'TraceData')
            error('Second input argument should be a TraceData, not a %s',class(ws));
         end
         p = parseInputs(s, varargin);

         %% search for relevent property pairs passed as parameters
         myaxis = p.Results.axis; % area to be used
         % position not used...
         alternateMap = p.Results.colormap; 
         xChoice = p.Results.xunit; %time units for plot
         currFontSize = p.Results.fontsize; % used for all laels within plot
         colorbarpref = p.Results.colorbar; %position of colorbar
         suppressLabels = p.Results.innerlabels; %show only outside
         useXlabel = p.Results.useXlabel; % no x labels
         useYlabel = p.Results.useYlabel; % no y labels

         logscale = strcmpi(p.Results.yscale,'log');

         
         %% figure out exactly WHERE to plot the spectrogram(s)
         %find out area(axis) in which the spectrograms will be plotted
         clabel= 'Relative Amplitude  (dB)';
         
         if myaxis == 0,
            clf;
            myaxis = gca;
            get(gca,'position');
         else
            get(myaxis,'position');
         end
         
         %% If there are multiple waveforms...
         % subdivide the axis and loop through specgram2 with individual waveforms.
                  
         if numel(ws) > 1
            %create the colorbar if desired
            TraceSpectra.createcolorbar(s, colorbarpref, clabel, currFontSize)
            h = TraceSpectra.subdivide_axes(myaxis,size(ws));
            remainingproperties = buildParameterList(p.Unmatched);
            for n=1:numel(h)
               keepYlabel =  ~suppressLabels || (n <= size(h,1));
               keepXlabel = ~suppressLabels || (mod(n,size(h,2))==0);
               specgram(s,ws(n),...
                  'xunit',xChoice,...
                  'axis',h(n),...
                  'fontsize',currFontSize,...
                  'useXlabel',keepXlabel,...
                  'useYlabel',keepYlabel,...
                  'colorbar','none',...
                  remainingproperties{:});
            end
            return
         end
         
         axes(myaxis);
         
         if ws.hasnan % only 1 trace guaranteed at this point...
            warning('TraceSpectra:specgram:nanValue',...
               ['This trace has at least one NaN value, which will blank',...
               'the related spectrogram segment. ',...
               'Remove NaN values by either splitting up the ',...
               'waveform into non-NaN sections or by using TraceData/fillgaps',...
               ' to replace the NaN values.']);
         end
         
         [xunit, xfactor] = TraceSpectra.parse_xunit(xChoice);
         
         switch lower(xunit)
            case 'date'
               % we need the actual times...
               Xvalues = get(ws,'timevector');
               
            case 'day of year'
               startvec = datevec(get(ws,'start'));
               Xvalues = get(ws,'timevector');
               dec31 = datenum(startvec(1)-1,12,31); % 12/31/xxxx of previous year in Matlab format
               Xvalues = Xvalues - dec31;
               xunit = [xunit, ' (', datestr(startvec,'yyyy'),')'];
               
            otherwise,
               dl= 1:ws:nsamples(); %dl : DataLength
               Xvalues = dl .* ws.period ./ xfactor;
         end
         
         
         %%  once was function specgram(d, NYQ, nfft, noverlap, freqmax, dBlims)
         
         nx = length(ws.data);
         window = hanning(s.nfft);
         nwind = length(window);
         if nx < nwind    % zero-pad x if it has length less than the window length
            ws.data(nwind) = 0;
            nx = nwind;
         end
         
         ncol = fix( (nx - s.over) / (nwind - s.over) );
         
         %added "floor" below
         colindex = 1 + floor(0:(ncol-1))*(nwind- s.over);
         rowindex = (1:nwind)';
         if length(ws.data)<(nwind+colindex(ncol)-1)
            ws.data(nwind+colindex(ncol)-1) = 0;   % zero-pad x
         end
         
         y = zeros(nwind,ncol);
         
         % put x into columns of y with the proper offset
         % should be able to do this with fancy indexing!
         A_ = colindex(  ones(nwind, 1) ,: )    ;
         B_ = rowindex(:, ones(1, ncol)    )    ;
         y(:) = ws.data(fix(A_ + B_ -1));
         clear A_ B_
         
         for k = 1:ncol;         %  remove the mean from each column of y
            y(:,k) = y(:,k)-mean(y(:,k));
         end
         
         % Apply the window to the array of offset signal segments.
         y = window(:,ones(1,ncol)).*y;
         
         % USE FFT
         % now fft y which does the columns
         y = fft(y,s.nfft);
         if ~any(any(imag(ws.data)))    % x purely real
            if rem(s.nfft,2),    % nfft odd
               select = 1:(s.nfft+1)/2;
            else
               select = 1:s.nfft/2+1;
            end
            y = y(select,:);
         else
            select = 1:s.nfft;
         end
         f = (select - 1)' * ws.samplerate / s.nfft;
                  
         NF = s.nfft/2 + 1;
         nf1=round(f(1) / ws.nyquist * NF);                     %frequency window
         if nf1==0, nf1=1; end
         nf2=NF;
         
         y = 20*log10(abs(y(nf1:nf2,:)));
         
         F = f(f <= s.freqmax);
         
         
         if F(1)==0,
            F(1)=0.001;
         end
         
         if logscale
            t = linspace(Xvalues(1), Xvalues(end),ncol); % Replaced by TCB - 01/18/2012
            try
               h = uimagesc(t, log10(F), y(nf1:length(F),:), s.dBlims);
            catch exception
               if strcmp(exception.identifier, 'MATLAB:UndefinedFunction')
                  warning('Spectralobject:specgram:uimageNotInstalled',...
                     ['Cannot plot with log spacing because uimage, uimagesc ',...
                     ' not installed or not visible in matlab path.']);
                  h = imagesc(Xvalues,F,y(nf1:length(F),:),s.dBlims);
                  logscale = false;
               else
                  rethrow(exception)
               end
            end
         else
            h = imagesc(Xvalues, F, y(nf1:length(F),:), s.dBlims);
         end
         set(gca, 'fontsize', currFontSize);
         if strcmpi(xunit, 'date')
            datetick('x', 'keepticks');
         end
         titlename = [ws.station '-' ws.channel '  from:' ws.start];
         title (titlename);
         axis xy;
         colormap(alternateMap);
         shading flat
         axis tight;
         if useYlabel
            if ~logscale
               ylabel ('Frequency (Hz)')
            else
               ylabel ('Log Frequency (log Hz)')
            end
            
         end
         if useXlabel
            xlabel(['Time - ',xunit]);
         end

         %create the colorbar if desired
         TraceSpectra.createcolorbar(s,colorbarpref, clabel, currFontSize);
         
         %% added a series of functions that help with argument parsing.
         % These were ported from my waveform/plot function.
         

      end %specgram
      
function p = parseInputs(me, cellOfArgs)
   %TODO: Unify(?) specgram2 and specgram parseInputs
   p = inputParser;
   p.StructExpand = true;
   p.KeepUnmatched = true;
   p.CaseSensitive = false;
   %NOTE: older version of matlab requires addParamValue instead of addParamter
   % AXIS: a handle to the axis, defining the area to be used
   p.addParameter('axis', 0); %myaxis
   % POSITION: 1x4 vector, specifying area in which to plot [left, bottom, width, height]
   p.addParameter('position', []);
   % alternateMap: COLORMAP:
   p.addParameter('colormap', me.SPECTRAL_MAP);
   % COLORBAR: Dictate the position of the colorbart relative to the plot
   p.addParameter('colorbar', 'horiz');
   % XUNIT: Specify the time units for the plot.  eg, hours, minutes, doy, etc.
   p.addParameter('xunit', me.scaling);
   % FONTSIZE: specify the font size to be used for all labels within the plot
   p.addParameter('fontsize', 10);
   % YSCALE: either 'normal', or 'log'
   p.addParameter('yscale', 'normal');
   % SUPRESSINNERLABELS: true, false
   p.addParameter('innerlabels', false);
   % USEXLABELS: true, false
   p.addParameter('useXlabel', true);
   % USEYLABELS: true, false
   p.addParameter('useYlabel', true);
   p.parse(cellOfArgs{:});
end

function newParams = buildParameterList(paramStruct)
   %newParams   creates argument list from a struct
   %TODO: Unify(?) specgram2 and specgram buildParameterList
   fieldList = fieldnames(paramStruct);
   if isempty(fieldList)
      newParams = {};
   else
      v = struct2cell(paramStruct);
      newParams = horzcat(fieldList,v);
   end
end