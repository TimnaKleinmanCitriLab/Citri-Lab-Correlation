classdef AudInAccOutMouse < Mouse
    %AUDINACCOUTMOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        GCAMP = 'Aud in'
        JRGECO = 'Acc out'
    end
    
    methods
        function obj = AudInAccOutMouse(name, gcampJrGecoReversed, saveLocation)
            %AUDINACCOUTMOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj@Mouse(name, gcampJrGecoReversed, saveLocation);
        end
    end
end

