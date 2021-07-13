classdef AudInAudOutMouse < Mouse
    % A class for mice of type AudInAudOutMouse
    
    properties (Constant)
        GCAMP = 'Aud in'
        JRGECO = 'Aud out'
    end
    
    methods
        function obj = AudInAudOutMouse(name, gcampJrGecoReversed)
            %AUDINAUDOUTMOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj@Mouse(name, gcampJrGecoReversed, "AudInAudOutMice");
        end
    end
end

