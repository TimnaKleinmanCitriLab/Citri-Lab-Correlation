classdef AccInAccOutMouse < Mouse
    % A class for mice of type AccInAccOutMouse
    
    properties (Constant)
        GCAMP = 'Acc in'
        JRGECO = 'Acc out'
    end
    
    methods
        function obj = AccInAccOutMouse(name, gcampJrGecoReversed)
            %ACCINACCOUTMOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj@Mouse(name, gcampJrGecoReversed, "AccInAccOutMice");
        end
    end
end

