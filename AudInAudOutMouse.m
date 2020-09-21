classdef AudInAudOutMouse < Mouse
    %AUDINAUDOUTMOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        GCAMP = 'Aud in'
        JRGECO = 'Aud out'
    end
    
    methods
        function obj = AudInAudOutMouse(name, gcampJrGecoReversed)
            %AUDINAUDOUTMOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj@Mouse(name, gcampJrGecoReversed);
        end
    end
end

