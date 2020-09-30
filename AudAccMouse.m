classdef AudAccMouse < Mouse
    %ACCAUDMOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        GCAMP = 'Aud'
        JRGECO = 'Acc'
    end
    
    
    methods
        function obj = AudAccMouse(name, gcampJrGecoReversed)
            %ACCAUDMOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj@Mouse(name, gcampJrGecoReversed, "AudAccMice");
        end
    end
end

