classdef AudInAccOutMouse < Mouse
    % A class for mice of type AudInAccOutMouse
    
    properties (Constant)
        GCAMP = 'Aud in'
        JRGECO = 'Acc out'
    end
    
    methods
        function obj = AudInAccOutMouse(name, gcampJrGecoReversed)
            %AUDINACCOUTMOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj@Mouse(name, gcampJrGecoReversed, "AudInAccOutMice");
        end
    end
end

