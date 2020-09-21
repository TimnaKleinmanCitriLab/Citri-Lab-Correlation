classdef AccInAccOutMouse < Mouse
    %ACCINACCOUTMOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        GCAMP = 'Acc in'
        JRGECO = 'Acc out'
    end
    
    methods
        function obj = AccInAccOutMouse(name, gcampJrGecoReversed)
            %ACCINACCOUTMOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj@Mouse(name, gcampJrGecoReversed);
        end
    end
end

