function Tracked=EasyTrack(varargin)

try
    Tracked=Initialize(varargin);
    LoadFiles;
    RemoveBackground;
    DoSegmentation;
    DoTracking;
    DoFluorescence;
    openGUI;
catch ME
    if strcmp(ME.message,'Init.cancel')
        Tracked=[];
        return
    else
        rethrow(ME);
    end
end



    function Tracked=Initialize(params)
        if length(params)==1
            %TBD: verify parameters?
            Tracked=params{1};
        else
            Tracked.cfg=CreateConfigFile;
        end
        
        function configstruct=CreateConfigFile
            
            configstruct=struct;
            
            %% Setup the gui
            
            %create the figure
            fh=figure('Name','Configure analysis parameters','MenuBar','none','NumberTitle','off');
            hroot=groot;
            figH=600;
            figW=550;
            fh.Position=[(hroot.ScreenSize(3)-figW)/2,(hroot.ScreenSize(4)-figH)/2,figW,figH];
            line_height=56/3;
            %% specify folder name
            start_line=0;
            num_lines=7;
            hparameters=uipanel('Title','Analysis Folder','Units','pixels','Position',[0,figH-(start_line+num_lines)*line_height,figW,num_lines*line_height]);
            first_row=3;
            col_sep=10;
            
            cur_row=first_row;
            cur_col=col_sep;
            hFN.lbl=uicontrol('parent',hparameters,'Style','Text',...
                'String','Folder Name :','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height]);
            hFN.lbl.Position(3)=hFN.lbl.Extent(3);
            
            cur_col=hFN.lbl.Position(1)+hFN.lbl.Position(3)+col_sep;
            hFN.name=uicontrol('parent',hparameters,'Style','Edit',...
                'String','','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@CbFolderBox);
            hFN.name.Position(3)=figW-cur_col-line_height-col_sep;
            
            cur_col=hFN.name.Position(1)+hFN.name.Position(3);
            hFN.btn=uicontrol('parent',hparameters,'Style','pushbutton',...
                'String','...','HorizontalAlignment','center',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,line_height,line_height],...
                'Callback',@CbFolderBtn);
            %% define the file name format
            
            cur_row=cur_row+2;
            cur_col=col_sep;
            hRE.lbl=uicontrol('parent',hparameters,'Style','Text',...
                'String','File name format :','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height]);
            hRE.lbl.Position(3)=hRE.lbl.Extent(3);
            
            cur_col=hRE.lbl.Position(1)+hRE.lbl.Position(3)+col_sep;
            hRE.sep1=uicontrol('parent',hparameters,'Style','Edit',...
                'String','.*_w','HorizontalAlignment','center',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hRECallback);
            hRE.sep1.Position(3)=60;
            
            cur_col=hRE.sep1.Position(1)+hRE.sep1.Position(3)+1;
            hRE.tok1=uicontrol('parent',hparameters,'Style','popupmenu',...
                'String',{'Channel','Position','Frame'},'Value',1,...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hRECallback);
            hRE.tok1.Position(3)=60;
            
            cur_col=hRE.tok1.Position(1)+hRE.tok1.Position(3)+1;
            hRE.sep2=uicontrol('parent',hparameters,'Style','Edit',...
                'String','_s','HorizontalAlignment','center',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hRECallback);
            hRE.sep2.Position(3)=60;
            
            cur_col=hRE.sep2.Position(1)+hRE.sep2.Position(3)+1;
            hRE.tok2=uicontrol('parent',hparameters,'Style','popupmenu',...
                'String',{'Channel','Position','Frame'},'Value',2,...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hRECallback);
            hRE.tok2.Position(3)=60;
            
            cur_col=hRE.tok2.Position(1)+hRE.tok2.Position(3)+1;
            hRE.sep3=uicontrol('parent',hparameters,'Style','Edit',...
                'String','_t','HorizontalAlignment','center',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hRECallback);
            hRE.sep3.Position(3)=60;
            
            cur_col=hRE.sep3.Position(1)+hRE.sep3.Position(3)+1;
            hRE.tok3=uicontrol('parent',hparameters,'Style','popupmenu',...
                'String',{'Channel','Position','Frame'},'Value',3,...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hRECallback);
            hRE.tok3.Position(3)=60;
            
            cur_col=hRE.tok3.Position(1)+hRE.tok3.Position(3)+1;
            hRE.ext=uicontrol('parent',hparameters,'Style','Edit',...
                'String','.TIF','Value',1,...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hRECallback);
            hRE.ext.Position(3)=50;
            
            % advanced mode
            cur_row=cur_row+1;
            toggleRegExpFields;
            
            cur_col=col_sep;%hFN.lbl.Position(1)+hFN.lbl.Position(3)+col_sep;
            hREadv=uicontrol('parent',hparameters,'Style','pushbutton',...
                'String','Advanced','HorizontalAlignment','center',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hREadvCallback);
            hREadv.Position(3)=1.5*hREadv.Extent(3);
            
            % include subfolders
            cur_col=hREadv.Position(1)+hREadv.Position(3)+col_sep;
            hFN.subfolders=uicontrol('parent',hparameters,'Style','checkbox',...
                'String','Include Subfolders','HorizontalAlignment','center','Value',1,...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@CbFolderBox);
            hFN.subfolders.Position(3)=hFN.subfolders.Extent(3)+50;
            %% select channels/position/frames
            start_line=start_line+num_lines;
            num_lines=10;
            hEFpanel=uipanel('Title','Select Channels/Position/Frames','Units','pixels','Position',[0,figH-(start_line+num_lines)*line_height,figW,num_lines*line_height]);
            cur_row=3;
            cur_col=3*col_sep;
            hEF.lbl1a=uicontrol('parent',hEFpanel,'Style','Text',...
                'String','Select Channels','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height]);
            hEF.lbl1a.Position(3)=hEF.lbl1a.Extent(3);
            hEF.lbl1b=uicontrol('parent',hEFpanel,'Style','Text',...
                'String','For Tracking','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row-1)*line_height,1,line_height]);
            hEF.lbl1b.Position(3)=hEF.lbl1b.Extent(3);
            hEF.listbox1=uicontrol('parent',hEFpanel,'Style','listbox',...
                'String','','HorizontalAlignment','left','Max',2,...
                'Position',[cur_col,(num_lines-cur_row-2-4)*line_height,1,5*line_height],...
                'Callback',@hEFlistboxCallback);
            hEF.listbox1.Position(3)=100;
            cur_col=hEF.listbox1.Position(1)+hEF.listbox1.Position(3)+3*col_sep;
            
            hEF.lbl2a=uicontrol('parent',hEFpanel,'Style','Text',...
                'String','Select Channels','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height]);
            hEF.lbl2a.Position(3)=hEF.lbl2a.Extent(3);
            hEF.lbl2b=uicontrol('parent',hEFpanel,'Style','Text',...
                'String','For Analysis','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row-1)*line_height,1,line_height]);
            hEF.lbl2b.Position(3)=hEF.lbl2b.Extent(3);
            hEF.listbox2=uicontrol('parent',hEFpanel,'Style','listbox',...
                'String','','HorizontalAlignment','left','Max',2,...
                'Position',[cur_col,(num_lines-cur_row-2-4)*line_height,1,5*line_height],...
                'Callback',@hEFlistboxCallback);
            hEF.listbox2.Position(3)=100;
            cur_col=hEF.listbox2.Position(1)+hEF.listbox2.Position(3)+3*col_sep;
            
            hEF.lbl3a=uicontrol('parent',hEFpanel,'Style','Text',...
                'String','Select','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height]);
            hEF.lbl3a.Position(3)=hEF.lbl3a.Extent(3);
            hEF.lbl3b=uicontrol('parent',hEFpanel,'Style','Text',...
                'String','Position','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row-1)*line_height,1,line_height]);
            hEF.lbl3b.Position(3)=hEF.lbl3b.Extent(3);
            hEF.listbox3=uicontrol('parent',hEFpanel,'Style','listbox',...
                'String','','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row-2-4)*line_height,1,5*line_height],...
                'Callback',@hEFlistboxCallback);
            hEF.listbox3.Position(3)=100;
            cur_col=hEF.listbox3.Position(1)+hEF.listbox3.Position(3)+3*col_sep;
            
            hEF.lbl4a=uicontrol('parent',hEFpanel,'Style','Text',...
                'String','Select','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height]);
            hEF.lbl4a.Position(3)=hEF.lbl4a.Extent(3);
            hEF.lbl4b=uicontrol('parent',hEFpanel,'Style','Text',...
                'String','Frame numbers','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row-1)*line_height,1,line_height]);
            hEF.lbl4b.Position(3)=hEF.lbl4b.Extent(3);
            hEF.listbox4=uicontrol('parent',hEFpanel,'Style','listbox',...
                'String','','HorizontalAlignment','left','Max',2,...
                'Position',[cur_col,(num_lines-cur_row-2-4)*line_height,1,5*line_height],...
                'Callback',@hEFlistboxCallback);
            hEF.listbox4.Position(3)=100;
            
            %% Background subtruction
            start_line=start_line+num_lines;
            num_lines=7;
            hBSpanel=uipanel('Title','Background Subtruction','Units','pixels','Position',[0,figH-(start_line+num_lines)*line_height,figW,num_lines*line_height]);
            
            cur_row=2;
            cur_col=col_sep;
            hBStypeBG=uibuttongroup(hBSpanel,'Units','pixels','Position',[cur_col,(num_lines-cur_row-5+0.5)*line_height,200,5*line_height]);
            hBS.noneRB=uicontrol('parent',hBStypeBG,'Style','radiobutton',...
                'String','None','Tag','None','HorizontalAlignment','center',...
                'Position',[0,3.7*line_height,100,line_height],'Enable','off',...
                'Callback',@CbBSType);
            hBS.flatRB=uicontrol('parent',hBStypeBG,'Style','radiobutton',...
                'String','Flat','Tag','Flat','HorizontalAlignment','center',...
                'Position',[100,3.7*line_height,100,line_height],'Enable','off','Value',1,...
                'Callback',@CbBSType);
            hBS.fitRB=uicontrol('parent',hBStypeBG,'Style','radiobutton',...
                'String','Fit (Auto)','Tag','Fit','HorizontalAlignment','center',...
                'Position',[0,2.6*line_height,100,line_height],'Enable','off',...
                'Callback',@CbBSType);
            hBS.posRB=uicontrol('parent',hBStypeBG,'Style','radiobutton',...
                'String','Position(s)','Tag','Pos','HorizontalAlignment','center',...
                'Position',[0,1.5*line_height,100,line_height],'Enable','off',...
                'Callback',@CbBSType);
            hBS.fileRB=uicontrol('parent',hBStypeBG,'Style','radiobutton',...
                'String','File','Tag','File','HorizontalAlignment','center',...
                'Position',[0,0.4*line_height,100,line_height],'Enable','off',...
                'Callback',@CbBSType);
            
            cur_col=hBStypeBG.Position(1)+hBStypeBG.Position(3)+col_sep;
            cur_row=2.5;
            hBS.listboxSelPos=uicontrol('parent',hBSpanel,'Style','listbox',...
                'String','','HorizontalAlignment','left','Max',2,...
                'Position',[cur_col,(num_lines-cur_row-4)*line_height,100,5*line_height],'Visible','off',...
                'Callback',@CbBSSelPos);
            hBS.listboxSelFile=uicontrol('parent',hBSpanel,'Style','listbox',...
                'String','','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row-4)*line_height,300,5*line_height],'Visible','off',...
                'Callback',@CbBSSelFile);
            
            cur_col=hBS.listboxSelFile.Position(1)+hBS.listboxSelFile.Position(3)+col_sep;
            cur_row=2.5;
            hBS.choosePB=uicontrol('parent',hBSpanel,'Style','pushbutton',...
                'String','Choose Files...','HorizontalAlignment','center',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,100,line_height],'Visible','off',...
                'Callback',@CbBSFileChoose);
            
            
            
            % choose/create file
            
            hBScell=struct2cell(hBS);
            hBScell=[hBScell{:}];
            [hBScell.Enable]=deal('off');
            
            hBSfiles=[];
            %% preferences
            start_line=start_line+num_lines;
            num_lines=5;
            hprefs=uipanel('Title','Choose analysis preferences','Units','pixels','Position',[0,figH-(start_line+num_lines)*line_height,figW,num_lines*line_height]);
            
            cur_row=2;
            cur_col=col_sep;
            hPrefs.checkbox1=uicontrol('parent',hprefs,'Style','checkbox',...
                'String','Segment','HorizontalAlignment','left','Value',1,...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hPrefsCallback);
            hPrefs.checkbox1.Position(3)=hPrefs.checkbox1.Extent(3)+50;
            cur_row=cur_row+1;
            hPrefs.checkbox2=uicontrol('parent',hprefs,'Style','checkbox',...
                'String','Track','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hPrefsCallback);
            hPrefs.checkbox2.Position(3)=hPrefs.checkbox2.Extent(3)+50;
            cur_row=cur_row+1;
            hPrefs.checkbox3=uicontrol('parent',hprefs,'Style','checkbox',...
                'String','Extract Fluorescence','HorizontalAlignment','left',...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hPrefsCallback);
            hPrefs.checkbox3.Position(3)=hPrefs.checkbox3.Extent(3)+50;
            
            cur_row=2;
            cur_col=col_sep+150;
            hPrefs.checkbox4=uicontrol('parent',hprefs,'Style','checkbox',...
                'String','Open GUI','HorizontalAlignment','left','Value',1,...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hPrefsCallback);
            hPrefs.checkbox4.Position(3)=hPrefs.checkbox4.Extent(3)+50;
            cur_row=cur_row+1;
            hPrefs.checkbox5=uicontrol('parent',hprefs,'Style','checkbox',...
                'String','Parallel Processing','HorizontalAlignment','left','Value',0,...
                'Position',[cur_col,(num_lines-cur_row)*line_height,1,line_height],...
                'Callback',@hPrefsCallback);
            hPrefs.checkbox5.Position(3)=hPrefs.checkbox5.Extent(3)+50;
            
            hPrefscell=struct2cell(hPrefs);
            hPrefscell=[hPrefscell{:}];
            [hPrefscell.Enable]=deal('off');
            %% close
            start_line=start_line+num_lines;
            hAnlz=uicontrol('parent',fh,'Style','pushbutton',...
                'String','ANALYZE','HorizontalAlignment','center','FontSize',20,...
                'Position',[0,0,figW,figH-(start_line)*line_height],...
                'Callback',@AnalyzeCallback);
            hAnlz.Enable='off';
            
            uiwait
            if ~isfield(configstruct,'Foldername')
                error('Init.cancel')
            end
            
            %% functions
            function CbFolderBtn(~,~)
                selected_directory=uigetdir;
                hFN.name.String=selected_directory;
                UpdateFolder;
            end
            function CbFolderBox(~,~)
                UpdateFolder;
            end
            function hRECallback(~,~)
                hREcell=struct2cell(hRE);
                hREcell=[hREcell{:}];
                if all(sort([hRE.tok1.Value,hRE.tok2.Value,hRE.tok3.Value,])==[1,2,3])
                    [hREcell.BackgroundColor]=deal([0.94,0.94,0.94]);
                    hEF.lbl1.String=hRE.tok1.String{hRE.tok1.Value};
                    hEF.lbl2.String=hRE.tok2.String{hRE.tok2.Value};
                    hEF.lbl2.String=hRE.tok2.String{hRE.tok2.Value};
                    UpdateFolder;
                else
                    [hREcell.BackgroundColor]=deal('r');
                end
            end
            function hREadvCallback(~,~)
                toggleRegExpFields;
            end
            function hEFlistboxCallback(~,~)
                UpdateBSFilelist
            end
            function CbBSType(~,~)
                hBS.choosePB.Visible='off';
                hBS.listboxSelPos.Visible='off';
                hBS.listboxSelFile.Visible='off';
                switch hBStypeBG.SelectedObject.String
                    case 'Position(s)'
                        hBS.listboxSelPos.Visible='on';
                    case 'File'
                        hBS.listboxSelFile.Visible='on';
                        hBS.choosePB.Visible='on';
                end
            end
            function CbBSSelPos(~,~)
            end
            function CbBSSelFile(~,~)
            end
            function CbBSFileChoose(~,~)
                [filename,pathname]=uigetfile('*');
                hBSfiles(hBS.listboxSelFile.Value).file=[pathname filename];
                UpdateBSFilelist;
            end
            function hPrefsCallback(~,~)
                ProcessPrefs;
            end
            function AnalyzeCallback(~,~)
                configstruct=struct;
                configstruct.Foldername=hFN.name.String;
                configstruct.subfolders=hFN.subfolders.Value;
                configstruct.REstr=[hRE.sep1.String, '(.*)',...
                    hRE.sep2.String, '(.*)',...
                    hRE.sep3.String, '(.*)',...
                    hRE.ext.String];
                configstruct.tokenNames=[hRE.tok1.String(hRE.tok1.Value),...
                    hRE.tok2.String(hRE.tok2.Value),...
                    hRE.tok3.String(hRE.tok3.Value)];
                configstruct.ChannelTrak=hEF.listbox1.String(hEF.listbox1.Value);
                configstruct.ChannelAnlz=hEF.listbox2.String(hEF.listbox2.Value);
                configstruct.PositionAnlz=hEF.listbox3.String(hEF.listbox3.Value);
                configstruct.FramesAnlz=str2num(hEF.listbox4.String(hEF.listbox4.Value,:)); %#ok<ST2NM>
                
                configstruct.BkgSub.Type=hBStypeBG.SelectedObject.Tag;
                configstruct.BkgSub.Prm=[];
                switch configstruct.BkgSub.Type
                    case 'Pos'
                        configstruct.BkgSub.Prm=hBS.listboxSelPos.String(hBS.listboxSelPos.Value);
                    case 'File'
                        configstruct.BkgSub.Prm=hBSfiles;
                end
                
                configstruct.Anlz.Segment=hPrefs.checkbox1.Value;
                configstruct.Anlz.Track=hPrefs.checkbox2.Value;
                configstruct.Anlz.Extract=hPrefs.checkbox3.Value;
                configstruct.Anlz.GUI=hPrefs.checkbox4.Value;
                configstruct.Anlz.Parallel=hPrefs.checkbox5.Value;
                
                close(fh);
            end
            
            function UpdateFolder
                if extractFields
                    [hPrefscell.Enable]=deal('on');
                    ProcessPrefs;
                    hAnlz.Enable='on';
                    [hBScell.Enable]=deal('on');
                else
                    [hPrefscell.Enable]=deal('off');
                    hAnlz.Enable='off';
                    [hBScell.Enable]=deal('off');
                end
            end
            
            function R=extractFields
                R=0;
                hEF.listbox1.String='';
                hEF.listbox1.Value=1;
                hEF.listbox2.String='';
                hEF.listbox2.Value=1;
                hEF.listbox3.String='';
                hEF.listbox3.Value=1;
                hEF.listbox4.String='';
                hEF.listbox4.Value=1;
                
                if isdir(hFN.name.String)
                    if hFN.subfolders.Value==1
                        filelist=inclusivedir(hFN.name.String);
                    else
                        filelist=dir(hFN.name.String);
                        filelist={filelist.name};
                    end
                else
                    filelist={};
                end
                
                if ~isempty(filelist)
                    REstr = [hRE.sep1.String, '(.*)',...
                        hRE.sep2.String, '(.*)',...
                        hRE.sep3.String, '(.*)',...
                        hRE.ext.String];
                    [~,~,~,~,tokenstruct]=regexp(filelist,REstr);
                    tokenstruct=cellfun(@(e) e',[tokenstruct{:}],'unif',0);
                    tokenstruct=[tokenstruct{:}]';
                    
                    tokenNames=[hRE.tok1.String(hRE.tok1.Value),...
                        hRE.tok2.String(hRE.tok2.Value),...
                        hRE.tok3.String(hRE.tok3.Value)];
                    ChannelToken= strcmp(tokenNames,'Channel');
                    PositionToken= strcmp(tokenNames,'Position');
                    FrameToken= strcmp(tokenNames,'Frame');
                    
                    if ~isempty(tokenstruct)
                        R=1;
                        hEF.listbox1.String=unique(tokenstruct(:,ChannelToken));
                        hEF.listbox1.Value=1;
                        hEF.listbox2.String=unique(tokenstruct(:,ChannelToken));
                        hEF.listbox2.Value=1:length(hEF.listbox2.String);
                        hEF.listbox3.String=unique(tokenstruct(:,PositionToken));
                        hEF.listbox3.Value=1;
                        hEF.listbox4.String=unique(cellfun(@str2num, tokenstruct(:,FrameToken)));
                        hEF.listbox4.Value=1:length(hEF.listbox4.String);
                        % also put the positions in the background subtruction
                        % listbox
                        hBS.listboxSelPos.String=unique(tokenstruct(:,PositionToken));
                        hBS.listboxSelPos.Value=1;
                    end
                end
                hBSfiles=[];
                UpdateBSFilelist;
            end
            function toggleRegExpFields
                hREcell=struct2cell(hRE);
                hREcell=[hREcell{:}];
                if any(strcmp({hREcell.Visible},'on'))
                    [hREcell.Visible]=deal('off');
                    hREadv.String='Advanced';
                else
                    [hREcell.Visible]=deal('on');
                    hREadv.String='Hide';
                end
            end
            function UpdateBSFilelist
                Nchan=length(hEF.listbox1.String);
                if isempty(hBSfiles) && Nchan>0
                    [hBSfiles(1:Nchan).channel]=deal(hEF.listbox1.String{:});
                    [hBSfiles(1:Nchan).file]=deal('None');
                end
                
                %update the background subtruction file listbox
                if isempty(hEF.listbox1.String)
                    hBS.listboxSelFile.String=[];
                else
                    hBS.listboxSelFile.String=strcat({hBSfiles.channel},' (',{hBSfiles.file}, ')');
                end
                hBS.listboxSelFile.Value=1;
            end
            function ProcessPrefs
                if hPrefs.checkbox1.Value==0;
                    hPrefs.checkbox2.Enable='off';
                    hPrefs.checkbox3.Enable='off';
                    hPrefs.checkbox2.Value=0;
                    hPrefs.checkbox3.Value=0;
                else
                    hPrefs.checkbox2.Enable='on';
                    hPrefs.checkbox3.Enable='on';
                end
            end
        end
        
    end
    function LoadFiles
        if ~isfield(Tracked,'Frames')
            Data=openfiles(Tracked.cfg,Tracked.cfg.PositionAnlz{1}, Tracked.cfg.ChannelTrak{1},'Loading files...');
            N=length(Data);
            Data=num2cell(Data);
            [Tracked.Frames(1:N).TrackData]=deal(Data{:});
        end
    end
    function RemoveBackground
        if ~isfield(Tracked,'Background')
            allChannels=union(Tracked.cfg.ChannelAnlz,Tracked.cfg.ChannelTrak);
            % extract background model
            for cchannel=reshape(allChannels,1,[])
                [a,B,I,A]=anlzBkg(cchannel);
                Tracked.Background.(matlab.lang.makeValidName(cchannel{:})).a=a;
                Tracked.Background.(matlab.lang.makeValidName(cchannel{:})).B=B;
                Tracked.Background.(matlab.lang.makeValidName(cchannel{:})).I=I;
                Tracked.Background.(matlab.lang.makeValidName(cchannel{:})).A=A;
            end
        end
        
        a=Tracked.Background.(matlab.lang.makeValidName(Tracked.cfg.ChannelTrak{1})).a;
        B=Tracked.Background.(matlab.lang.makeValidName(Tracked.cfg.ChannelTrak{1})).B;
        I=Tracked.Background.(matlab.lang.makeValidName(Tracked.cfg.ChannelTrak{1})).I;
        A=Tracked.Background.(matlab.lang.makeValidName(Tracked.cfg.ChannelTrak{1})).A;

        for cframe=1:length(Tracked.Frames)
            Tracked.Frames(cframe).TrackData.bs=(Tracked.Frames(cframe).TrackData.raw-(a*I*A(cframe)+B))./I;
        end
    end
    function DoSegmentation
        if ~Tracked.cfg.Anlz.Segment || isfield(Tracked.Frames,'Cells')
            return
        end
        
        hwb=waitbar(0,'Segmenting images...');

        %find the noise std
        allim=[Tracked.Frames.TrackData];
        allim=(cat(3,allim.bs));
        bkgmin=abs(min(allim(:)));
        hbins=(-bkgmin:bkgmin)';
        noisestd=zeros(1,size(allim,3));
        
        for cframe=1:size(allim,3)
            %find the standard deviation of the noise
            im=allim(:,:,cframe);
            hists=hist(reshape(im,[],1),hbins);
            bkgfit=fit(hbins,hists','gauss1',...
                fitoptions('gauss1','Lower',[-Inf,-bkgmin,0],'Upper',[Inf,bkgmin,bkgmin]));
            noisestd(cframe)=bkgfit.c1;
            
            Tracked.Frames(cframe).Cells=imsegment(im,noisestd(cframe));
            
            waitbar(cframe/size(allim,3),hwb, ['Segmenting image ' num2str(cframe)]);
        end
        delete(hwb)
        
        Tracked.Background.Track.std=noisestd;
    end
    function DoTracking
        if ~Tracked.cfg.Anlz.Track
            return
        end
        hwb=waitbar(0,'Tracking...');
        prog=0;
        step=1/length(Tracked.Frames);
        for cframe=1:length(Tracked.Frames)-1
            im0=Tracked.Frames(cframe).TrackData.bs;
            im1=Tracked.Frames(cframe+1).TrackData.bs;
            c0=Tracked.Frames(cframe).Cells;
            c1=Tracked.Frames(cframe+1).Cells;
            
            [cl0,cl1]=TrackFrame(im0,c0,im1,c1);
            
            Tracked.Frames(cframe).Cells=cl0;
            Tracked.Frames(cframe+1).Cells=cl1;
            prog=prog+step;
            waitbar(prog,hwb)
        end
        delete(hwb)
    end
    function DoFluorescence
        if ~Tracked.cfg.Anlz.Extract
            return
        end
        
        extractFluorescence;
        
    end
    function openGUI
        % define some global variables
        ImgSize=max(cell2mat(cellfun(@(x) size(x.bs),{Tracked.Frames.TrackData},'uniform',0)'));
        imy=ImgSize(1);
        imx=ImgSize(2);
        AR=imx/imy; 
        frame=1;
        State='view';%editing state: view, delete, add,
        StateText='';
        ColorCode=1;
        ColorByNum=0;
        Boundary=1;
        selectedcell=[];
        LogFScale=0;
        
        hStruct=setupGUI;
        plotframe;

        function hStruct=setupGUI
            %  Construct the main GUI figure
            scrsz=get(0,'ScreenSize'); %detect screen size
            guiW=scrsz(3)*0.8; %width of the GUI
            guiH=scrsz(4)*0.8; %height of the GUI
            MainPos=[guiW/10,guiH/10 ,guiW,guiH]; %position of the GUI
            
            hStruct.fh=figure('Position',MainPos,...
                'MenuBar','none',...
                'Name','Tranalyze- Movie Analysis Tool',...
                'NumberTitle','off',...
                'CloseRequestFcn',@CloseFcn);
            set(hStruct.fh,'KeyPressFcn',@KeyPressCB,...
                'ResizeFcn',@fhResizeFcn) %make the clicking above figure work
            hStruct.KPF=uicontrol(hStruct.fh,'KeyPressFcn',@KeyPressCB,'Position',[1,1,1,1]); %workaround to get the focus for KeyPressFcn
            
            % Construct buttons and menus
            %         fhctl=figure('MenuBar','None'); %deleteLB
            butSz=0.05; %size of buttons
            butLS=0.05+0.35-2.15*butSz; %distance between left of figure and menu buttons (as fraction of GUI fig)
            Bstr=char(9664);
            Fstr=char(9654);
            Pstr=char(2404);
            hStruct.FBbutton=uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string',[Bstr,Bstr],'Position',...
                [butLS,0.8,butSz,butSz],'Callback',@runbackward,'FontSize',20);
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string',[Pstr Bstr],'Position',...
                [butLS+1.1*butSz,0.8,butSz,butSz],'Callback',{@BtnPress,'leftarrow'},'FontSize',20);
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string',[Fstr Pstr],'Position',...
                [butLS+2.2*butSz,0.8,butSz,butSz],'Callback',{@BtnPress,'rightarrow'},'FontSize',20);
            hStruct.FFbutton=uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string',[Fstr Fstr],'Position',...
                [butLS+3.3*butSz,0.8,butSz,butSz],'Callback',@runforward,'FontSize',20);
            
            butLS=0.8; %redefine distance between left of figure and menu buttons (as fraction of GUI fig)
            butSz=0.05;
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Color','Position',...
                [butLS,0.75-butSz,butSz,butSz],'Callback',{@BtnPress,'c'})
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Boundary','Position',...
                [butLS+1.1*butSz,0.75-butSz,butSz,butSz],'Callback',{@BtnPress,'b'})
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Select','Position',...
                [butLS+2.2*butSz,0.75-butSz,butSz,butSz],'Callback',{@BtnPress,'s'})
            
            
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Delete','Position',...
                [butLS,0.8-3.5*butSz,butSz,butSz],'Callback',{@BtnPress,'d'})
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Add','Position',...
                [butLS+1.1*butSz,0.8-3.5*butSz,butSz,butSz],'Callback',{@BtnPress,'a'})
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','^Autoadd','Position',...
                [butLS+2.2*butSz,0.8-3.5*butSz,butSz,butSz],'Callback',{@BtnPress,'a','control'})
            
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','segmeNt','Position',...
                [butLS,0.8-5*butSz,butSz,butSz],'Callback',{@BtnPress,'n'})
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Merge','Position',...
                [butLS+1.1*butSz,0.8-5*butSz,butSz,butSz],'Callback',{@BtnPress,'m'})
            %        uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','meRge all','Position',...
            %            [butLS+2.2*butSz,0.8-5*butSz,butSz,butSz],'Callback',{@BtnPress,'r'})
            %uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Editseed','Position',...
            %    [butLS+2.2*butSz,0.8-5*butSz,butSz,butSz],'Callback',{@BtnPress,'e'})
            
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','linK','Position',...
                [butLS,0.8-6.5*butSz,butSz,butSz],'Callback',{@BtnPress,'k'})
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Unlink','Position',...
                [butLS+1.1*butSz,0.8-6.5*butSz,butSz,butSz],'Callback',{@BtnPress,'u'})
            
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Track','Position',...
                [butLS,0.8-8.5*butSz,butSz,butSz],'Callback',{@BtnPress,'t'})
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','backYrack','Position',...
                [butLS+1.1*butSz,0.8-8.5*butSz,butSz,butSz],'Callback',{@BtnPress,'y'})
            %          uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Plot','Position',...
            %            [butLS+2.2*butSz,0.8-8.5*butSz,butSz,butSz],'Callback',{@BtnPress,'p'})
            
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Goto','Position',...
                [butLS,0.8-10*butSz,butSz,butSz],'Callback',{@BtnPress,'g'})
            %uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Lock','Position',...
            %    [butLS+1.1*butSz,0.8-10*butSz,butSz,butSz],'Callback',{@BtnPress,'l'})
            %uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','Flour','Position',...
            %    [butLS+2.2*butSz,0.8-10*butSz,butSz,butSz],'Callback',{@BtnPress,'f'})
            
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','autoTrack','Position',...
                [butLS+1.1*butSz,0.8-12*butSz,butSz,butSz],'Callback',{@BtnPress,'t','control'})
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','autosegN','Position',...
                [butLS,0.8-12*butSz,butSz,butSz],'Callback',{@BtnPress,'n','control'})
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','autoFlour','Position',...
                [butLS+2.2*butSz,0.8-12*butSz,butSz,butSz],'Callback',{@BtnPress,'f','control'})
            
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','zoom','Position',...
                [butLS          ,0.8-14*butSz,butSz,butSz],'Callback',@ZoomFcn)
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','save','Position',...
                [butLS+1.1*butSz,0.8-14*butSz,butSz,butSz],'Callback',@SaveFcn)
            uicontrol( 'Parent', hStruct.fh, 'Units','normalized','Style','pushbutton','string','close','Position',...
                [butLS+2.2*butSz,0.8-14*butSz,butSz,butSz],'Callback',@CloseFcn)
            
            hStruct.hPlotAxes = axes(...    % Axes for plotting the frame
                'Parent', hStruct.fh, ...
                'Units', 'normalized');
            axresize(hStruct.fh,hStruct.hPlotAxes)
        end

        function axresize(fh,hPlotAxes)
            cPos=get(fh,'Position');
            guiW=cPos(3);
            guiH=cPos(4);
            axes_size=0.7*[guiH/guiW*AR, 1]/max([guiH/guiW*AR, 1]);
            
            set(hPlotAxes,'Parent', fh, ...
                'Units', 'normalized', ...
                'Position',[0.05+0.35-axes_size/2, axes_size]);
            axis([0,imx,0,imy])
        end
        
        function plotframe(overlay)

            
            % add special colors for specific events:
            % highlight cell border (red)
            % cells before and after division (red/yellow)
            % appearing/disappearing cells
            % selected cells (yellow)
            cmap=colormap('parula');
            cmapsize=size(cmap,1);
            Nborder=cmapsize+1;
            Nparent=cmapsize+2;
            Nchild=cmapsize+3;
            Napp=cmapsize+4;
            Ndisapp=cmapsize+5;
            Nsel=cmapsize+6;
            cmap=[cmap;
                0.75,0,0;
                0.75,0,0;
                1,1,0;
                0.375,1,0.625;
                1,0.375,0;
                1,1,0];
            colormap(cmap);
            
            IMborder=zeros(imy,imx);
            IMparent=zeros(imy,imx);
            IMchild=zeros(imy,imx);
            IMapp=zeros(imy,imx);
            IMdisapp=zeros(imy,imx);
            IMselborder=zeros(imy,imx);
            
            % find the boundary/state of each cell
            for ccell=1:length(Tracked.Frames(frame).Cells)
                Scell=Tracked.Frames(frame).Cells(ccell);
                % cell boundary
                IMborder=addPixel(IMborder, bwperim(Scell.mask), Scell.pos);
                if any(selectedcell==ccell)
                    IMselborder=addPixel(IMselborder, bwperim(Scell.mask), Scell.pos);
                end

                % find cell state (inside color)
                if isempty(Scell.progenitor)
                    IMapp=addPixel(IMapp,Scell.mask,Scell.pos);
                elseif isempty(Scell.descendants)
                    IMdisapp=addPixel(IMdisapp,Scell.mask,Scell.pos);
                else
                    if ~isscalar(Scell.descendants)
                        IMparent=addPixel(IMparent,Scell.mask,Scell.pos);
                    end
                    prevScell=Tracked.Frames(frame-1).Cells(Scell.progenitor);
                    if ~isscalar(prevScell.descendants)
                        IMchild=addPixel(IMchild,Scell.mask,Scell.pos);
                    end
                end
                
            end
            
            
            
            im=Tracked.Frames(frame).TrackData.bs;
            % TBD if no image, load it
            if LogFScale
                im=log(max(0,im));
            end
            %scale the image to the original colormap size
            im=im./max(im(:))*cmapsize;
            if ColorCode
                im(IMparent>0)=Nparent;
                im(IMchild>0)=Nchild;
                im(IMapp>0)=Napp;
                im(IMdisapp>0)=Ndisapp;
            elseif ColorByNum
                % TBD what is this doing?
                cellsnum=(SegRenderNum([Tracked.Frames(frame).Cells{:}],imy,imx)*64/length(Tracked.Frames(frame).Cells));
                im(cellsnum>0)=cellsnum(cellsnum>0);
            end
            if Boundary
                im(IMborder>0)=Nborder;
            end
            im(IMselborder>0)=Nsel; %this plots only color on the boundary of selected cell

            % show the image
            set(hStruct.fh,'CurrentAxes',hStruct.hPlotAxes ) %select the plot axes
            zoomax=axis;
            if exist('overlay','var')
                image(im+overlay)
                zoom reset
                axis(zoomax)
            else
                image(im)
                zoom reset
                axis(zoomax)
            end
            % make the title
            selectedcellstr=num2str(selectedcell,'%d,');
            selectedcellstr=selectedcellstr(1:end-1);
            set(gcf,'name',['frame:',num2str(frame),' ', Tracked.Frames(frame).TrackData.filename,' #cell: (' ,selectedcellstr, ')/',num2str(length(Tracked.Frames(frame).Cells))])
            title(StateText)
            % give the focus to the keypressfcn uicontrol
            uicontrol(hStruct.KPF)
            
        end
        function fhResizeFcn(~,~)
            axresize(hStruct.fh,hStruct.hPlotAxes);
        end
        function BtnPress(src,~,key,mod)
            evnt2.Key=key;
            evnt2.Modifier='';
            if exist('mod','var')
                evnt2.Modifier={mod};
            end
            figure(hStruct.fh)
            zoom off
            KeyPressCB(src,evnt2);
        end
        function SaveFcn(~,~)
            export2wsdlg({'Tracked Data'},{'Tracked'},{Tracked});
        end
        function CloseFcn(src,evnt)
            SaveFcn(src,evnt);
            delete(hStruct.fh);
        end
        
        function runforward(src,~)
            %stop backward run
            hStruct.FBbutton.UserData=0;
            hStruct.FBbutton.BackgroundColor=0.94*[1,1,1];
            hStruct.FBbutton.ForegroundColor=[0,0,0];
            
            if get(src,'UserData')==1
                %stop running
                set(src,'UserData',0)
                set(src,'BackgroundColor',[0.94,0.94,0.94])
                set(src,'ForegroundColor',[0,0,0])
            else
                %start running
                set(src,'UserData',1)
                set(src,'BackgroundColor',[0,0,0])
                set(src,'ForegroundColor',[1,1,1])
            end
            while get(src,'UserData')
                ccell=Tracked.Frames(frame).Cells(selectedcell);
                lastframe=(frame==length(Tracked.Frames));
                frame=min(frame+1,length(Tracked.Frames));
                
                if lastframe
                    %stop running
                    set(src,'UserData',0)
                    set(src,'BackgroundColor',[0.94,0.94,0.94])
                    set(src,'ForegroundColor',[0,0,0])
                end
                if ~isempty(ccell)
                    if ~lastframe
                        selectedcell=[ccell.descendants];
                        selectedcell=unique(selectedcell);
                    end
                else
                    selectedcell=[];
                end
                plotframe
                pause(0.01)
                drawnow
            end
        end
        function runbackward(src,~)
            %stop forward run
            hStruct.FFbutton.UserData=0;
            hStruct.FFbutton.BackgroundColor=0.94*[1,1,1];
            hStruct.FFbutton.ForegroundColor=[0,0,0];
            if get(src,'UserData')
                %stop running
                src.UserData=0;
                src.BackgroundColor=0.94*[1,1,1];
                src.ForegroundColor=[0,0,0];
            else
                src.UserData=1;
                src.BackgroundColor=[0,0,0];
                src.ForegroundColor=[1,1,1];
            end
            while get(src,'UserData')
                ccell=Tracked.Frames(frame).Cells(selectedcell);
                firstframe=(frame==1);
                frame=max(1,frame-1);
                
                if firstframe
                    %stop running
                    set(src,'UserData',0)
                    set(src,'BackgroundColor',[0.94,0.94,0.94])
                    set(src,'ForegroundColor',[0,0,0])
                end

                if ~isempty(ccell)
                    if ~firstframe
                        selectedcell=[ccell.progenitor];
                        selectedcell=unique(selectedcell);
                    end
                else
                    selectedcell=[];
                end
                plotframe
                drawnow
            end
        end
        function ZoomFcn(~,~)
            if strcmp(get(zoom(gcf),'Enable'),'off')
                set(gcf,'WindowButtonDownFcn',[])
                set(gcf,'WindowButtonUpFcn',[])
            end
            State='view';
            StateText='';
            plotframe
            zoom
        end
        
        function KeyPressCB(src,evnt)
            switch evnt.Key
                case 'leftarrow'
                    %stop playing
                    hStruct.FFbutton.UserData=0;
                    hStruct.FFbutton.BackgroundColor=0.94*[1,1,1];
                    hStruct.FFbutton.ForegroundColor=[0,0,0];
                    hStruct.FBbutton.UserData=0;
                    hStruct.FBbutton.BackgroundColor=0.94*[1,1,1];
                    hStruct.FBbutton.ForegroundColor=[0,0,0];

                    ccell=Tracked.Frames(frame).Cells(selectedcell);
                    firstframe=(frame==1);
                    frame=max(1,frame-1);
                    
                    if ~isempty(ccell)
                        if ~firstframe
                            selectedcell=[ccell.progenitor];
                            selectedcell=unique(selectedcell);
                        end
                    else
                        selectedcell=[];
                    end
                    plotframe
                case 'rightarrow'
                    %stop playing
                    hStruct.FFbutton.UserData=0;
                    hStruct.FFbutton.BackgroundColor=0.94*[1,1,1];
                    hStruct.FFbutton.ForegroundColor=[0,0,0];
                    hStruct.FBbutton.UserData=0;
                    hStruct.FBbutton.BackgroundColor=0.94*[1,1,1];
                    hStruct.FBbutton.ForegroundColor=[0,0,0];

                    ccell=Tracked.Frames(frame).Cells(selectedcell);
                    lastframe=(frame==length(Tracked.Frames));
                    frame=min(frame+1,length(Tracked.Frames));
                    
                    if ~isempty(ccell)
                        if ~lastframe
                            selectedcell=[ccell.descendants];
                            selectedcell=unique(selectedcell);
                        end
                    else
                        selectedcell=[];
                    end
                    plotframe
                case 'c' %show/hide cell colorcode
                    if strcmp(evnt.Modifier,'control')
                        ColorByNum=~ColorByNum;
                        ColorCode=0;
                    else
                        ColorCode=~ColorCode;
                        ColorByNum=0;
                    end
                    plotframe
                case 'b' %show/hide cell boundary
                    Boundary=~Boundary;
                    plotframe
                case 'd' %delete segment
                    DeleteSegment;
                    plotframe
                case 'a' %add segment, control=autoadd blob
                    if strcmp(evnt.Modifier,'control')
                        AutoAddSegment;
                    else
                        AddSegment;
                    end
                    title(StateText);
                case 't' %recalulate tracking
                    if strcmp(evnt.Modifier,'control')
                        AutoReTrack;
                        plotframe;
                    else
                        ReTrack;
                        BtnPress(src,evnt,'rightarrow')
                    end
                case 'y' %back tracking
                    BackTrack;
                case 'r' %reset segmentation
                    ResetSeg;
                case 'm' %merge segments
                    MergeSeg;
                    plotframe;
                case 's' %select cell to follow
                    SelectCell;
                    plotframe;
                case 'g' %goto frame
                    fnum=inputdlg('Goto frame:','Goto frame:');
                    if ~isempty(fnum)
                        frame=str2double(char(fnum));
                    end
                    plotframe;
                case 'x' %fix links
                    if strcmp(evnt.Modifier,'control')
                        FixLinks(1);
                    else
                        FixLinks(0);
                    end
                case 'k' %link cells
                    LinkCells;
                    plotframe;
                case 'n' %resegment
                    if strcmp(evnt.Modifier,'control')
                        AutoReSegment;
                    else
                        ReSegment;
                    end
                case 'p' %plot fluorescence of lineage
                    PlotLineage;
                case 'f' %recalculate fluorescence in the other channels
                    if strcmp(evnt.Modifier,'control')
                        AutoReFlourescence;
                    else
                        ReFlourescence;
                    end
                case 'e' %edit seeds
                    EditSeeds;
                case 'u' %unlink cells (select parent and child to be separated)
                    UnlinkCells;
                    plotframe;
            end
            
            
        end
        function DeleteSegment
            if strcmp(State,'delete')
                set(gcf,'WindowButtonDownFcn',[])
                set(gcf,'WindowButtonUpFcn',[])
                State='view';
                StateText='';
            else
                set(gcf,'WindowButtonDownFcn',@btndown)
                set(gcf,'WindowButtonUpFcn',[])
                State='delete';
                StateText='Select Cell To Delete';
            end
            
            function btndown(~,~)
                p=get(gca,'CurrentPoint');
                coord=p(1,[2,1]);
                allpos=cell2mat(arrayfun(@(x) double(x.pos),Tracked.Frames(frame).Cells,'Uniform',0)');
                allsize=cell2mat(arrayfun(@(x) double(x.size),Tracked.Frames(frame).Cells,'Uniform',0)');
                isincell=all(bsxfun(@minus,allsize+allpos,coord)>0 & bsxfun(@minus,allpos,coord)<0,2);
                clicked=find(isincell,1);
                if isempty(clicked)
                    return
                end
                
                deleteCells(clicked)
                plotframe;
                
            end
        end
        function AutoAddSegment
            if strcmp(State,'autoadd')
                set(gcf,'WindowButtonDownFcn',[])
                set(gcf,'WindowButtonUpFcn',[])
                State='view';
                StateText='';
            else
                set(gcf,'WindowButtonDownFcn',@btndown)
                set(gcf,'WindowButtonUpFcn',[])
                State='autoadd';
                StateText='Select Cell To AutoAdd';
            end
            
            function btndown(~,~)
                p=get(gca,'CurrentPoint');
                coord=p(1,[2,1]);
                
                im=Tracked.Frames(frame).TrackData.bs;
                noisestd=Tracked.Background.Track.std(frame);
                imLH=normpdf(im./noisestd);
                imSeg=imLH<0.054;
                imSegLbl=bwlabel(imSeg);
                blobnum=imSegLbl(round(coord(1)),round(coord(2)));
                if blobnum~=0
                    Tracked.Frames(frame).Cells(end+1)=CalcCellProperties(mask2cells(imSegLbl==blobnum), im);
                    
                end
                plotframe;
            end
        end
        function AddSegment
            if strcmp(State,'add')
                set(gcf,'WindowButtonDownFcn',[])
                set(gcf,'WindowButtonUpFcn',[])
                State='view';
                StateText='';
            else
                set(gcf,'WindowButtonDownFcn',@btndown)
                set(gcf,'WindowButtonUpFcn',@btnup)
                State='add';
                StateText='Mark Region To Add';
                lh=[];
                newseg=[];
                
            end
            
            function btndown(src,~)
                lh=line('Visible','off');
                newseg=[];
                p=get(gca,'CurrentPoint');
                coord=p(1,[2,1]);
                newseg(end+1,:)=coord;
                set(lh,'XData',newseg(:,2),'YData',newseg(:,1),'Marker','none','Color','r','Visible','on');
                set(src,'WindowButtonMotionFcn',@move)
            end
            function move(~,~)
                p=get(gca,'CurrentPoint');
                coord=p(1,[2,1]);
                steps=1+ceil(max(abs(newseg(end,:)-coord)));
                newseg=[newseg;[linspace(newseg(end,1),coord(1),steps); linspace(newseg(end,2),coord(2),steps)]'];
                %newseg(end+1,:)=coord;
                set(lh,'XData',newseg(:,2),'YData',newseg(:,1),'Marker','none','Color','r','Visible','on');
            end
            function btnup(src,~)
                coord=newseg(1,:);
                steps=1+ceil(max(abs(newseg(end,:)-coord)));
                newseg=[newseg;[linspace(newseg(end,1),coord(1),steps); linspace(newseg(end,2),coord(2),steps)]'];
                set(src,'WindowButtonMotionFcn',[])
                newsegmask=zeros(imy,imx);
                newsegind=sub2ind(size(newsegmask),round(newseg(:,1)),round(newseg(:,2)));
                newsegmask(newsegind)=1;
                newsegmask=imerode(imfill(imdilate(newsegmask,strel('diamond',1))),strel('diamond',1));
                
                Tracked.Frames(frame).Cells(end+1)=CalcCellProperties(mask2cells(newsegmask), Tracked.Frames(frame).TrackData.bs);

                plotframe;
            end
        end
        function deleteCells(remcells)
            %delete cells information
            %start from the higher number so that i don't renumber cells to
            %be deleted
            for cremcell=reshape(remcells(end:-1:1),1,[])
                pro=Tracked.Frames(frame).Cells(cremcell).progenitor;
                if ~isempty(pro)
                    prodes=Tracked.Frames(frame-1).Cells(pro).descendants;
                    %delete this cell from its progenitor
                    if isscalar(prodes)
                        Tracked.Frames(frame-1).Cells(pro).descendants=[];
                    else
                        Tracked.Frames(frame-1).Cells(pro).descendants(prodes==cremcell)=[];
                    end
                end
                if frame>1
                    %renumber the other 'cousins' in their parents
                    for ccell=1:length(Tracked.Frames(frame-1).Cells)
                        cousins=Tracked.Frames(frame-1).Cells(ccell).descendants;
                        Tracked.Frames(frame-1).Cells(ccell).descendants=cousins-(cousins>cremcell);
                    end
                end
                for des=Tracked.Frames(frame).Cells(cremcell).descendants
                    Tracked.Frames(frame+1).Cells(des).progenitor=[];
                end
                if frame<length(Tracked.Frames)
                    %renumber the other 'cousins' in their children
                    for ccell=1:length(Tracked.Frames(frame+1).Cells)
                        cousins=Tracked.Frames(frame+1).Cells(ccell).progenitor;
                        Tracked.Frames(frame+1).Cells(ccell).progenitor=cousins-(cousins>cremcell);
                    end
                end
                Tracked.Frames(frame).Cells(cremcell)=[];
            end
        end
        function ReTrack
            im0=Tracked.Frames(frame).TrackData.bs;
            im1=Tracked.Frames(frame+1).TrackData.bs;
            c0=Tracked.Frames(frame).Cells;
            c1=Tracked.Frames(frame+1).Cells;
            
            [cl0,cl1]=TrackFrame(im0,c0,im1,c1);
            
            Tracked.Frames(frame).Cells=cl0;
            Tracked.Frames(frame+1).Cells=cl1;
            plotframe
        end
        function AutoReTrack
            for cframe=frame:length(Tracked.Frames)-1
                im0=Tracked.Frames(cframe).TrackData.bs;
                im1=Tracked.Frames(cframe+1).TrackData.bs;
                c0=Tracked.Frames(cframe).Cells;
                c1=Tracked.Frames(cframe+1).Cells;
                
                [cl0,cl1]=TrackFrame(im0,c0,im1,c1);
                
                Tracked.Frames(cframe).Cells=cl0;
                Tracked.Frames(cframe+1).Cells=cl1;
            end
        end
        function BackTrack
            im0=Tracked.Frames(frame).TrackData.bs;
            im1=Tracked.Frames(frame+1).TrackData.bs;
            c0=Tracked.Frames(frame).Cells;
            c1=Tracked.Frames(frame+1).Cells;

            %use track frame from 1 to 0. need to flip the desc and pro.
            %flip prog and desc
            prog={c0.progenitor};
            [c0.progenitor]=deal(c0.descendants);
            [c0.descendants]=deal(prog{:});
            prog={c1.progenitor};
            [c1.progenitor]=deal(c1.descendants);
            [c1.descendants]=deal(prog{:});

            [cl0,cl1]=TrackFrame(im0,c0,im1,c1);

            %flip back
            prog={cl0.progenitor};
            [cl0.progenitor]=deal(cl0.descendants);
            [cl0.descendants]=deal(prog{:});
            prog={cl1.progenitor};
            [cl1.progenitor]=deal(cl1.descendants);
            [cl1.descendants]=deal(prog{:});

            Tracked.Frames(frame).Cells=cl0;
            Tracked.Frames(frame+1).Cells=cl1;
            plotframe
        end
        function ReSegment
            %remove the links from progenitors and descendants
            if frame<length(Tracked.Frames)
                for cell=1:length(Tracked.Frames(frame+1).Cells)
                    Tracked.Frames(frame+1).Cells(cell).progenitor=[];
                end
            end
            if frame>1
                for cell=1:length(Tracked.Frames(frame-1).Cells)
                    Tracked.Frames(frame-1).Cells(cell).descendants=[];
                end
            end
            %resegment frame
            Tracked.Frames(frame).Cells=imsegment(Tracked.Frames(frame).TrackData.bs,Tracked.Background.Track.std(frame));
            plotframe
        end
        function AutoReSegment
            h=waitbar(0,'Segmenting...');
            for cframe=frame:length(Tracked.Frames)
                Tracked.Frames(frame).Cells=imsegment(Tracked.Frames(frame).TrackData.bs,Tracked.Background.Track.std(frame));
                waitbar((cframe-frame)/(length(Tracked.Frames)-frame),h,['Segmenting frame ' num2str(cframe)]);
                if ~ishandle(h)
                    break
                end
            end
            if ishandle(h)
                delete(h)
            end
            %remove the links from progenitors and descendants
            if cframe<length(Tracked.Frames)
                for cell=1:length(Tracked.Frames(cframe+1).Cells)
                    Tracked.Frames(cframe+1).Cells(cell).progenitor=[];
                end
            end
            if frame>1
                for cell=1:length(Tracked.Frames(frame-1).Cells)
                    Tracked.Frames(frame-1).Cells(cell).descendants=[];
                end
            end
            
            plotframe
        end
        function ReFlourescence
            % TBD ?
        end
        function AutoReFlourescence
            extractFluorescence;
        end
        function SelectCell
            if strcmp(State,'select')
                set(gcf,'WindowButtonDownFcn',[])
                set(gcf,'WindowButtonUpFcn',[])
                State='view';
                StateText='';
            else
                set(gcf,'WindowButtonDownFcn',@btndown)
                set(gcf,'WindowButtonUpFcn',[])
                State='select';
                StateText='Select Cell To Follow';
            end
            
            function btndown(~,~)
                p=get(gca,'CurrentPoint');
                coord=p(1,[2,1]);
                allpos=cell2mat(arrayfun(@(x) double(x.pos),Tracked.Frames(frame).Cells,'Uniform',0)');
                allsize=cell2mat(arrayfun(@(x) double(x.size),Tracked.Frames(frame).Cells,'Uniform',0)');
                isincell=all(bsxfun(@minus,allsize+allpos,coord)>0 & bsxfun(@minus,allpos,coord)<0,2);
                clicked=find(isincell,1);
                selectedcell=clicked;
                plotframe;
            end
        end
        function MergeSeg
            if strcmp(State,'merge')
                set(gcf,'WindowButtonDownFcn',[])
                set(gcf,'WindowButtonUpFcn',[])
                State='view';
                StateText='';
            else
                set(gcf,'WindowButtonDownFcn',@btndown)
                set(gcf,'WindowButtonUpFcn',[])
                State='merge';
                StateText='Select Overlapping Cells To Merge';
            end
            
            function btndown(~,~)
                p=get(gca,'CurrentPoint');
                coord=p(1,[2,1]);
                allpos=cell2mat({Tracked.Frames(frame).Cells.pos}');
                allsize=cell2mat({Tracked.Frames(frame).Cells.size}');
                isincell=all(bsxfun(@minus,allsize+allpos,coord)>0 & bsxfun(@minus,allpos,coord)<0,2);
                clicked=find(isincell);
                if sum(isincell)<2
                    return
                end
                
                newFmask=zeros(imy,imx);
                for ccell=clicked'
                    newFmask=addPixel(newFmask, Tracked.Frames(frame).Cells(ccell).Fmask, Tracked.Frames(frame).Cells(ccell).pos);
                end
                newsegmask=newFmask>0;
                
                newcell=CalcCellProperties(mask2cells(newsegmask), Tracked.Frames(frame).TrackData.bs);
                newcell.Fmask=getPixels(newFmask,newcell.pos,newcell.size);
                Tracked.Frames(frame).Cells(end+1)=CalcCellProperties(newcell, Tracked.Frames(frame).TrackData.bs);
                
                %delete the original cells
                deleteCells(clicked);
                
                plotframe;
            end
        end

        function LinkCells
            if strcmp(State,'link')
                set(gcf,'WindowButtonDownFcn',[])
                set(gcf,'WindowButtonUpFcn',[])
                State='view';
                StateText='';
            else
                set(gcf,'WindowButtonDownFcn',@btndown_prog)
                set(gcf,'WindowButtonUpFcn',[])
                State='link';
                StateText='Select Parent';
            end
            clickedP=[];
            function btndown_prog(~,~)
                p=get(gca,'CurrentPoint');
                coord=p(1,[2,1]);
                allpos=cell2mat({Tracked.Frames(frame).Cells.pos}');
                allcom=allpos+cell2mat({Tracked.Frames(frame).Cells.Acom}');
                [~,clickedP]=min(sum((bsxfun(@minus,allcom,coord)).^2,2));
                if isempty(clickedP)
                    return
                end
                %keep track of selected cell (if exist) before switching frames
                tmp=Tracked.Frames(frame).Cells(selectedcell);
                if ~isempty(tmp)
                    selectedcell=[tmp.descendants];
                else
                    selectedcell=[];
                end
                %move to the next frame
                frame=frame+1;
                set(gcf,'WindowButtonDownFcn',@btndown_des)
                set(gcf,'WindowButtonUpFcn',[])
                State='link';
                StateText='Select Descendant';
                plotframe;
            end
            function btndown_des(~,~)
                p=get(gca,'CurrentPoint');
                coord=p(1,[2,1]);
                allpos=cell2mat({Tracked.Frames(frame).Cells.pos}');
                allcom=allpos+cell2mat({Tracked.Frames(frame).Cells.Acom}');
                [~,clickedD]=min(sum((bsxfun(@minus,allcom,coord)).^2,2));
                if isempty(clickedD)
                    return
                end
                %keep track properly of selected cell
                tmp=Tracked.Frames(frame).Cells(selectedcell);
                if ~isempty(tmp)
                    at=tmp.progenitor;
                    selectedcell=unique(at);
                else
                    selectedcell=[];
                end
                frame=frame-1;
                set(gcf,'WindowButtonDownFcn',@btndown_prog)
                set(gcf,'WindowButtonUpFcn',[])
                State='link';
                StateText='Select Parent';
                
                %adding the correct descendant
                Tracked.Frames(frame).Cells(clickedP).descendants(end+1)=clickedD;
                %make sure not to duplicated descendants
                Tracked.Frames(frame).Cells(clickedP).descendants=unique(Tracked.Frames(frame).Cells(clickedP).descendants);
                %adding the correct progenitor
                Tracked.Frames(frame+1).Cells(clickedD).progenitor=clickedP;
                plotframe;
            end
        end
        function UnlinkCells
            if strcmp(State,'unlink')
                set(gcf,'WindowButtonDownFcn',[])
                set(gcf,'WindowButtonUpFcn',[])
                State='view';
                StateText='';
            else
                set(gcf,'WindowButtonDownFcn',@btndown_prog)
                set(gcf,'WindowButtonUpFcn',[])
                State='unlink';
                StateText='Select Parent';
            end
            clickedP=[];
            function btndown_prog(~,~)
                p=get(gca,'CurrentPoint');
                coord=p(1,[2,1]);
                allpos=cell2mat({Tracked.Frames(frame).Cells.pos}');
                allcom=allpos+cell2mat({Tracked.Frames(frame).Cells.Acom}');
                [~,clickedP]=min(sum((bsxfun(@minus,allcom,coord)).^2,2));
                if isempty(clickedP)
                    return
                end
                
                %deleting current cell from its descendants
                for desc=Tracked.Frames(frame).Cells(clickedP).descendants
                    if Tracked.Frames(frame+1).Cells(desc).progenitor==clickedP;
                        Tracked.Frames(frame+1).Cells(desc).progenitor=[];
                    end
                end
                
                %clear descendants of current cell
                Tracked.Frames(frame).Cells(clickedP).descendants=[];
                
                plotframe;
            end
        end
        
        
        % TBD: what are these functions?
        function ResetSeg
            newsegmask=SegRenderNum([Tracked.Frames(frame).Cells{:}],imy,imx)>0;
            [newsegmaskl,num]=bwlabel((newsegmask)>0);
            bbox=regionprops(newsegmaskl,'BoundingBox');
            cells=struct('mask',{},'pos',{},'size',{},'progenitor',{},'descendants',{});
            for cseg=1:num
                cellslice={floor(bbox(cseg).BoundingBox(2))+1:floor(bbox(cseg).BoundingBox(2)+bbox(cseg).BoundingBox(4)),...
                    floor(bbox(cseg).BoundingBox(1))+1:floor(bbox(cseg).BoundingBox(1)+bbox(cseg).BoundingBox(3))};
                cells(end+1).mask=double(newsegmaskl(cellslice{1},cellslice{2})==cseg);
                cells(end).pos=floor(bbox(cseg).BoundingBox(2:-1:1))+1;
                cells(end).size=size(cells(end).mask);
            end
            Tracked.Frames(frame).Cells=num2cell(cells);
            Tracked.Frames(frame).predictMito=0;
            %remove the links from progenitors and descendants
            if frame<length(Tracked.Frames)
                for cell=1:length(Tracked.Frames(frame+1).Cells)
                    Tracked.Frames(frame+1).Cells{cell}.progenitor=[];
                end
            end
            if frame>1
                for cell=1:length(Tracked.Frames(frame-1).Cells)
                    Tracked.Frames(frame-1).Cells{cell}.descendants=[];
                end
            end
            plotframe
        end
        function EditSeeds
            if strcmp(State,'seed')
                set(gcf,'WindowButtonDownFcn',[])
                set(gcf,'WindowButtonUpFcn',[])
                State='view';
                StateText='';
                %recalcseg;
                plotframe;
            else
                set(gcf,'WindowButtonDownFcn',@btndown)
                set(gcf,'WindowButtonUpFcn',[])
                State='seed';
                StateText='Select to add or remove';
                seedmtx=zeros(size(AllImg{frame}));
                %                 [Tracked.Frames(frame).Cells{:}];
                %                 cellsAcom=cell2mat({ans.pos}')+cell2mat({ans.Acom}');
                %                seedmtx(sub2ind(size(seedmtx),cellsAcom(:,1),cellsAcom(:,2)))=1;
                maxpos=cellfun(@(x) find(x.Fpixels(:)==max(x.Fpixels(:)),1,'first'),Tracked.Frames(frame).Cells);
                [Tracked.Frames(frame).Cells{:}];
                hlen=cell2mat({ans.size}');
                cellsmax=  -1 + cell2mat({ans.pos}') + [mod(maxpos',hlen(:,1)),ceil(maxpos'./hlen(:,1))];
                seedmtx(sub2ind(size(seedmtx),cellsmax(:,1),cellsmax(:,2)))=1;
                plotframe(50*imdilate(seedmtx,[1,1,1;1,1,1;1,1,1]))
            end
            
            function recalcseg(src,evnt)
                im=medfilt2(AllImg{frame},[5,5],'symmetric');
                ll=MarkerControlledWatershedSegmentation(im,seedmtx);
                ll=(ll.*SegRenderNum([Tracked.Frames(frame).Cells{:}],512,512))>0;
                %[ll2,nn]=bwlabel(ll,4);
                ll2=ll;
                cells=mask2cells(ll2);
                cells=CalcCellProperties(cells,AllImg{frame});
                Tracked.Frames(frame).Cells=num2cell(cells);
                Tracked.Frames(frame).predictMito=0;
                %remove the links from progenitors and descendants
                if frame<length(Tracked.Frames)
                    for cell=1:length(Tracked.Frames(frame+1).Cells)
                        Tracked.Frames(frame+1).Cells{cell}.progenitor=[];
                    end
                end
                if frame>1
                    for cell=1:length(Tracked.Frames(frame-1).Cells)
                        Tracked.Frames(frame-1).Cells{cell}.descendants=[];
                    end
                end
            end
            function btndown(src,evnt)
                p=get(gca,'CurrentPoint');
                coord=p(1,[2,1]);
                indx=sub2ind(size(seedmtx),round(coord(1)),round(coord(2)));
                tmpseedmtx=zeros(size(seedmtx));
                tmpseedmtx(indx)=1;
                nearindx=find(seedmtx & imdilate(tmpseedmtx,[1,1,1;1,1,1;1,1,1]));
                if ~isempty(nearindx)
                    indx=nearindx;
                end
                
                seedmtx(indx)=~seedmtx(indx);
                recalcseg
                plotframe(50*imdilate(seedmtx,[1,1,1;1,1,1;1,1,1]))
            end
        end
        function PlotLineage
            
            if isempty(selectedcell)
                StateText='Please Celect Cell First';
                plotframe
            else
                cells0=selectedcell;
                %                 Nframes=length(Tracked.Frames);
                Nframes=200;
                
                Rt{1}=zeros(Nframes, 1);
                Rm{1}=zeros(Nframes, 1);
                Rt{2}=zeros(Nframes, 1);
                Rm{2}=zeros(Nframes, 1);
                
                cellnum=[];
                
                
                fr=1:Nframes;
                newcells=cells0;
                cells=cells0;
                %get progenitor all the way back
                for k=1:frame
                    frame1=frame-k+1; %counting backwards for progenitors
                    for cell1=cells
                        if cell1==-1
                            continue
                        end
                        Rt{1}(frame1,cells==cell1)=Tracked{frame1}.Cells(cell1).Ftotal;
                        Rm{1}(frame1,cells==cell1)=Tracked{frame1}.Cells(cell1).Fmean;
                        if isfield(Tracked{frame1}.Cells{cell1}, 'Fdata') %fluorescence data (not used for segmentation)
                            color{1,1}=Tracked{frame1}.Cells{cell1}.Fname;
                            for n=2:length(Tracked{frame1}.Cells{cell1}.Fdata.Ftotal)+1
                                Rt{n}(frame1,cells==cell1)=Tracked{frame1}.Cells{cell1}.Fdata.Ftotal;
                                Rm{n}(frame1,cells==cell1)=Tracked{frame1}.Cells{cell1}.Fdata.Fmean;
                                color{1,n}=Tracked{frame1}.Cells{cell1}.Fdata.Fname;
                            end
                        else
                            color{1,1}=' tracking color';
                        end
                        cellnum(frame1,cells==cell1)=cell1;
                        if isempty(Tracked{frame1}.Cells{cell1}.progenitor)
                            newcells(cells==cell1)=-1;
                        else
                            newcells(cells==cell1)=Tracked{frame1}.Cells{cell1}.progenitor;
                        end
                    end
                    cells=newcells;
                    newcells=cells;
                end
                %get descendants
                newcells=cells0;
                cells=cells0;
                for frame1=frame:Nframes
                    for cell1=cells
                        if cell1==-1
                            continue
                        end
                        Rt{1}(frame1,cells==cell1)=Tracked{frame1}.Cells{cell1}.Ftotal;
                        Rm{1}(frame1,cells==cell1)=Tracked{frame1}.Cells{cell1}.Fmean;
                        cellnum(frame1,cells==cell1)=cell1;
                        if isfield(Tracked{frame1}.Cells{cell1}, 'Fdata') %fluorescence data (not used for segmentation)
                            for n=2:length(Tracked{frame1}.Cells{cell1}.Fdata.Ftotal)+1
                                Rt{n}(frame1,cells==cell1)=Tracked{frame1}.Cells{cell1}.Fdata.Ftotal;
                                Rm{n}(frame1,cells==cell1)=Tracked{frame1}.Cells{cell1}.Fdata.Fmean;
                            end
                        end
                        if isempty(Tracked{frame1}.Cells{cell1}.descendants)
                            newcells(cells==cell1)=-1;
                        elseif isscalar(Tracked{frame1}.Cells{cell1}.descendants)
                            newcells(cells==cell1)=Tracked{frame1}.Cells{cell1}.descendants;
                        else
                            newcells(cells==cell1)=Tracked{frame1}.Cells{cell1}.descendants(1);
                            newcells(end+1)=Tracked{frame1}.Cells{cell1}.descendants(2);
                            Rt{1}(:,end+1)=Rt{1}(:,cells==cell1);
                            Rm{1}(:,end+1)=Rm{1}(:,cells==cell1);
                            if isfield(Tracked{frame1}.Cells{cell1}, 'Fdata') %fluorescence data (not used for segmentation)
                                for n=2:length(Tracked{frame1}.Cells{cell1}.Fdata.Ftotal)+1
                                    Rt{n}(:,end+1)=Rt{n}(:,cells==cell1);
                                    Rm{n}(:,end+1)=Rm{n}(:,cells==cell1);
                                end
                            end
                            cellnum(:,end+1)=cellnum(:,cells==cell1);
                        end
                    end
                    cells=newcells;
                    newcells=cells;
                end
                
                fp = figure(); hold on; set(fp, 'Name', ['Cell ' num2str(cellnum(1,1)) ' in frame 1'])
                subplot(2,2,1); plot(1:length(Rt{1}),Rt{1},'.-');
                celltags=regexp(num2str(cellnum(end,:)), '\s*', 'split'); xlabel('time (frames)');
                ylabel(['total ' color{1,1}(2:end) ' (a.u.)']);
                legend(celltags); legend('off'); %this labels the cells
                subplot(2,2,2); plot(1:length(Rm{1}),Rm{1},'.-');
                celltags=regexp(num2str(cellnum(end,:)), '\s*', 'split'); xlabel('time (frames)');
                ylabel(['mean ' color{1,1}(2:end) ' (a.u.)']);
                legend(celltags); legend('off'); %this labels the cells
                
                %plot other colors, if fluorescence information exists
                subplot(2,2,3); plot(1:length(Rt{2}),Rt{2},'.-');
                celltags=regexp(num2str(cellnum(end,:)), '\s*', 'split');
                xlabel('time (frames)'); ylabel(['total ' color{1,2}{1,1}(2:end) ' (a.u.)']);
                legend(celltags); legend('off'); %this labels the cells
                subplot(2,2,4); plot(1:length(Rm{2}),Rm{2} ,'.-');
                celltags=regexp(num2str(cellnum(end,:)), '\s*', 'split'); xlabel('time (frames)'); ylabel(['mean ' color{1,2}{1,1}(2:end) ' (a.u.)']);
                legend(celltags); legend('off'); %this labels the cells
            end
        end
        function XpandSegs
            segsize=0;
            newsegmask=SegRenderNum([Tracked.Frames(frame).Cells{:}],imy,imx)>0;
            im=AllImg{frame};
            while segsize<sum(sum(newsegmask))
                segsize=sum(sum(newsegmask));
                tavg=imfilter(newsegmask.*im,fspecial('average',6),'symmetric');
                navg=imfilter(newsegmask,fspecial('average',6),'symmetric');
                bratio=imdilate(newsegmask,strel('diamond',1)).*(1-newsegmask).*im./tavg.*navg;
                newsegmask=newsegmask+(bratio>0.9);
            end
            
            [newsegmaskl,num]=bwlabel((newsegmask)>0);
            bbox=regionprops(newsegmaskl,'BoundingBox');
            cells=struct('mask',{},'pos',{},'size',{},'progenitor',{},'descendants',{});
            for cseg=1:num
                cellslice={floor(bbox(cseg).BoundingBox(2))+1:floor(bbox(cseg).BoundingBox(2)+bbox(cseg).BoundingBox(4)),...
                    floor(bbox(cseg).BoundingBox(1))+1:floor(bbox(cseg).BoundingBox(1)+bbox(cseg).BoundingBox(3))};
                cells(end+1).mask=double(newsegmaskl(cellslice{1},cellslice{2})==cseg);
                cells(end).pos=floor(bbox(cseg).BoundingBox(2:-1:1))+1;
                cells(end).size=size(cells(end).mask);
            end
            Tracked.Frames(frame).Cells=num2cell(cells);
            Tracked.Frames(frame).predictMito=0;
            %remove the links from progenitors and descendants
            if frame<length(Tracked.Frames)
                for cell=1:length(Tracked.Frames(frame+1).Cells)
                    Tracked.Frames(frame+1).Cells{cell}.progenitor=[];
                end
            end
            if frame>1
                for cell=1:length(Tracked.Frames(frame-1).Cells)
                    Tracked.Frames(frame-1).Cells{cell}.descendants=[];
                end
            end
            plotframe
        end
        function FixLinks(dir)
            cframe=frame;
            cellnb0=length(Tracked{cframe}.Cells);
            cellnb1=length(Tracked{cframe+1}.Cells);
            transition01=zeros(cellnb0,cellnb1);
            transition10=zeros(cellnb0,cellnb1);
            
            for ccell=1:cellnb0
                desc=Tracked{cframe}.Cells{ccell}.descendants;
                transition01(ccell,desc)=1;
            end
            for ccell=1:cellnb1
                prev=Tracked{cframe+1}.Cells{ccell}.progenitor;
                transition10(prev,ccell)=1;
            end
            if dir==0
                %use frame 0 to correct frame 1
                for ccell=1:cellnb1
                    prev=find(transition01(:,ccell));
                    Tracked{cframe+1}.Cells{ccell}.progenitor=prev;
                end
            else
                %use frame 1 to correct frame 0
                for ccell=1:cellnb0
                    desc=find(transition10(ccell,:));
                    Tracked{cframe}.Cells{ccell}.descendants=desc;
                end
            end
            
            plotframe
        end
        
        
    end

% File Functions
    function Data=openfiles(Cfg,Pos,Channel,WBmsg)
        %determine which files to load
        
        fname=Cfg.Foldername;
        if Cfg.subfolders==1
            filelist=inclusivedir(fname);
        else
            filelist=dir(fname);
            filelist={filelist.name};
        end
        
        [~,~,~,~,REres]=regexp(filelist,Cfg.REstr);
        %get only images that fit rhe regular expression
        imagefiles=filelist(~cellfun(@isempty, REres));
        [~,~,~,~,REres]=regexp(imagefiles,Cfg.REstr);
        %get only images of the right position
        imagefiles=imagefiles(cellfun(@(el) strcmp(el{1}{strcmp(Cfg.tokenNames,'Position')},Pos),REres));
        [~,~,~,~,REres]=regexp(imagefiles,Cfg.REstr);
        %get only images of the desired Channel
        imagefiles=imagefiles(cellfun(@(el) strcmp(el{1}{strcmp(Cfg.tokenNames,'Channel')},Channel),REres));
        [~,~,~,~,REres]=regexp(imagefiles,Cfg.REstr);
        %get only images of the Frames to be anlayzed
        [~,imagefilesI]=intersect(cellfun(@(el) str2num(el{1}{strcmp(Cfg.tokenNames,'Frame')}), REres),Cfg.FramesAnlz);
        imagefiles=imagefiles(imagefilesI);
        
        
        if exist('WBmsg','var')
            hwb=waitbar(0,WBmsg);
        end
        for cframe=1:length(imagefiles)
            cfilename=imagefiles{cframe};
            Data(cframe).filename=cfilename;
            Data(cframe).raw=double(imread([fname filesep cfilename]));
        if exist('WBmsg','var')
            waitbar(cframe./length(imagefiles),hwb)
        end
        end
        delete(hwb)
    end
    function filelist=inclusivedir(fname)
        %find all files in current folder and all subfolders.
        
        alllist=dir(fname);
        dirlist={alllist([alllist.isdir]).name};
        filelist=[];
        filelist=cat(2,filelist,{alllist(~[alllist.isdir]).name});
        
        %include files in subfolders
        for cdir=dirlist
            if strcmp(cdir{1}(1),'.')
                continue
            else
                alllist=dir([fname,filesep,cdir{1}]);
                alllist=cellfun(@(el) [cdir{1} filesep el],{alllist(~[alllist.isdir]).name},'unif',0);
                filelist=cat(2,filelist,alllist);
            end
        end
        
    end
% Backgroun Subtraction Functions
    function [a,B,I,A]=anlzBkg(BkgChannel)
        % we assume specific model for the background
        % S = I(x)*D(x,t) + a*I(x)*A(t) + B
        % where S is the total signal, a is a scale factor I is the illumination
        % profile scaled to have mean=1, D is the real data, A is the auto
        % fluorescence (scaled) and B is the black level of the sensor
        %
        
        XYsz=size(Tracked.Frames(1).TrackData.raw);
        Tsz=length(Tracked.Frames);
        BkgType=Tracked.cfg.BkgSub.Type;
        BkgPrm=Tracked.cfg.BkgSub.Prm;
        
        switch BkgType
            case 'None'
                % in this case a=1, I=1, A=0, B=0;
                a=1;
                B=0;
                I=ones(XYsz);
                A=zeros(Tsz,1);
            case 'Flat'
                % flat background but non zero
                % in this case a=1, I=1, A=0, B;
                a=1;
                I=ones(XYsz);
                A=zeros(Tsz,1);                
                %assess background levels and take only bkg pixels
                SignalData=openfiles(Tracked.cfg, Tracked.cfg.PositionAnlz{1}, BkgChannel,'Loading files...');
                lindata=reshape([SignalData.raw],1,[]);
                hbins=min(lindata):prctile(lindata,50)*2;
                bgfit=fit(hbins',hist(lindata,hbins)','gauss1');
                B=bgfit.b1;
                
            case 'Pos'
                % Here we measure S for D=0; solve for a, I, A and B
                
                % parameters
                temporalAvg=4;
                spatialAvg=16;
                Npos=length(BkgPrm);
                
                % if more than one position than solve for each and average
                a=zeros(1,Npos);
                B=zeros(1,Npos);
                I=zeros([XYsz,Npos]);
                A=zeros(Tsz,Npos);
                Data=struct('filename',{},'raw',{});
                for cPos=1:Npos
                    %open files
                    Data(:,cPos)=openfiles(Tracked.cfg, BkgPrm{cPos}, BkgChannel,['Loading ' BkgChannel{:} ' background position ' num2str(cPos) '...']);
                    %calculate params
                    [a(cPos),B(cPos),I(:,:,cPos),A(:,cPos)]=extractBkgPrm(cat(3,Data(:,cPos).raw),spatialAvg,temporalAvg);
                end
                a=mean(a);
                B=mean(B);
                I=mean(I,3);
                A=mean(A,2);
            case 'Fit'
                % parameters
                temporalAvg=4;
                spatialAvg=16;
                
                %find the background fit for each frame
                SignalData=openfiles(Tracked.cfg, Tracked.cfg.PositionAnlz{1}, BkgChannel,'Loading files...');
                Data=zeros([XYsz,Tsz]);
                hwb=waitbar(0,'Extracting fit parameters...');
                prog=0;
                step=1./Tsz;
                for ctime=1:Tsz
                    Data(:,:,ctime)=fitS0(SignalData(ctime).raw);
                    prog=prog+step; 
                    waitbar(prog,hwb);
                end
                delete(hwb)
                %calculate params
                [a,B,I,A]=extractBkgPrm(Data, spatialAvg, temporalAvg);
                
                
            case 'File'
                
        end
    end
    function [S, bgstd]=fitS0(im)
        [imy,imx]=size(im);
        %fit background
        sx=1:5:imx;
        sy=1:5:imy;
        ss=im(1:5:imy,1:5:imx);
        [xInput, yInput, zOutput] = prepareSurfaceData( sx, sy, ss );
        
        %assess background levels and take only bkg pixels
        hbins=min(zOutput):prctile(zOutput,50)*2;
        bgfit=fit(hbins',hist(zOutput,hbins)','gauss1');
        bgstd=bgfit.c1;
        bgcutoff=bgfit.b1+(bgfit.b1-min(zOutput));
        bkgI=zOutput<bgcutoff;
        xInput=xInput(bkgI);
        yInput=yInput(bkgI);
        zOutput=zOutput(bkgI);
        
        % Set up fittype and options.
        ft = fittype( 'p00+p10*x+p01*y+p20*x^2+p11*x*y+p02*y^2', 'indep', {'x', 'y'}, 'depend', 'z' );
        opts = fitoptions( ft );
        opts.Display = 'Off';
        opts.Lower = [-Inf -Inf -Inf -Inf -Inf -Inf];
        opts.StartPoint = [bgfit.b1 0 0 0 0 0];
        opts.Upper = [Inf Inf Inf Inf Inf Inf];
        % Fit model to data.
        [fitresult] = fit( [xInput, yInput], zOutput, ft, opts );
        % generate Signal profile
        [x,y]=meshgrid(1:imx,1:imy);
        S=fitresult(x,y);
    end
    function [a,B,I,A]=extractBkgPrm(Sraw,spatialAvg,temporalAvg)
        if size(Sraw,3)<5*temporalAvg
            temporalAvg=1;
        end
        %reduce image size
        S=imresize(Sraw,1/spatialAvg);
        reducedsize=size(S);
        %reduce time-dimension size
        tlast=floor(size(S,3)/temporalAvg)*temporalAvg;
        S=squeeze(mean(reshape(S(:,:,1:tlast),size(S,1),size(S,2),temporalAvg,[]),3));
        S=reshape(S,[],size(S,3));
        
        
        Sx=median(S,1);
        St=median(S,2);
        Sxt=median(Sx);
        F1=bsxfun(@times,(Sx-Sxt),(St-Sxt));
        F2=S+Sxt-bsxfun(@plus, St,Sx);
        a=exp(nanmedian(log(F1(:))-log(F2(:))));
        B=Sxt-a;
        I=imresize(reshape((St-B)/a,reducedsize(1),reducedsize(2)),size(Sraw(:,:,1)));
        if length(Sx)==1
            A=repmat((Sx-B)/a,size(Sraw,3));
        else
            A=interp1( 1:temporalAvg:tlast, (Sx-B)/a, 1:size(Sraw,3), 'previous', 'extrap');
        end
    end
% Segmentation Functions
    function cells=imsegment(im,bgstd)
        %im=imtophat(im,strel('disk',30));
        %bgstd=mean(reshape((imtophat(bgstd*randn(size(im)),strel('disk',30))),1,[]));

        %find the likelihood for each pixel to be noise
        imLH=normpdf(im./bgstd);

        %find all pixels which are 2sigma away
        %but only positively. don't take very negative values, less than
        %background, since this is just closed shutter.
        imSeg=imLH<0.054 & im>0;

        %take cells whose likelihood is <1e-50
        imSegLbl=bwlabel(imSeg);
        stats=regionprops(imSegLbl, imLH, 'PixelValues');
        CellLbl=find((cellfun(@(x) sum(log10(x)),{stats.PixelValues})<-50));
        imMask=ismember(imSegLbl,CellLbl);

        %make the cell database
        cells=mask2cells(imMask);
        cells=CalcCellProperties(cells, im);
    end
    function cells=mask2cells(mask)
        cells=struct('mask',{},'pos',{},'size',{},'progenitor',{},'descendants',{});
        [imy,imx]=size(mask);
        num=max(mask(:));
        if num==0
            return
        elseif num==1
            %input is just a mask
            [maskLbl,num]=bwlabel((mask)>0);
        else
            %input is a labeled mask
            maskLbl=mask;
        end
        newsegclose=imfill(imclose(maskLbl,strel('square',2)),'holes');
        tst=regionprops(newsegclose,{'BoundingBox','Image'});
        [cells(1:num).mask]=deal(tst.Image);
        allpos=cellfun(@(x) floor(x([2,1]))+1, {tst.BoundingBox},'Unif',0);
        [cells(:).pos]=deal(allpos{:});
        allsize=cellfun(@(x) x([4,3]), {tst.BoundingBox},'Unif',0);
        [cells(:).size]=deal(allsize{:});
        
    end
    function C=getPixels(im, pos, size)
        C=im(pos(1):pos(1)+size(1)-1,pos(2):pos(2)+size(2)-1);
    end
    function I=setPixel(I,C,pos)
        % set pixels from C into image I at position pos
        [L,W]=size(C);
        I(pos(1):pos(1)+L-1, pos(2):pos(2)+W-1)=C;
    end
    function I=addPixel(I,C,pos)
        % add pixels from C to image I at position pos
        [L,W]=size(C);
        I(pos(1):pos(1)+L-1, pos(2):pos(2)+W-1)=I(pos(1):pos(1)+L-1, pos(2):pos(2)+W-1)+C;
    end
% Tracking Functions
    function [cells0,cells1]=TrackFrame(im0,cells0,im1,cells1)
        [imy,imx]=size(im1);
        
        % Calculate image registration
        regshift=imageregistration(im1,im0);
        
        nbcell0=length(cells0);
        nbcell1=length(cells1);
        if nbcell0==0 || nbcell1==0
            return
        end
        
        %TBD if no cells in the next frame try to look better for them
        %where they are expected
        
        % TBD: review anything from here until the end of TrackFrame
        recalculate=0;
        
        %TBD 
        % use morphological reconstruction to see if a segment can be
        % broken into two. It essentially uses the contours at 50% of the
        % height and watershed them.
        %
        %imMask=(watershed(-imreconstruct(0.5*im,im))>0).*imMask;
        %
        %l=floor(min(size(cim))/4)*2;
        %fcim=(imfilter(cim,fspecial('log',l)));
        %imagesc(watershed(-imreconstruct(0.1*fcim,fcim))>0)

        %2. map cells
        
        %Calculate properties of cell pairs: overlap, and distance
        [overlap,celldistance]=CalcCellPairProperties(cells0,cells1,nbcell0,nbcell1,regshift);
        %Calculate the cost functions
        overlapnorm0=bsxfun(@rdivide,overlap,[cells0.area]');
        fmapping=bsxfun(@ldivide,[cells0.Ftotal]',0.9*[cells1.Ftotal]);
        cost=overlapnorm0+1./sqrt(512/length(im0)*celldistance+1);
        fused=zeros(nbcell0,nbcell1);
        %cost=bsxfun(@rdivide,overlapnorm0,sum(overlapnorm0))+1./sqrt(512/imx*celldistance+1);
        
        %find the mapping
        cellmapping=zeros(nbcell0,nbcell1);
        cellscore=zeros(nbcell0,nbcell1);
        mappedcells=zeros(1,nbcell0);
        NNmapping=1;
        HAmapping=1;
        OrigCell=[];
        
        %if have some links use them
        for ccell=1:nbcell0
            if isempty(cells0(ccell).descendants)
            elseif isscalar(cells0(ccell).descendants)
                cellmapping(ccell,cells0(ccell).descendants)=1;
            else %assume 2 descendants
                cellmapping(ccell,cells0(ccell).descendants(1))=1;
                cellmapping(end+1,:)=0;
                cellmapping(end,cells0(ccell).descendants(2))=1;
                
                cells0(end+1)=cells0(ccell);
                usedpercent=[cells1(cells0(ccell).descendants).Ftotal]./cells0(ccell).Ftotal;
                cells0(ccell).Fmask=usedpercent(1)*cells0(ccell).Fmask;
                cells0(end).Fmask=usedpercent(2)*cells0(end).Fmask;
                cellscore(end+1,:)=0;
                mappedcells(end+1)=0;
                fmapping(end+1,:)=fmapping(ccell,:)/usedpercent(2);
                fmapping(ccell,:)=fmapping(ccell,:)/usedpercent(1);
                cost(end+1,:)=cost(ccell,:);
                OrigCell(end+1)=ccell;
                recalculate=1;
            end
        end
        nbcell0=length(cells0);
        fused=cellmapping.*fmapping;
        cellscore=cellmapping.*cost.*fmapping;
        mappedcells=sum(cellmapping,2);
        
        %complete the mapping
        while sum(NNmapping(:).*HAmapping(:))>0
            fresidue=bsxfun(@times,fmapping,(1-sum(cellmapping./fmapping)));
            fresidue=min(max(fresidue,0.001),1);%cut it at 1 and 0.001
            fcost=cost.*fresidue.*fresidue;
            %prefer orphan segments
            %fcost=bsxfun(@plus,fcost,0.1*(1-sum(cellmapping)));
            fcost=fcost+bsxfun(@times,fcost,0.1*(1-sum(cellmapping)));
            %maybe square it maybe not. for cells that have divided once definitly should be hard to divide again.
            %        fcost=cost*((fmapping*(1-sum(cellmapping/fmapping,axis=0)))**2).clip(max=1,min=0.001)
            fcost(mappedcells==1,:)=0.0001;
            NNmapping=zeros(nbcell0,nbcell1);
            [~,tmp]=max(fcost,[],2);
            NNmapping(sub2ind(size(fcost),1:nbcell0,tmp'))=1;
            %HAmapping=CalcHungarian(1./fcost);
            HAmapping=CalcHungarian(1./max(fcost,0.0001),1/0.01);
            
            cellmapping=cellmapping+NNmapping.*HAmapping;
            cellscore=cellscore+NNmapping.*HAmapping.*fcost;
            mappedcells=sum(cellmapping,2);
            
            %how much of the energy of the original cell is mapped to the
            %new cell
            fused=fused+NNmapping.*HAmapping.*fresidue;
            %if a cell mapped to a low energy segment it probably mitosed so remove .5 of the energy and keep it unmapped
            %TBD: maybe it was mapped to an undersegmented cell. check segmentation.
            for mitcell=find(sum((fused<0.66).*cellmapping,2))'
                %                 display('here, please check this code again')
                %                continue
                usedpercent=fused(mitcell,cellmapping(mitcell,:)==1);
                cells0(end+1)=cells0(mitcell);
                %maybe 0.9-used and 0.1+used
                cells0(end).Fmask=(1-usedpercent)*cells0(end).Fmask;
                cells0(mitcell).Fmask=(usedpercent)*cells0(mitcell).Fmask;
                nbcell0=nbcell0+1;
                cellmapping(end+1,:)=0;
                cellscore(end+1,:)=0;
                mappedcells(end+1)=0;
                fmapping(end+1,:)=fmapping(mitcell,:)/(1-usedpercent);
                fmapping(mitcell,:)=fmapping(mitcell,:)/usedpercent;
                fused(end+1,:)=0;
                fused(mitcell,:)=fused(mitcell,:)/usedpercent;
                cost(end+1,:)=cost(mitcell,:);
                OrigCell(end+1)=mitcell;
                recalculate=1;
            end
        end
        
        % check if i mapped something into the noise. that is, if a dim object mapped into a bright one.
        % check both Ftotal ratio <5 and Fmean ratio <3
        FtotalR=cellmapping*[cells1.Ftotal]'./[cells0.Ftotal]';
        FmeanR=cellmapping*[cells1.Fmean]'./[cells0.Fmean]';
        tmpcellmapping=cellmapping;
        tmpcellmapping((FtotalR>5) & (FmeanR>3),:)=0;
        areaR=cellmapping*([cells0.area]*tmpcellmapping./[cells1.area])';
        % TBD: it is really a noise if its level is only a fraction of the pixels it cover
        cellmapping((FtotalR>5) & (FmeanR>3) & (areaR>0.85),:)=0;
        
        % if it disappears try to look for it
        for dcell=find(sum(cellmapping,2)==0)'
            position=min(max(cells0(dcell).pos+cells0(dcell).Acom-[51,51]-regshift,1),size(im1));
            eposition=min(position+100,size(im1));
            imreg=im1(position(1):eposition(1)-1,position(2):eposition(2)-1);
            if isempty(imreg)
                continue
            end
            
            %ll=localsegment(medfilt2(imreg,[5,5],'symmetric'),SegType);
            ll=zeros(size(imreg));
            [ll2,nn]=bwlabel(ll,8);
            stats = regionprops(ll2, imreg, 'meanIntensity','area','BoundingBox');
            %check that it is similar size and level
            similaritydist=([stats.MeanIntensity]/cells0(dcell).Fmean-1).^2/0.04+([stats.Area]/cells0(dcell).area-1).^2/0.04;
            
            overlapdist=zeros(size(similaritydist));
            origcellreg=SegRenderNum(cells0(dcell),imy,imx);
            origcellreg=origcellreg(position(1):eposition(1)-1,position(2):eposition(2)-1);
            overlapIdx=unique(origcellreg.*ll2);
            
            overlapdist(overlapIdx(2:end))=1;
            
            if ~isempty(cells1)
                emptycell=struct(cells1(end));
                for cfield=fieldnames(emptycell)'
                    emptycell.(cfield{1})=[];
                end
            else
                emptycell=struct('mask',[],'pos',[],'size',[],'progenitor',[],'descendants',[]);
            end
            candict=emptycell;
            
            %for cand=find(similaritydist<4/pi | overlapdist)
            for cand=find(similaritydist<3*4/pi)
                cellslice=[ceil(stats(cand).BoundingBox(2:-1:1)) ceil(stats(cand).BoundingBox(2:-1:1))+stats(cand).BoundingBox(4:-1:3)-1];
                cellmask=ll2(cellslice(1):cellslice(3),cellslice(2):cellslice(4))==cand;
                cellpos=position+cellslice(1:2);
                candict(end+1)=emptycell;
                candict(end).mask=cellmask;
                candict(end).pos=cellpos;
                candict(end).size=size(cellmask);
            end
            candict(1)=[];
            if isempty(candict)
                continue
            end
            candict=CalcCellProperties(candict,imn1);
            %should also check that it is not an existing segment (does not overlap with anything)
            overlapcand = any(CalcCellPairProperties(candict,cells1,length(candict),nbcell1)>0,2);
            candict=candict(~overlapcand);
            
            %imshow(SegRender(candict,imx,imx)+2*SegRender(cells1,imx,imx));show()
            if isempty(candict)
                continue
            end
            % and if more than one candidate, take the closest one
            % maybe later just recompute from scratch
            [~,canddist]=CalcCellPairProperties(candict,cells0(dcell),length(candict),1);
            [~,candselect]=min(canddist);
            cells1(end+1)=candict(candselect);
            nbcell1=nbcell1+1;
            cellmapping(:,end+1)=0;
            cellmapping(dcell,end)=1;
            recalculate=1;
            
        end
        
        % if two predicted mitotic cells are mapped to the same segment, don't mitose
        addedCells=length(OrigCell);
        for mitocellnum=1:addedCells
            mitocell=OrigCell(addedCells+1-mitocellnum);
            mitocellsister=nbcell0-mitocellnum+1;
            if all(cellmapping(mitocell,:)==cellmapping(mitocellsister,:))
                OrigCell(addedCells+1-mitocellnum)=[];
                cells0(mitocell).Fmask=cells0(mitocell).Fmask+cells0(mitocellsister).Fmask;
                cells0(mitocellsister)=[];
                %renumber the OrigCell numbers since we removed a cell
                OrigCell(OrigCell==mitocellsister)=mitocell;
                OrigCell(OrigCell>mitocellsister)=OrigCell(OrigCell>mitocellsister)-1;
                cellmapping(mitocellsister,:)=[];
                recalculate=1;
            end
        end
        if recalculate==1
            nbcell0=length(cells0);
            cells0=CalcCellProperties(cells0,im0);
            [overlap,celldistance]=CalcCellPairProperties(cells0,cells1,nbcell0,nbcell1,regshift);
            overlapnorm0=bsxfun(@rdivide,overlap,[cells0.area]');
            recalculate=0;
        end
        
        % 3. split cells
        
        % if two cells map to the same segment, split it
        % three options. touching, partiall overlapp or one withing the other.
        SplitOrigCell=1:nbcell1;
        AllOrigSeed=[];
        for j=find(sum(cellmapping)>1)
            
            %find the xcorr of each original cell with the target segment
            
            
            seeds={};
            abscell=find(cellmapping(:,j));
            shifts=bsxfun(@plus,cell2mat({cells0(abscell).pos}'),-cells1(j).pos+[50,50]-regshift);
            change=[0,0;0,-1;1,0;-1,0;0,1];
            Target=zeros([100,100]+size(cells1(j).Fpixels));
            Target=AddCell(Target,[0,0],cells1(j).Fpixels,[50,50]);
            OMtmp=zeros(size(Target));
            OM=zeros(size(Target));
            %start with overlapping cells. maybe take only >0.2 overlapnorm0
            for cell=find(overlap(abscell,j))'
                OM=AddCell(OM,[0,0],cells0(abscell(cell)).Fpixels,shifts(cell,:));
            end
            
            %move them around until they fit best
            origshifts=zeros(size(shifts));
            while any(any(origshifts~=shifts))
                origshifts=shifts;
                for cell=find(overlap(abscell,j))'
                    score=[];
                    OM=AddCell(OM,[0,0],-cells0(abscell(cell)).Fpixels,shifts(cell,:));
                    for shft=change'
                        OM=AddCell(OM,[0,0],cells0(abscell(cell)).Fpixels,shifts(cell,:)+shft');
                        
                        score(end+1)=sum(sum(abs((OM-Target)./(OM+Target+1))));
                        OM=AddCell(OM,[0,0],-cells0(abscell(cell)).Fpixels,shifts(cell,:)+shft');
                    end
                    shifts(cell,:)=shifts(cell,:)+change(find(score==min(score),1),:);
                    OM=AddCell(OM,[0,0],cells0(abscell(cell)).Fpixels,shifts(cell,:));
                end
            end
            %add them to a seed list
            OrigSeed=[];
            for cell=find(overlap(abscell,j))'
                seeds{end+1}=AddCell(zeros(cells1(j).size),[0,0],cells0(abscell(cell)).mask,shifts(cell,:)-[50,50]);
                seeds{end}=seeds{end}.*cells1(j).mask;
                OrigSeed(end+1)=abscell(cell);
            end
            % now add the non overlapping cells
            for cell=find(overlap(abscell,j)==0)'
                % find the minima of missing energy
                [I,J]=find((imerode(OM-Target,cells0(abscell(cell)).mask)==OM-Target).*(Target>0));
                candidatePos=[I,J];
                %if it is empty take the minimal one.
                if isempty(candidatePos)
                    [~,tmp]=min(OM(:)-Target(:));
                    [I,J]=ind2sub(size(Target),tmp);
                    candidatePos=[I,J];
                end
                %find the closest one
                [~,candidate]=min(sum(bsxfun(@minus,candidatePos,shifts(cell,:)+cells0(abscell(cell)).Acom).^2,2));
                OMtmp(candidatePos(candidate,1),candidatePos(candidate,2))=1;
                OMtmp=bwlabel((OM-Target)<min(min(OM-Target))/2);
                blobn=OMtmp(candidatePos(candidate,1),candidatePos(candidate,2));
                OMtmp=(OMtmp==blobn);
                
                while sum(sum(OMtmp.*Target)) < cells0(abscell(cell)).Ftotal
                    prevsize=sum(sum(OMtmp));
                    OMtmp=imdilate(OMtmp,strel('diamond',1)).*(Target>0);
                    if prevsize==sum(sum(OMtmp))
                        break
                    end
                end
                OM=AddCell(OM,[0,0],OMtmp.*Target,[0,0]);
                seeds{end+1}=AddCell(zeros(cells1(j).size),[0,0],OMtmp(51:end,51:end),[0,0]).*cells1(j).mask;
                OrigSeed(end+1)=abscell(cell);
            end
            %           take the cells and expand, adding unasociated pixels
            targetarea=cells1(j).area;
            allseeds=sum(cat(3, seeds{:}),3)>0;
            seedsarea=sum(sum( allseeds>0 ));
            while seedsarea<targetarea
                for n=1:length(seeds)
                    seeds{n}=imdilate(seeds{n},ones(3,3)).*cells1(j).mask.*(1-allseeds)+seeds{n};
                end
                allseeds=sum(cat(3, seeds{:}),3)>0;
                if seedsarea==sum(sum(allseeds));
                    disp('may have some broken cell. check err20120604.')
                    break;%no area change, infinite loop;
                end
                seedsarea=sum(sum( allseeds ));
            end
            %           add the new cells to the dictionary
            %           if n cells are overlapping, split the F between all
            fmeanseeds=[];
            fmeanseeds(1,1,:)=[cells0(OrigSeed).Fmean];
            fmeanseeds=sum(bsxfun(@times,cat(3, seeds{:}),fmeanseeds),3);
            numseeds=sum(cat(3, seeds{:}),3);
            for seednum=1:length(seeds)
                cell=seeds(seednum);
                if ~any(any(cell{1}))
                    continue
                end
                tmp=zeros(size(cell{1})+2);
                tmp(2:end-1,2:end-1)=cell{1};
                tmp=imopen(tmp,strel('diamond', 4));
                if any(any(tmp(2:end-1,2:end-1)))
                    cellOpen=tmp(2:end-1,2:end-1);
                else
                    cellOpen=cell{1};
                end
                bbox=regionprops(cellOpen,'BoundingBox');
                cellslice={floor(bbox.BoundingBox(2))+1:floor(bbox.BoundingBox(2)+bbox.BoundingBox(4)),...
                    floor(bbox.BoundingBox(1))+1:floor(bbox.BoundingBox(1)+bbox.BoundingBox(3))};
                cells1(end+1).mask=cellOpen(cellslice{1},cellslice{2});
                cells1(end).pos=cells1(j).pos+floor(bbox.BoundingBox(2:-1:1));
                cells1(end).Fmask=cells1(end).mask.*cells0(OrigSeed(seednum)).Fmean./fmeanseeds(cellslice{1},cellslice{2});
                %NaN could appear where numseeds is zero. also cell mask is
                %zero there and it should just be zero
                cells1(end).Fmask(isnan(cells1(end).Fmask))=0;
                cells1(end).size=size(cells1(end).mask);
                SplitOrigCell(end+1)=j;
                AllOrigSeed(end+1)=OrigSeed(seednum);
            end
        end
        %   remove the old ones, and recalculate everthing
        if any(sum(cellmapping)>1)
            todelete=sum(cellmapping)>1;
            cells1(todelete)=[];
            for i=1:length(AllOrigSeed)
                cellmapping(:,end+1)=0;
                cellmapping(AllOrigSeed(i),end)=1;
            end
            SplitOrigCell(todelete)=[];
            cellmapping(:,todelete)=[];
            
            nbcell1=length(cells1);
            cells1=CalcCellProperties(cells1,im1);
            [overlap,celldistance]=CalcCellPairProperties(cells0,cells1,nbcell0,nbcell1,regshift);
            overlapnorm0=bsxfun(@rdivide,overlap,[cells0.area]');
            recalculate=0;
        end
        
        
        
        % Build the mapping:
        %   now we should have nbcell0=nbcell1
        %   we might want to allow cells to apear or disappear but we'll see
        %   if i have a ghost from the previous frame i would try to map all the others and then use it. so give it a cost of 0
        %   if nbcell1 is bigger, there are new cells. i will pad with zero rows. these assignments won't give me any gain so i will try to maximize assigmnment to 'real' cells and only the others will be assigned here.
        %   if nbcell0 is bigger, cells turns into ghosts. again, i will pad with 0.
        cost=(overlapnorm0+1./sqrt(512/imx*celldistance+1));
        fmapping=bsxfun(@ldivide,[cells0.Ftotal]',0.9*[cells1.Ftotal]);
        newcellmapping=CalcHungarian(-cost./exp(abs(log(fmapping))),-0.02);
        %%try to rebuild the matrix for the original unsplitted cells and
        %%see it it is the same as before
        %unsplitcellmapping=zeros(nbcell0,max(SplitOrigCell));
        %for j=1:nbcell1
        %    unsplitcellmapping(:,SplitOrigCell(j))=unsplitcellmapping(:,SplitOrigCell(j))+newcellmapping(:,j);
        %end
        %if ~all(all(newcellmapping==cellmapping))
        %    disp('There might be a problem in the tracking')
        %end
        %cellmapping=newcellmapping;
        
        %cellmapping=CalcHungarian(1./(cost.*fmapping.*fmapping));
        % Predict Mito in the next frame add 0.01 so as not to divide by zero
        FmeanRatio=[cells0.Fmean]*cellmapping./[cells1.Fmean];
        FtRatio=[cells0.Ftotal]*cellmapping./[cells1.Ftotal];
        areaRatio=[cells0.area]*cellmapping./[cells1.area];
        % fix cell mapping for the mitotic cells
        % merge back into the original cell
        for mitocell=OrigCell(end:-1:1)
            cellmapping(mitocell,:)=0.5*(cellmapping(mitocell,:)+cellmapping(end,:));
            cellmapping=cellmapping(1:end-1,:);
            cells0(mitocell).Fmask=cells0(mitocell).Fmask+cells0(end).Fmask;
            cells0(end)=[];
            nbcell0=nbcell0-1;
            recalculate=1;
        end
        if recalculate==1
            nbcell0=length(cells0);
            cells0=CalcCellProperties(cells0,im0);
            recalculate=0;
        end
        predictMito=areaRatio>1.43;
        % if a mito wasn't predicted but a cell have much less size and F, plus there was an appearing cell, tere was a mito
        % #    for cell in predictMito.nonzero()[0]:
        for cell=find(FtRatio>1.43)
            origcell= find(cellmapping(:,cell));
            %is there a relatively close appearing cell
            for newcell=find((cost(origcell,:)>0.2) & (sum(cellmapping)==0))
                %associate it as a descendant
                cellmapping(origcell,newcell)=0.5;
                cellmapping(origcell,cell)=0.5;
            end
        end
        predictMito = predictMito & (sum(cellmapping)==1);
        % if a cell mitosed into two daughters that touch
        % remerge the daughters
        %if mitosed into three, unlink random daugter
        cellstoremove=[];
        for cell=1:nbcell0
            descend=find(cellmapping(cell,:));
            if length(descend)>1
                if length(descend)>2
                    cellmapping(cell,descend)=0.5;
                    for cdes=3:length(descend)
                        cellmapping(cell,descend(cdes))=0;
                    end
                    descend=find(cellmapping(cell,:));
                end
                descend_overlap=sum(sum(SegRenderCnt(cells1(descend))==2));
                if descend_overlap>0 &1<0 %never do that
                    %merge the daughters
                    newcell=struct(cells1(descend(1)));
                    for cfield=fieldnames(newcell)'
                        newcell.(cfield{1})=[];
                    end
                    newcell.mask=min(SegRenderNum(cells1(descend)),1);
                    newcell.pos=min(cell2mat({cells1(descend).pos}'));
                    newcell.size=size(newcell.mask);
                    cells1(descend(1))=newcell;
                    cellmapping(:,descend(1))=sum(cellmapping(:,descend),2);
                    cellstoremove=[cellstoremove descend(2:end)];
                    recalculate=1;
                end
            end
        end
        cellmapping(:,cellstoremove)=[];
        cells1(:,cellstoremove)=[];
        if recalculate==1
            nbcell1=length(cells1);
            cells1=CalcCellProperties(cells1,imn1);
            recalculate=0;
        end
        
        %%%     if toplot==1:
        %%%         imshow(SegRenderNum(cells0));colorbar();figure();imshow(SegRenderNum(cells1));colorbar();show()
        % add final information to the Dictionary and save
        for cell=1:nbcell0
            cells0(cell).descendants=find(cellmapping(cell,:));
        end
        for cell=1:nbcell1
            cells1(cell).progenitor=find(cellmapping(:,cell));
        end
        
        
    end
    function regshift=imageregistration(im1,im0)
        [imy,imx]=size(im1);
        %xc=normxcorr2(im1,im0);
        xc=xcorr2(imresize(im1,0.2),imresize(im0,0.2));
        xc=imresize(xc, 2*size(im1));
        %allow at most 25% frame shifts
        maxshiftY=round(0.25*imy);
        maxshiftX=round(0.25*imx);
        xc=xc(imy-maxshiftY:imy+maxshiftY,imx-maxshiftX:imx+maxshiftX);
        %xc=imfilter(xc, fspecial('gaussian',100,10));
        [I,J]=find(xc==max(xc(:)),1);
        regshift=[I,J]-[maxshiftY,maxshiftX];
    end
    function cellsDictNew=CalcCellProperties(cellsDict,imn)
        % Calculate properties of cells
        % assume existing: pos, size, mask
        % area, Acom (area-center-of-mass), Ftotal, Fmean, Fmax, Fpixels
        cellsDictNew=cellsDict;
        nbcell=length(cellsDict);
        for cell=1:nbcell
            %if there is an 'Fmask' then it is the percent of F in every pixel that belongs to that cell. if not it is ones.
            if ~isfield(cellsDictNew(cell),'Fmask') || isempty(cellsDictNew(cell).Fmask)
                cellsDictNew(cell).Fmask=double(cellsDictNew(cell).mask);
            end
            cellsDictNew(cell).area=sum(cellsDictNew(cell).mask(:));
            cellsDictNew(cell).Acom=...
                floor([sum(sum(cellsDictNew(cell).mask,2).*(1:cellsDictNew(cell).size(1))')/cellsDictNew(cell).area,...
                sum(sum(cellsDictNew(cell).mask,1).*(1:cellsDictNew(cell).size(2)))/cellsDictNew(cell).area]);
            cellsDictNew(cell).Fpixels=double(imn(cellsDictNew(cell).pos(1):cellsDictNew(cell).pos(1)+cellsDictNew(cell).size(1)-1,...
                cellsDictNew(cell).pos(2):cellsDictNew(cell).pos(2)+cellsDictNew(cell).size(2)-1)).*cellsDictNew(cell).Fmask;
            cellsDictNew(cell).Ftotal=sum(cellsDictNew(cell).Fpixels(:));
            cellsDictNew(cell).Fmax=max(cellsDictNew(cell).Fpixels(:));
            cellsDictNew(cell).Fmean=cellsDictNew(cell).Ftotal/cellsDictNew(cell).area;
            cellsDictNew(cell).Fdata=[];
        end
    end
    function [overlap,celldistance]=CalcCellPairProperties(cells0,cells1,nbcell0,nbcell1,regshift)
        if ~exist('regshift','var')
            regshift=[0,0];
        end
        % Calculate properties of cell pairs
        % The overlap matrix
        overlap=zeros(nbcell0,nbcell1);
        celldistance=zeros(nbcell0,nbcell1);
        
        for n1=1:length(cells1)
            [a,b]=ind2sub(size(cells1(n1).mask),find(cells1(n1).mask));
            cell1xy=[a(:),b(:)];
            comdist=sqrt(sum(bsxfun(@minus,cells1(n1).pos+cells1(n1).Acom+regshift,cell2mat({cells0.pos}')+cell2mat({cells0.Acom}')).^2,2));
            for n0=1:length(cells0)
                if comdist(n0)>10*max(cells1(n1).size)
                    celldistance(n0,n1)=comdist(n0)^2;
                else
                    celldistance(n0,n1)=min(sum((bsxfun(@plus,cell1xy,cells1(n1).pos+regshift-cells0(n0).pos-cells0(n0).Acom)).^2,2));
                    if celldistance(n0,n1)< (max(cells1(n1).size)+max(cells0(n0).size))^2
                        overlap_slice=[max(cells0(n0).pos,cells1(n1).pos+regshift)+[1,1] min(cells0(n0).pos+cells0(n0).size,cells1(n1).pos+regshift+cells1(n1).size)];
                        overlap(n0,n1)=sum(sum(cells0(n0).mask((overlap_slice(1):overlap_slice(3))-cells0(n0).pos(1),(overlap_slice(2):overlap_slice(4))-cells0(n0).pos(2)).*...
                            cells1(n1).mask((overlap_slice(1):overlap_slice(3))-cells1(n1).pos(1)-regshift(1),(overlap_slice(2):overlap_slice(4))-cells1(n1).pos(2)-regshift(2))));
                    end
                end
                
            end
        end
        
    end
    function cellmapping=CalcHungarian(cost,appear_cost)
        if ~exist('appear_cost','var')
            appear_cost=1/0.02;
        end
        [nbcell0,nbcell1]=size(cost);
        if nbcell0>nbcell1
            cost=[cost zeros(nbcell0,nbcell0-nbcell1)]';
        elseif nbcell0<nbcell1
            cost=[cost;zeros(nbcell1-nbcell0,nbcell1)];
        end
        
        cost=[cost appear_cost*ones(size(cost)); appear_cost*ones(size(cost).*[1,2])];
        cellmapping=double(munkres(cost));
        if nbcell0>nbcell1
            cellmapping=cellmapping';
        end
        cellmapping=cellmapping(1:nbcell0,1:nbcell1);
    end
    function [assignment,cost] = munkres(costMat)
        % MUNKRES   Munkres Assign Algorithm
        %
        % [ASSIGN,COST] = munkres(COSTMAT) returns the optimal assignment in ASSIGN
        % with the minimum COST based on the assignment problem represented by the
        % COSTMAT, where the (i,j)th element represents the cost to assign the jth
        % job to the ith worker.
        %
        
        % This is vectorized implementation of the algorithm. It is the fastest
        % among all Matlab implementations of the algorithm.
        
        % Examples
        % Example 1: a 5 x 5 example
        %{
[assignment,cost] = munkres(magic(5));
[assignedrows,dum]=find(assignment);
disp(assignedrows'); % 3 2 1 5 4
disp(cost); %15
        %}
        % Example 2: 400 x 400 random data
        %{
n=400;
A=rand(n);
tic
[a,b]=munkres(A);
toc                 % about 6 seconds
        %}
        
        % Reference:
        % "Munkres' Assignment Algorithm, Modified for Rectangular Matrices",
        % http://csclab.murraystate.edu/bob.pilgrim/445/munkres.html
        
        % version 1.0 by Yi Cao at Cranfield University on 17th June 2008
        
        assignment = false(size(costMat));
        cost = 0;
        
        costMat(costMat~=costMat)=Inf;
        validMat = costMat<Inf;
        validCol = any(validMat);
        validRow = any(validMat,2);
        
        nRows = sum(validRow);
        nCols = sum(validCol);
        n = max(nRows,nCols);
        if ~n
            return
        end
        
        dMat = zeros(n);
        dMat(1:nRows,1:nCols) = costMat(validRow,validCol);
        
        %*************************************************
        % Munkres' Assignment Algorithm starts here
        %*************************************************
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %   STEP 1: Subtract the row minimum from each row.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        dMat = bsxfun(@minus, dMat, min(dMat,[],2));
        
        %**************************************************************************
        %   STEP 2: Find a zero of dMat. If there are no starred zeros in its
        %           column or row start the zero. Repeat for each zero
        %**************************************************************************
        zP = ~dMat;
        starZ = false(n);
        while any(zP(:))
            [r,c]=find(zP,1);
            starZ(r,c)=true;
            zP(r,:)=false;
            zP(:,c)=false;
        end
        
        while 1
            %**************************************************************************
            %   STEP 3: Cover each column with a starred zero. If all the columns are
            %           covered then the matching is maximum
            %**************************************************************************
            primeZ = false(n);
            coverColumn = any(starZ);
            if ~any(~coverColumn)
                break
            end
            coverRow = false(n,1);
            while 1
                %**************************************************************************
                %   STEP 4: Find a noncovered zero and prime it.  If there is no starred
                %           zero in the row containing this primed zero, Go to Step 5.
                %           Otherwise, cover this row and uncover the column containing
                %           the starred zero. Continue in this manner until there are no
                %           uncovered zeros left. Save the smallest uncovered value and
                %           Go to Step 6.
                %**************************************************************************
                zP(:) = false;
                zP(~coverRow,~coverColumn) = ~dMat(~coverRow,~coverColumn);
                Step = 6;
                while any(any(zP(~coverRow,~coverColumn)))
                    [uZr,uZc] = find(zP,1);
                    primeZ(uZr,uZc) = true;
                    stz = starZ(uZr,:);
                    if ~any(stz)
                        Step = 5;
                        break;
                    end
                    coverRow(uZr) = true;
                    coverColumn(stz) = false;
                    zP(uZr,:) = false;
                    zP(~coverRow,stz) = ~dMat(~coverRow,stz);
                end
                if Step == 6
                    % *************************************************************************
                    % STEP 6: Add the minimum uncovered value to every element of each covered
                    %         row, and subtract it from every element of each uncovered column.
                    %         Return to Step 4 without altering any stars, primes, or covered lines.
                    %**************************************************************************
                    M=dMat(~coverRow,~coverColumn);
                    minval=min(min(M));
                    if minval==inf
                        return
                    end
                    dMat(coverRow,coverColumn)=dMat(coverRow,coverColumn)+minval;
                    dMat(~coverRow,~coverColumn)=M-minval;
                else
                    break
                end
            end
            %**************************************************************************
            % STEP 5:
            %  Construct a series of alternating primed and starred zeros as
            %  follows:
            %  Let Z0 represent the uncovered primed zero found in Step 4.
            %  Let Z1 denote the starred zero in the column of Z0 (if any).
            %  Let Z2 denote the primed zero in the row of Z1 (there will always
            %  be one).  Continue until the series terminates at a primed zero
            %  that has no starred zero in its column.  Unstar each starred
            %  zero of the series, star each primed zero of the series, erase
            %  all primes and uncover every line in the matrix.  Return to Step 3.
            %**************************************************************************
            rowZ1 = starZ(:,uZc);
            starZ(uZr,uZc)=true;
            while any(rowZ1)
                starZ(rowZ1,uZc)=false;
                uZc = primeZ(rowZ1,:);
                uZr = rowZ1;
                rowZ1 = starZ(:,uZc);
                starZ(uZr,uZc)=true;
            end
        end
        
        % Cost of assignment
        assignment(validRow,validCol) = starZ(1:nRows,1:nCols);
        cost = sum(costMat(assignment));
    end
    function image=SegRenderNum(cells,imy,imx)
        if isempty(cells)
            if ~exist('imy','var') || ~exist('imx','var')
                image=[];
            else
                image=zeros(imy,imx);
            end
            return
        end
        cellpos=cell2mat({cells.pos}');
        cellsize=cell2mat({cells.size}');
        if ~exist('imy','var')
            ystart=min(cellpos(:,1));
            ystop=max(cellpos(:,1)+cellsize(:,1)-1);
        else
            ystart=1;
            ystop=imy;
        end
        if ~exist('imx','var')
            xstart=min(cellpos(:,2));
            xstop=max(cellpos(:,2)+cellsize(:,2)-1);
        else
            xstart=1;
            xstop=imx;
        end
        
        image=zeros(ystop-ystart+1,xstop-xstart+1);
        for j=1:length(cells)
            image=AddCell(image,[ystart,xstart],(j)*cells(j).mask,cells(j).pos);
        end
    end
    function newtarget=AddCell(target, targetpos, cellvalue, cellpos)
        relativepos=cellpos-targetpos;
        %find the coordinates of the region inside the target and inside the cellvalue
        trgtXslice=max(1,relativepos(1)+1):min(size(target,1),relativepos(1)+size(cellvalue,1));
        trgtYslice=max(1,relativepos(2)+1):min(size(target,2),relativepos(2)+size(cellvalue,2));
        cellXslice=max(1,-relativepos(1)+1):min(size(cellvalue,1), size(target,1)-relativepos(1));
        cellYslice=max(1,-relativepos(2)+1):min(size(cellvalue,2), size(target,2)-relativepos(2));
        %put the cell values inside target
        newtarget=target;
        newtarget(trgtXslice,trgtYslice)=target(trgtXslice,trgtYslice)+cellvalue(cellXslice,cellYslice);
    end
    function image=SegRenderCnt(cells,imy,imx)
        if isempty(cells)
            image=[];
            return
        end
        cellpos=cell2mat({cells.pos}');
        cellsize=cell2mat({cells.size}');
        if ~exist('imy','var')
            ystart=min(cellpos(:,1));
            ystop=max(cellpos(:,1)+cellsize(:,1)-1);
        else
            ystart=1;
            ystop=imy;
        end
        if ~exist('imx','var')
            xstart=min(cellpos(:,2));
            xstop=max(cellpos(:,2)+cellsize(:,2)-1);
        else
            xstart=1;
            xstop=imx;
        end
        
        image=zeros(ystop-ystart+1,xstop-xstart+1);
        for j=1:length(cells)
            image=AddCell(image,[ystart,xstart],cells(j).mask,cells(j).pos);
        end
    end
% Fluorescence Functions
    function extractFluorescence
            for cchannel=Tracked.cfg.ChannelAnlz'
                Data=openfiles(Tracked.cfg,Tracked.cfg.PositionAnlz{1},cchannel{1},['Loading ' cchannel{1} ' channel...']);
                %background parameters
                a=Tracked.Background.(matlab.lang.makeValidName(cchannel{1})).a;
                B=Tracked.Background.(matlab.lang.makeValidName(cchannel{1})).B;
                A=Tracked.Background.(matlab.lang.makeValidName(cchannel{1})).A;
                I=Tracked.Background.(matlab.lang.makeValidName(cchannel{1})).I;
                
                hwb=waitbar(0,['Extracting ' cchannel{1} ' fluorescence...']);
                step=1./length([Tracked.Frames.Cells]);
                prog=0;
                for cframe=1:length(Tracked.Frames)
                    
                    DataBS=(Data(cframe).raw-(a*I*A(cframe)+B))./I;
                    
                    for ccell=1:length(Tracked.Frames(cframe).Cells)
                        Fpxl=Tracked.Frames(cframe).Cells(ccell).Fmask.*getPixels(DataBS, Tracked.Frames(cframe).Cells(ccell).pos, Tracked.Frames(cframe).Cells(ccell).size);
                        Tracked.Frames(cframe).Cells(ccell).Fdata.(matlab.lang.makeValidName(cchannel{1}))=Fpxl;
                        prog=prog+step;
                        waitbar(prog, hwb)
                    end
                end
                delete(hwb)
            end
        end
        


end