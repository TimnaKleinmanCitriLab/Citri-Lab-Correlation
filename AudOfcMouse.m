classdef AudOfcMouse < Mouse
    %OFCAUDMOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        GCAMP = 'Aud'
        JRGECO = 'Ofc'
    end
    
    methods
        function obj = AudOfcMouse(name, gcampJrGecoReversed)
            %OFCAUDMOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj@Mouse(name, gcampJrGecoReversed);
        end
    end
end

