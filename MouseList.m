classdef MouseList < handle
    %MouseList Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        CONST_FOLDER_DELIMITER = "\";
        
        CONST_LIST_SAVE_PATH = "W:\shared\Timna\Gal Projects\Mouse Lists";
    end
    
    properties
        Type
        ObjectPath
        MousePathList
        LoadedMouseList
    end
    
    methods
        %========== Constructor Functions ==========
        function obj = MouseList(listType)
            %MouseList Construct an instance of this class
            %   Detailed explanation goes here
            obj.Type = listType;
            obj.ObjectPath = obj.CONST_LIST_SAVE_PATH + obj.CONST_FOLDER_DELIMITER + listType + ".mat";
            
            save(obj.ObjectPath, "obj");
        end
        
        function add(obj, mouse)
            for index = 1:length(obj.MousePathList)
                if obj.MousePathList(index).Name == mouse.Name
                    obj.MousePathList(index).Path = mouse.ObjectPath;
                    save(obj.ObjectPath, "obj");
                    return;
                end
            end
            
            newMouse.Name = mouse.Name;
            newMouse.Path = mouse.ObjectPath;
            obj.MousePathList = [obj.MousePathList, newMouse];
            save(obj.ObjectPath, "obj");
        end
        
        function loadMice(obj)
            for mouseStruct = obj.MousePathList
                curMouse = load(mouseStruct.Path).obj;
                obj.LoadedMouseList = [obj.LoadedMouseList, curMouse];
            end
        end
        
        % ================ Plot ================
        function plotCorrelationScatterPlot(obj, descriptionVector)
           miceAmount = size(obj.LoadedMouseList, 2);
           [~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getSignals(descriptionVector);
           
           fig = figure("Name", "Comparing correlations of type " + signalTitle, "NumberTitle", "off");
           
           index = 1;
           
           for mouse = obj.LoadedMouseList
               curPlot = subplot(2, ceil(miceAmount / 2), index);
               mouse.drawScatterPlot(curPlot, descriptionVector)
               title(curPlot, {"Mouse " + mouse.Name}, 'Interpreter', 'none')
               index = index + 1;
           end
           sgtitle(fig, signalTitle)
        end
        
        function plotCorrelationBar(obj)
            [correlations, xLabels, mouseNames] = obj.calculateCorrelations();
            
            obj.helperPlotCorrelationBarByMouse(correlations, xLabels, mouseNames);
            obj.helperPlotCorrelationBarSummary(correlations, xLabels);
        end
        
        % ================ Helpers ================
        % ==== Plots ====
        function [correlations, xLabels, mouseNames] = calculateCorrelations(obj)
            currentCorrelations = [];
            finalCorrelations = [];
            currentXLabels = [];
            finalXLabels = [];
            mouseNames = [];
            
            for mouse = obj.LoadedMouseList
                % Passive
                for state = Mouse.CONST_PASSIVE_STATES
                    for soundType = Mouse.CONST_PASSIVE_SOUND_TYPES
                        for time = Mouse.CONST_PASSIVE_TIMES
                            currentXLabels = [currentXLabels; (time) + ' ' + (state) + ' ' + (soundType)];
                            
                            descriptionVector = ["Passive", (state), (soundType), (time)];
                            mouseCorrelation = mouse.getWholeSignalCorrelation(descriptionVector);
                            
                            currentCorrelations = [currentCorrelations; mouseCorrelation];
                        end
                    end
                end
                
                % Task
                currentXLabels = [currentXLabels; "Task"];
                
                descriptionVector = ["Task", "onset"];
                mouseCorrelation = mouse.getWholeSignalCorrelation(descriptionVector);
                
                currentCorrelations = [currentCorrelations; mouseCorrelation];
                
                % Add to all
                finalXLabels = [finalXLabels, currentXLabels];
                finalCorrelations = [finalCorrelations, currentCorrelations];
                mouseNames = [mouseNames, mouse.Name];
                
                % Clean
                currentXLabels = [];
                currentCorrelations = [];
            end
            xLabels = finalXLabels;
            correlations = finalCorrelations;
        end
        
    end
    
    methods (Static)
        % ================ Helpers ================
        function helperPlotCorrelationBarByMouse(correlations, xLabels, mouseNames)
            fig = figure("Name", "Results of comparing whole signal correlation", "NumberTitle", "off");
            ax = axes;
            
            categories = categorical(xLabels);
            categories = reordercats(categories, xLabels(:,1));
            
            bar(ax, categories, correlations)
            set(ax,'TickLabelInterpreter','none')
            title(ax, "Whole signal correlations by mouse", 'Interpreter', 'none')
            ylabel("Correlation")
            legend(ax, mouseNames, 'Interpreter', 'none')
            ylim(ax, [-1, 1])
        end
        
        function helperPlotCorrelationBarSummary(correlations, xLabels)
            fig = figure("Name", "Results of comparing whole signal correlation", "NumberTitle", "off");
            ax = axes;
            
            correlationMean = mean(correlations, 2);
            
            categories = categorical(xLabels(:,1));
            categories = reordercats(categories, xLabels(:,1));
            
            bar(ax, categories, correlationMean)
            set(ax,'TickLabelInterpreter','none')
            title(ax, "Whole signal correlations summary for all mice", 'Interpreter', 'none')
            ylabel(["Correlation", "(mean of all mice)"])
            ylim(ax, [-1, 1])
        end
    end
end

